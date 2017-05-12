# OpenSP.pm -- SGML::Parser::OpenSP module
#
# $Id: OpenSP.pm,v 1.35 2007/12/06 06:00:02 hoehrmann Exp $

package SGML::Parser::OpenSP;
use 5.008; 
use strict;
use warnings;
use Carp;
use SGML::Parser::OpenSP::Tools qw();
use File::Temp                  qw();

use base qw(Class::Accessor);

our $VERSION = '0.994';

require XSLoader;
XSLoader::load('SGML::Parser::OpenSP', $VERSION);

__PACKAGE__->mk_accessors(qw/
    handler
    show_open_entities
    show_open_elements
    show_error_numbers
    output_comment_decls
    output_marked_sections
    output_general_entities
    map_catalog_document
    restrict_file_reading
    warnings
    catalogs
    search_dirs
    include_params
    active_links
    pass_file_descriptor
/);

sub split_message
{
    my $self = shift;
    my $mess = shift;
    my $loca = $self->get_location;
    my $name = $loca->{FileName};

    return SGML::Parser::OpenSP::Tools::split_message
    (
        $mess->{Message},
        $loca->{FileName},
        $self->show_open_entities,
        $self->show_error_numbers,
        $self->show_open_elements
    );
}

sub parse_string
{
    my $self = shift;
    my $text = shift;
    
    # high security on systems that support it
    File::Temp->safe_level(File::Temp::HIGH);
    
    # create temp file, this would croak if it fails, so
    # there is no need for us to check the return value
    my $fh = File::Temp->new();

    # set proper mode
    binmode $fh, ':utf8';

    # store content
    print $fh $text;

    # seek to start
    seek $fh, 0, 0;

    if (not $self->pass_file_descriptor)
    {
        $self->parse('<OSFILE encoding="utf-8">' . $fh->filename);
    }
    else
    {
        my $no = fileno $fh;
        unless (defined $no)
        {
            carp "fileno() on temporary file handle failed.\n";
            return;
        }
        $self->parse('<OSFD encoding="utf-8">' . $no);
    }
}

1;

__END__

=pod

=head1 NAME

SGML::Parser::OpenSP - Parse SGML documents using OpenSP

=head1 SYNOPSIS

  use SGML::Parser::OpenSP;

  my $p = SGML::Parser::OpenSP->new;
  my $h = ExampleHandler->new;

  $p->catalogs(qw(xhtml.soc));
  $p->warnings(qw(xml valid));
  $p->handler($h);

  $p->parse("example.xhtml");

=head1 DESCRIPTION

This module provides an interface to the OpenSP SGML parser. OpenSP and
this module are event based. As the parser recognizes parts of the document
(say the start or end of an element), then any handlers registered for that
type of an event are called with suitable parameters.

=head1 COMMON METHODS

=over 4

=item new()

Returns a new SGML::Parser::OpenSP object. Takes no arguments.

=item parse($file)

Parses the file passed as an argument. Note that this must be a filename and
not a filehandle. See L<PROCESSING FILES> below for details.

=item parse_string($data)

Parses the data passed as an argument. See L<PROCESSING FILES> below for details.

=item halt()

Halts processing before parsing the entire document. Takes no arguments.

=item split_message()

Splits OpenSP's error messages into their component parts.
See L<POST-PROCESSING ERROR MESSAGES> below for details.

=item get_location()

See L<POSITIONING INFORMATION> below for details.

=back

=head1 CONFIGURATION

=head2 BOOLEAN OPTIONS

=over 4

=item $p->handler([$handler])

Report events to the blessed reference $handler.

=back

=head2 ERROR MESSAGE FORMAT

=over 4

=item $p->show_open_entities([$bool])

Describe open entities in error messages. Error messages always include
the position of the most recently opened external entity. The default is
false.

=item $p->show_open_elements([$bool])

Show the generic identifiers of open elements in error messages.
The default is false.

=item $p->show_error_numbers([$bool])

Show message numbers in error messages.

=back

=head2 GENERATED EVENTS

=over 4

=item $p->output_comment_decls([$bool])

