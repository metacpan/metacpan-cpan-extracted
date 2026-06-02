#!/bin/false
# ABSTRACT: Shared container for a collection of DHCPv6 options
# PODNAME: Net::DHCPv6::OptionList
use strictures 2;

package Net::DHCPv6::OptionList;
$Net::DHCPv6::OptionList::VERSION = '0.002';
use Net::DHCPv6::Option::Generic;
use Carp      qw( croak );
use Ref::Util qw( is_ref );
use namespace::clean;

my $EMPTY        = q();
my $OPT_HDR_SIZE = 4;     ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

our %OPTION_CLASS;

sub new {
    my $class = shift;
    return bless {
        options_by_code => {},
        options_order   => [],
    }, $class;
}

sub add_option {
    my ( $self, $option ) = @_;
    my $code = $option->code;
    push @{ $self->{options_order} }, $code
        unless exists $self->{options_by_code}{$code};
    $self->{options_by_code}{$code} //= [];
    return push @{ $self->{options_by_code}{$code} }, $option;
}

sub get_option {
    my ( $self, $code ) = @_;
    my $list = $self->{options_by_code}{$code};
    return unless $list && @{$list};
    return $list->[0];
}

sub remove_option {
    my ( $self, $code ) = @_;
    delete $self->{options_by_code}{$code};
    return @{ $self->{options_order} } = grep { $_ != $code } @{ $self->{options_order} };
}

sub options {
    my $self = shift;
    return [] unless @{ $self->{options_order} };
    my @opts;
    for my $code ( @{ $self->{options_order} } ) {
        my $list = $self->{options_by_code}{$code};
        push @opts, @{$list} if $list;
    }
    return \@opts;
}

sub as_bytes {
    my $self     = shift;
    my $opt_list = $self->options or return $EMPTY;
    return join( $EMPTY, map { $_->as_bytes } @{$opt_list} );
}

sub try_from_bytes {
    my ( $class, $bytes ) = @_;
    return ( $class->new, undef ) unless defined $bytes && CORE::length( $bytes );

    my $list   = $class->new;
    my $offset = 0;
    my $len    = CORE::length( $bytes );
    my $error;

    while ( $offset + $OPT_HDR_SIZE <= $len ) {
        my $code   = unpack( 'n', substr( $bytes, $offset,     2 ) );
        my $optlen = unpack( 'n', substr( $bytes, $offset + 2, 2 ) );
        $offset += $OPT_HDR_SIZE;
        if ( $offset + $optlen > $len ) {
            $error = "Truncated option $code: need $optlen bytes, have " . ( $len - $offset );
            last;
        }
        my $payload = substr( $bytes, $offset, $optlen );
        $offset += $optlen;

        my $class_name = $OPTION_CLASS{$code} || 'Net::DHCPv6::Option::Generic';
        my $option;
        eval { $option = $class_name->from_bytes_inner( $code, $payload ); };
        if ( my $err = $@ ) {
            if ( is_ref( $err ) && $err->isa( 'Net::DHCPv6::X' ) ) {
                $option = Net::DHCPv6::Option::Generic->new( code => $code, data => $payload );
            }
            else {
                $error = "Option $code parse error: $err";
                last;
            }
        }
        $list->add_option( $option );
    }

    if ( !$error && $offset != $len ) {
        $error = 'Trailing garbage in option data';
    }

    return ( $list, $error );
}

sub from_bytes {
    my ( $class, $bytes ) = @_;
    my ( $list,  $error ) = $class->try_from_bytes( $bytes );
    croak $error if $error;
    return $list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::OptionList - Shared container for a collection of DHCPv6 options

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $ol = Net::DHCPv6::OptionList->new;
  $ol->add_option($clientid);
  $ol->add_option($oro);

  my $opt    = $ol->get_option(1);        # first ClientId
  my $opts   = $ol->options;              # arrayref in insertion order
  my $bytes  = $ol->as_bytes;             # TLV chain

  my $parsed = Net::DHCPv6::OptionList->from_bytes($bytes);

=head1 DESCRIPTION

Stores options in insertion order for deterministic serialization while
providing O(1) lookup by option code. Used by L<Net::DHCPv6::Packet>,
L<Net::DHCPv6::Option::IANA>, L<Net::DHCPv6::Option::IAPD>, and
L<Net::DHCPv6::Option::IAAddr>.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>

Returns an empty option list.

=item B<add_option>($option)

Appends an option. Multiple options with the same code are allowed.

=item B<get_option>($code)

Returns the first option with the given code, or C<undef>.

=item B<remove_option>($code)

Removes all options with the given code.

=item B<options>

Returns an arrayref of all options in insertion order, or C<undef> if
empty.

=item B<as_bytes>

Serializes all options as a TLV chain.

=item B<from_bytes>($bytes)

Class method. Parses a TLV chain from wire bytes. Uses C<%OPTION_CLASS>
to dispatch to concrete option subclasses. Falls back to
C<Option::Generic> for unknown codes or parse failures.

=item B<try_from_bytes>($bytes)

Class method. Like C<from_bytes> but returns C<($option_list, $error)>.
On truncation mid-option, C<$option_list> contains whatever options were
fully parsed before the truncation, and C<$error> is an error string.
On success, C<$error> is C<undef>. Never throws.

=back

=head1 DISPATCH TABLE

C<%OPTION_CLASS> maps numeric option codes to package names. Each
concrete option class registers itself at compile time. For example:

  $Net::DHCPv6::OptionList::OPTION_CLASS{1} = 'Net::DHCPv6::Option::ClientId';

=head1 SEE ALSO

L<Net::DHCPv6::Option>, concrete option classes under L<Net::DHCPv6::Option>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
