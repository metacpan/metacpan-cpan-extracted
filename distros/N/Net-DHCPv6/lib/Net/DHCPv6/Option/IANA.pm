#!/usr/bin/false
# ABSTRACT: Identity Association for Non-temporary Addresses option (code 3)
# PODNAME: Net::DHCPv6::Option::IANA
package Net::DHCPv6::Option::IANA;
$Net::DHCPv6::Option::IANA::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'IANA requires iaid' unless defined $args{iaid};
    $args{code}    = $OPTION_IA_NA;
    $args{t1}      = $args{t1}      // 0;
    $args{t2}      = $args{t2}      // 0;
    $args{options} = $args{options} // Net::DHCPv6::OptionList->new;
    my $data = pack( 'N N N', $args{iaid}, $args{t1}, $args{t2} ) . $args{options}->as_bytes;
    $args{data} = $data;
    my $self = $class->SUPER::new( %args );
    $self->{iaid}    = $args{iaid};
    $self->{t1}      = $args{t1};
    $self->{t2}      = $args{t2};
    $self->{options} = $args{options};
    bless $self, $class;
}

sub iaid    { shift->{iaid} }
sub t1      { shift->{t1} }
sub t2      { shift->{t2} }
sub options { shift->{options} }

sub add_option {
    my ( $self, $option ) = @_;
    $self->{options}->add_option( $option );
}

sub get_option {
    my ( $self, $code ) = @_;
    return $self->{options}->get_option( $code );
}

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated IANA option' )
        if CORE::length( $data ) < 12;
    my ( $iaid, $t1, $t2 ) = unpack( 'N N N', substr( $data, 0, 12 ) );
    my $opt_data = substr( $data, 12 );
    my $opts     = Net::DHCPv6::OptionList->from_bytes( $opt_data );
    return $class->new( iaid => $iaid, t1 => $t1, t2 => $t2, options => $opts );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'N N N', $self->{iaid}, $self->{t1}, $self->{t2} ) . $self->{options}->as_bytes;
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_IA_NA} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::IANA - Identity Association for Non-temporary Addresses option (code 3)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $iana = Net::DHCPv6::Option::IANA->new(iaid => 42, t1 => 3600, t2 => 5400);
  $iana->add_option($iaaddr);

  print $iana->iaid;
  print $iana->get_option($OPTION_IAADDR)->address;

=head1 DESCRIPTION

Implements the IA_NA option (OPTION_IA_NA, code 3) per RFC 8415 §21.4.
Contains an IAID, T1, T2, and sub-options (typically IAAddr options).

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(iaid => $num, t1 => $num, t2 => $num, options => $optionlist)

Constructor. C<iaid> is required; C<t1>, C<t2>, and C<options> default to 0
and an empty L<Net::DHCPv6::OptionList>.

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

L<Net::DHCPv6::Option>, L<Net::DHCPv6::Option::IAAddr>, L<Net::DHCPv6::Option::IAPD>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
