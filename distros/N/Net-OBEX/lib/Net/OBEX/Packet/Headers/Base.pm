
package Net::OBEX::Packet::Headers::Base;

use strict;
use warnings;
use Carp;

our $VERSION = '1.001001'; # VERSION

sub new {
    my ( $class, $hi, $value ) = @_;

    croak "Missing header name or HI identifier"
        unless defined $hi;

    $value = ''
        unless defined $value;

    return bless {
        value  => $value,
        hi     => $hi,
    }, $class;
}

sub make {
    my $self = shift;

    my $value = $self->value;
    unless ( length $value ) {
        return $self->hi;
    }

    my $header = $self->hi . $value;
    return $self->header($header);
}

sub header {
    my $self = shift;
    if ( @_ ) {
        $self->{ header } = shift;
    }
    return $self->{ header };
}

sub value {
    my $self = shift;
    if ( @_ ) {
        $self->{ value } = shift;
    }
    return $self->{ value };
}

sub hi {
    my $self = shift;
    if ( @_ ) {
        $self->{ hi } = shift;
    }
    return $self->{ hi };
}

1;

__END__

=encoding utf8

=head1 NAME

Net::OBEX::Packet::Headers::Byte4 - construct
"4-byte sequence" OBEX headers.

=head1 SYNOPSIS

    package Net::OBEX::Packet::Headers;

    use strict;
    use warnings;

    use base 'Net::OBEX::Packet::Headers::Base';

    our $VERSION = '0.001';

    sub make {
        my $self = shift;

        my $value = $self->value;
        unless ( length $value ) {
            return $self->hi . "\x00\x03";
        }

        $value = pack 'n*', unpack 'U*', encode_utf8($value);

        my $header = $self->hi; # header code
        $header .= pack 'n', 4 + length $value;
        $header .= $value . "\x00";
        return $self->header($header);
    }

    1;

    __END__

=head1 DESCRIPTION

B<WARNING!!! This module is still in alpha stage. Use it for test purposes
only as interface might change in the future>.

The module is a base class for OBEX packet headers.

It defines C<new()>, C<make()>, C<header()>, C<value()> and C<hi()> methods.
The default C<make()> method is:

    sub make {
        my $self = shift;

        my $value = $self->value;
        unless ( length $value ) {
            return $self->hi;
        }

        my $header = $self->hi . $value;
        return $self->header($header);
    }

Refer to the documentation of either:
L<Net::OBEX::Packet::Headers::Byte1>,
L<Net::OBEX::Packet::Headers::Byte4>,
L<Net::OBEX::Packet::Headers::ByteSeq>
or L<Net::OBEX::Packet::Headers::Unicode> for the documentation of the
methods.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Net-OBEX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Net-OBEX/issues>

If you can't access GitHub, you can email your request
to C<bug-Net-OBEX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut