package RT::Extension::Gravatar;

use 5.008003;
use strict;
use warnings;

our $VERSION = '2.01';

package RT::User;

use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;

sub GravatarUrl {
    my $self = shift;
    my $size = shift;

    my $email = $self->EmailAddress || '';
    return unless length $email;

    my $url  = 'https://gravatar.com/avatar/';
       $url .= md5_hex(lc $email);
       $url .= "?s=" . $size if $size;

    return $url;
}

sub HasGravatar {
    my $self = shift;

    my $url = $self->GravatarUrl;
    return 0 unless $url;

    $url .= "?d=404";

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);

    return $response->is_success;
}

=head1 NAME

RT::Extension::Gravatar - Displays Gravatar images within RT

=head1 DESCRIPTION

This Plugin displays Gravatar image on the following pages:

=over

=item More about the requestors widget

=item Modify user page

=item About me (Preferences)

=item User Summary

=back

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::Gravatar');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::Gravatar));

or add C<RT::Extension::Gravatar> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj/*

=item Restart your webserver

=back

=head1 METHODS ADDED TO OTHER CLASSES

=head2 RT::User

=head3 GravatarUrl

Return the gravatar image url of the user.

=head3 HasGravatar

Return true if the user has an gravatar image.

=head1 AUTHOR

Christian Loos <cloos@netsandbox.de>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (C) 2010-2016, Christian Loos.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 SEE ALSO

L<http://bestpractical.com/rt/>

L<http://gravatar.com/>

=cut

1;
