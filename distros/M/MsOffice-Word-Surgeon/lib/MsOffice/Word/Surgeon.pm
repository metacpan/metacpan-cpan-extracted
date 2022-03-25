package MsOffice::Word::Surgeon;
use 5.10.0;
use Moose;
use MooseX::StrictConstructor;
use Archive::Zip                          qw(AZ_OK);
use Encode                                qw(encode_utf8 decode_utf8);
use Carp                                  qw(croak);
use XML::LibXML;
use MsOffice::Word::Surgeon::Run;
use MsOffice::Word::Surgeon::Text;
use MsOffice::Word::Surgeon::Change;

use namespace::clean -except => 'meta';

our $VERSION = '1.08';

# constant integers to specify indentation modes -- see L<XML::LibXML>
use constant XML_NO_INDENT     => 0;
use constant XML_SIMPLE_INDENT => 1;

# name of the zip member that contains the main document body
use constant MAIN_DOCUMENT => 'word/document.xml';

has 'docx'      => (is => 'ro', isa => 'Str', required => 1);

has 'zip'       => (is => 'ro', isa => 'Archive::Zip', init_arg => undef,
                    builder => '_zip',   lazy => 1);

has 'contents'  => (is => 'rw', isa => 'Str',          init_arg => undef,
                    builder => 'original_contents', lazy => 1,
                    trigger => sub {shift->clear_runs});

has 'runs'      => (is => 'ro', isa => 'ArrayRef',     init_arg => undef,
                    builder => '_runs', lazy => 1, clearer => 'clear_runs');

has 'rev_id'    => (is => 'bare', isa => 'Num', default => 1, init_arg => undef);
   # used by the change() method for creating *::Change objects -- each instance
   # gets a fresh value

#======================================================================
# GLOBAL VARIABLES
#======================================================================

# Various regexes for removing uninteresting XML information
my %noise_reduction_regexes = (
  proof_checking        => qr(<w:(?:proofErr[^>]+|noProof/)>),
  revision_ids          => qr(\sw:rsid\w+="[^"]+"),
  complex_script_bold   => qr(<w:bCs/>),
  page_breaks           => qr(<w:lastRenderedPageBreak/>),
  language              => qr(<w:lang w:val="[^/>]+/>),
  empty_run_props       => qr(<w:rPr></w:rPr>),
  soft_hyphens          => qr(<w:softHyphen/>),
 );

my @noise_reduction_list = qw/proof_checking revision_ids
                              complex_script_bold page_breaks language 
                              empty_run_props soft_hyphens/;

#======================================================================
# BUILDING
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



#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _zip {
  my $self = shift;

  my $zip = Archive::Zip->new;
  $zip->read($self->{docx}) == AZ_OK
      or die "cannot unzip $self->{docx}";

  return $zip;
}

sub original_contents { # can also be called later, not only as lazy constructor
  my $self = shift;

  my $bytes    = $self->zip->contents(MAIN_DOCUMENT)
    or die "no contents for member ", MAIN_DOCUMENT();
  my $contents = decode_utf8($bytes);
  return $contents;
}


sub _runs {
  my $self = shift;

  state $run_regex = qr[
    <w:r>                             # opening tag for the run
    (?:<w:rPr>(.*?)</w:rPr>)?         # run properties -- capture in $1
    (.*?)                             # run contents -- capture in $2
    </w:r>                            # closing tag for the run
  ]x;

  state $txt_regex = qr[
    <w:t(?:\ xml:space="preserve")?>  # opening tag for the text contents
    (.*?)                             # text contents -- capture in $1
    </w:t>                            # closing tag for text
  ]x;


  # split XML content into run fragments
  my $contents      = $self->contents;
  my @run_fragments = split m[$run_regex], $contents, -1;
  my @runs;

  # build internal RUN objects
 RUN:
  while (my ($xml_before_run, $props, $run_contents) = splice @run_fragments, 0, 3) {
    $run_contents //= '';

    # split XML of this run into text fragmentsn
    my @txt_fragments = split m[$txt_regex], $run_contents, -1;
    my @texts;

    # build internal TEXT objects
  TXT:
    while (my ($xml_before_text, $txt_contents) = splice @txt_fragments, 0, 2) {
      next TXT if !$xml_before_text && ( !(defined $txt_contents) || $txt_contents eq '');
      push @texts, MsOffice::Word::Surgeon::Text->new(
        xml_before   => $xml_before_text // '',
        literal_text => $txt_contents    // '',
       );
    }

    # assemble TEXT objects into a RUN object
    next RUN if !$xml_before_run && !@texts;
    push @runs, MsOffice::Word::Surgeon::Run->new(
      xml_before  => $xml_before_run // '',
      props       => $props          // '',
      inner_texts => \@texts,
     );
  }

  return \@runs;
}