Generate C<comment_decl> events. The default is false.

=item $p->output_marked_sections([$bool])

Generate marked section events (C<marked_section_start>,
C<marked_section_end>, C<ignored_chars>). The default is false.

=item $p->output_general_entities([$bool])

Generate C<general_entity> events. The default is false.

=back

=head2 IO SETTINGS

=over 4

=item $p->map_catalog_document([$bool])

C<parse> arguments specify catalog files rather than the document entity.
The document entity is specified by the first DOCUMENT entry in the catalog
files. The default is false.

=item $p->restrict_file_reading([$bool])

Restrict file reading to the specified directories (see the C<search_dirs>
method and the C<SGML_SEARCH_PATH> environment variable). You should turn
this option on and configure the search paths accordingly if you intend to
process untrusted resources. The default is false.

=item $p->catalogs([@catalogs])

Map public identifiers and entity names to system identifiers using the
specified catalog entry files. Multiple catalogs are allowed. If there
is a catalog entry file called C<catalog> in the same place as the
document entity, it will be searched for immediately after those specified.

=item $p->search_dirs([@search_dirs])

Search the specified directories for files specified in system identifiers.
Multiple values options are allowed. See the description of the osfile
storage manager in the OpenSP documentation for more information about file
searching.

=item $p->pass_file_descriptor([$bool])

Instruct C<parse_string> to pass the input data down to the guts of OpenSP
using the C<OSFD> storage manager (if true) or the C<OSFILE> storage manager
(if false). This amounts to the difference between passing a file descriptor
and a (temporary) file name.

The default is true except on platforms, such as Win32, which are known to
not support passing file descriptors around in this manner. On platforms
which support it you can call this method with a false parameter to force
use of temporary file names instead.

In general, this will do the right thing on its own so it's best to
consider this an internal method. If your platform is such that you have
to force use of the OSFILE storage manager, please report it as a bug
and include the values of C<$^O>, C<$Config{archname}>, and a description
of the platform (e.g. "Windows Vista Service Pack 42").

=back

=head2 PROCESSING OPTIONS

=over 4

=item $p->include_params([@include_params])

For each name in @include_params pretend that 

  <!ENTITY % name "INCLUDE">

occurs at the start of the document type declaration subset in the SGML
document entity. Since repeated definitions of an entity are ignored,
this definition will take precedence over any other definitions of this
entity in the document type declaration. Multiple names are allowed.
If the SGML declaration replaces the reserved name INCLUDE then the new
reserved name will be the replacement text of the entity. Typically the
document type declaration will contain 

  <!ENTITY % name "IGNORE">

and will use %name; in the status keyword specification of a marked
section declaration. In this case the effect of the option will be to
cause the marked section not to be ignored.

=item $p->active_links([@active_links])

???

=back

=head2 ENABLING WARNINGS

Additional warnings can be enabled using

  $p->warnings([@warnings])

The following values can be used to enable warnings:

=over 4

=item xml 

Warn about constructs that are not allowed by XML. 

=item mixed 

Warn about mixed content models that do not allow #pcdata anywhere. 

=item sgmldecl 

Warn about various dubious constructions in the SGML declaration. 

=item should 

Warn about various recommendations made in ISO 8879 that the document
does not comply with. (Recommendations are expressed with ``should'',
as distinct from requirements which are usually expressed with ``shall''.)

=item default 

Warn about defaulted references. 

=item duplicate 

Warn about duplicate entity declarations. 

=item undefined 

Warn about undefined elements: elements used in the DTD but not defined. 

=item unclosed 

Warn about unclosed start and end-tags. 

=item empty 

Warn about empty start and end-tags. 

=item net 

Warn about net-enabling start-tags and null end-tags. 

=item min-tag 

Warn about minimized start and end-tags. Equivalent to combination of
unclosed, empty and net warnings. 

=item unused-map 

Warn about unused short reference maps: maps that are declared with a
short reference mapping declaration but never used in a short reference
use declaration in the DTD. 

=item unused-param 

Warn about parameter entities that are defined but not used in a DTD.
Unused internal parameter entities whose text is C<INCLUDE> or C<IGNORE>
won't get the warning. 

