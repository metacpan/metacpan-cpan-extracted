package Net::ISC::DHCPd::OMAPI::Control;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Control - OMAPI control class

=head1 SEE ALSO

L<Net::ISC::DHCPd::OMAPI::Actions>.
L<Net::ISC::DHCPd::OMAPI::Meta::Attribute>.

=head1 SYNOPSIS

 use Net::ISC::DHCPd::OMAPI;

 $omapi = Net::ISC::DHCPd::OMAPI->new(...);
 $omapi->connect
 $control = $omapi->new_object("control", { $attr => $value });
 $control->read; # retrieve server information
 $control->$attr($value); # update a value
 $control->write; # write to server

=cut

use Net::ISC::DHCPd::OMAPI::Sugar;
use Moose;

with 'Net::ISC::DHCPd::OMAPI::Actions';

=head1 METHODS

=head2 shutdown_server

 $bool = $self->shutdown_server;

Will shutdown the remote server. See C<dhcpd.8> for details.

=cut

sub shutdown_server {
    my $self = shift;
    my $buffer;

    $self->errstr("");

    for my $cmd ("open", "set state = 2", "update") {
        ($buffer) = $self->_cmd($cmd);

        unless($buffer =~ /state\s=/) {
            warn $buffer;
            $self->errstr($buffer);
            return;
        }
    }

    $self->parent->disconnect;

    return 1;
}

around shutdown_server => \&Net::ISC::DHCPd::OMAPI::Actions::_around;

=head1 ACKNOWLEDGEMENTS

Most of the documentation is taken from C<dhcpd(8)>.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