#======================================================================
# CONTENTS RESTITUTION
#======================================================================

sub indented_contents {
  my $self = shift;

  my $dom = XML::LibXML->load_xml(string => $self->contents);
  return $dom->toString(XML_SIMPLE_INDENT); # returned as bytes sequence, not a Perl string
}

sub plain_text {
  my $self = shift;

  # XML contents
  my $txt = $self->contents;

  # replace opening paragraph tags by newlines
  $txt =~ s/(<w:p[ >])/\n$1/g;

  # replace break tags by newlines
  $txt =~ s[<w:br/>][\n]g;

  # replace tab nodes by ASCII tabs
  $txt =~ s/<w:tab[^s][^>]*>/\t/g;

  # remove all remaining XML tags
  $txt =~ s/<[^>]+>//g;

  return $txt;
}

#======================================================================
# MODIFYING CONTENTS
#======================================================================

sub cleanup_XML {
  my ($self, @merge_args) = @_;

  $self->reduce_all_noises;
  my @names_of_ASK_fields = $self->unlink_fields;
  $self->suppress_bookmarks(@names_of_ASK_fields);
  $self->merge_runs(@merge_args);
}

sub noise_reduction_regex {
  my ($self, $regex_name) = @_;
  my $regex = $noise_reduction_regexes{$regex_name}
    or croak "->noise_reduction_regex('$regex_name') : unknown regex name";
  return $regex;
}

sub reduce_noise {
  my ($self, @noises) = @_;

  # gather regexes to apply, given either directly as regex refs, or as names of builtin regexes
  my @regexes = map {ref $_ eq 'Regexp' ? $_ : $self->noise_reduction_regex($_)} @noises;

  # get contents, apply all regexes, put back the modified contents.
  my $contents = $self->contents;
  no warnings 'uninitialized'; # for regexes without capture groups, $1 will be undef
  $contents =~ s/$_/$1/g foreach @regexes;
  $self->contents($contents);
}

sub reduce_all_noises {
  my $self = shift;

  $self->reduce_noise(@noise_reduction_list);
}

sub suppress_bookmarks {
  my ($self, @names_to_erase) = @_;

  # regex to find bookmarks markup
  state $bookmark_rx = qr{
     <w:bookmarkStart         # initial tag
       .+? w:id="(\d+)"       # 'id' attribute, bookmark identifier -- capture 1
       .+? w:name="([^"]+)"   # 'name' attribute                    -- capture 2
       .*? />                 # end of this tag
       (.*?)                  # bookmark contents (may be empty)    -- capture 3
     <w:bookmarkEnd           # ending tag
       \s+ w:id="\1"          # same 'id' attribute
       .*? />                 # end of this tag
    }sx;

  # closure to decide what to do with bookmark contents
  my %should_erase_contents = map {($_ => 1)} @names_to_erase;
  my $deal_with_bookmark_text = sub {
    my ($bookmark_name, $bookmark_contents) = @_;
    return $should_erase_contents{$bookmark_name} ? "" : $bookmark_contents;
  };

  # remove bookmarks markup
  my $contents = $self->contents;
  $contents    =~ s{$bookmark_rx}{$deal_with_bookmark_text->($2, $3)}eg;

  # re-inject the modified contents
  $self->contents($contents);
}

