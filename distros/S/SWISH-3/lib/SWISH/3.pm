use strict;
use warnings;
use 5.008_003;

package SWISH::3;

our $VERSION = '1.000015';
my $version = $VERSION;
$VERSION = eval $VERSION;    # numerify

# set by libswish3 in swish.c but that happens after %ENV has been
# initialized at Perl compile time.
$ENV{SWISH3} = 1;

use Carp;
use Data::Dump;

use base qw( Exporter );

use constant SWISH_DOC_FIELDS =>
    qw( mtime size encoding mime uri nwords ext parser );
use constant SWISH_TOKEN_FIELDS => qw( pos meta value context len );

# these numbers are assigned via enum in libswish3.h
# and so are too tedious to parse via Makefile.PL
# since they are typically only added-to, not a big deal
# to maintain manually here.
# we can't just assign to the constant value since the
# constants are not loaded until run time above via XSLoader.
use constant SWISH_DOC_FIELDS_MAP => {
    encoding    => 10,
    mime        => 8,
    description => 6,
    mtime       => 5,
    nwords      => 7,
    parser      => 9,
    size        => 4,
    title       => 3,
    uri         => 1,
};

# property name to docinfo attribute
use constant SWISH_DOC_PROP_MAP => {
    swishencoding     => 'encoding',
    swishmime         => 'mime',
    swishlastmodified => 'mtime',
    swishwordnum      => 'nwords',
    swishparser       => 'parser',
    swishdocsize      => 'size',
    swishdocpath      => 'uri'
};

# load the XS at runtime, since we need $version
require XSLoader;
XSLoader::load( __PACKAGE__, $version );

# init the memory counter as class method at start up
# and call debug in END block
SWISH::3->_setup;

END {

# NOTE This will give false positives if there is a Perl reference
# count attached to a SWISH::3 object when the program ends,
# as when in a closure or function.
# so only report when env var is on.
# this is a bug in Perl 5.8.x:
# http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2007-12/msg01047.html

    if ( $ENV{SWISH_DEBUG_MEMORY} && SWISH::3->get_memcount ) {
        warn " ***WARNING*** possible memory leak ***WARNING***\n";
        SWISH::3->mem_debug();
    }
}

# our symbol table is populated with newCONSTSUB in Constants.xs
# directly from libswish3.h, so we just grep the symbol table.
my @constants = ( grep {m/^SWISH_/} keys %SWISH::3:: );

our %EXPORT_TAGS = ( 'constants' => [@constants], );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} } );

# convenience accessors
*config   = \&get_config;
*analyzer = \&get_analyzer;
*regex    = \&get_regex;
*parser   = \&get_parser;

# alias debugging methods for all classes
*SWISH::3::Config::refcount   = \&refcount;
*SWISH::3::Analyzer::refcount = \&refcount;
*SWISH::3::WordList::refcount = \&refcount;
*SWISH::3::Word::refcount     = \&refcount;
*SWISH::3::Doc::refcount      = \&refcount;
*SWISH::3::Data::refcount     = \&refcount;
*SWISH::3::Property::refcount = \&refcount;
*SWISH::3::MetaName::refcount = \&refcount;

# another mnemonic alias
*SWISH::3::Config::merge = \&SWISH::3::Config::add;

