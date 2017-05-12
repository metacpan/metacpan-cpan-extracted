package RPSL::Parser;
require 5.006_001;
use strict;
use warnings;
use base qw( Class::Accessor );
__PACKAGE__->mk_accessors(
    qw( text type tokens key comment
      object omit_key order )
);

our $VERSION = "0.04000";

# Public Interface Methods

# Constructor
sub new {
    my $class = shift;
    my $self  = bless {
        __META => {
            comment => {},
            object  => {},
        }
    }, $class;
    return $self;
}

# service method
sub parse {
    my $self_or_class = shift;
    my $self = ref $self_or_class ? $self_or_class : $self_or_class->new();
    unless ( UNIVERSAL::isa( $self, q{RPSL::Parser} ) ) {
        $self = RPSL::Parser->new;
    }
    return $self->_read_text(@_)->_tokenize->_build_parse_tree->_parse_tree;
}

# Private Interface Methods

# Overriding Class::Accessor::get
sub get {
    my ( $self, @keys ) = @_;
    return wantarray
      ? @{ $self->{__META} }{@keys}
      : ${ $self->{__META} }{ $keys[0] };
}

# Overriding Class::Accessor::set
sub set {
    my ( $self, $key, $value ) = @_;
    return $self->{__META}{$key} = $value;
}

# Other private methods
sub _read_text {
    my ( $self, @input ) = @_;
    my $data;
    if (   UNIVERSAL::isa( $input[0], 'GLOB' )
        or UNIVERSAL::isa( $input[0], 'IO::Handle' ) )
    {
        local $/;
        $data = <$input[0]>;
    }
    else {
        $data = join '', @input;
    }
    $self->text($data);
    return $self;
}

sub _cleanup_attribute {
    my ( $self, $value ) = @_;
    return unless $value;
    $value =~ s/\n\s+/\n/gosm;
    $value =~ s/^\s+|\s+$//go;
    return $value;
}

sub _tokenize {
    my $self = shift;
    my $text = $self->text;
    study $text;
    my @tokens = $text =~ m{
        ^(?:
            # Look for an attribute name ...
            ( [a-z0-9][a-z0-9_-]+[a-z0-9] ):
            # ... followed by zero or more horizontal spaces ...
            [\t ]*
            # ... followed by a value ...
            ( .*?
                # ... and all valid continuation lines.
                (?: \n [\s+] .* ? )*
            )
        )$
    }mixg;
    $self->tokens( \@tokens );
    return $self;
}

sub _store_attribute {
    my ( $self, $key, $value ) = @_;
    $value = $self->_cleanup_attribute($value);

    # Store the value
    if ( exists $self->object->{$key} ) {
        if ( !UNIVERSAL::isa( $self->object->{$key}, 'ARRAY' ) ) {
            $self->object->{$key} = [ $self->object->{$key} ];
        }
        push @{ $self->object->{$key} }, $value;
    }
    else {
        $self->object->{$key} = $value;
    }
    return $self;
}