=item notation-sysid 

Warn about notations for which no system identifier could be generated. 

=item all 

Warn about conditions that should usually be avoided (in the opinion of
the author). Equivalent to: C<mixed>, C<should>, C<default>, C<undefined>,
C<sgmldecl>, C<unused-map>, C<unused-param>, C<empty> and C<unclosed>.

=back

=head2 DISABLING WARNINGS

A warning can be disabled by using its name prefixed with C<no->.
Thus calling warnings(qw(all no-duplicate)) will enable all warnings
except those about duplicate entity declarations. 

The following values for C<warnings()> disable errors: 

=over 4

=item no-idref 

Do not give an error for an ID reference value which no element has
as its ID. The effect will be as if each attribute declared as an ID
reference value had been declared as a name. 

=item no-significant 

Do not give an error when a character that is not a significant
character in the reference concrete syntax occurs in a literal in the
SGML declaration. This may be useful in conjunction with certain buggy
test suites. 

=item no-valid 

Do not require the document to be type-valid. This has the effect of
changing the SGML declaration to specify C<VALIDITY NOASSERT> and C<IMPLYDEF
ATTLIST YES ELEMENT YES>. An option of C<valid> has the effect of changing
the SGML declaration to specify C<VALIDITY TYPE> and C<IMPLYDEF ATTLIST NO
ELEMENT NO>. If neither C<valid> nor C<no-valid> are specified, then the
C<VALIDITY> and C<IMPLYDEF> specified in the SGML declaration will be used. 

=back

=head2 XML WARNINGS

The following warnings are turned on for the C<xml> warning described above:

=over 4

=item inclusion 

Warn about inclusions in element type declarations. 

=item exclusion 

Warn about exclusions in element type declarations. 

=item rcdata-content 

Warn about RCDATA declared content in element type declarations. 

=item cdata-content 

Warn about CDATA declared content in element type declarations. 

=item ps-comment 

Warn about comments in parameter separators. 

=item attlist-group-decl 

Warn about name groups in attribute declarations. 

=item element-group-decl 

Warn about name groups in element type declarations. 

=item pi-entity 

Warn about PI entities. 

=item internal-sdata-entity 

Warn about internal SDATA entities. 

=item internal-cdata-entity 

Warn about internal CDATA entities. 

=item external-sdata-entity 

Warn about external SDATA entities. 

=item external-cdata-entity 

Warn about external CDATA entities. 

=item bracket-entity 

Warn about bracketed text entities. 

=item data-atts 

Warn about attribute definition list declarations for notations. 

=item missing-system-id 

Warn about external identifiers without system identifiers. 

=item conref 

Warn about content reference attributes. 

=item current 

Warn about current attributes. 

=item nutoken-decl-value 

Warn about attributes with a declared value of NUTOKEN or NUTOKENS. 

=item number-decl-value 

Warn about attributes with a declared value of NUMBER or NUMBERS. 

=item name-decl-value 

Warn about attributes with a declared value of NAME or NAMES. 

=item named-char-ref 

Warn about named character references. 

=item refc 

Warn about ommitted refc delimiters. 

=item temp-ms 

Warn about TEMP marked sections. 

=item rcdata-ms 

Warn about RCDATA marked sections. 

=item instance-include-ms 

Warn about INCLUDE marked sections in the document instance. 

=item instance-ignore-ms 

Warn about IGNORE marked sections in the document instance. 

=item and-group 

Warn about AND connectors in model groups. 

=item rank 

Warn about ranked elements. 

=item empty-comment-decl 

Warn about empty comment declarations. 

=item att-value-not-literal 

Warn about attribute values which are not literals. 

=item missing-att-name 

Warn about ommitted attribute names in start tags. 

=item comment-decl-s 

Warn about spaces before the MDC in comment declarations. 

=item comment-decl-multiple 

Warn about comment declarations containing multiple comments. 

=item missing-status-keyword 

Warn about marked sections without a status keyword. 

=item multiple-status-keyword 

Warn about marked sections with multiple status keywords. 

=item instance-param-entity 

