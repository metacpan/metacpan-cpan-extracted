# $Id: Buffer.pm,v 1.12 2005/01/16 21:36:56 dbrobins Exp $

package Net::SFTP::Buffer;
use strict;

use Net::SSH::Perl::Buffer;
use base qw( Net::SSH::Perl::Buffer );

use Math::Int64 qw( :native_if_available net_to_int64 int64_to_net );

sub new {
    return shift->SUPER::new(@_);
}

sub get_int64 {
    my $buf = shift;
    my $off = defined $_[0] ? shift : $buf->{offset};
    $buf->{offset} += 8;
    net_to_int64( $buf->bytes($off, 8) );
}

sub put_int64 {
    my $buf = shift;
    $buf->{buf} .= int64_to_net($_[0]);
}

sub get_attributes {
    my $buf = shift;
    Net::SFTP::Attributes->new(Buffer => $buf);
}

sub put_attributes {
    my $buf = shift;
    $buf->{buf} .= $_[0]->as_buffer->bytes;
}

1;
__END__

=head1 NAME

Net::SFTP::Buffer - Read/write buffer class

=head1 SYNOPSIS

    use Net::SFTP::Buffer;
    my $buffer = Net::SFTP::Buffer->new;

=head1 DESCRIPTION

I<Net::SFTP::Buffer> inherits from I<Net::SSH::Perl::Buffer> to
provide read/write buffer functionality for SSH. SFTP buffers
are exactly the same as SSH buffers, with a couple of additions:

=over 4

=item * 64-bit integers

SFTP requires the use of 64-bit integers to represent very
large file sizes. In I<Net::SFTP::Buffer> 64-bit integers
are implemented as I<Math::Pari> objects.

=item * File attribute bundles

Attribute bundles are not strictly a simple data type--they are,
in fact, made up of smaller pieces, like 32-bit integers, 64-bit
integers, etc.--but for matters of convenience, it is easiest
to provide methods to directly serialize/deserialize attributes
from buffers.

=back

=head1 USAGE

Usage of I<Net::SFTP::Buffer> objects is exactly the same as
usage of I<Net::SSH::Perl::Buffer> objects, with additions of
the following methods to support the above data types.

=head2 $buffer->get_int64

Extracts a 64-bit integer from I<$buffer> and returns it as
a I<Math::Pari> object.

=head2 $buffer->put_int64($int)

Serializes a 64-bit integer I<$int> into the buffer I<$buffer>;
I<$int> can be either a I<Math::Pari> object or a built-in
Perl integer, if it is small enough to fit into a Perl int.

=head2 $buffer->get_attributes

Uses I<Net::SFTP::Attributes> to extract a list of file
attributes from I<$buffer>, and returns a I<Net::SFTP::Attributes>
object containing those file attributes.

=head2 $buffer->put_attributes($attrs)

Serializes a I<Net::SFTP::Attributes> object I<$attrs> into
the buffer I<$buffer>.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SFTP manpage for author, copyright, and
license information.

=cut