sub merge_runs {
  my ($self, %args) = @_;

  # check validity of received args
  state $is_valid_arg = {no_caps => 1};
  $is_valid_arg->{$_} or croak "merge_runs(): invalid arg: $_"
    foreach keys %args;

  my @new_runs;
  # loop over internal "run" objects
  foreach my $run (@{$self->runs}) {

    $run->remove_caps_property if $args{no_caps};

    # check if the current run can be merged with the previous one
    if (   !$run->xml_before                    # no other XML markup between the 2 runs
        && @new_runs                            # there was a previous run
        && $new_runs[-1]->props eq $run->props  # both runs have the same properties
       ) {
      # conditions are OK, so merge this run with the previous one
      $new_runs[-1]->merge($run);
    }
    else {
      # conditions not OK, just push this run without merging
      push @new_runs, $run;
    }
  }

  # reassemble the whole stuff and inject it as new contents
  $self->contents(join "", map {$_->as_xml} @new_runs);
}





sub unlink_fields {
  my $self = shift;

  # must find out what are the ASK fields before erasing the markup
  state $ask_field_rx = qr[<w:instrText[^>]+?>\s+ASK\s+(\w+)];
  my $contents            = $self->contents;
  my @names_of_ASK_fields = $contents =~ /$ask_field_rx/g;


  # regexes to remove field nodes and "field instruction" nodes
  state $field_instruction_txt_rx = qr[<w:instrText.*?</w:instrText>];
  state $field_boundary_rx        = qr[<w:fldChar
                                         (?:  [^>]*?/>                 # ignore all attributes until end of node ..
                                            |                          # .. or
                                              [^>]*?>.*?</w:fldChar>)  # .. ignore node content until closing tag
                                      ]x;   # field boundaries are encoded as  "begin" / "separate" / "end"
  state $simple_field_rx          = qr[</?w:fldSimple[^>]*>];

  $self->reduce_noise($field_instruction_txt_rx, $field_boundary_rx, $simple_field_rx);

  return @names_of_ASK_fields;
}


sub replace {
  my ($self, $pattern, $replacement_callback, %replacement_args) = @_;

  # cleanup the XML structure so that replacements work better
  my $keep_xml_as_is = delete $replacement_args{keep_xml_as_is};
  $self->cleanup_XML unless $keep_xml_as_is;

  # special option to avoid modying contents
  my $dont_overwrite_contents = delete $replacement_args{dont_overwrite_contents};

  # apply replacements and generate new XML
  my $xml = join "", map {
    $_->replace($pattern, $replacement_callback, %replacement_args)
  }  @{$self->runs};

  $self->contents($xml) unless $dont_overwrite_contents;

  return $xml;
}

#======================================================================
# DELEGATION TO SUBCLASSES
#======================================================================

sub change {
  my $self = shift;

  my $change = MsOffice::Word::Surgeon::Change->new(rev_id => $self->{rev_id}++, @_);
  return $change->as_xml;
}


#======================================================================
# SAVING THE FILE
#======================================================================


sub _update_contents_in_zip {
  my $self = shift;

  $self->zip->contents(MAIN_DOCUMENT, encode_utf8($self->contents));
}

sub overwrite {
  my $self = shift;

  $self->_update_contents_in_zip;
  $self->zip->overwrite;
}

sub save_as {
  my ($self, $docx) = @_;

  $self->_update_contents_in_zip;
  $self->zip->writeToFileNamed($docx) == AZ_OK
    or die "error writing zip archive to $docx";
}

1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon - tamper wit the guts of Microsoft docx documents

=head1 SYNOPSIS

  my $surgeon = MsOffice::Word::Surgeon->new(docx => $filename);

  # extract plain text
  my $text = $surgeon->plain_text;

  # anonymize
  my %alias = ('Claudio MONTEVERDI' => 'A_____', 'Heinrich SCHÜTZ' => 'B_____');
  my $pattern = join "|", keys %alias;
  my $replacement_callback = sub {
    my %args =  @_;
    my $replacement = $surgeon->change(to_delete  => $args{matched},
                                       to_insert  => $alias{$args{matched}},
                                       run        => $args{run},
                                       xml_before => $args{xml_before},
                                      );
    return $replacement;
  };
  $surgeon->replace(qr[$pattern], $replacement_callback);

  # save the result
  $surgeon->overwrite; # or ->save_as($new_filename);


=head1 DESCRIPTION

=head2 Purpose

This module supports a few operations for modifying or extracting text
from Microsoft Word documents in '.docx' format -- therefore the name
'surgeon'. Since a surgeon does not give life, there is no support for
creating fresh documents; if you have such needs, use one of the other
packages listed in the L<SEE ALSO> section.

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

pretty-printing the internal XML structure

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


=head2 Contents restitution

=head3 contents

Returns a Perl string with the current internal XML representation of the document
contents.

=head3 original_contents

Returns a Perl string with the XML representation of the
document contents, as it was in the ZIP archive before any
modification.

=head3 indented_contents

Returns an indented version of the XML contents, suitable for inspection in a text editor.
This is produced by L<XML::LibXML::Document/toString> and therefore is returned as an encoded
byte string, not a Perl string.

=head3 plain_text

Returns the text contents of the document, without any markup.
Paragraphs and breaks are converted to newlines, all other formatting instructions are ignored.


=head3 runs

Returns a list of L<MsOffice::Word::Surgeon::Run> objects. Each of
these objects holds an XML fragment; joining all fragments
restores the complete document.

  my $contents = join "", map {$_->as_xml} $self->runs;


=head2 Modifying contents

=head3 cleanup_XML

  $surgeon->cleanup_XML;

Apply several other methods for removing unnecessary nodes within the internal
XML. This method successively calls L</reduce_all_noises>, L</unlink_fields>,
L</suppress_bookmarks> and L</merge_runs>.


=head3 reduce_noise

  $surgeon->reduce_noise($regex1, $regex2, ...);

This method is used for removing unnecessary information in the XML
markup.  It applies the given list of regexes to the whole document,
suppressing matches.  The final result is put back into C<<
$self->contents >>. Regexes may be given either as C<< qr/.../ >>
references, or as names of builtin regexes (described below).  Regexes
are applied to the whole XML contents, not only to run nodes.


=head3 noise_reduction_regex

  my $regex = $surgeon->noise_reduction_regex($regex_name);

Returns the builtin regex corresponding to the given name.
Known regexes are :

  proof_checking       => qr(<w:(?:proofErr[^>]+|noProof/)>),
  revision_ids         => qr(\sw:rsid\w+="[^"]+"),
  complex_script_bold  => qr(<w:bCs/>),
  page_breaks          => qr(<w:lastRenderedPageBreak/>),
  language             => qr(<w:lang w:val="[^/>]+/>),
  empty_run_props      => qr(<w:rPr></w:rPr>),
  soft_hyphens         => qr(<w:softHyphen/>),

=head3 reduce_all_noises

  $surgeon->reduce_all_noises;

Applies all regexes from the previous method.

=head3 unlink_fields

  my @names_of_ASK_fields = $self->unlink_fields;

Removes all fields from the document, just leaving the current
value stored in each field. This is the equivalent of performing Ctrl-Shift-F9
on the whole document.

The return value is a list of names of ASK fields within the document.
Such names should then be passed to the L</suppress_bookmarks> method
(see below).


=head3 suppress_bookmarks

  $surgeon->suppress_bookmarks(@names_to_erase);

Removes bookmarks markup in the document. This is useful because
MsWord may silently insert bookmarks in unexpected places; therefore
some searches within the text may fail because of such bookmarks.

By default, this method only removes the bookmarks markup, leaving
intact the contents of the bookmark. However, when the name of a
bookmark belongs to the list C<< @names_to_erase >>, the contents
is also removed. Currently this is used for suppressing ASK fields,
because such fields contain a bookmark content that is never displayed by MsWord.



=head3 merge_runs

  $surgeon->merge_runs(no_caps => 1); # optional arg

Walks through all runs of text within the document, trying to merge
adjacent runs when possible (i.e. when both runs have the same
properties, and there is no other XML node inbetween).

This operation is a prerequisite before performing replace operations, because
documents edited in MsWord often have run boundaries across sentences or
even in the middle of words; so regex searches can only be successful if those
artificial boundaries have been removed.

If the argument C<< no_caps => 1 >> is present, the merge operation
will also convert runs with the C<w:caps> property, putting all letters
into uppercase and removing the property; this makes more merges possible.


=head3 replace

  $surgeon->replace($pattern, $replacement, %replacement_args);

Replaces all occurrences of C<$pattern> regex within the text nodes by the
given C<$replacement>. This is not exactly like a search-replace
operation performed within MsWord, because the search does not cross boundaries
of text nodes. In order to maximize the chances of successful replacements,
the L</cleanup_XML> method is automatically called before starting the operation.

The argument C<$pattern> can be either a string or a reference to a regular expression.
It should not contain any capturing parentheses, because that would perturb text
splitting operations.

The argument C<$replacement> can be either a fixed string, or a reference to
a callback subroutine that will be called for each match.


The C<< %replacement_args >> hash can be used to pass information to the callback
subroutine. That hash will be enriched with three entries :

=over

=item matched

The string that has been matched by C<$pattern>.

=item run

The run object in which this text resides.

=item xml_before

The XML fragment (possibly empty) found before the matched text .

=back

The callback subroutine may return either plain text or structured XML.
See the L</SYNOPSIS> for an example of a replacement callback.


The following special keys within C<< %replacement_args >> are interpreted by the 
C<replace()> method itself, and therefore are not passed to the callback subroutine :

=over

=item keep_xml_as_is

if true, no call is made to the L</cleanup_XML> method before performing the replacements

=item dont_overwrite_contents

if true, the internal XML contents is not modified in place; the new XML after performing
replacements is merely returned to the caller.

=back




=head3 change

  my $xml = $surgeon->change(
    to_delete   => $text_to_delete,
    to_insert   => $text_to_insert,
    author      => $author_string,
    date        => $date_string,
    run         => $run_object,
    xml_before  => $xml_string,
  );

This method generates markup for MsWord tracked changes. Users can
then manually review those changes within MsWord and accept or reject
them. This is best used in collaboration with the L</replace> method :
the replacement callback can call C<< $self->change(...) >> to
generate tracked change marks in the document.

All parameters are optional, but either C<to_delete> or C<to_insert> (or both) must
be present. The parameters are :

=over

=item to_delete

The string of text to delete (usually this will be the C<matched> argument
passed to the replacement callback).

=item to_insert

The string of new text to insert.

=item author

A short string that will be displayed by MsWord as the "author" of this tracked change.

=item date

A date (and optional time) in ISO format that will be displayed by
MsWord as the date of this tracked change. The current date and time
will be used by default.

=item run

A reference to the L<MsOffice::Word::Surgeon::Run> object surrounding
this tracked change. The formatting properties of that run will be
copied into the C<< <w:r> >> nodes of the deleted and inserted text fragments.


=item xml_before

An optional XML fragment to be inserted before the C<< <w:t> >> node
of the inserted text

=back

This method delegates to the
L<MsOffice::Word::Surgeon::Change> class for generating the
XML markup.




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
paragraphes, styles, fonts, inline shapes, etc.

The present module is much simpler but also much more limited : it was optimised
for dealing with the text contents and offers no support for presentation or
paging features. However, it has the rare advantage of providing an API for
regex substitutions within Word documents.

The L<MsOffice::Word::Template> module relies on the present module, together with
the L<Perl Template Toolkit|Template>, to implement a templating system for Word documents.


=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2019, 2020 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