sub _store_comment {
    my ( $self, $order, $value ) = @_;
    return unless defined $value;
    if ( $value =~ s{#(.*)}{} ) {
        $self->comment->{$order} = $self->_cleanup_attribute($1);
    }
    return $value;
}

sub _build_parse_tree {
    my $self   = shift;
    my @tokens = @{ $self->tokens };
    my ( @order, @omit_key );
    while ( my ( $key, $value ) = splice @tokens, 0, 2 ) {

        # Save the order
        push @order, $key;

        # Handle multi-line comments
        if ( defined $value ) {
            my @parts = split qr{\n\+?\s*}, $value;
            if ( @parts > 1 ) {    # too much, put it back.
                unshift @tokens, $key, $_ for reverse @parts[ 1 .. $#parts ];
                $value = $parts[0];
                my $count = $#order;
                map { push @omit_key, $count + $_ } 1 .. $#parts;
            }
        }

        $value = $self->_store_comment( $#order, $value );
        $self->_store_attribute( $key, $value );
    }    # end while

    # Fill in the object's meta-attributes
    $self->order( \@order );
    $self->omit_key( \@omit_key );
    $self->type( $order[0] );

    # Stores the object primary key value
    my $primary_key = $self->object->{ $order[0] };
    $primary_key = $primary_key->[0]
      if UNIVERSAL::isa( $primary_key, 'ARRAY' );
    $primary_key =~ s{\s*\#.*$}{};
    $self->key($primary_key);

    # Done!
    return $self;
}

sub _parse_tree {
    my $self = shift;
    return {
        data => $self->object,
        type => $self->type,
        key  => $self->key,
        meta => {
            order    => $self->order,
            comment  => $self->comment,
            omit_key => $self->omit_key,
        },
    };
}

1;
__END__

=head1 NAME

RPSL::Parser - Router Policy Specification Language (RFC2622) Parser

=head1 SYNOPSIS

    # The new interface doesn't requires the creation of
    # a parser object anymore:
    use RPSL::Parser;
    my $data_structure = RPSL::Parser->parse( $data );

    ###########

    # Alternativelly, use the old and deprecated interface:
    use RPSL::Parser;
    # Create a parser
    my $parser = new RPSL::Parser;
    # Use it
    my $data_structure = $parser->parse($data);

=head1 DESCRIPTION

This is a rather simplistic lexer and tokenizer for the RPSL language.

It currently does not validate the object in any way, it just tries (rather
hard) to grab the biggest ammount of information it can from the text presented
and place it in a Parse Tree (that can be passed to other objects from the
I<RPSL> namespace for validation and more RFC2622 related functionality).

=head1 PUBLIC METHODS

=head2 B<C<new()>> B<deprecated>

Constructor. Handles the accessor creation and returns a new L<RPSL::Parser> object.

This method is deprecated, under request of some users. The RPSL::Parser
interface will change, and there will be no need to create a "parser" object
anymore.

=head2 B<C<parse( [ $rpsl_source | IO::Handle | GLOB ] )>>

Parses B<one> RPSL object for each call, uses the parser internal fields to
store the data gathered. This is the method you need to call to transform your
RPSL text into a Perl data structure.

It accepts a list or a scalar containing the strings representing the RPSL
source code you want to parse, and can read it directly from any L<IO::Handle>
or C<GLOB> representing an open file handle.

This is a mixture between a class and a object method at this moment, due to
the deprecation of the C<new()> method. It can detect whenever it was called
with a class as the first parameter, and will try to instantiate and use that
class as the parser implementation.

=head1 ACCESSOR METHODS

=head2 B<C<comment()>>

Stores an array reference containing all the inline comments found in the RPSL
text.

=head2 B<C<object>>

Stores a hash reference containing all the RPSL attributes found in the RPSL
text.

=head2 B<C<omit_key>>

Stores an array reference containing all the position of the keys we must omit
from the original RPSL text.

=head2 B<C<order>>

Stores an array reference containing an ordered list of RPSL attribute names,
to enable the RPSL to be rebuilt from the parsed data version.

=head2 B<C<key>>

Stores the value found in the first RPSL attribute parsed. This is sometimes
refered as the RPSL object key.

=head2 B<C<text>>

Stores an scalar containing the RPSL text to be parsed.

=head2 B<C<tokens>>

Stores an array reference containing an ordered list of tokens and token values
produced by the tokenize method.

=head2 B<C<type>>

Stores a string representing the name of the first RPSL attribute found in the
RPSL text parsed. The RFC 2622 requires that the first attribute declares the
"data type" of the RPSL object declared.

=head1 Private Interface

=head2 B<C<_read_text( @input )>>

Checks if the first element from C<@input> is a L<IO::Handle> or a C<GLOB>, and
reads from it. If the first element is not any type of file handle, assumes
it's an array of scalars containing the text for the RPSL object to be parsed,
C<join()> it all toghether and feed it to the parser.

=head2 B<C<_tokenize()>>

This method breaks down the RPSL source code read by C<read_text()> into
tokens, and store them internally. For commodity, it returs a reference to the
object itself, so you can chain up method calls.

=head2 B<C<_cleanup_attribute( $value )>>

Returns a cleaned-up version of the attribute passed in: no trailling or
leading whitespace or newlines.

=head2 B<C<_store_attribute( $attribute_name, $attribute_value )>>

Auxiliary method. It clean up the value and store the attribute in the data
structure being built, and does the necessary storage upkeep.

=head2 B<C<_store_comment( $comment_position_index, $attribute_and_comment_text )>>

This method extracts inline comments from the inline part of an object and
store those comments into the parse tree being built. It returns the attribute
passed in with the comments stripped, so it can be stored into the appropriated
place afterwards.

=head2 B<C<_build_parse_tree()>>

This method consumes the tokens produced by C<_tokenize()> and builds a data
structure containing all the information needed to re-build the RPSL object
back.

It returns a reference to the parser object itself, making easy to chain method
calls again.

=head2 B<C<_parse_tree()>>

This method assembles all the information gathered during the RPSL source code
tokenization and parsing into a hash reference containing the following keys:

=head2 B<data>

Holds a hash reference whose keys are the RPSL attributes found, and the values
are the string passed in as values to the respective attributes in the RPSL
text. Multi-valued attributes are represented by array references. As this
parser doesn't enforces all the RPSL business rules, you must take care when
fiddling with this structure, as any value could be an array reference.

=head2 B<order>

Holds an array reference containing the key names from the B<data> hash, in the
order they where found in the RPSL text. This is stored here because the RFC
2622 commands that the order of the attributes in a RPSL object is important.

=head2 B<type>

Holds a string containing the name of the first RPSL attribute found in the
RPSL text. RFC 2622 commands that the first attribute must be the type of the
object declared. Knowing the type of object can allow proper manipulation of
the different RPSL object types by other RPSL namespace modules.

=head2 B<key>

Holds the value contained by the first attribute of an RPSL object. This is
sometimes the "primary key" of a RPSL object, but not always.

=head2 B<comment>

Comment is a hash structure where the keys are index positions in the B<order>
array, and values are the inline comments extracted during the parsing stage.
Preserving inline comments is not a requirement from RFC 2622, just a nice
thing to have.

=head2 B<omit_key>

RFC 2622 allows some attribute names to contain multiple values. For every new
value, a new line must be inserted into the RPSL object. For brevity, and to
allow humans to read and write RPSL, the RFC 2622 allows the attribute name to
be omited and replaced by whitespace. It also dictates that lines begining with
a "+" sign must be considered as being part of a multi-line RPSL attribute.

This array reference stores integers representing index positions in the
B<order> array signaling attribute positions that must be omited when
generating RPSL text back from this parse tree. As RFC 2622 doesn't request
that attributes omited by starting a line with whitespace or "+" must preserve
this characteristic, this is only a nice-to-have feature.  =back

=head1 EXAMPLES

=head2 Example #1: retrieving information from the Whois Database

Suppose you retrieve a RPSL Person object from the RIPE NCC WHOIS Database,
like the one below. It's a simple query and I will not explain how you could do
it here, because it's a bit out of scope for this module. Anyway, you have the
following text as a result:

    person:       I. M. A. Fool
    address:      F.A.K.E Corporation
    address:      226 Nowhere st
    address:      10DD10 Nevercity
                  Neverland
    phone:        +99-99-999-9999
    fax-no:       +99-99-999-9999
    e-mail:       xxx@somewhere.com
    nic-hdl:      XXX007-RIPE # Look, ma, I'm 007! ;)
    mnt-by:       NICE-GUY-MNT
    changed:      xxx@somewhere.com 20001016
    source:       RIPE

Let's assume you need to send an email (for example, to report routing
problems) to Mr Fool. It means that you need to retrieve the I<e-mail> field
value from this RPSL object.

Let's assume you have the previous text in the C<$text> variable. In order to
parse the contents of the text into a nice Perl data structure, all you need to
do is instanciate a parser, with

    use RPSL::Parser;
    my $parser = new RPSL::Parser;

And then pass it the contents of the C<$text> variable, and collect the
resulting data structure back:

    my $data_structure = $parser->parse( $text );

It will give you something that will look more or less like this (dumped by
L<Data::Dumper>):

    $data_strucutre = {
        __META => {
            'omit_key' => [4],
            'comment'  => { 8 => q{Look, ma, I'm 007! ;)} },
            'order'    => [
                'person',  'address', 'address', 'address',
                'address', 'phone',   'fax-no',  'e-mail',
                'nic-hdl', 'mnt-by',  'changed', 'source'
            ],
            'type' => 'person',
            'data' => {
                'source'  => 'RIPE',
                'mnt-by'  => 'NICE-GUY-MNT',
                'phone'   => '+99-99-999-9999',
                'nic-hdl' => 'XXX007-RIPE',
                'fax-no'  => '+99-99-999-9999',
                'e-mail'  => 'xxx@somewhere.com',
                'changed' => 'xxx@somewhere.com 20001016',
                'person'  => 'I. M. A. Fool',
                'address' => [
                    'F.A.K.E Corporation',
                    '226 Nowhere st',
                    '10DD10 Nevercity',
                    'Neverland'
                ]
            },
            'key' => 'I. M. A. Fool'
        },
    };

In a near future, there will be other objects that will know how to interpret
this as the specific RPSL object declared, and to write the corresponding RPSL
representation of a given data structure, simmilar to this one.

=head1 SEE ALSO

RFC2622 L<http://www.ietf.org/rfc/rfc2622.txt>, for the full RPSL specification.

=head1 AUTHOR

Luis Motta Campos, E<lt>lmc@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Luis Motta Campos

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
