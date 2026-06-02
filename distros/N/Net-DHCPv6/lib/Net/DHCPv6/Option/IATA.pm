#!/bin/false
# ABSTRACT: Identity Association for Temporary Addresses option (code 4)
# PODNAME: Net::DHCPv6::Option::IATA
use strictures 2;

package Net::DHCPv6::Option::IATA;
$Net::DHCPv6::Option::IATA::VERSION = '0.002';
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

my $IA_HDR_SIZE = 4;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

sub new {
    my ( $class, %args ) = @_;
    croak 'IATA requires iaid' unless defined $args{iaid};
    $args{code}    = $OPTION_IA_TA;
    $args{options} = $args{options} // Net::DHCPv6::OptionList->new;
    my $payload = pack( 'N', $args{iaid} ) . $args{options}->as_bytes;
    $args{data} = $payload;
    my $self = $class->SUPER::new( %args );
    $self->{iaid}    = $args{iaid};
    $self->{options} = $args{options};
    return bless $self, $class;
}

sub iaid    { return shift->{iaid} }
sub options { return shift->{options} }

sub add_option {
    my ( $self, $option ) = @_;
    return $self->{options}->add_option( $option );
}

sub get_option {
    my ( $self, $code ) = @_;
    return $self->{options}->get_option( $code );
}

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated IATA option' )
        if CORE::length( $payload ) < $IA_HDR_SIZE;
    my $iaid     = unpack( 'N', substr( $payload, 0, $IA_HDR_SIZE ) );
    my $opt_data = substr( $payload, $IA_HDR_SIZE );
    my $opts     = Net::DHCPv6::OptionList->from_bytes( $opt_data );
    return $class->new( iaid => $iaid, options => $opts );
}

sub as_bytes {
    my $self    = shift;
    my $payload = pack( 'N', $self->{iaid} ) . $self->{options}->as_bytes;
    return pack( 'nn', $self->{code}, CORE::length( $payload ) ) . $payload;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_IA_TA} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::IATA - Identity Association for Temporary Addresses option (code 4)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $iata = Net::DHCPv6::Option::IATA->new(iaid => 42);
  $iata->add_option($iaaddr);

=head1 DESCRIPTION

Implements the IA_TA option (OPTION_IA_TA, code 4) per RFC 8415 E<167>21.5.
Contains an IAID and sub-options. Unlike IA_NA, there are no T1/T2
timers for temporary addresses.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(iaid => $num, options => $optionlist)

Constructor. C<iaid> is required; C<options> defaults to an empty
L<Net::DHCPv6::OptionList>.

=item B<iaid>

Returns the IAID.

=item B<options>

Returns the internal L<Net::DHCPv6::OptionList> of sub-options.

=item B<add_option>($option)

Add a sub-option.

=item B<get_option>($code)

Retrieve the first sub-option with the given code.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::Option::IANA>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
