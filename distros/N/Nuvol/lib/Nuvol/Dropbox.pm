package Nuvol::Dropbox;
use Mojo::Base -base, -signatures;

1;

=encoding utf8

=head1 NAME

Nuvol::Dropbox - Dropbox services

=head1 SYNOPSIS

    use Nuvol::Connector;
    my $connector = Nuvol::Connector->new($configfile, 'Dropbox');

=head1 DESCRIPTION

L<Nuvol::Dropbox> provides modules with internal methods to access Dropbox services.

On authentication, Nuvol will be registered as C<Nuvol Connector>. You can check or revoke its
permissions in the tab C<Connected apps> of your L<Dropbox
account|https://www.dropbox.com/account/connected_apps>. 

=head1 SEE ALSO

L<Nuvol>, L<Nuvol::Dropbox::Connector>, L<Nuvol::Dropbox::Drive>, L<Nuvol::Dropbox::File>,
L<Nuvol::Dropbox::Folder>, L<Nuvol::Dropbox::Item>.

=cut
