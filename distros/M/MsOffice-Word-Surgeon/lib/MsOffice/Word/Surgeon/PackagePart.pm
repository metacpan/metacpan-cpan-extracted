package MsOffice::Word::Surgeon::PackagePart;
use 5.24.0;
use Moose;
use MooseX::StrictConstructor;
use MsOffice::Word::Surgeon::Utils qw(maybe_preserve_spaces is_at_run_level);
use MsOffice::Word::Surgeon::Run;
use MsOffice::Word::Surgeon::Text;
use XML::LibXML;
use List::Util                     qw(max);
use Carp                           qw(croak carp);

# syntactic sugar for attributes
sub has_inner ($@) {my $attr = shift; has($attr => @_, lazy => 1, builder => "_$attr", init_arg => undef)}

# constant integers to specify indentation modes -- see L<XML::LibXML>
use constant XML_NO_INDENT     => 0;
use constant XML_SIMPLE_INDENT => 1;

use namespace::clean -except => 'meta';

our $VERSION = '2.03';


#======================================================================
# ATTRIBUTES
#======================================================================


# attributes passed to the constructor
has       'surgeon'        => (is => 'ro', isa => 'MsOffice::Word::Surgeon', required => 1, weak_ref => 1);
has       'part_name'      => (is => 'ro', isa => 'Str',                     required => 1);


# attributes constructed by the module -- not received through the constructor
has_inner 'contents'       => (is => 'rw', isa => 'Str',      trigger => \&_on_new_contents);
has_inner 'runs'           => (is => 'ro', isa => 'ArrayRef', clearer => 'clear_runs');
has_inner 'relationships'  => (is => 'ro', isa => 'ArrayRef');
has_inner 'images'         => (is => 'ro', isa => 'HashRef');

has 'contents_has_changed' => (is => 'bare', isa => 'Bool', default => 0);
has 'was_cleaned_up'       => (is => 'bare', isa => 'Bool', default => 0);

#======================================================================
# GLOBAL VARIABLES
#======================================================================

