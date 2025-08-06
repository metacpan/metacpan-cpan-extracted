####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1,
#        XDR::Gen version 0.0.5 and LibVirt version v11.6.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################

package Protocol::Sys::Virt::KeepAlive::XDR v11.6.0;

use v5.14;
use warnings FATAL => 'uninitialized';
use Config;
use Carp qw(croak);
use constant PROGRAM => 1801807216; # 0x6b656570
use constant PROTOCOL_VERSION => 1; # 1
# Define elements from enum 'procedure'
use constant {
    PROC_PING => 1,
    PROC_PONG => 2,
};
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_procedure {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1] = unpack("l>", substr( $_[3], $_[2] ) );
    die "Out of range enum value supplied: $_[1]"
        unless vec(state $m = pack('H*', '06'),
                   $_[1], 1);
    $_[2] += 4;
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_procedure {
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'enum' value"
        unless defined $_[1];
    die "Out of range enum value: $_[1]"
        unless vec(state $m = pack('H*', '06'),
                   $_[1], 1);
    substr( $_[3], $_[2] ) = pack("l>", $_[1]);
    $_[2] += 4;
}


1;

__END__

=head1 NAME

Protocol::Sys::Virt::KeepAlive::XDR - Constants and (de)serializers for KeepAlive messages

=head1 VERSION

v11.6.0

Based on LibVirt tag v11.6.0

=head1 SYNOPSYS

  use Protocol::Sys::Virt::Transport::XDR;
  use Protocol::Sys::Virt::KeepAlive::XDR;
  my $transport = 'Protocol::Sys::Virt::Transport::XDR';
  my $ka = 'Protocol::Sys::Virt::KeepAlive::XDR';

  my $out = '';
  my $idx = 0;
  my $value = {
     proc => $ka->PROC_PING,
  };
  $transport->serialize_Header( $value, $idx, $out );


=head1 SERIALIZERS

=over 8

=item * procedure

=back

head1 DESERIALIZERS

=over 8

=item * procedure

=back

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution


