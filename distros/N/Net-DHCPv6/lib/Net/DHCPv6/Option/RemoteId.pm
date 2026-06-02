#!/bin/false
# ABSTRACT: Remote ID option (code 37) -- enterprise-number + opaque data
# PODNAME: Net::DHCPv6::Option::RemoteId
use strictures 2;

package Net::DHCPv6::Option::RemoteId;
$Net::DHCPv6::Option::RemoteId::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $ENT_NUM_LEN = 4;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

sub new {
    my ( $class, %args ) = @_;
    croak 'RemoteId requires enterprise_number' unless defined $args{enterprise_number};
    croak 'RemoteId requires remote_data'       unless defined $args{remote_data};
    $args{code} = $OPTION_REMOTE_ID;
    $args{data} = pack( 'N', $args{enterprise_number} ) . $args{remote_data};
    my $self = $class->SUPER::new( %args );
    $self->{enterprise_number} = $args{enterprise_number};
    $self->{remote_data}       = $args{remote_data};
    return bless $self, $class;
}

sub enterprise_number { return shift->{enterprise_number} }
sub remote_data       { return shift->{remote_data} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated RemoteId option' )
        if CORE::length( $payload ) < $ENT_NUM_LEN;
    my $en   = unpack( 'N', substr( $payload, 0, $ENT_NUM_LEN ) );
    my $rest = substr( $payload, $ENT_NUM_LEN );
    return $class->new( enterprise_number => $en, remote_data => $rest );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_REMOTE_ID} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::RemoteId - Remote ID option (code 37) -- enterprise-number + opaque data

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::RemoteId;
  my $opt = Net::DHCPv6::Option::RemoteId->new(
      enterprise_number => 9,        # Cisco (IANA PEN)
      remote_data       => "\x00\x01\x02\x03",
  );

=head1 DESCRIPTION

Carries a relay agent's remote identification, consisting of an IANA
Private Enterprise Number (PEN, see
L<https://www.iana.org/assignments/enterprise-numbers>)
and opaque data.  See RFC 4649.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<enterprise_number> and C<remote_data>.

=head2 enterprise_number

Returns the IANA enterprise number.

=head2 remote_data

Returns the opaque remote identification data.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
