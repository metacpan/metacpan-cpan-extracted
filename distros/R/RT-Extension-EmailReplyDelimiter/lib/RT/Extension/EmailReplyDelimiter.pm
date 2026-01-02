use strict;
use warnings;

package RT::Extension::EmailReplyDelimiter;

our $VERSION = '0.10';

=head1 NAME

RT::Extension::EmailReplyDelimiter - Strip text from emails after a delimiter

=head1 DESCRIPTION

This extension alters email while it is being received by L<Request Tracker|https://bestpractical.com/request-tracker>,
removing text and any associated image attachments appearing after a reply
delimiter such as "I<##- Please type your reply above this line -##>".

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, 5.0.1, and 6.0.2.

=head1 INSTALLATION

As root, build the Makefile and use it to install the extension.
This example works with Debian's B<request-tracker5> package:

 export RTHOME=/usr/share/request-tracker5/lib
 perl Makefile.PL
 make
 make install

Edit your F<RT_SiteConfig.pm> file or equivalent, such as
F</etc/request-tracker5/RT_SiteConfig.pm>, and add these lines:

 Set(@EmailReplyDelimiters,
     '##- Please type your reply above this line -##',
     qr/<div[^>]+id="appendonsend"/
 );
 Plugin('RT::Extension::EmailReplyDelimiter');

Then, restart the service.

=head1 CONFIGURATION

In F<RT_SiteConfig.pm>, adjust I<@EmailReplyDelimiters> so it contains a
list of all of the email reply delimiters you will be using.

Delimiters can be either literal strings (quoted with single or double
quotes), or compiled regular expressions (quoted using C<qr//>).

Restart the service after making changes to this configuration item.

Then adjust the relevant RT templates to include a reply delimiter, on a
line by itself, in the appropriate place.

=head2 Examples

Note that for the extension to be enabled, this line is always required:

 Plugin('RT::Extension::EmailReplyDelimiter');

The following examples only suggest different reply delimiters; the
C<Plugin()> line should always also be present.

Simplest possible configuration:

 Set(@EmailReplyDelimiters,
     '##- Please type your reply above this line -##'
 );

For this to work, you'll need to add
"I<##- Please type your reply above this line -##>"
to all of your RT templates in the appropriate place.
Then, when someone replies to an RT message by email, the quoted message
they are replying to will not be included when their reply reaches RT.

Configuration which finds and removes the quoted message when the sender is
using a recent Outlook version, or Outlook webmail, and also includes the
template-dependent configuration above:

 Set(@EmailReplyDelimiters,
     '##- Please type your reply above this line -##',
     qr/<div[^>]+id="appendonsend"/
 );

A configuration which removes the quoted part from most messages sent from
Outlook, with two fallback template-dependent delimiters which work as
above:

 Set(@EmailReplyDelimiters,
     # New Outlook and webmail put this right before the quoted text starts:
     qr/<div[^>]+id="appendonsend"/,
 
     # Mobile Outlook puts this around the quoted message:
     qr/<div[^>]+id="divRplyFwdMsg"/,
 
     # Classic Outlook inserts a div like this before quoted text:
     '<div style="border:none;border-top:solid #E1E1E1 1.0pt;padding:3.0pt 0in 0in 0in">',
 
     # Outlook puts this in the plain text version - a line made of
     # underscores then From on the line below that, with a Windows style
     # newline:
     "________________________________\r\nFrom: ",
 
     # Put these in the RT templates themselves, so we can detect and remove
     # the quoted part of replies even if none of the above matches:
     '##- Please type your reply above this line.',
     '##- Do not edit quoted section when replying.',
 );

The benefit of the more complex configuration is that it can strip all of
the quoted text, not leaving any header parts.
The downside is that if someone I<forwards> an email from Outlook to RT, the
forwarded content is likely to be lost.

=head1 ISSUES AND CONTRIBUTIONS

The project is held on L<Codeberg|https://codeberg.org>; its issue tracker
is at L<https://codeberg.org/ivarch/rt-extension-emailreplydelimiter/issues>.

The following people have contributed to this project, and their assistance
is acknowledged and greatly appreciated:

=over

=item *

L<grantemsley|https://codeberg.org/grantemsley> - fixed issues with
quoted-printable messages, added support for regular expression delimiters,
and provided examples for removing quoted text from messages sent from
Outlook (L<#1|https://codeberg.org/ivarch/rt-extension-emailreplydelimiter/pulls/1>).

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2023, 2026 Andrew Wood.

License GPLv3+: GNU GPL version 3 or later: L<https://gnu.org/licenses/gpl.html>

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

    # Decode quoted-printable if needed
    my $WasQuotedPrintable = 0;
    if ( $Entity->head->mime_encoding =~ /quoted-printable/i ) {
        require MIME::QuotedPrint;
        $BodyContent = MIME::QuotedPrint::decode($BodyContent);
        $WasQuotedPrintable = 1;
    }

    $RemovedContent = undef;

    # If any entity updates fail, we will write the original message to stdout
    # and return early.
    $FailedUpdate = 0;

    # If a delimiter is found, remove it and anything following it.
    foreach my $Delimiter ( @{ $Delimiters || [] } ) {
        my $IsRegex = ref($Delimiter) eq 'Regexp';
        
        $RT::Logger->debug("EmailReplyDelimiter testing: " . 
            ($IsRegex ? "regex pattern" : $Delimiter));
        
        if ( $TextType eq 'plain' ) {
            if ( $IsRegex ) {
                $RemovedContent = $1
                  if ( $BodyContent =~ s/(\s+$Delimiter.+)$//s );
            } else {
                $RemovedContent = $1
                  if ( $BodyContent =~ s/(\s+\Q$Delimiter\E.+)$//s );
            }
        }
        else {
            if ( $IsRegex ) {
                $RemovedContent = $2
                  if ( $BodyContent =~ s/(\s+|>\s*)($Delimiter.+)$/$1/s );
            } else {
                $RemovedContent = $2
                  if ( $BodyContent =~ s/(\s+|>\s*)(\Q$Delimiter\E.+)$/$1/s );
            }

            if ( defined $RemovedContent ) {
                $BodyContent .= '</body></html>'
                  if ( $RemovedContent =~ /<\/body/i );
            }
        }

        if ( defined $RemovedContent ) {
            # Re-encode if we decoded earlier
            if ( $WasQuotedPrintable ) {
                $BodyContent = MIME::QuotedPrint::encode($BodyContent);
            }
            
            $RT::Logger->info("EmailReplyDelimiter Removed " . 
                length($RemovedContent) . " characters after delimiter");
            
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