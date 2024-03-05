package MsOffice::Word::Surgeon;
use 5.24.0;
use Moose;
use MooseX::StrictConstructor;
use Archive::Zip                          qw(AZ_OK);
use Encode                                qw(encode_utf8 decode_utf8);
use Carp::Clan                            qw(^MsOffice::Word::Surgeon); # will import carp, croak, etc.
use MsOffice::Word::Surgeon::Revision;
use MsOffice::Word::Surgeon::PackagePart;

# syntactic sugar for attributes
sub has_lazy  ($@) {my $attr = shift; has($attr => @_, lazy => 1, builder => "_$attr")}
sub has_inner ($@) {my $attr = shift; has_lazy($attr => @_, init_arg => undef)}


use namespace::clean -except => 'meta';

our $VERSION = '2.05';


#======================================================================
# ATTRIBUTES
#======================================================================

# attributes to the constructor -- either the filename or an existing zip archive
has      'docx'      => (is => 'ro', isa => 'Str');
has_lazy 'zip'       => (is => 'ro', isa => 'Archive::Zip');

# inner attributes lazily constructed by the module
has_inner 'parts'    => (is => 'ro', isa => 'HashRef[MsOffice::Word::Surgeon::PackagePart]',
                         traits => ['Hash'], handles => {part => 'get'});

has_inner 'document' => (is => 'ro', isa => 'MsOffice::Word::Surgeon::PackagePart',
                        handles => [qw/contents original_contents indented_contents plain_text replace/]);
  # Note: this attribute is equivalent to $self->part('document'); made into an attribute
  # for convenience and for automatic delegation of methods through the 'handles' declaration

# just a slot for internal storage
has 'next_rev_id'    => (is => 'bare', isa => 'Num', default => 1, init_arg => undef);
   # used by the revision() method for creating *::Revision objects -- each instance
   # gets a fresh value


#======================================================================
# BUILDING INSTANCES
#======================================================================


# syntactic sugar for supporting ->new($path) instead of ->new(docx => $path)
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && !ref $_[0] ) {
    return $class->$orig(docx => $_[0]);
  }
  else {
    return $class->$orig(@_);
  }
};


# make sure that the constructor got either a 'docx' or a 'zip' attribute
sub BUILD {
  my $self = shift;

  my $class = ref $self;

  $self->{docx} || $self->{zip}
    or croak "$class->new() : need either 'docx' or 'zip' attribute";
  not ($self->{docx} && $self->{zip})
    or croak "$class->new() : can't have both 'docx' and 'zip' attributes";
}


#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _zip {
  my $self = shift;

  -f $self->{docx}
    or croak "file $self->{docx} does not exist";

  my $zip = Archive::Zip->new;
  $zip->read($self->{docx}) == AZ_OK
    or croak "cannot unzip $self->{docx}";

  return $zip;
}



