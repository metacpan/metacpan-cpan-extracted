use strict;
use warnings;

package RT::Extension::EmailReplyDelimiter;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::EmailReplyDelimiter - Strip text from emails after a delimiter

=head1 DESCRIPTION

This extension alters email while it is being received by L<Request Tracker|https://bestpractical.com/request-tracker>,
removing text and any associated image attachments appearing after a reply
delimiter such as "I<##- Please type your reply above this line -##>".

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add these lines:

    Set(@EmailReplyDelimiters, '##- Please type your reply above this line -##');
    Plugin('RT::Extension::EmailReplyDelimiter');

=item Restart your web server

=back

=head1 CONFIGURATION

In F<RT_SiteConfig.pm>, adjust I<@EmailReplyDelimiters> so it contains a
list of all of the email reply delimiters you will be using.  Restart the
service after making changes to this configuration item.

Then adjust the relevant RT templates to include a reply delimiter, on a
line by itself, in the appropriate place.

=head1 ISSUES AND CONTRIBUTIONS

The project is held on L<Codeberg|https://codeberg.org>; its issue tracker
is at L<https://codeberg.org/a-j-wood/rt-extension-emailreplydelimiter/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Andrew Wood.

License GPLv3+: GNU GPL version 3 or later: https://gnu.org/licenses/gpl.html

This is free software: you are free to change and redistribute it.  There is
NO WARRANTY, to the extent permitted by law.

=cut

# Global variable which is set by our /REST/1.0/NoAuth/mail-gateway "Pre"
# callback when it has overridden the
# RT::EmailParser::SmartParseMIMEEntityFromScalar function.
our $ParserOverridden = 0;

# Modify the given MIME::Entity object, which represents an inbound email,
# by looking for the configured email reply delimiters in the text parts and
# stripping them, all that follows them, and any attachments that were only
# referenced by HTML tags in the stripped parts.
#
# This gets called just after
# RT::EmailParser::SmartParseMIMEEntityFromScalar while the mail gateway is
# receiving a new email.
#
sub ModifyMIMEEntity {
    my ($TopEntity) = @_;

    # If the parsing failed or there was no subject line detected, make no
    # changes.
    return
      if ( ( not defined $TopEntity )
        || ( not ref $TopEntity )
        || ( not defined $TopEntity->head )
        || ( not $TopEntity->head->count('subject') ) );

    # If no EmailReplyDelimiters are defined, do nothing.
    #
    my $Delimiters = RT->Config->Get('EmailReplyDelimiters');
    $Delimiters = []            if ( not defined $Delimiters );
    $Delimiters = [$Delimiters] if ( not ref $Delimiters );

    return if ( 0 == scalar @{$Delimiters} );

    if ( $TopEntity->bodyhandle ) {

        # If there's a top-level body, this is a simple message with no
        # attachments, so just process the body directly.

        _ProcessEntity( $Delimiters, $TopEntity, {}, {} );

    }
    else {

        # If there isn't a top-level body, this is a multipart message, so
        # process each of the parts which has a body, and then remove any of
        # those which were flagged for removal by processing.

        my @MessageParts = $TopEntity->parts;

        # Content IDs seen in kept sections of entity bodies.
        my %ContentIdInKeptSection = ();

        # Content IDs seen in removed sections of entity bodies.
        my %ContentIdInRemovedSection = ();

        foreach (@MessageParts) {
            _ProcessEntity( $Delimiters, $_, \%ContentIdInKeptSection,
                \%ContentIdInRemovedSection );
        }

        # Content IDs seen ONLY in removed sections of entity bodies.
        my %ContentIdToRemove = ();
        foreach ( keys %ContentIdInRemovedSection ) {
            $ContentIdToRemove{$_} = 1
              if ( not exists $ContentIdInKeptSection{$_} );
        }

        # Remove parts the need to be removed.
        if ( scalar keys %ContentIdToRemove > 0 ) {
            my @RemainingParts =
              grep { _ShouldKeepPart( $_, \%ContentIdToRemove ) } @MessageParts;
            $TopEntity->parts( \@RemainingParts );
        }

    }
}

