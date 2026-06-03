#!/bin/false
# ABSTRACT: DHCPv6 option base class
# PODNAME: Net::DHCPv6::Option
use strictures 2;

package Net::DHCPv6::Option;
$Net::DHCPv6::Option::VERSION = '0.003';
use Carp                      qw( croak );
use Net::DHCPv6::Constants    ();
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Helpers';
use namespace::clean;
my $EMPTY        = q();
my $OPT_HDR_SIZE = 4;     ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
our $FOLLOW_COMPRESSION = 0;

sub new {
    my ( $class, %args ) = @_;
    croak 'Option->new: code is required' unless defined $args{code};
    my $self = { code => $args{code}, data => $args{data} // $EMPTY };
    return bless $self, $class;
}

sub code { return shift->{code} }
sub data { return shift->{data} }    ## no critic (Bangs::ProhibitVagueNames)

sub type {
    my $self = shift;
    return $Net::DHCPv6::Constants::REV_OPTION_CODE{ $self->{code} };
}

sub as_bytes {
    my $self    = shift;
    my $payload = $self->{data} // $EMPTY;
    return pack( 'nn', $self->{code}, CORE::length( $payload ) ) . $payload;
}

sub from_bytes {
    my ( $class, $bytes ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Option->from_bytes: need at least 4 bytes for TLV header' )
        if !defined $bytes || CORE::length( $bytes ) < $OPT_HDR_SIZE;
    my $code   = unpack( 'n', substr( $bytes, 0, 2 ) );
    my $optlen = unpack( 'n', substr( $bytes, 2, 2 ) );
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated option TLV payload' )
        if $OPT_HDR_SIZE + $optlen > CORE::length( $bytes );
    my $payload = substr( $bytes, $OPT_HDR_SIZE, $optlen );
    my $remain  = substr( $bytes, $OPT_HDR_SIZE + $optlen );

    require Net::DHCPv6::OptionList;
    my $class_name = $Net::DHCPv6::OptionList::OPTION_CLASS{$code}
        || 'Net::DHCPv6::Option::Generic';
    my $option = $class_name->from_bytes_inner( $code, $payload );
    return ( $option, $remain );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option - DHCPv6 option base class

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $opt = Net::DHCPv6::Option->new(
      code => 99,
      data => "\x01\x02",
  );

  print $opt->code;       # 99
  print $opt->data;       # raw bytes
  print $opt->as_bytes;   # TLV-encoded wire bytes

  my ($opt, $remain) = Net::DHCPv6::Option->from_bytes($tlv_bytes);

=head1 DESCRIPTION

Base class for all DHCPv6 options. Stores a numeric option code and
raw payload data. Subclasses provide typed accessors for specific
option types.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(code => $num, data => $bytes)

Constructor. Requires C<code>; C<data> defaults to empty string.

=item B<code>

Returns the numeric option code.

=item B<data>

Returns the raw payload bytes.

=item B<type>

Returns the option name string (e.g. C<CLIENTID>) via reverse
lookup, or C<undef> for unknown codes.

=item B<as_bytes>

Serializes the option as a TLV: code(16) + length(16) + data.

=item B<from_bytes>($bytes)

Class method. Parses one option TLV from wire bytes. Returns
C<($option, $remaining_bytes)>. Dispatches to the appropriate
subclass via C<%OPTION_CLASS>. Falls back to C<Option::Generic>
for unknown codes.

=back

=head1 SUBCLASSING

Concrete option classes should:

=over

=item Override C<new> to accept typed attributes and set C<code> + C<data>

=item Override C<as_bytes> if the wire format differs from standard TLV

=item Implement C<from_bytes_inner($code, $payload)> for parse-from-wire

=item Register with C<$Net::DHCPv6::OptionList::OPTION_CLASS{$code} = __PACKAGE__>

=back

=head1 SEE ALSO

L<Net::DHCPv6::OptionList>, concrete option classes under L<Net::DHCPv6::Option>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
