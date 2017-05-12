package Net::ISC::DHCPd::Config::Root;

=head1 NAME

Net::ISC::DHCPd::Config::Root - Role for root config classes

=head1 DESCRIPTION

This role is applied to root classes, such as L<Net::ISC::DHCPd::Config>
and L<Net::ISC::DHCPd::Config::Include>.

=cut

use Moose::Role;
use MooseX::Types::Path::Class 0.05 qw(File);

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 file

This attribute holds a L<Path::Class::File> object representing
path to a config file. Default value is "/etc/dhcp3/dhcpd.conf".

=cut


has fh => (
    is => 'rw',
    isa => 'FileHandle',
    required => 0,
);

has file => (
    is => 'rw',
    isa => File,
    coerce => 1,
    default => sub { Path::Class::File->new('', 'etc', 'dhcp3', 'dhcpd.conf') },
);

=head1 METHODS

=head2 generate

Will use L<Net::ISC::DHCPd::Config::Role/generate_config_from_children>
to convert the object graph into text.

=cut

sub generate {
    shift->generate_config_from_children ."\n";
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

1;
