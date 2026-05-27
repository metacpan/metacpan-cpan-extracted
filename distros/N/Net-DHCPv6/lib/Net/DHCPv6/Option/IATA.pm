#!/usr/bin/false
# ABSTRACT: Identity Association for Temporary Addresses option (code 4)
# PODNAME: Net::DHCPv6::Option::IATA
package Net::DHCPv6::Option::IATA;
$Net::DHCPv6::Option::IATA::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'IATA requires iaid' unless defined $args{iaid};
    $args{code}    = $OPTION_IA_TA;
    $args{options} = $args{options} // Net::DHCPv6::OptionList->new;
    my $data = pack( 'N', $args{iaid} ) . $args{options}->as_bytes;
    $args{data} = $data;
    my $self = $class->SUPER::new( %args );
    $self->{iaid}    = $args{iaid};
    $self->{options} = $args{options};
    bless $self, $class;
}

sub iaid    { shift->{iaid} }
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
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated IATA option' )
        if CORE::length( $data ) < 4;
    my $iaid     = unpack( 'N', substr( $data, 0, 4 ) );
    my $opt_data = substr( $data, 4 );
    my $opts     = Net::DHCPv6::OptionList->from_bytes( $opt_data );
    return $class->new( iaid => $iaid, options => $opts );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'N', $self->{iaid} ) . $self->{options}->as_bytes;
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_IA_TA} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::IATA - Identity Association for Temporary Addresses option (code 4)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $iata = Net::DHCPv6::Option::IATA->new(iaid => 42);
  $iata->add_option($iaaddr);

=head1 DESCRIPTION

Implements the IA_TA option (OPTION_IA_TA, code 4) per RFC 8415 §21.5.
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
