package Net::OBEX::Packet::Headers;

use strict;
use warnings;

our $VERSION = '1.001001'; # VERSION

use Carp;
use Net::OBEX::Packet::Headers::Unicode;
use Net::OBEX::Packet::Headers::ByteSeq;
use Net::OBEX::Packet::Headers::Byte4;

my %Header_Meaning_Of = _make_header_meanings();
my %Header_Type_Of = (
    ( map { $_ => 'byte4' } qw( count  length  timeb  connection_id ) ),

    ( map { $_ => 'byteseq' } qw(
            type  time        target           http
            who   app_params  auth_challenge   auth_response
            body  end_of_body object_class
        )
    ),

    ( map { $_ => 'unicode' } qw( name  description ) ),
);

sub new {
    my ( $class, $headers_raw ) = @_;

    return bless { HEADERS_RAW => $headers_raw }, $class;
}

sub make {
    my $self = shift;
    my ( $name, $value ) = @_;
    $name = lc $name;
    croak "Invalid header name specified to make()"
        unless exists $Header_Type_Of{ $name };

    my $type = $Header_Type_Of{ $name };
    if ( $type eq 'byteseq' ) {
        return Net::OBEX::Packet::Headers::ByteSeq->new(
            $name   => $value,
        )->make;
    }
    elsif ( $type eq 'byte4' ) {
        return Net::OBEX::Packet::Headers::Byte4->new(
            $name   => $value,
        )->make;
    }
    elsif ( $type eq 'unicode' ) {
        return Net::OBEX::Packet::Headers::Unicode->new(
            $name   => $value,
        )->make;
    }
    else {
        die 'I should never got to here. Please email '
            . 'to zoffix@cpan.org';
    }
}

sub parse {
    my $self = shift;

    my $headers_raw = shift;
    $headers_raw = $self->headers_raw
        unless defined $headers_raw;

    $self->headers_raw( $headers_raw );

    my %headers;
    while (length $headers_raw) {
        (my $HI_raw, $headers_raw ) = unpack 'a a*', $headers_raw;

        my $HI = $Header_Meaning_Of{ $HI_raw };
         last
             unless defined $HI;

        ( $headers{ $HI }, $headers_raw)
        = $self->_make_header_value( $HI_raw, $headers_raw );
    }

    return $self->headers_parsed( \%headers );
}

sub _make_header_value {
    my ( $self, $HI_raw, $headers_raw ) = @_;

    # Bits 8 and 7 of HI  - Interpretation
    # 00  - null terminated Unicode text,
    #               length prefixed with 2 byte unsigned integer
    # 01 - byte sequence, length prefixed with 2 byte unsigned integer
    # 10 - 1 byte quantity
    # 11 - 4 byte quantity - transmitted in network byte order

    my $type = unpack 'B2', $HI_raw;
    if ( $type eq '00' or $type eq '01' ) {
        my ( $header_length, $headers_raw ) = unpack 'n a*', $headers_raw;
        $header_length -= 3; # first three bytes of length are
                             # the HI and it's length bytes
        return unpack "a$header_length a*", $headers_raw;
    }
    elsif ( $type eq '10' ) {
        return unpack 'aa*', $headers_raw;
    }
    elsif ( $type eq '11' ) {
        return unpack 'a4a*', $headers_raw;
    }
}

sub headers_raw {
    my $self = shift;
    if ( @_ ) {
        $self->{ HEADERS_RAW } = shift;
    }
    return $self->{ HEADERS_RAW };
}

sub headers_parsed {
    my $self = shift;
    if ( @_ ) {
        $self->{ HEADERS_PARSED } = shift;
    }
    return $self->{ HEADERS_PARSED };
}

sub _make_header_meanings {
    return (
        "\xC0"      => 'count',
        "\x01"      => 'name',
        "\x42"      => 'type',
        "\xC3"      => 'length',
        "\x44"      => 'time',
        "\xC4"      => 'timeb',
        "\x05"      => 'description',
        "\x46"      => 'target',
        "\x47"      => 'http',
        "\x48"      => 'body',
        "\x49"      => 'end_of_body',
        "\x4A"      => 'who',
        "\xCB"      => 'connection_id',
        "\x4C"      => 'app_params',
        "\x4D"      => 'auth_challenge',
        "\x4E"      => 'auth_response',
        "\x4F"      => 'object_class',
    );

}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN RT Te timeb

=head1 NAME

Net::OBEX::Packet::Headers - construct and parse OBEX packet headers

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Net::OBEX::Packet::Headers;

    # this would be the data from the socket.
    my $header = pack 'H*', '4a0013f9ec7bc4953c11d2984e525400dc9e09cb00000001';

    my $head = Net::OBEX::Packet::Headers->new;

    my $parse_ref = $head->parse( $header );

    my @headers = keys %$parse_ref;

    print "Your data containts " . @headers . " headers which are: \n",
        map { "[$_]\n" } @headers;

    my $type_header = $head->make(
        'target' => pack 'H*', 'F9EC7BC4953C11D2984E525400DC9E09'
    );

    printf "Type header for OBEX FTP (F9EC7BC4953C11D2984E525400DC9E09) "
            . "in hex is: \n%s\n",
                unpack 'H*', $type_header;

    print "Let's see what the parse says... \n";

    $head->parse( $type_header );

    print map { "$_ => " . uc unpack( 'H*', $parse_ref->{$_}) . "\n" }
            keys %{ $head->headers_parsed };

=head1 DESCRIPTION

B<WARNING!!! This module is still in alpha stage. Use it for test purposes
only as interface might change in the future>.

The module provides means to create OBEX protocol packet headers as well
as means to parse the data containing headers.

=head1 CONSTRUCTOR

=head2 new

    my $head = Net::OBEX::Packet::Headers->new;

    my $head = Net::OBEX::Packet::Headers->new( $raw_headers );

Constructs and returns a Net::OBEX::Packet::Headers object.
Takes one I<optional>
argument which is raw data containing headers you would want to parse.

=head1 METHODS

=head2 parse

    my $parse_ref = $head->parse;

    my $parse_ref = $head->parse( $raw_headers );

Instructs the object to parse raw data containing OBEX headers.
Returns a hashref, keys of which will be the names of OBEX headers
found in the data and value will be the values of each of those headers.

Takes one optional argument which is a scalar containing raw OBEX
headers, if this argument is not specified will parse whatever data
you've specified in the constructor. The possible header names in
the return hashref are the same as the names of the headers to C<make()>
method "header name" argument. B<Note:> parsing of custom, i.e.
"user defined" headers is not implemented yet.

=head2 make

    my $type_header = $head->make(
        'target' => pack 'H*', 'F9EC7BC4953C11D2984E525400DC9E09'
    );

    my $name_header = $head->make( 'name' => 'x-obex/folder-listing' );

Constructs an OBEX header suitable to go down the wire. Takes two
arguments the name of the header and its value.
If you wish to specify a header with no value use an empty string as a
value, e.g.:

    my $set_path_root_name_header = $head->make( 'name' => '' );

Possible header names are as follows:

=over 10

=item count

The C<COUNT> header.

=item length

The C<LENGTH> header.

=item time

The C<TIME> header in its I<byte sequence> format.

=item timeb

The C<TIME> header in its 4-byte format.

=item connection_id

The C<Connection ID> header.

=item type

The C<TYPE> header.

=item target

The C<TARGET> header.

=item http

The C<HTTP> header.

=item who

The C<WHO> header.

=item app_params

The C<Application Parameters> header.

=item auth_challenge

The C<Authentication Challenge> header.

=item auth_response

The C<Authentication Response> header.

=item body

The C<BODY> header.

=item end_of_body

The C<End Of Body> header.

=item object_class

The C<Object Class> header.

=item name

The C<NAME> header.

=item description

Te C<Description> header.

=back

I<Note:> If you want to create custom headers take a look at either
L<Net::OBEX::Packet::Headers::Unicode>,
L<Net::OBEX::Packet::Headers::ByteSeq>,
L<Net::OBEX::Packet::Headers::Byte4>
or L<Net::OBEX::Packet::Headers::Byte1> modules depending on which type
of header you want to create.

=head2 headers_raw

    my $raw = $head->headers_raw;

Takes no arguments, returns the raw headers data you've supplied to
the constructor or last C<parse()> call.

=head2 headers_parsed

    my $parse_ref = $head->headers_parsed;

Must be called after the call to C<parse()>. Takes no arguments, returns
the hashref of parsed headers, same as the return value of C<parse()>.
See C<parse()> method for more information.

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