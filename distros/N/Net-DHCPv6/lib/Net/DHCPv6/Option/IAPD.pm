#!/bin/false
# ABSTRACT: Identity Association for Prefix Delegation option (code 25)
# PODNAME: Net::DHCPv6::Option::IAPD
use strictures 2;

package Net::DHCPv6::Option::IAPD;
$Net::DHCPv6::Option::IAPD::VERSION = '0.002';
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

my $IA_HDR_SIZE = 12;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

sub new {
    my ( $class, %args ) = @_;
    croak 'IAPD requires iaid' unless defined $args{iaid};
    $args{code}    = $OPTION_IA_PD;
    $args{t1}      = $args{t1}      // 0;
    $args{t2}      = $args{t2}      // 0;
    $args{options} = $args{options} // Net::DHCPv6::OptionList->new;
    my $payload = pack( 'N N N', $args{iaid}, $args{t1}, $args{t2} ) . $args{options}->as_bytes;
    $args{data} = $payload;
    my $self = $class->SUPER::new( %args );
    $self->{iaid}    = $args{iaid};
    $self->{t1}      = $args{t1};
    $self->{t2}      = $args{t2};
    $self->{options} = $args{options};
    return bless $self, $class;
}

sub iaid    { return shift->{iaid} }
sub t1      { return shift->{t1} }
sub t2      { return shift->{t2} }
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
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated IAPD option' )
        if CORE::length( $payload ) < $IA_HDR_SIZE;
    my ( $iaid, $t1, $t2 ) = unpack( 'N N N', substr( $payload, 0, $IA_HDR_SIZE ) );
    my $opt_data = substr( $payload, $IA_HDR_SIZE );
    my $opts     = Net::DHCPv6::OptionList->from_bytes( $opt_data );
    return $class->new( iaid => $iaid, t1 => $t1, t2 => $t2, options => $opts );
}

sub as_bytes {
    my $self    = shift;
    my $payload = pack( 'N N N', $self->{iaid}, $self->{t1}, $self->{t2} ) . $self->{options}->as_bytes;
    return pack( 'nn', $self->{code}, CORE::length( $payload ) ) . $payload;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_IA_PD} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::IAPD - Identity Association for Prefix Delegation option (code 25)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $iapd = Net::DHCPv6::Option::IAPD->new(
      iaid => 1,
      t1   => 3_600,
      t2   => 5_400,
  );
  $iapd->add_option($iaprefix);

=head1 DESCRIPTION

Implements the IA_PD option (OPTION_IA_PD, code 25) per RFC 8415 E<167>21.22.
Contains an IAID, T1, T2, and sub-options (typically IAPrefix options).
Same wire layout as IA_NA.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(iaid => $num, t1 => $num, t2 => $num, options => $optionlist)

Constructor. C<iaid> is required.

=item B<iaid>

Returns the IAID.

=item B<t1>

Returns T1 (renew time) in seconds.

=item B<t2>

Returns T2 (rebind time) in seconds.

=item B<options>

Returns the internal L<Net::DHCPv6::OptionList> of sub-options.

=item B<add_option>($option)

Add a sub-option.

=item B<get_option>($code)

Retrieve the first sub-option with the given code.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::Option::IAPrefix>, L<Net::DHCPv6::Option::IANA>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