Warn about parameter entities in the document instance. 

=item min-param 

Warn about minimization parameters in element type declarations. 

=item mixed-content-xml 

Warn about cases of mixed content which are not allowed in XML. 

=item name-group-not-or 

Warn about name groups with a connector different from OR. 

=item pi-missing-name 

Warn about processing instructions which don't start with a name. 

=item instance-status-keyword-s 

Warn about spaces between DSO and status keyword in marked sections. 

=item external-data-entity-ref 

Warn about references to external data entities in the content. 

=item att-value-external-entity-ref 

Warn about references to external data entities in attribute values. 

=item data-delim 

Warn about occurances of `<' and `&' as data. 

=item explicit-sgml-decl 

Warn about an explicit SGML declaration. 

=item internal-subset-ms 

Warn about marked sections in the internal subset. 

=item default-entity 

Warn about a default entity declaration. 

=item non-sgml-char-ref 

Warn about numeric character references to non-SGML characters. 

=item internal-subset-ps-param-entity 

Warn about parameter entity references in parameter separators in the internal subset. 

=item internal-subset-ts-param-entity 

Warn about parameter entity references in token separators in the internal subset. 

=item internal-subset-literal-param-entity 

Warn about parameter entity references in parameter literals in the internal subset. 

=back

=head1 PROCESSING FILES

In order to start processing of a document and recieve events, the
C<parse> method must be called. It takes one argument specifying
the path to a file (not a file handle). You must set an event handler
using the C<handler> method prior to using this method. The return
value of C<parse> is currently undefined.

=head1 EVENT HANDLERS

In order to receive data from the parser you need to write an event
handler. For example,

  package ExampleHandler;

  sub new { bless {}, shift }

  sub start_element
  {
      my ($self, $elem) = @_;
      printf "  * %s\n", $elem->{Name};
  }

This handler would print all the element names as they are found
in the document, for a typical XHTML document this might result in
something like

  * html
  * head
  * title
  * body
  * p
  * ...

The events closely match those in the generic interface to OpenSP,
see L<http://openjade.sf.net/doc/generic.htm> for more
information.

The event names have been changed to lowercase and underscores to separate
words and properties are capitalized. Arrays are represented as Perl array
references. C<Position> information is not passed to the handler but made
available through the C<get_location> method which can be called from event
handlers. Some redundant information has also been stripped and the generic
identifier of an element is stored in the C<Name> hash entry.

For example, for an EndElementEvent the C<end_element> handler gets called
with a hash reference

  {
    Name => 'gi'
  }

The following events are defined:

  * appinfo
  * processing_instruction
  * start_element
  * end_element
  * data
  * sdata
  * external_data_entity_ref
  * subdoc_entity_ref
  * start_dtd
  * end_dtd
  * end_prolog
  * general_entity       # set $p->output_general_entities(1)
  * comment_decl         # set $p->output_comment_decls(1)
  * marked_section_start # set $p->output_marked_sections(1)
  * marked_section_end   # set $p->output_marked_sections(1)
  * ignored_chars        # set $p->output_marked_sections(1)
  * error
  * open_entity_change

If the documentation of the generic interface to OpenSP states that
certain data is not valid, it will not be available through this
interface (i.e., the respective key does not exist in the hash ref).

=head1 POSITIONING INFORMATION

Event handlers can call the C<get_location> method on the parser object
to retrieve positioning information, the get_location method will return
a hash reference with the following properties:

  LineNumber   => ..., # line number
  ColumnNumber => ..., # column number
  ByteOffset   => ..., # number of preceding bytes
  EntityOffset => ..., # number of preceding bit combinations
  EntityName   => ..., # name of the external entity
  FileName     => ..., # name of the file

These can be C<undef> or an empty string.

=head1 POST-PROCESSING ERROR MESSAGES

OpenSP returns error messages in form of a string rather than individual
components of the message like line numbers or message text. The
C<split_message> method on the parser object can be used to post-process
these error message strings as reliable as possible. It can be used e.g.
from an error event handler if the parser object is accessible like

  sub error
  {
    my $self = shift;
    my $erro = shift;
    my $mess = $self->{parser}->split_message($erro);
  }