sub _parts {
  my $self = shift;

  # first create a package part for the main document
  my $doc = MsOffice::Word::Surgeon::PackagePart->new(surgeon   => $self,
                                                      part_name => 'document');

  # gather names of headers and footers related to that document
  my @headers_footers = map  {$_->{Target} =~ s/\.xml$//r}
                        grep {$_ && $_->{short_type} =~ /^(header|footer)$/}
                        $doc->relationships->@*;

  # create package parts for headers and footers and assemble all parts into a hash
  my %parts = (document => $doc);
  $parts{$_} = MsOffice::Word::Surgeon::PackagePart->new(surgeon   => $self,
                                                         part_name => $_)
    for @headers_footers;

  return \%parts;
}


sub _document {shift->part('document')}


#======================================================================
# ACCESSING OR CHANGING THE INTERNAL STATE
#======================================================================

sub xml_member {
  my ($self, $member_name, $new_content) = @_;

  if (! defined $new_content) {  # used as a reader
    my $bytes = $self->zip->contents($member_name)
      or croak "no zip member for $member_name";
    return decode_utf8($bytes);
  }
  else {                         # used as a writer
    my $bytes = encode_utf8($new_content);
    return $self->zip->contents($member_name, $bytes);
  }
}

sub _content_types {
  my ($self, $new_content_types) = @_;
  return $self->xml_member('[Content_Types].xml', $new_content_types);
}


sub headers {
  my ($self) = @_;
  return sort {substr($a, 6) <=> substr($b, 6)} grep {/^header/} keys $self->parts->%*;
}

sub footers {
  my ($self) = @_;
  return sort {substr($a, 6) <=> substr($b, 6)} grep {/^footer/} keys $self->parts->%*;
}

sub new_rev_id {
  my ($self) = @_;
  return $self->{next_rev_id}++;
}



#======================================================================
# GENERIC PROPAGATION TO ALL PARTS
#======================================================================


sub all_parts_do {
  my ($self, $method_name, @args) = @_;

  my $parts = $self->parts;

  # apply the method to each package part
  my %result;
  $result{$_} = $parts->{$_}->$method_name(@args) foreach keys %$parts;


  return \%result;
}


#======================================================================
# CLONING
#======================================================================

sub clone {
  my $self = shift;

  # create a new Zip archive and copy all members to it
  my $new_zip = Archive::Zip->new;
  foreach my $member ($self->zip->members) {
    $new_zip->addMember($member);
  }

  # create a new instance of this class
  my $class = ref $self;
  my $clone = $class->new(zip => $new_zip);

  # other attributes will be recreated lazily within the clone .. not
  # the most efficient way, but it is easier and safer, otherwise there is
  # a risk of mixed references

  return $clone;
}

#======================================================================
# SAVING THE FILE
#======================================================================


sub _update_contents_in_zip {
  my $self = shift;
  $_->_update_contents_in_zip foreach values $self->parts->%*;
}


sub overwrite {
  my $self = shift;

  $self->_update_contents_in_zip;
  $self->zip->overwrite == AZ_OK
    or croak "error overwriting zip archive " . $self->docx;
}

sub save_as {
  my ($self, $docx) = @_;

  $self->_update_contents_in_zip;
  $self->zip->writeToFileNamed($docx) == AZ_OK
    or croak "error writing zip archive to $docx";
}


#======================================================================
# DELEGATION TO OTHER CLASSES
#======================================================================

sub new_revision {
  my $self = shift;

  my $revision = MsOffice::Word::Surgeon::Revision->new(rev_id => $self->new_rev_id, @_);
  return $revision->as_xml;
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon - tamper with the guts of Microsoft docx documents, with regexes

=head1 SYNOPSIS

  my $surgeon = MsOffice::Word::Surgeon->new(docx => $filename);

  # extract plain text
  my $main_text    = $surgeon->document->plain_text;
  my @header_texts = map {$surgeon->part($_)->plain_text} $surgeon->headers;

  # reveal bookmarks
  $surgeon->document->reveal_bookmarks(color => 'cyan');

  # anonymize
  my %alias = ('Claudio MONTEVERDI' => 'A_____', 'Heinrich SCHÜTZ' => 'B_____');
  my $pattern = join "|", keys %alias;
  my $replacement_callback = sub {
    my %args =  @_;
    my $replacement = $surgeon->new_revision(to_delete  => $args{matched},
                                             to_insert  => $alias{$args{matched}},
                                             run        => $args{run},
                                             xml_before => $args{xml_before},
                                            );
    return $replacement;
  };
  $surgeon->all_parts_do(replace => qr[$pattern], $replacement_callback);

  # save the result
  $surgeon->overwrite; # or ->save_as($new_filename);


=head1 DESCRIPTION

=head2 Purpose

This module supports a few operations for inspecting or modifying contents
in Microsoft Word documents in '.docx' format -- therefore the name
'surgeon'. Since a surgeon does not give life, there is no support for
creating fresh documents; if you have such needs, use one of the other
packages listed in the L<SEE ALSO> section -- or use the companion module
L<MsOffice::Word::Template>.

Some applications for this module are :

=over

=item *

content extraction in plain text format;

=item *

unlinking fields (equivalent of performing Ctrl-Shift-F9 on the whole document)

=item *

regex replacements within text, for example for :

=over

=item *

anonymization, i.e. replacement of names or adresses by aliases;

=item *

templating, i.e. replacement of special markup by contents coming from a data tree
(see also L<MsOffice::Word::Template>).

=back

=item *

insertion of generated images (for example barcodes) -- see L<MsOffice::Word::Surgeon::PackagePart/images>;

=item *

pretty-printing the internal XML structure.

=back




=head2 Operating mode

The format of Microsoft C<.docx> documents is described in
L<http://www.ecma-international.org/publications/standards/Ecma-376.htm>
and  L<http://officeopenxml.com/>. An excellent introduction can be
found at L<https://www.toptal.com/xml/an-informal-introduction-to-docx>.
Internally, a document is a zipped
archive, where the member named C<word/document.xml> stores the main
document contents, in XML format.

The present module does not parse all details of the whole XML
structure because it only focuses on I<text> nodes (those that contain
literal text) and I<run> nodes (those that contain text formatting
properties). All remaining XML information, for example for
representing sections, paragraphs, tables, etc., is stored as opaque
XML fragments; these fragments are re-inserted at proper places when
reassembling the whole document after having modified some text nodes.


=head1 METHODS

=head2 Constructor

=head3 new

  my $surgeon = MsOffice::Word::Surgeon->new(docx => $filename);
  # or simply : ->new($filename);

Builds a new surgeon instance, initialized with the contents of the given filename.

=head2 Accessors

=head3 docx

Path to the C<.docx> file

=head3 zip

Instance of L<Archive::Zip> associated with this file

=head3 parts

Hashref to L<MsOffice::Word::Surgeon::PackagePart> objects, keyed by their part name in the ZIP file.
There is always a C<'document'> part. Currently, other optional parts may be headers and footers.
Future versions may include other parts like footnotes or endnotes.

=head3 document

Shortcut to C<< $surgeon->part('document') >> -- the 
L<MsOffice::Word::Surgeon::PackagePart> object corresponding to the main document.
See the C<PackagePart> documentation for operations on part objects.
Besides, the following operations are supported directly as methods to the C<< $surgeon >> object
and are automatically delegated to the C<< document >> part :
C<contents>, C<original_contents>, C<indented_contents>, C<plain_text>, C<replace>.



=head3 headers

  my @header_parts = $surgeon->headers;

Returns the ordered list of names of header members stored in the ZIP file.

=head3 footers

  my @footer_parts = $surgeon->footers;

Returns the ordered list of names of footer members stored in the ZIP file.


=head2 Other methods


=head3 part

  my $part = $surgeon->part($part_name);

Returns the L<MsOffice::Word::Surgeon::PackagePart> object corresponding to the given part name.


=head3 all_parts_do

  my $result = $surgeon->all_parts_do($method_name => %args);

Calls the given method on all part objects. Results are accumulated
in a hash, with part names as keys to the results. This is mostly
used to invoke the L<MsOffice::Word::Surgeon::PackagePart/replace> method, i.e. 

  $surgeon->all_parts_do(replace => qr[$pattern], $replacement_callback, %replacement_args);


=head3 xml_member

  my $xml = $surgeon->xml_member($member_name); # reading
  # or
  $surgeon->xml_member($member_name, $new_xml); # writing

Reads or writes the given member name in the ZIP file, with utf8 decoding or encoding.


=head3 save_as

  $surgeon->save_as($docx_file);

Writes the ZIP archive into the given file.


=head3 overwrite

  $surgeon->overwrite;

Writes the updated ZIP archive into the initial file.


=head3 new_revision

  my $xml = $surgeon->new_revision(
    to_delete   => $text_to_delete,
    to_insert   => $text_to_insert,
    author      => $author_string,
    date        => $date_string,
    run         => $run_object,
    xml_before  => $xml_string,
  );

This method is syntactic sugar for instantiating the
L<MsOffice::Word::Surgeon::Revision> class and returning 
XML markup for MsWord revisions (a.k.a. "tracked changes")
generated by that class. Users can
then manually review those revisions within MsWord and accept or reject
them. This is best used in collaboration with the L</replace> method :
the replacement callback can call C<< $self->new_revision(...) >> to
generate revision marks in the document.

Either C<to_delete> or C<to_insert> (or both) must
be present. Other parameters are optional. The parameters are :

=over

=item to_delete

The string of text to delete (usually this will be the C<matched> argument
passed to the replacement callback).

=item to_insert

The string of new text to insert.

=item author

A short string that will be displayed by MsWord as the "author" of this revision.

=item date

A date (and optional time) in ISO format that will be displayed by
MsWord as the date of this revision. The current date and time
will be used by default.

=item run

A reference to the L<MsOffice::Word::Surgeon::Run> object surrounding
this revision. The formatting properties of that run will be
copied into the C<< <w:r> >> nodes of the deleted and inserted text fragments.


=item xml_before

An optional XML fragment to be inserted before the C<< <w:t> >> node
of the inserted text

=back


=head2 Operations on parts

See the L<MsOffice::Word::Surgeon::PackagePart> documentation for other
operations on package parts.

=head1 SEE ALSO

The L<https://metacpan.org/pod/Document::OOXML> distribution on CPAN
also manipulates C<docx> documents, but with another approach :
internally it uses L<XML::LibXML> and XPath expressions for
manipulating XML nodes. The API has some intersections with the
present module, but there are also some differences : C<Document::OOXML>
has more support for styling, while C<MsOffice::Word::Surgeon>
has more flexible mechanisms for replacing
text fragments.


Other programming languages also have packages for dealing with C<docx> documents; here
are some references :

=over

=item L<https://docs.microsoft.com/en-us/office/open-xml/word-processing>

The C# Open XML SDK from Microsoft

=item L<http://www.ericwhite.com/blog/open-xml-powertools-developer-center/>

Additional functionalities built on top of the XML SDK.

=item L<https://poi.apache.org>

An open source Java library from the Apache foundation.

=item L<https://www.docx4java.org/trac/docx4j>

Another open source Java library, competitor to Apache POI.

=item L<https://phpword.readthedocs.io/en/latest/>

A PHP library dealing not only with Microsoft OOXML documents but also
with OASIS and RTF formats.

=item L<https://pypi.org/project/python-docx/>

A Python library, documented at L<https://python-docx.readthedocs.io/en/latest/>.

=back

As far as I can tell, most of these libraries provide objects and methods that
closely reflect the complete XML structure : for example they have classes for
paragraphs, styles, fonts, inline shapes, etc.

The present module is much simpler but also much more limited : it was optimised
for dealing with the text contents and offers no support for presentation or
paging features. However, it has the rare advantage of providing an API for
regex substitutions within Word documents.

The L<MsOffice::Word::Template> module relies on the present module, together with
the L<Perl Template Toolkit|Template>, to implement a templating system for Word documents.


=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2019-2023 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
