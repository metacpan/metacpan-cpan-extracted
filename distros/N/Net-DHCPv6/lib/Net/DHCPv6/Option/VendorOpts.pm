#!/usr/bin/false
# ABSTRACT: Vendor-specific Information option (code 17) — enterprise + sub-options
# PODNAME: Net::DHCPv6::Option::VendorOpts
package Net::DHCPv6::Option::VendorOpts;
$Net::DHCPv6::Option::VendorOpts::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use Ref::Util qw(is_plain_arrayref);
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'VendorOpts requires enterprise_number' unless defined $args{enterprise_number};
    $args{code} = $OPTION_VENDOR_OPTS;
    my $sub_data = $args{sub_options} // '';
    $sub_data = join( '', map { $_->as_bytes } @$sub_data ) if is_plain_arrayref( $sub_data );
    $args{data} = pack( 'N', $args{enterprise_number} ) . $sub_data;
    my $self = $class->SUPER::new( %args );
    $self->{enterprise_number} = $args{enterprise_number};
    bless $self, $class;
}

sub enterprise_number { shift->{enterprise_number} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated VendorOpts option' )
        if CORE::length( $data ) < 4;
    my $en = unpack( 'N', substr( $data, 0, 4 ) );
    return $class->new( enterprise_number => $en, sub_options => substr( $data, 4 ) );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_VENDOR_OPTS} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::VendorOpts - Vendor-specific Information option (code 17) — enterprise + sub-options

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::VendorOpts;
  my $opt = Net::DHCPv6::Option::VendorOpts->new(
      enterprise_number => 9,
      sub_options       => [ $subopt1, $subopt2 ],
  );

=head1 DESCRIPTION

Carries vendor-specific sub-options scoped by an IANA enterprise
number.  See RFC 8415 §21.17.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<enterprise_number>.  Optional C<sub_options>
(an arrayref of L<Net::DHCPv6::Option> objects or raw bytes).

=head2 enterprise_number

Returns the IANA enterprise number.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