sub new {
    my $class = shift;
    my %arg   = @_;
    my $self  = $class->_init;

    if ( $arg{config} ) {
        $self->get_config->add( $arg{config} );
    }

    # override defaults
    for my $param (qw( data_class parser_class config_class analyzer_class ))
    {
        my $method = 'set_' . $param;

        if ( exists $arg{$param} ) {

            #warn "$method";
            $self->$method( $arg{$param} );
        }
    }

    $arg{handler} ||= \&default_handler;

    $self->set_handler( $arg{handler} );

    # Lucy default regex -- should also match swish_tokenize() behaviour
    $arg{regex} ||= qr/\w+(?:[\x{2019}']\w+)*/;
    $self->set_regex( $arg{regex} );

    return $self;
}

sub parse {
    my $self = shift;
    my $what = shift
        or croak "parse requires filehandle, scalar ref or file path";
    if ( ref $what eq 'SCALAR' ) {
        return $self->parse_buffer($what);
    }
    elsif ( ref $what ) {
        return $self->parse_fh($what);
    }
    else {
        return $self->parse_file($what);
    }
}

sub dump {
    my $self = shift;
    if (@_) {
        $self->describe(@_);
        Data::Dump::dump(@_);
    }
    else {
        $self->describe($self);
        Data::Dump::dump($self);
    }
}

sub default_handler {
    my $data = shift;
    unless ( $ENV{SWISH_DEBUG} ) {
        warn "default handler called\n";
        return;
    }

    select(STDERR);
    print '~' x 80, "\n";

    my $props     = $data->properties;
    my $prop_hash = $data->config->get_properties;

    print "Properties\n";
    for my $p ( sort keys %$props ) {
        print " key: $p\n";
        my $prop_value = $props->{$p};
        print " value: " . Data::Dump::dump($prop_value) . "\n";
        my $prop = $prop_hash->get($p);
        printf( "    <%s type='%s'>%s</%s>\n",
            $prop->name, $prop->type, $data->property($p), $prop->name );
    }

    print "Doc\n";
    for my $d (SWISH_DOC_FIELDS) {
        printf( "%15s: %s\n", $d, $data->doc->$d );
    }

    print "TokenList\n";
    my $tokens = $data->tokens;
    while ( my $token = $tokens->next ) {
        print '-' x 50, "\n";
        for my $field (SWISH_TOKEN_FIELDS) {
            printf( "%15s: %s\n", $field, $token->$field );
        }
    }
}

{
    package    # hide from CPAN
        SWISH::3::xml2TiedHash;

    use overload (
        '%{}'    => sub { shift->_as_hash() },
        bool     => sub {1},
        fallback => 1,
    );

    sub _as_hash {
        my $self = shift;
        my %tmp  = ();
        for my $k ( @{ $self->keys } ) {
            my $v = $self->get($k);
            if ( ref $v ) {
                $tmp{$k} = $v->_as_hash();
            }
            else {
                $tmp{$k} = $v;
            }
        }
        return \%tmp;
    }

    sub TO_JSON {
        return shift->_as_hash;
    }

    sub FREEZE {
        return shift->_as_hash;
    }

}
{
    package    # hide
        SWISH::3::xml2Hash;
    our @ISA = ('SWISH::3::xml2TiedHash');
}
{
    package    # hide
        SWISH::3::MetaNameHash;
    our @ISA = ('SWISH::3::xml2TiedHash');
}
{
    package    # hide
        SWISH::3::PropertyHash;
    our @ISA = ('SWISH::3::xml2TiedHash');
}
{
    package    # hide
        SWISH::3::MetaName;
    our @ISA = ('SWISH::3::xml2TiedHash');

    sub _as_hash {
        my $self = shift;
        return { map { $_ => $self->$_ } qw( id name bias alias_for ) };
    }
}
{
    package    # hide
        SWISH::3::Property;
    our @ISA = ('SWISH::3::xml2TiedHash');

    sub _as_hash {
        my $self = shift;
        return { map { $_ => $self->$_ }
                qw( id name ignore_case type verbatim max sort presort alias_for )
        };
    }
}

1;

__END__

=head1 NAME

SWISH::3 - Perl interface to libswish3

=head1 SYNOPSIS

 use SWISH::3 qw(:constants);
 my $handler = sub {
    my $s3_data   = shift;
    my $props     = $s3_data->properties;
    my $prop_hash = $s3_data->config->get_properties;

    print "Properties\n";
    for my $p ( sort keys %$props ) {
        print " key: $p\n";
        my $prop = $prop_hash->get($p);
        printf( "    <%s type='%s'>%s</%s>\n",
            $prop->name, $prop->type, $s3_data->property($p), $prop->name );
    }    

    print "Doc\n";
    for my $d (SWISH_DOC_FIELDS) {
        printf( "%15s: %s\n", $d, $s3_data->doc->$d );
    }    

    print "TokenList\n";
    my $tokens = $s3_data->tokens;
    while ( my $token = $tokens->next ) {
        print '-' x 50, "\n";
        for my $field (SWISH_TOKEN_FIELDS) {
            printf( "%15s: %s\n", $field, $token->$field );
        }    
    }
 };
 my $swish3 = SWISH::3->new(
                config      => 'path/to/config.xml',
                handler     => $handler,
                regex       => qr/\w+(?:'\w+)*/,
                );
 $swish3->parse( 'path/to/file.xml' )
    or die "failed to parse file: " . $swish3->error;
 
 printf "libxml2 version %s\n", $swish3->xml2_version;
 printf "libswish3 version %s\n", $swish3->version;
 
 
=head1 DESCRIPTION

SWISH::3 is a Perl interface to the libswish3 C library.

=head1 CONSTANTS

All the C<SWISH_*> constants defined in libswish3.h are available
and can be optionally imported with the B<:constants> keyword.

 use SWISH::3 qw(:constants);

See the SWISH::3::Constants section below.

In addition, the SWISH::3 Perl class defines some Perl-only constants:

=over

=item SWISH_DOC_FIELDS

An array of method names that can be called on a SWISH::3::Doc object
in your handler method.

=item SWISH_TOKEN_FIELDS

An array of method names that can be called on a SWISH::3::Token object.

=item SWISH_DOC_FIELDS_MAP

A hashref of method names to id integer values. The integer values
are assigned in libswish3.h.

=item SWISH_DOC_PROP_MAP

A hashref of built-in property names to docinfo attribute names.
The values of SWISH_DOC_PROP_MAP are the keys of SWISH_DOC_FIELDS_MAP.

=back

=head1 FUNCTIONS

=head2 default_handler

The handler used if you do not specify one. By default is simply
prints the contents of SWISH::3::Data to stderr.

=head1 CLASS METHODS

=head2 new( I<args> )

I<args> should be an array of key/value pairs. See SYNOPSIS.

Returns a new SWISH::3 instance.

=head2 xml2_version

Returns the libxml2 version used by libswish3.

=head2 version

Returns the libswish3 version.

=head2 refcount( I<object> )

Returns the Perl reference count for I<object>.

=head2 wc_report( I<codepoint> )

Prints a isw* summary to stderr for I<codepoint>. I<codepoint>
should be a positive integer representing a Unicode codepoint.

This prints a report similar to the swish_isw.c example script.

=head2 slurp( I<filename> )

Returns the contents of I<filename> as a scalar string. May also
be called as an object method.

=head1 OBJECT METHODS

=head2 get_file_ext( I<filename> )

Returns file extension for I<filename>.

=head2 get_mime( I<filename> )

Returns the configured MIME type for I<filename> based on file
extension.

=head2 get_real_mime( I<filename> )

Returns the configured MIME type for I<filename>, ignoring
any C<.gz> extension. See L<looks_like_gz>.

=head2 looks_like_gz( I<filename> )

Returns true if I<filename> has a file extension indicating
it is gzip'd. Wraps the swish_fs_looks_like_gz() C function.

=head2 parse( I<filename_or_filehandle_or_string> )

Wrapper around parse_file(), parse_buffer() and parse_fh() that tries
to Do the Right Thing.

=head2 parse_file( I<filename> )

Calls the C function of the same name on I<filename>.

=head2 parse_buffer( I<str> )

Calls the C function of the same name on I<str>. B<Note> that
I<str> should contain the API headers.

=head2 parse_fh( I<filehandle> )

Calls the C function of the same name on I<filehandle>. B<Note> that
the stream pointed to by I<filehandle> should contain the API headers.
See L<SWISH::3::Headers>.

=head2 error

Returns the error message from the last call to parse(), parse_file()
parse_buffer() or parse_fh(). If there was no error on the last
call to one of those methods, returns undef.

=head2 set_config( I<swish_3_config> )

Set the Config object.

=head2 get_config

Returns SWISH::3::Config object.

=head2 config

Alias for get_config().

=head2 set_analyzer( I<swish_3_analyzer> )

Set the Analyzer object.

=head2 get_analyzer

Returns SWISH::3::Analyzer object.

=head2 analyzer

Alias for get_analyzer()

=head2 set_parser( I<swish_3_parser> )

Set the Parser object.

=head2 get_parser

Returns SWISH::3::Parser object.

=head2 parser

Alias for get_parser().

=head2 set_handler( \&handler )

Set the parser handler CODE ref.

=head2 get_handler

Returns a CODE ref for the handler.

=head2 set_data_class( I<class_name> )

Default I<class_name> is C<SWISH::3::Data>.

=head2 get_data_class

Returns class name.

=head2 set_parser_class( I<class_name> )

Default I<class_name> is C<SWISH::3::Parser>.

=head2 get_parser_class

Returns class name.

=head2 set_config_class( I<class_name> )

Default I<class_name> is C<SWISH::3::Config>.

=head2 get_config_class

Returns class name.

=head2 set_analyzer_class( I<class_name> )

Default I<class_name> is C<SWISH::3::Analyzer>.

=head2 get_analyzer_class

Returns class name.

=head2 set_regex( qr/\w+(?:'\w+)*/ )

Set the regex used in tokenize().

=head2 get_regex

Returns the regex used in tokenize().

=head2 regex

Alias for get_regex().

=head2 get_stash

Returns the SWISH::3::Stash object used internally by 
the SWISH::3 object. You typically do not need to access this object
as a user of SWISH::3, but if you are developing code that needs to
access objects within a I<handler> function, you can put it in the Stash
object and then retrieve it later.

Example:

 my $s3    = SWISH::3->new( handler => \&handler );
 my $stash = $s3->get_stash();
 $stash->set('my_indexer' => $indexer);
 
 # later..
 sub handler {
     my $data  = shift;
     my $indexer = $data->s3->get_stash->get('my_indexer');
     $indexer->add_doc( $data );
 }

=head2 tokenize( I<string> [, I<metaname>, I<context> ] )

Returns a SWISH::3::TokenIterator object representing I<string>.
The tokenizer uses the regex defined in set_regex().

=head2 tokenize_native( I<string> [, I<metaname>, I<context> ] )

Returns a SWISH::3::TokenIterator object representing I<string>.
The tokenizer uses the built-in libswish3 tokenizer, not a regex.

=head1 DEVELOPER METHODS

=head2 ref_cnt

Returns the internal reference count for the underlying C struct pointer.

=head2 debug([I<n>])

Get/set the internal debugging level.

=head2 describe( I<object> )

Like calling Devel::Peek::Dump on I<object>.

=head2 mem_debug

Calls the C function swish_memcount_debug().

=head2 get_memcount

Returns the global C malloc counter value.

=head2 dump

A wrapper around describe() and Data::Dump::dump().

=head1 SWISH::3::Analyzer

=head2 new( I<swish_3_config> )

Returns a new SWISH::3::Analyzer instance.

=head2 set_regex( qr/\w+/ )

Set the regex used in SWISH::3->tokenize().

=head2 get_regex

Returns a qr// regex object.

=head2 get_tokenize

Get the tokenize flag. Default is true.

=head2 set_tokenize( 0|1 )

Toggle the tokenize flag. Default is true (tokenize contents when
file is parsed).

=head1 SWISH::3::Config

=head2 set_default

=head2 set_properties

Not yet implemented.

=head2 get_properties

Returns SWISH::3::PropertyHash object.

=head2 set_metanames

Not yet implemented.

=head2 get_metanames

Returns SWISH::3::MetaNameHash object.

=head2 set_mimes

Not yet implemented.

=head2 get_mimes

Returns SWISH::3::xml2Hash object.

=head2 set_parsers

Not yet implemented.

=head2 get_parsers

Returns SWISH::3::xml2Hash object.

=head2 set_aliases

Not yet implemented.

=head2 get_aliases

Returns SWISH::3::xml2Hash object.

=head2 set_index

Not yet implemented.

=head2 get_index

Returns SWISH::3::xml2Hash object.

=head2 set_misc

Not yet implemented.

=head2 get_misc

Returns SWISH::3::xml2Hash object.

=head2 debug

=head2 add(I<file_or_xml>)

An alias for add() is merge().

=head2 delete

delete() is B<NOT YET IMPLEMENTED>.

=head2 read( I<filename> )

Returns SWISH::3::Config object.

=head2 write( I<filename> )

=head1 SWISH::3::Data

=head2 s3

Get the parent SWISH::3 object.

=head2 config

Get the parent SWISH::3::Config object.

=head2 property( I<name> )

Returns the string value of PropertyName I<name>.

=head2 metaname( I<name> )

Returns the string value of MetaName I<name>.

=head2 properties

Returns a hashref of name/value pairs.

=head2 metanames

Returns a hashref of name/value pairs.

=head2 doc

Returns a SWISH::3::Doc object.

=head2 tokens

Returns a SWISH::3::TokenIterator object.

=head1 SWISH::3::Doc

=head2 mtime

Returns the last modified time as epoch int.

=head2 size

Returns the size in bytes.

=head2 nwords

Returns the number of tokenized words in the Doc.

=head2 encoding

Returns the string encoding of Doc.

=head2 uri

Returns the URI value.

=head2 ext

Returns the file extension.

=head2 mime

Returns the mime type.

=head2 parser

Returns the name of the parser used (TXT, HTML, or XML).

=head2 action

Returns the intended action (e.g., add, delete, update).

=head1 SWISH::3::MetaName

=head2 new( I<name> )

Returns a new SWISH::3::MetaName instance. 

TODO: there are no set methods so this isn't of much use.

=head2 id

Returrns the id integer.

=head2 name

Returns the name string.

=head2 bias

Returns the bias integer.

=head2 alias_for

Returns the alias_for string.

=head1 SWISH::3::MetaNameHash

=head2 get( I<name> )

Get the SWISH::3::MetaName object for I<name>

=head2 set( I<name>, I<swish_3_metaname> )

Set the SWISH::3::MetaName for I<name>.

=head2 keys

Returns array of names.

=head1 SWISH::3::Property

=head2 id

Returns the id integer.

=head2 name

Returns the name string.

=head2 ignore_case

Returns the ignore_case boolean.

=head2 type

Returns the type integer.

=head2 verbatim

Returns the verbatim boolean.

=head2 max

Returns the max integer.

=head2 sort

Returns the sort boolean.

=head2 alias_for

Returns the alias_for string.

=head1 SWISH::3::PropertyHash

=head2 get( I<name> )

Get the SWISH::3::Property object for I<name>

=head2 set( I<name>, I<swish_3_property> )

Set the SWISH::3::Property for I<name>.

=head2 keys

Returns array of names.

=head1 SWISH::3::Stash

=head2 get( I<key> )

=head2 set( I<key>, I<value> )

=head2 keys

=head2 values

=head1 SWISH::3::Token

=head2 value

Returns the value string.

=head2 meta

Returns the SWISH::3::MetaName object for the Token.

=head2 meta_id

Returns the id integer for the related MetaName.

=head2 context

Returns the context string.

=head2 pos

Returns the position integer.

=head2 len

Returns the length in bytes of the Token.

=head1 SWISH::3::TokenIterator

=head2 next

Returns the next SWISH::3::Token.

=head1 SWISH::3::xml2Hash

=head2 get( I<key> )

=head2 set( I<key>, I<value> )

=head2 keys

=head1 SWISH::3::Constants

The following constants are imported directly from libswish3
and are defined there.

=over

=item SWISH_ALIAS

=item SWISH_BODY_TAG

=item SWISH_BUFFER_CHUNK_SIZE

=item SWISH_CASCADE_META_CONTEXT

=item SWISH_CLASS_ATTRIBUTES

=item SWISH_CONTRACTIONS

=item SWISH_DATE_FORMAT_STRING

=item SWISH_DEFAULT_ENCODING

=item SWISH_DEFAULT_METANAME

=item SWISH_DEFAULT_MIME

=item SWISH_DEFAULT_PARSER

=item SWISH_DEFAULT_PARSER_TYPE

=item SWISH_DEFAULT_VALUE

=item SWISH_DOM_CHAR

=item SWISH_DOM_STR

=item SWISH_ENCODING_ERROR

=item SWISH_ESTRAIER_FORMAT

=item SWISH_EXT_SEP

=item SWISH_FALSE

=item SWISH_FOLLOW_XINCLUDE

=item SWISH_HEADER_FILE

=item SWISH_HEADER_ROOT

=item SWISH_IGNORE_XMLNS

=item SWISH_INCLUDE_FILE

=item SWISH_INDEX

=item SWISH_INDEX_FILEFORMAT

=item SWISH_INDEX_FILENAME

=item SWISH_INDEX_FORMAT

=item SWISH_INDEX_LOCALE

=item SWISH_INDEX_STEMMER_LANG

=item SWISH_INDEX_NAME

=item SWISH_KINOSEARCH_FORMAT

=item SWISH_LATIN1_ENCODING

=item SWISH_LOCALE

=item SWISH_LUCY_FORMAT

=item SWISH_MAXSTRLEN

=item SWISH_MAX_FILE_LEN

=item SWISH_MAX_HEADERS

=item SWISH_MAX_SORT_STRING_LEN

=item SWISH_MAX_WORD_LEN

=item SWISH_META

=item SWISH_MIME

=item SWISH_MIN_WORD_LEN

=item SWISH_PARSERS

=item SWISH_PARSER_HTML

=item SWISH_PARSER_TXT

=item SWISH_PARSER_XML

=item SWISH_PATH_SEP_STR

=item SWISH_PREFIX_MTIME

=item SWISH_PREFIX_URL

=item SWISH_PROP

=item SWISH_PROP_DATE

=item SWISH_PROP_DBFILE

=item SWISH_PROP_DESCRIPTION

=item SWISH_PROP_DOCID

=item SWISH_PROP_DOCPATH

=item SWISH_PROP_ENCODING

=item SWISH_PROP_INT

=item SWISH_PROP_MIME

=item SWISH_PROP_MTIME

=item SWISH_PROP_NWORDS

=item SWISH_PROP_PARSER

=item SWISH_PROP_RANK

=item SWISH_PROP_RECCNT

=item SWISH_PROP_SIZE

=item SWISH_PROP_STRING

=item SWISH_PROP_TITLE

=item SWISH_RD_BUFFER_SIZE

=item SWISH_SPECIAL_ARG

=item SWISH_STACK_SIZE

=item SWISH_SWISH_FORMAT

=item SWISH_TITLE_METANAME

=item SWISH_TITLE_TAG

=item SWISH_TOKENIZE

=item SWISH_TOKENPOS_BUMPER

=item SWISH_TOKEN_LIST_SIZE

=item SWISH_TRUE

=item SWISH_UNDEFINED_METATAGS

=item SWISH_UNDEFINED_XML_ATTRIBUTES

=item SWISH_URL_LENGTH

=item SWISH_VERSION

=item SWISH_WORDS

=item SWISH_XAPIAN_FORMAT

=back

=head1 BUGS AND LIMITATIONS

libswish3 is not yet ported to Windows.

=head1 AUTHOR

Peter Karman C<< perl@peknet.com >>

=head1 COPYRIGHT

Copyright 2010 Peter Karman.

This file is part of libswish3.

libswish3 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

libswish3 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.


=head1 SEE ALSO

L<http://swish3.dezi.org/>, L<http://swish-e.org/>

L<SWISH::Prog>, L<Dezi::App>

=cut