# Various regexes for removing uninteresting XML information
my %noise_reduction_regexes = (
  proof_checking         => qr(<w:(?:proofErr[^>]+|noProof/)>),
  revision_ids           => qr(\sw:rsid\w+="[^"]+"),
  complex_script_bold    => qr(<w:bCs/>),
  page_breaks            => qr(<w:lastRenderedPageBreak/>),
  language               => qr(<w:lang w:val="[^/>]+/>),
  empty_run_props        => qr(<w:rPr></w:rPr>),
  soft_hyphens           => qr(<w:softHyphen/>),
 );

my @noise_reduction_list = qw/proof_checking revision_ids
                              complex_script_bold page_breaks language
                              empty_run_props soft_hyphens/;

#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS AND TRIGGERS
#======================================================================


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


sub _relationships {
  my $self = shift;

  # xml that describes the relationships for this package part
  my $rel_xml = $self->_rels_xml;

  # parse the relationships and assemble into a sparse array indexed by relationship ids
  my @relationships;
  while ($rel_xml =~ m[<Relationship\s+(.*?)/>]g) {
    my %attrs = parse_attrs($1);
    $attrs{$_} or croak "missing attribute '$_' in <Relationship> node" for qw/Id Type Target/;
    ($attrs{num}        = $attrs{Id})  =~ s[^\D+][];
    ($attrs{short_type} = $attrs{Type}) =~ s[^.*/][];
    $relationships[$attrs{num}] = \%attrs;
  }

  return \@relationships;
}


sub _images {
  my $self = shift;

  # get relationship ids associated with images
  my %rel_image  = map  {$_->{Id} => $_->{Target}}
                   grep {$_ && $_->{short_type} eq 'image'}
                   $self->relationships->@*;

  # get titles and relationship ids of images found within the part contents
  my %image;
  my @drawings = $self->contents =~ m[<w:drawing>(.*?)</w:drawing>]g;
 DRAWING:
  foreach my $drawing (@drawings) {
    if ($drawing =~ m[<wp:docPr \s+ (.*?) />
                      .*?
                      <a:blip \s+ r:embed="(\w+)"]x) {
      my ($lst_attrs, $rId) = ($1, $2);
      my %attrs = parse_attrs($lst_attrs);
      my $img_id = $attrs{title} || $attrs{descr}
        or next DRAWING;

      $image{$img_id} = "word/$rel_image{$rId}"
        or die "couldn't find image for relationship '$rId' associated with image '$img_id'";
        # NOTE: targets in the rels XML miss the "word/" prefix, I don't know why.
    }
  }

  return \%image;
}


sub _contents {shift->original_contents}

sub _on_new_contents {
  my $self = shift;

  $self->clear_runs;
  $self->{contents_has_changed} = 1;
  $self->{was_cleaned_up}       = 0;
}

#======================================================================
# METHODS
#======================================================================


sub  _rels_xml {
  my ($self, $new_xml) = @_;
  my $rels_name = sprintf "word/_rels/%s.xml.rels", $self->part_name;
  return $self->surgeon->xml_member($rels_name, $new_xml);
}


sub zip_member_name {
  my $self = shift;
  return sprintf "word/%s.xml", $self->part_name;
}


sub original_contents {
  my $self = shift;

  return $self->surgeon->xml_member($self->zip_member_name);
}


sub image {
  my ($self, $title, $new_image_content) = @_;

  # name of the image file within the zip
  my $zip_member_name = $self->images->{$title}
                     || ($title =~ /^\d+$/ ? "word/media/image$title.png"
                                           : die "couldn't find image '$title'");

  # delegate to Archive::Zip::contents
  return $self->surgeon->zip->contents($zip_member_name, $new_image_content);
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

  # avoid doing it twice
  return if $self->{was_cleaned_up};

  # do the cleanup
  $self->reduce_all_noises;
  my $names_of_ASK_fields = $self->unlink_fields;
  $self->suppress_bookmarks(@$names_of_ASK_fields);
  $self->merge_runs(@merge_args);

  # remember it was done
  $self->{was_cleaned_up} = 1;
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

  # closure to decide what to do with bookmark contents
  my %should_erase_contents = map {($_ => 1)} @names_to_erase;
  my $deal_with_bookmark_text = sub {
    my ($bookmark_name, $bookmark_contents) = @_;
    return $should_erase_contents{$bookmark_name} ? "" : $bookmark_contents;
  };

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
  my @invalid_args    = grep {!$is_valid_arg->{$_}} keys %args;
  croak "merge_runs(): invalid arg(s): " . join ", ", @invalid_args if @invalid_args;

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

  # apply the regexes
  $self->reduce_noise($field_instruction_txt_rx, $field_boundary_rx, $simple_field_rx);

  return \@names_of_ASK_fields;
}


sub replace {
  my ($self, $pattern, $replacement_callback, %replacement_args) = @_;

  # shared initial string for error messages
  my $error_msg = '->replace($pattern, $callback, %args)';

  # default value for arg 'cleanup_XML', possibly from deprecated arg 'keep_xml_as_is'
  if (delete $replacement_args{keep_xml_as_is}) {
    not exists $replacement_args{cleanup_XML}
      or croak "$error_msg: deprecated arg 'keep_xml_as_is' conflicts with arg 'cleanup_XML'";
    carp "$error_msg: arg 'keep_xml_as_is' is deprecated, use 'cleanup_XML' instead";
    $replacement_args{cleanup_XML} = 0;
  }
  else {
    $replacement_args{cleanup_XML} //= 1; # default
  }

  # cleanup the XML structure so that replacements work better
  if (my $cleanup_args = $replacement_args{cleanup_XML}) {
    $cleanup_args = {} if ! ref $cleanup_args;
    ref $cleanup_args eq 'HASH'
      or croak "$error_msg: arg 'cleanup_XML' should be a hashref";
    $self->cleanup_XML(%$cleanup_args);
  }

  # check for presences of a special option to avoid modying contents
  my $dont_overwrite_contents = delete $replacement_args{dont_overwrite_contents};

  # apply replacements and generate new XML
  my $xml = join "",
            map {$_->replace($pattern, $replacement_callback, %replacement_args)} $self->runs->@*;

  # overwrite previous contents
  $self->contents($xml) unless $dont_overwrite_contents;

  return $xml;
}


sub _update_contents_in_zip { # called for each part before saving the zip file
  my $self = shift;

  $self->surgeon->xml_member($self->zip_member_name, $self->contents)
    if $self->{contents_has_changed};
}


sub replace_image {
  my ($self, $image_title, $image_PNG_content) = @_;

  my $member_name = $self->images->{$image_title}
    or die "could not find an image with title: $image_title";
  $self->surgeon->zip->contents($member_name, $image_PNG_content);
}



sub add_image {
  my ($self, $image_PNG_content) = @_;

  # compute a fresh image number and a fresh relationship id
  my @image_members = $self->surgeon->zip->membersMatching(qr[^word/media/image]);
  my @image_nums    = map {$_->fileName =~ /(\d+)/} @image_members;
  my $last_img_num  = max @image_nums // 0;
  my $target        = sprintf "media/image%d.png", $last_img_num + 1;
  my $last_rId_num  = $self->relationships->$#*;
  my $rId           = sprintf "rId%d", $last_rId_num + 1;

  # assemble XML for the new relationship
  my $type          = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image";
  my $new_rel_xml   = qq{<Relationship Id="$rId" Type="$type" Target="$target"/>};

  # update the rels member
  my $xml = $self->_rels_xml;
  $xml =~ s[</Relationships>][$new_rel_xml</Relationships>];
  $self->_rels_xml($xml);

  # add the image as a new member into the archive
  my $member_name = "word/$target";
  $self->surgeon->zip->addString(\$image_PNG_content, $member_name);

  # update the global content_types if it doesn't include PNG
  my $ct = $self->surgeon->_content_types;
  if ($ct !~ /Extension="png"/) {
    $ct =~ s[(<Types[^>]+>)][$1<Default Extension="png" ContentType="image/png"/>];
    $self->surgeon->_content_types($ct);
  }

  # return the relationship id
  return $rId;
}



#======================================================================
# UTILITY FUNCTIONS
#======================================================================


sub parse_attrs {  # cheap parsing of attribute lists in an XML node
  my ($lst_attrs) = @_;

  state $attr_pair_regex = qr[
     ([^=\s"'&<>]+)     # attribute name
     \h* = \h*          # Eq
     (?:                # attribute value
        " ([^<"]*) "    # .. enclosed in double quotes
       |
        ' ([^<']*) '    # .. or enclosed in single quotes
     )
   ]x;

  state $entity       = {quot => '"', amp => '&', 'lt' => '<', gt => '>'};
  state $entity_names = join "|", keys %$entity;

  my %attr;
  while ($lst_attrs =~ /$attr_pair_regex/g) {
    my ($name, $val) = ($1, $2 // $3);
    $val =~ s/&(entity_names);/$entity->{$1}/eg;
    $attr{$name} = $val;
  }

  return %attr;
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Surgeon::PackagePart - Operations on a single part within the ZIP package of a docx document

=head1 SYNOPSIS

  my $part = $surgeon->document;
  print $part->plain_text;
  $part->replace(qr[$pattern], $replacement_callback);
  $part->replace_image($image_alt_text, $image_PNG_content);


=head1 DESCRIPTION

This class is part of L<MsOffice::Word::Surgeon>; it encapsulates operations for a single
I<package part> within the ZIP package of a C<.docx> document.
It is mostly used for the I<document> part, that contains the XML representation of the
main document body. However, other parts such as headers, footers, footnotes, etc. have the
same internal representation and therefore the same operations can be invoked.


=head1 METHODS

=head2 new

  my $run = MsOffice::Word::Surgeon::PackagePart->new(
    surgeon   => $surgeon,
    part_name => $name,
  );

Constructor for a new part object. This is called internally from
L<MsOffice::Word::Surgeon>; it is not meant to be called directly
by clients. 

=head3 Constructor arguments


=over

=item surgeon

a weak reference to the main surgeon object 

=item part_name

ZIP member name of this part

=back

=head3 Other attributes

Other attributes, which are not passed through the constructor but are generated lazily on demand, are :

=over

=item contents

the XML contents of this part

=item runs

a decomposition of the XML contents into a collection of
L<MsOffice::Word::Surgeon::Run> objects.

=item relationships

an arrayref of Office relationships associated with this part. This information comes from
a C<.rels> member in the ZIP archive, named after the name of the package part.
Array indices correspond to relationship numbers. Array values are hashrefs with
keys

=over

=item Id

the full relationship id

=item num

the numeric part of C<rId>

=item Type

the full reference to the XML schema for this relationship

=item short_type

only the last word of the type, e.g. 'image', 'style', etc.

=item Target

designation of the target within the ZIP file. The prefix 'word/' must be
added for having a complete Zip member name.

=back



=item images

a hashref of images within this package part. Keys of the hash are image I<alternative texts>.
If present, the alternative I<title> will be prefered; otherwise the alternative I<description> will be taken
(note : the I<title> field was displayed in Office 2013 and 2016, but more recent versions only display
the I<description> field -- see
L<https://support.microsoft.com/en-us/office/add-alternative-text-to-a-shape-picture-chart-smartart-graphic-or-other-object-44989b2a-903c-4d9a-b742-6a75b451c669|MsOffice documentation>).

Images without alternative text will not be accessible through the current Perl module.

Values of the hash are zip member names for the corresponding
image representations in C<.png> format.


=back


=head2 Contents restitution

=head3 contents

Returns a Perl string with the current internal XML representation of the part
contents.

=head3 original_contents

Returns a Perl string with the XML representation of the
part contents, as it was in the ZIP archive before any
modification.

=head3 indented_contents

Returns an indented version of the XML contents, suitable for inspection in a text editor.
This is produced by L<XML::LibXML::Document/toString> and therefore is returned as an encoded
byte string, not a Perl string.

=head3 plain_text

Returns the text contents of the part, without any markup.
Paragraphs and breaks are converted to newlines, all other formatting instructions are ignored.


=head3 runs

Returns a list of L<MsOffice::Word::Surgeon::Run> objects. Each of
these objects holds an XML fragment; joining all fragments
restores the complete document.

  my $contents = join "", map {$_->as_xml} $self->runs;


=head2 Modifying contents


=head3 cleanup_XML

  $part->cleanup_XML(%args);

Apply several other methods for removing unnecessary nodes within the internal
XML. This method successively calls L</reduce_all_noises>, L</unlink_fields>,
L</suppress_bookmarks> and L</merge_runs>.

Currently there is only one legal arg :

=over

=item C<no_caps>

If true, the method L<MsOffice::Word::Surgeon::Run/remove_caps_property> is automatically
called for each run object. As a result, all texts within runs with the C<caps> property are automatically
converted to uppercase.

=back



=head3 reduce_noise

  $part->reduce_noise($regex1, $regex2, ...);

This method is used for removing unnecessary information in the XML
markup.  It applies the given list of regexes to the whole document,
suppressing matches.  The final result is put back into 
C<< $self->contents >>. Regexes may be given either as C<< qr/.../ >>
references, or as names of builtin regexes (described below).  Regexes
are applied to the whole XML contents, not only to run nodes.


=head3 noise_reduction_regex

  my $regex = $part->noise_reduction_regex($regex_name);

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

  $part->reduce_all_noises;

Applies all regexes from the previous method.

=head3 unlink_fields

  my $names_of_ASK_fields = $part->unlink_fields;

Removes all fields from the part, just leaving the current
value stored in each field. This is the equivalent of performing Ctrl-Shift-F9
on the whole document.

The return value is an arrayref to a  list of names of ASK fields within the document.
Such names should then be passed to the L</suppress_bookmarks> method
(see below).


=head3 suppress_bookmarks

  $part->suppress_bookmarks(@names_to_erase);

Removes bookmarks markup in the part. This is useful because
MsWord may silently insert bookmarks in unexpected places; therefore
some searches within the text may fail because of such bookmarks.

By default, this method only removes the bookmarks markup, leaving
intact the contents of the bookmark. However, when the name of a
bookmark belongs to the list C<< @names_to_erase >>, the contents
is also removed. Currently this is used for suppressing ASK fields,
because such fields contain a bookmark content that is never displayed by MsWord.



=head3 merge_runs

  $part->merge_runs(no_caps => 1); # optional arg

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

  $part->replace($pattern, $replacement, %replacement_args);

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
See L<MsOffice::Word::Surgeon::Run/SYNOPSIS> for an example of a replacement callback.

The following special keys within C<< %replacement_args >> are interpreted by the 
C<replace()> method itself, and therefore are not passed to the callback subroutine :

=over

=item keep_xml_as_is

if true, no call is made to the L</cleanup_XML> method before performing the replacements

=item dont_overwrite_contents

if true, the internal XML contents is not modified in place; the new XML after performing
replacements is merely returned to the caller.

=item cleanup_args

the argument should be an arrayref and will be passed to the L</cleanup_XML> method. This
is typically used as 

  $part->replace($pattern, $replacement, cleanup_args => [no_caps => 1]);

=back


=head3 replace_image

  $part->replace_image($image_alt_text, $image_PNG_content);

Replaces an existing PNG image by a new image. All features of the old image will
be preserved (size, positioning, border, etc.) -- only the image itself will be
replaced. The C<$image_alt_text> must correspond to the I<alternative text> set in Word
for this image.

This operation replaces a ZIP member within the C<.docx> file. If several XML
nodes refer to the I<same> ZIP member, i.e. if the same image is displayed at several
locations, the new image will appear at all locations, even if they do not have the
same alternative text -- unfortunately this module currently has no facility for
duplicating an existing image into separate instances. So if your intent is to only replace
one image, your original document should contain several distinct images, coming from
several distinct C<.PNG> file copies.


=head3 add_image

  my $rId = $part->add_image($image_PNG_content);

Stores the given PNG image within the ZIP file, adds it as a relationship to the
current part, and returns the relationship id. This operation is not sufficient
to  make the image visible in Word : it just stores the image, but you still
have to insert a proper C<drawing> node in the contents XML, using the C<$rId>.
Future versions of this module may offer helper methods for that purpose;
currently it must be done by hand.


=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2019-2023 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