# Process a MIME::Entity, adjusting its body if necessary, and populating
# %$ContentIdInKeptSection and %$ContentIdInRemovedSection with the
# content-IDs detected in the body section that was kept, and in the body
# section that was removed (if any), respectively.
#
sub _ProcessEntity {
    my ( $Delimiters, $Entity, $ContentIdInKeptSection,
        $ContentIdInRemovedSection, $Depth )
      = @_;
    my (
        $EffectiveType,  $TextType, $BodyContent,
        $RemovedContent, $FailedUpdate
    );

    $EffectiveType = $Entity->effective_type;

    # Guard against deep recursion.
    $Depth = 0 if ( not defined $Depth );
    $Depth++;
    return if ( $Depth > 3 );

    # Recurse into multipart entities.
    if ( $EffectiveType =~ /^multipart/ ) {
        _ProcessEntity( $Delimiters, $_, $ContentIdInKeptSection,
            $ContentIdInRemovedSection, $Depth )
          foreach ( $Entity->parts );
        return;
    }

    return if ( $EffectiveType !~ /^text\/(plain|html)/ );
    $TextType = $1;

    $BodyContent = $Entity->bodyhandle->as_string;
    return if ( not defined $BodyContent );

    $RemovedContent = undef;

    # If any entity updates fail, we will write the original message to stdout
    # and return early.
    $FailedUpdate = 0;

    # If a delimiter is found, remove it and anything following it.
    foreach my $Delimiter ( @{ $Delimiters || [] } ) {

        if ( $TextType eq 'plain' ) {
            $RemovedContent = $1
              if ( $BodyContent =~ s/(\s+\Q$Delimiter\E.+)$//s );
        }
        else {
            $RemovedContent = $2
              if ( $BodyContent =~ s/(\s+|>\s*)(\Q$Delimiter\E.+)$/$1/s );

            if ( defined $RemovedContent ) {
                $BodyContent .= '</body></html>'
                  if ( $RemovedContent =~ /<\/body/i );
            }
        }

        if ( defined $RemovedContent ) {
            my $IO;
            $IO = $Entity->bodyhandle->open('w');
            if ($IO) {
                $IO->print($BodyContent);
                if ( not $IO->close ) {
                    $FailedUpdate = 1;
                    RT->Logger->error(
"EmailReplyDelimiter failed to close bodyhandle after rewrite"
                    );
                }
            }
            else {
                RT->Logger->error(
                    "EmailReplyDelimiter failed to open bodyhandle for rewrite"
                );
                $FailedUpdate = 1;
            }

            last;
        }
    }

    # If we tried and failed to update the body, exit early instead of
    # trying to delete any attachments.
    if ($FailedUpdate) {
        RT->Logger->error(
            "EmailReplyDelimiter detected errors - skipping attachment removal"
        );
        return;
    }

    # If this is an HTML part, look for content IDs referenced in tags, and
    # update the hash references as described above.
    if ( $TextType eq 'html' ) {
        foreach ( split /</, $BodyContent ) {
            next if ( !/\s(?:src|href)=(?:['"])?cid:([^'">\s]+)/i );
            $ContentIdInKeptSection->{$1} = 1;
        }
        if ( defined $RemovedContent ) {
            foreach ( split /</, $RemovedContent ) {
                next if ( !/\s(?:src|href)=(?:['"])?cid:([^'">\s]+)/i );
                $ContentIdInRemovedSection->{$1} = 1;
            }
        }
    }
}

# Return true if the given MIME::Entity should be kept in the message: it
# should be kept if either it has no "Content-ID", or if its "Content-ID"
# value does NOT appear as a key in the hashref %$ContentIdToRemove.
#
sub _ShouldKeepPart {
    my ( $Entity, $ContentIdToRemove ) = @_;
    my ( $ContentIdHeader, $ContentId );

    $ContentIdHeader = $Entity->head->get( 'content-id', 0 );
    return 1 if ( not defined $ContentIdHeader );
    return 1 if ( $ContentIdHeader !~ /^(<)?(.+?)(?(1)>)\s*$/ );

    $ContentId = $2;

    return 1 if ( not exists $ContentIdToRemove->{$ContentId} );

    return 0;
}

1;
