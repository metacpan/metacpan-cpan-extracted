#
#  Copyright 2009-2013 MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

use strict;
use warnings;
package MongoDB::BSON;


# ABSTRACT: Tools for serializing and deserializing data in BSON form

use version;
our $VERSION = 'v1.8.2';


use XSLoader;
XSLoader::load("MongoDB", $VERSION);

use BSON::Decimal128;
use Carp ();
use Config;
use if ! $Config{use64bitint}, "Math::BigInt";
use DateTime;
use MongoDB::Error;
use Moo;
use MongoDB::_Types qw(
    Boolish
    NonNegNum
    SingleChar
);
use Types::Standard qw(
    CodeRef
    Maybe
    Str
    Undef
);
use boolean;
use namespace::clean -except => 'meta';

# cached for efficiency during decoding
our $_boolean_true = true;
our $_boolean_false = false;

#pod =attr dbref_callback
#pod
#pod A document with keys C<$ref> and C<$id> is a special MongoDB convention
#pod representing a
#pod L<DBRef|http://docs.mongodb.org/manual/applications/database-references/#dbref>.
#pod
#pod This attribute specifies a function reference that will be called with a hash
#pod reference argument representing a DBRef.
#pod
#pod The hash reference will have keys C<$ref> and C<$id> and may have C<$db> and
#pod other keys.  The callback must return a scalar value representing the dbref
#pod (e.g. a document, an object, etc.)
#pod
#pod The default C<dbref_callback> returns the DBRef hash reference without
#pod modification.
#pod
#pod Note: in L<MongoDB::MongoClient>, when no L<MongoDB::BSON> object is
#pod provided as the C<bson_codec> attribute, L<MongoDB:MongoClient> creates a
#pod B<custom> L<MongoDB::BSON> object that inflates DBRefs into
#pod L<MongoDB::DBRef> objects using a custom C<dbref_callback>:
#pod
#pod     dbref_callback => sub { return MongoDB::DBRef->new(shift) },
#pod
#pod Object-database mappers may wish to implement alternative C<dbref_callback>
#pod attributes to provide whatever semantics they require.
#pod
#pod =cut

has dbref_callback => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub { sub { shift }  },
);

#pod =attr dt_type
#pod
#pod Sets the type of object which is returned for BSON DateTime fields. The default
#pod is L<DateTime>. Other acceptable values are L<Time::Moment>, L<DateTime::Tiny>
#pod and C<undef>. The latter will give you the raw epoch value (possibly as a
#pod floating point value) rather than an object.
#pod
#pod =cut

has dt_type => (
    is      => 'ro',
    isa     => Str|Undef,
    default => 'DateTime',
);

#pod =attr error_callback
#pod
#pod This attribute specifies a function reference that will be called with
#pod three positional arguments:
#pod
#pod =for :list
#pod * an error string argument describing the error condition
#pod * a reference to the problematic document or byte-string
#pod * the method in which the error occurred (e.g. C<encode_one> or C<decode_one>)
#pod
#pod Note: for decoding errors, the byte-string is passed as a reference to avoid
#pod copying possibly large strings.
#pod
#pod If not provided, errors messages will be thrown with C<Carp::croak>.
#pod
#pod =cut

has error_callback => (
    is      => 'ro',
    isa     => Maybe[CodeRef],
);

#pod =attr invalid_chars
#pod
#pod A string containing ASCII characters that must not appear in keys.  The default
#pod is the empty string, meaning there are no invalid characters.
#pod
#pod =cut

has invalid_chars => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#pod =attr max_length
#pod
#pod This attribute defines the maximum document size. The default is 0, which
#pod disables any maximum.
#pod
#pod If set to a positive number, it applies to both encoding B<and> decoding (the
#pod latter is necessary for prevention of resource consumption attacks).
#pod
#pod =cut

has max_length => (
    is => 'ro',
    isa => NonNegNum,
    default => 0,
);

#pod =attr op_char
#pod
#pod This is a single character to use for special operators.  If a key starts
#pod with C<op_char>, the C<op_char> character will be replaced with "$".
#pod
#pod The default is "$".
#pod
#pod =cut

