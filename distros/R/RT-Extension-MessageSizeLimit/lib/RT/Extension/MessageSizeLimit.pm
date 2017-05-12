use strict;
use warnings;
package RT::Extension::MessageSizeLimit;

our $VERSION = '0.02';

=head1 NAME

RT-Extension-MessageSizeLimit - Force web message size limit on ticket create/update

=head1 DESCRIPTION

This RT extension enforces a certain message size limit when a user create a
ticket or make a comment/correspondance on it.

It uses a guess of outgoing mail size based on subject/content/attachments. It
may miss a few bytes from mail headers, templates contents.

You would typically set the limit a little bit lower than your outgoing MTA
limit.

See the configuration example under L</INSTALLATION>.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::MessageSizeLimit');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::MessageSizeLimit));

or add C<RT::Extension::MessageSizeLimit> to your existing C<@Plugins> line.

Then configure the limit (default 9MB) using the C<$MessageSizeLimit>
config option.  This option takes the generic form of:

    Set( $MessageSizeLimit, BYTES );

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 IMPLEMENTATION DETAILS

=head2 Methods

=head3 BytesToHuman

Take BYTES, returns a basic human readable representation of it.

=cut

sub BytesToHuman {
    my $bytes = shift;

    if ( $bytes >= 1000 * 1000 * 1000 ) {
        return sprintf("%0.2f%s", $bytes / 1000 / 1000 / 1000, "GB");
    } elsif ( $bytes >= 1000 * 1000 ) {
        return sprintf("%0.2f%s", $bytes / 1000 / 1000, "MB");
    } elsif ( $bytes >= 1000 ) {
        return sprintf("%0.2f%s", $bytes / 1000, "kB");
    } else {
        return sprintf("%0.2f%s", $bytes, "B");
    }
}

=head3 CheckMessageSizeLimit

This is the main routine, it takes args from RT callbacks and validate message size.

Returns undef if size isn't exceeded, localized error message if it has been exceeded.

=cut

sub CheckMessageSizeLimit {
    my %args = (
        Subject     => '',
        Content     => '',
        Attachments => undef,
        CurrentUser => undef,
        @_
    );

    my $max_size = RT->Config->Get('MessageSizeLimit') || 9 * 1000 * 1000;
    my $size = 0;

    # Compute subject size
    $size += length($args{Subject}) if ( $args{Subject} );

    # Compute body size
    $size += length($args{Content}) if ( $args{Content} );

    # Add attachments sizes if any
    foreach my $file_name ( keys %{$args{'Attachments'}} ) {
        my $attach_size = length($args{'Attachments'}{$file_name}->as_string);

        RT->Logger->debug("Attachment size: $attach_size B");
        $size += $attach_size;
    }

    RT->Logger->debug("Message size: $size");

    if ( $size && $size > $max_size ) {
        RT->Logger->info("Message size limit exceeded: $size / $max_size");
        return $args{'CurrentUser'}->loc("Message size limit exceeded"). " (".BytesToHuman($size)." / ".BytesToHuman($max_size)."), ".$args{'CurrentUser'}->loc("please reduce message size or remove attachments");
    }
    
    return undef;
}


=head1 TODO

=over 4

=item Dynamic enforcement using javascript

=item Allow translation of size units

=back

=head1 AUTHOR

Emmanuel Lacour, E<lt>elacour@home-dn.netE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-MessageSizeLimit@rt.cpan.org|mailto:bug-RT-Extension-MessageSizeLimit@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-MessageSizeLimit>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2016 by Emmanuel Lacour <elacour@home-dn.net>

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
