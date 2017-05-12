package Net::ISC::DHCPd::OMAPI::Lease;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Lease - OMAPI lease class

=head1 DESCRIPTION

This class does the roles L<Net::ISC::DHCPd::OMAPI::Actions>
and L<Net::ISC::DHCPd::Role::Lease>. See also
L<Net::ISC::DHCPd::OMAPI::Meta::Attribute>.

=head1 SYNOPSIS

 use Net::ISC::DHCPd::OMAPI;

 $omapi = Net::ISC::DHCPd::OMAPI->new(...);
 $omapi->connect
 $lease = $omapi->new_object("lease", { $attr => $value });
 $lease->$attr($value); # same as in constructor
 $lease->read; # retrieve server information
 $lease->write; # write to server

=cut

use Net::ISC::DHCPd::OMAPI::Sugar;
use Moose;

with qw/
    Net::ISC::DHCPd::Role::Lease
    Net::ISC::DHCPd::OMAPI::Actions
/;

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