has op_char => (
    is => 'ro',
    isa => Maybe[ SingleChar ],
);

#pod =attr prefer_numeric
#pod
#pod If set to true, scalar values that look like a numeric value will be
#pod encoded as a BSON numeric type.  When false, if the scalar value was ever
#pod used as a string, it will be encoded as a BSON UTF-8 string.
#pod
#pod The default is false.
#pod
#pod =cut

has prefer_numeric => (
    is => 'ro',
    isa => Boolish,
);

#--------------------------------------------------------------------------#
# public methods
#--------------------------------------------------------------------------#

#pod =method encode_one
#pod
#pod     $byte_string = $codec->encode_one( $doc );
#pod     $byte_string = $codec->encode_one( $doc, \%options );
#pod
#pod Takes a "document", typically a hash reference, an array reference, or a
#pod Tie::IxHash object and returns a byte string with the BSON representation of
#pod the document.
#pod
#pod An optional hash reference of options may be provided.  Valid options include:
#pod
#pod =for :list
#pod * first_key – if C<first_key> is defined, it and C<first_value>
#pod   will be encoded first in the output BSON; any matching key found in the
#pod   document will be ignored.
#pod * first_value - value to assign to C<first_key>; will encode as Null if omitted
#pod * error_callback – overrides codec default
#pod * invalid_chars – overrides codec default
#pod * max_length – overrides codec default
#pod * op_char – overrides codec default
#pod * prefer_numeric – overrides codec default
#pod
#pod =cut

sub encode_one {
    my ( $self, $document, $options ) = @_;

    my $merged_opts = { %$self, ( $options ? %$options : () ) };

    my $bson = eval { MongoDB::BSON::_encode_bson( $document, $merged_opts ) };
    if ( $@ or ( $merged_opts->{max_length} && length($bson) > $merged_opts->{max_length} ) ) {
        my $msg = $@ || "Document exceeds maximum size $merged_opts->{max_length}";
        if ( $merged_opts->{error_callback} ) {
            $merged_opts->{error_callback}->( $msg, $document, 'encode_one' );
        }
        else {
            Carp::croak("During encode_one, $msg");
        }
    }

    return $bson;
}

#pod =method decode_one
#pod
#pod     $doc = $codec->decode_one( $byte_string );
#pod     $doc = $codec->decode_one( $byte_string, \%options );
#pod
#pod Takes a byte string with a BSON-encoded document and returns a
#pod hash reference representin the decoded document.
#pod
#pod An optional hash reference of options may be provided.  Valid options include:
#pod
#pod =for :list
#pod * dbref_callback – overrides codec default
#pod * dt_type – overrides codec default
#pod * error_callback – overrides codec default
#pod * max_length – overrides codec default
#pod
#pod =cut

sub decode_one {
    my ( $self, $string, $options ) = @_;

    my $merged_opts = { %$self, ( $options ? %$options : () ) };

    if ( $merged_opts->{max_length} && length($string) > $merged_opts->{max_length} ) {
        my $msg = "Document exceeds maximum size $merged_opts->{max_length}";
        if ( $merged_opts->{error_callback} ) {
            $merged_opts->{error_callback}->( $msg, \$string, 'decode_one' );
        }
        else {
            Carp::croak("During decode_one, $msg");
        }
    }

    my $document = eval { MongoDB::BSON::_decode_bson( $string, $merged_opts ) };
    if ( $@ ) {
        if ( $merged_opts->{error_callback} ) {
            $merged_opts->{error_callback}->( $@, \$string, 'decode_one' );
        }
        else {
            Carp::croak("During decode_one, $@");
        }
    }

    return $document;
}

#pod =method clone
#pod
#pod     $codec->clone( dt_type => 'Time::Moment' );
#pod
#pod Constructs a copy of the original codec, but allows changing
#pod attributes in the copy.
#pod
#pod =cut

sub clone {
    my ($self, @args) = @_;
    my $class = ref($self);
    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        return $class->new( %$self, %{$args[0]} );
    }

    return $class->new( %$self, @args );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::BSON - Tools for serializing and deserializing data in BSON form

=head1 VERSION

version v1.8.2

