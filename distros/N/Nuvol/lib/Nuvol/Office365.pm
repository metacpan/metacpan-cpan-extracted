package Nuvol::Office365;
use Mojo::Base -base, -signatures;

1;

=encoding utf8

=head1 NAME

Nuvol::Office365 - Office 365 services

=head1 SYNOPSIS

    use Nuvol::Connector;
    my $connector = Nuvol::Connector->new($configfile, 'Office365');

=head1 DESCRIPTION

L<Nuvol::Office365> provides modules with internal methods to access Office 365 services.

On authentication, Nuvol will be registered as C<Nuvol Office 365 Connector>. You can check or
revoke its permissions in the app console of your L<Personal Microsoft
Account|https://account.live.com/consent/Manage> or L<Office 365 Business
Account|https://portal.office.com/account/#apps>.

=head1 SEE ALSO

L<Nuvol>, L<Nuvol::Office365::Connector>, L<Nuvol::Office365::Drive>, L<Nuvol::Office365::File>,
L<Nuvol::Office365::Folder>, L<Nuvol::Office365::Item>.

=cut