See the documentation of C<split_message> in the
L<SGML::Parser::OpenSP::Tools> documentation.

=head1 UNICODE SUPPORT

All strings returned from event handlers and helper routines are UTF-8
encoded with the UTF-8 flag turned on, helper functions like C<split_message>
expect (but don't check) that string arguments are UTF-8 encoded and have
the UTF-8 flag turned on. Behavior of helper functions is undefined when
you pass unexpected input and should be avoided.

C<parse> has limited support for binary input, but the binary input
must be compatible with OpenSP's generic interface requirements and you
must specify the encoding through means available to OpenSP to enable it
to properly decode the binary input. Any encoding meta data about such
binary input specific to Perl (such as encoding disciplines for file
handles when you pass a file descriptor) will be ignored. For more specific
information refer to the OpenSP manual.

=over 4

=item * L<http://openjade.sourceforge.net/doc/sysid.htm>

=item * L<http://openjade.sourceforge.net/doc/charset.htm>

=back

=begin comment

=head1 NOTES ON EXTERNAL ENTITIES

(Note that this list of issues in incomplete.)

If you intend to use this module to process untrusted content and/or
provide access to its output to untrusted users, you should be aware
of a number of issues involving external entities that might be relevant
to your application.

OpenSP will attempt to resolve external parsed entities and supports
resolution of system identifiers in a variety of ways. This can have
a number of undesired effects:

=over 4

=item undesired network traffic

You can compile OpenSP to support HTTP and if you attempt to process a
document like

  <!DOCTYPE example SYSTEM "http://www.example.org/example.dtd">
  <example></example>

OpenSP will attempt to fetch C<http://www.example.org/example.dtd> if
the system identifier cannot be generated from a catalog entry. A
malicious user might be able to abuse this ability to run denial of
service attacks on specific hosts or just to drive your network traffic
expenses.

=item access to internal and restricted resources

If the machine and/or service running this module has access privileges
to specific resources, a malicious user might be able to access these
resources in undesired ways or even be able to read such resources if
output from this module is exposed to them.

Examples for such attacks might include triggering read access to special
resources like C</dev/stdin> which might never finish or C</etc/passwd>
of which the content might be revealed depending on how much output from
this module is made available. If error messages are made available, a
document like

  <!DOCTYPE x [
    <!ENTITY x SYSTEM "/etc/passwd">
    <!ATTLIST x x (x|y) #IMPLIED>]
  ><x x="&x;"></x>

could trigger such behavior as OpenSP cites the content of the entity
replacement text in one of the error messages for the document (and
elsewhere). To restrict access to local file resources have a look at
the C<restrict_file_reading> method and the documentation of the
functionality in the OpenSP documentation.

The same applies to HTTP resources, if a web server trusts your host it
might reveal private data, for example, you have a web server on localhost
with a document root of C</>, then

  <!DOCTYPE x [
    <!ENTITY x SYSTEM "http://localhost/etc/passwd">
    <!ATTLIST x x (x|y) #IMPLIED>]
  ><x x="&x;"></x>

would have the same effect if the web server has access privileges to
the file.

Formal system identifiers might be an additional problem in this regard,
OpenSP for example generally supports documents like

  <!DOCTYPE x SYSTEM "<osfd>4">
  <x></x>
  
In order to resolve the system identifier OpenSP would attempt to read
from the file descriptor C<4> if the system supports that and C<4>
happens to be a legal file descriptor. See the OpenSP documentation on
system identifiers for additional information.

=item memory problems

Note in particular that OpenSP supports a literal storage manager which
would attempt to read from a string, an example would be

  <!DOCTYPE x SYSTEM "<LITERAL>
    <!ELEMENT x - - EMPTY>
  >
  <x>

While generally harmless, you should note that OpenSP's current
implementation would create many copies of the system identifier
most of which are encoded using 4 bytes per character and which gets
duplicated in a number of places, e.g. in error messages. Such a document
could be used in a denial of service attack where your application runs
quickly out of memory even for relatively small input documents.

=back

One strategy to avoid such problems would be to limit the resolution of
external entities, it is for example possible to C<halt> the parser from
within a C<start_dtd> handler after checking the specified and/or generated
system identifier for proper values. Though consider a document like

  <!DOCTYPE x [
    <!ENTITY % x SYSTEM '...'>
    %x;
  ]><x></x>

Here OpenSP would attempt to read from the external entity and the
C<start_dtd> would not know about it. This can be solved by using a
C<general_entity> handler which would be called when the reference to
the parameter entity in the example above is encountered, the same for
a document like

  <!DOCTYPE x [
    <!ENTITY x SYSTEM '...'>
  ]><x>&x;</x>

Note that halting from all undesired C<start_dtd> and C<general_entity>
events might not be sufficient to prevent reading of external entities.

Using the C<open_entity_change> event you can keep track of attempts to
open external parsed entities referenced from the document or one of its
entities. Note that the event handler gets called B<after> OpenSP opened
the entity.

=end comment

=head1 ENVIRONMENT VARIABLES

OpenSP supports a number of environment variables to control specific
processing aspects such as C<SGML_SEARCH_PATH> or C<SP_CHARSET_FIXED>.
Portable applications need to ensure that these are set prior to
loading the OpenSP library into memory which happens when the XS code
is loaded. This means you need to wrap the code into a C<BEGIN> block:

  BEGIN { $ENV{SP_CHARSET_FIXED} = 1; }
  use SGML::Parser::OpenSP;
  # ...

Otherwise changes to the environment might not propagate to OpenSP.
This applies specifically to Win32 systems. 

=over 4

=item SGML_SEARCH_PATH

See L<http://openjade.sourceforge.net/doc/sysid.htm>.

=item SP_HTTP_USER_AGENT

The C<User-Agent> header for HTTP requests.

=item SP_HTTP_ACCEPT

The C<Accept> header for HTTP requests.

=item SP_MESSAGE_FORMAT

Enable run time selection of message format, Value is one of C<XML>,
C<NONE>, C<TRADITIONAL>. Whether this will have an effect depends
on a compile time setting which might not be enabled in your OpenSP
build. This module assumes that no such support was compiled in.

=item SGML_CATALOG_FILES

=item SP_USE_DOCUMENT_CATALOG

See L<http://openjade.sourceforge.net/doc/catalog.htm>.

=item SP_SYSTEM_CHARSET

=item SP_CHARSET_FIXED

=item SP_BCTF

=item SP_ENCODING

See L<http://openjade.sourceforge.net/doc/charset.htm>.

=back

Note that you can use the C<search_dirs> method instead of using
C<SGML_SEARCH_PATH> and the C<catalogs> method instead of using
C<SGML_CATALOG_FILES> and attributes on storage object specifications
for C<SP_BCTF> and C<SP_ENCODING> respectively. For example, if
C<SP_CHARSET_FIXED> is set to C<1> you can use

  $p->parse("<OSFILE encoding='UTF-8'>example.xhtml");

to process C<example.xhtml> using the C<UTF-8> character encoding.

=head1 KNOWN ISSUES

OpenSP must be compiled with C<SP_MULTI_BYTE> I<defined> and with
C<SP_WIDE_SYSTEM> I<undefined>, this module will otherwise break
at runtime or not compile.

=head1 BUG REPORTS

Please report bugs in this module via
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SGML-Parser-OpenSP>

Please report bugs in OpenSP via
L<http://sf.net/tracker/?group_id=2115&atid=102115>

Please send comments and questions to the spo-devel mailing list, see
L<http://lists.sf.net/lists/listinfo/spo-devel>
for details.

=head1 SEE ALSO

=over 4

=item * L<http://openjade.sf.net/doc/generic.htm>

=item * L<http://openjade.sf.net/>

=item * L<http://sf.net/projects/spo/>

=back

=head1 AUTHORS

  Terje Bless <link@cpan.org> wrote version 0.01.
  Bjoern Hoehrmann <bjoern@hoehrmann.de> wrote version 0.02+.

=head1 COPYRIGHT AND LICENSE

  Copyright (c) 2006-2008 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