=head1 SYNOPSIS

    my $codec = MongoDB::BSON->new;

    my $bson = $codec->encode_one( $document );
    my $doc  = $codec->decode_one( $bson     );

=head1 DESCRIPTION

This class implements a BSON encoder/decoder ("codec").  It consumes documents
and emits BSON strings and vice versa.

=head1 ATTRIBUTES

=head2 dbref_callback

A document with keys C<$ref> and C<$id> is a special MongoDB convention
representing a
L<DBRef|http://docs.mongodb.org/manual/applications/database-references/#dbref>.

This attribute specifies a function reference that will be called with a hash
reference argument representing a DBRef.

The hash reference will have keys C<$ref> and C<$id> and may have C<$db> and
other keys.  The callback must return a scalar value representing the dbref
(e.g. a document, an object, etc.)

The default C<dbref_callback> returns the DBRef hash reference without
modification.

Note: in L<MongoDB::MongoClient>, when no L<MongoDB::BSON> object is
provided as the C<bson_codec> attribute, L<MongoDB:MongoClient> creates a
B<custom> L<MongoDB::BSON> object that inflates DBRefs into
L<MongoDB::DBRef> objects using a custom C<dbref_callback>:

    dbref_callback => sub { return MongoDB::DBRef->new(shift) },

Object-database mappers may wish to implement alternative C<dbref_callback>
attributes to provide whatever semantics they require.

=head2 dt_type

Sets the type of object which is returned for BSON DateTime fields. The default
is L<DateTime>. Other acceptable values are L<Time::Moment>, L<DateTime::Tiny>
and C<undef>. The latter will give you the raw epoch value (possibly as a
floating point value) rather than an object.

=head2 error_callback

This attribute specifies a function reference that will be called with
three positional arguments:

=over 4

=item *

an error string argument describing the error condition

=item *

a reference to the problematic document or byte-string

=item *

the method in which the error occurred (e.g. C<encode_one> or C<decode_one>)

=back

Note: for decoding errors, the byte-string is passed as a reference to avoid
copying possibly large strings.

If not provided, errors messages will be thrown with C<Carp::croak>.

=head2 invalid_chars

A string containing ASCII characters that must not appear in keys.  The default
is the empty string, meaning there are no invalid characters.

=head2 max_length

This attribute defines the maximum document size. The default is 0, which
disables any maximum.

If set to a positive number, it applies to both encoding B<and> decoding (the
latter is necessary for prevention of resource consumption attacks).

=head2 op_char

This is a single character to use for special operators.  If a key starts
with C<op_char>, the C<op_char> character will be replaced with "$".

The default is "$".

=head2 prefer_numeric

If set to true, scalar values that look like a numeric value will be
encoded as a BSON numeric type.  When false, if the scalar value was ever
used as a string, it will be encoded as a BSON UTF-8 string.

The default is false.

=head1 METHODS

=head2 encode_one

    $byte_string = $codec->encode_one( $doc );
    $byte_string = $codec->encode_one( $doc, \%options );

Takes a "document", typically a hash reference, an array reference, or a
Tie::IxHash object and returns a byte string with the BSON representation of
the document.

An optional hash reference of options may be provided.  Valid options include:

=over 4

=item *

first_key – if C<first_key> is defined, it and C<first_value> will be encoded first in the output BSON; any matching key found in the document will be ignored.

=item *

first_value - value to assign to C<first_key>; will encode as Null if omitted

=item *

error_callback – overrides codec default

=item *

invalid_chars – overrides codec default

=item *

max_length – overrides codec default

=item *

op_char – overrides codec default

=item *

prefer_numeric – overrides codec default

=back

=head2 decode_one

    $doc = $codec->decode_one( $byte_string );
    $doc = $codec->decode_one( $byte_string, \%options );

Takes a byte string with a BSON-encoded document and returns a
hash reference representin the decoded document.

An optional hash reference of options may be provided.  Valid options include:

=over 4

=item *

dbref_callback – overrides codec default

=item *

dt_type – overrides codec default

=item *

error_callback – overrides codec default

=item *

max_length – overrides codec default

=back

=head2 clone

    $codec->clone( dt_type => 'Time::Moment' );

Constructs a copy of the original codec, but allows changing
attributes in the copy.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
