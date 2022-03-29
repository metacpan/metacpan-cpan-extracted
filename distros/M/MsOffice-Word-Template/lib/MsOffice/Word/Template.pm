package MsOffice::Word::Template;
use Moose;
use MooseX::StrictConstructor;
use Carp                           qw(croak);
use HTML::Entities                 qw(decode_entities);
use MsOffice::Word::Surgeon 1.08;

use namespace::clean -except => 'meta';

our $VERSION = '1.02';

# attributes for interacting with MsWord
has 'surgeon'       => (is => 'ro',   isa => 'MsOffice::Word::Surgeon', required => 1);
has 'data_color'    => (is => 'ro',   isa => 'Str',                     default  => "yellow");
has 'control_color' => (is => 'ro',   isa => 'Str',                     default  => "green");
# see also BUILDARGS: the "docx" arg will be translated into "surgeon"

# attributes for interacting with the chosen template engine
# Filled by default with values for the Template Toolkit (a.k.a TT2)
has 'start_tag'     => (is => 'ro',   isa => 'Str',                     default  => "[% ");
has 'end_tag'       => (is => 'ro',   isa => 'Str',                     default  => " %]");
has 'engine'        => (is => 'ro',   isa => 'CodeRef',                 default  => sub {\&TT2_engine});
has 'engine_args'   => (is => 'ro',   isa => 'ArrayRef',                default  => sub {[]});

# attributes constructed by the module -- not received through the constructor
has 'template_text' => (is => 'bare', isa => 'Str',                     init_arg => undef);
has 'engine_stash'  => (is => 'bare', isa => 'HashRef',                 init_arg => undef,
                                                                        clearer  => 'clear_stash');

my $XML_COMMENT_FOR_MARKING_DIRECTIVES = '<!--TEMPLATE_DIRECTIVE_ABOVE-->';



#======================================================================
# BUILDING THE TEMPLATE
#======================================================================


# syntactic sugar for supporting ->new($surgeon) instead of ->new(surgeon => $surgeon)
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # if there is a unique arg without any keyword ...
  if ( @_ == 1) {

    # if the unique arg is an instance of Surgeon, it's the "surgeon" parameter
    unshift @_, 'surgeon' if $_[0]->isa('MsOffice::Word::Surgeon');

    # if the unique arg is a string, it's the "docx" parameter
    unshift @_, 'docx' if $_[0] && !ref $_[0];
  }

  # translate the "docx" parameter into a "surgeon" parameter
  my %args = @_;
  if (my $docx = delete $args{docx}) {
    $args{surgeon} = MsOffice::Word::Surgeon->new(docx => $docx);
  }

  # now call the regular Moose method
  return $class->$orig(%args);
};


sub BUILD {
  my ($self) = @_;

  # assemble the template text and store it into the bare attribute
  $self->{template_text} = $self->build_template_text;
}


sub build_template_text {
  my ($self) = @_;

  # start and end character sequences for a template fragment
  my ($rx_start, $rx_end) = map quotemeta, $self->start_tag, $self->end_tag;

  # Regexes for extracting template directives within the XML.
  # Such directives are identified through a specific XML comment -- this comment is
  # inserted by method "template_fragment_for_run()" below.
  # The (*SKIP) instructions are used to avoid backtracking after a
  # closing tag for the subexpression has been found. Otherwise the
  # .*? inside could possibly match across boundaries of the current
  # XML node, we don't want that.

  # regex for matching directives to be treated outside the text flow.
  my $regex_outside_text_flow = qr{
      <w:r\b           [^>]*>                  # start run node
        (?: <w:rPr> .*? </w:rPr>   (*SKIP) )?  # optional run properties
        <w:t\b         [^>]*>                  # start text node
          ($rx_start .*? $rx_end)  (*SKIP)     # template directive
          $XML_COMMENT_FOR_MARKING_DIRECTIVES  # specific XML comment
        </w:t>                                 # close text node
      </w:r>                                   # close run node
   }sx;

  # regex for matching paragraphs that contain only a directive
  my $regex_paragraph = qr{
    <w:p\b             [^>]*>                  # start paragraph node
      (?: <w:pPr> .*? </w:pPr>     (*SKIP) )?  # optional paragraph properties
      $regex_outside_text_flow
    </w:p>                                     # close paragraph node
   }sx;

  # regex for matching table rows that contain only a directive in the first cell
  my $regex_row = qr{
    <w:tr\b            [^>]*>                  # start row node
      <w:tc\b          [^>]*>                  # start cell node
         (?:<w:tcPr> .*? </w:tcPr> (*SKIP) )?  # cell properties
         $regex_paragraph                      # paragraph in cell
      </w:tc>                                  # close cell node
      (?:<w:tc> .*? </w:tc>        (*SKIP) )*  # ignore other cells on the same row
    </w:tr>                                    # close row node
   }sx;

  # assemble template fragments from all runs in the document into a global template text
  $self->surgeon->cleanup_XML;
  my @template_fragments = map {$self->template_fragment_for_run($_)}  @{$self->surgeon->runs};
  my $template_text      = join "", @template_fragments;

  # remove markup around directives, successively for table rows, for paragraphs, and finally
  # for remaining directives embedded within text runs.
  $template_text =~ s/$_/$1/g for $regex_row, $regex_paragraph, $regex_outside_text_flow;

  return $template_text;
}


sub template_fragment_for_run { # given an instance of Surgeon::Run, build a template fragment
  my ($self, $run) = @_;

  my $props         = $run->props;
  my $data_color    = $self->data_color;
  my $control_color = $self->control_color;

  # if this run is highlighted in yellow or green, it must be translated into a template directive
  if ($props =~ s{<w:highlight w:val="($data_color|$control_color)"/>}{}) {
    my $color       = $1;
    my $xml         = $run->xml_before;

    my $inner_texts = $run->inner_texts;
    if (@$inner_texts) {
      $xml .= "<w:r>";                                                # opening XML tag for run node
      $xml .= "<w:rPr>" . $props . "</w:rPr>" if $props;              # optional run properties
      $xml .= "<w:t>";                                                # opening XML tag for text node
      $xml .= $self->start_tag;                                       # start a template directive
      foreach my $inner_text (@$inner_texts) {                        # loop over text nodes
        my $txt = decode_entities($inner_text->literal_text);         # just take inner literal text
        $xml .= $txt . "\n";
        # NOTE : adding "\n" because the template parser may need them for identifying end of comments
      }

      $xml .= $self->end_tag;                                         # end of template directive
      $xml .= $XML_COMMENT_FOR_MARKING_DIRECTIVES
                                         if $color eq $control_color; # XML comment for marking
      $xml .= "</w:t>";                                               # closing XML tag for text node
      $xml .= "</w:r>";                                               # closing XML tag for run node
    }

    return $xml;
  }

  # otherwise this run is just regular MsWord content
  else {
    return $run->as_xml;
  }
}



#======================================================================
# PROCESSING THE TEMPLATE
#======================================================================

sub process {
  my ($self, $vars) = @_;

  # process the template to generate new XML
  my $engine  = $self->engine;
  my $new_XML = $self->$engine($vars);

  # insert the generated output into a new MsWord document; other zip members
  # are cloned from the original template
  my $new_doc = $self->surgeon->meta->clone_object($self->surgeon);
  $new_doc->contents($new_XML);

  return $new_doc;
}


#======================================================================
# DEFAULT ENGINE : TEMPLATE TOOLKIT, a.k.a. TT2
#======================================================================

# arbitrary value for the first bookmark id. 100 should most often be above other
# bookmarks generated by Word itself. TODO : would be better to find the highest
# id number really used in the template
my $first_bookmark_id = 100;

# precompiled blocks as facilities to be used within templates
my %precompiled_blocks = (

  # a wrapper block for inserting a Word bookmark
  bookmark => sub {
    my $context     = shift;
    my $stash       = $context->stash;

    # assemble xml markup
    my $bookmark_id = $stash->get('global.bookmark_id') || $first_bookmark_id;
    my $name        = fix_bookmark_name($stash->get('name') || 'anonymous_bookmark');

    my $xml         = qq{<w:bookmarkStart w:id="$bookmark_id" w:name="$name"/>}
                    . $stash->get('content') # content of the wrapper
                    . qq{<w:bookmarkEnd w:id="$bookmark_id"/>};

    # next bookmark will need a fresh id
    $stash->set('global.bookmark_id', $bookmark_id+1);

    return $xml;
  },

  # a wrapper block for linking to a bookmark
  link_to_bookmark => sub {
    my $context = shift;
    my $stash   = $context->stash;

    # assemble xml markup
    my $name    = fix_bookmark_name($stash->get('name') || 'anonymous_bookmark');
    my $content = $stash->get('content');
    my $tooltip = $stash->get('tooltip');
    if ($tooltip) {
      # TODO: escap quotes
      $tooltip = qq{ w:tooltip="$tooltip"};
    }
    my $xml  = qq{<w:hyperlink w:anchor="$name"$tooltip>$content</w:hyperlink>};

    return $xml;
  },

  # a block for generating a Word field. Can also be used as wrapper.
  field => sub {
    my $context = shift;
    my $stash   = $context->stash;
    my $code    = $stash->get('code');         # field code, including possible flags
    my $text    = $stash->get('content');      # initial text content (before updating the field)

    my $xml     = qq{<w:r><w:fldChar w:fldCharType="begin"/></w:r>}
                . qq{<w:r><w:instrText xml:space="preserve"> $code </w:instrText></w:r>};
    $xml       .= qq{<w:r><w:fldChar w:fldCharType="separate"/></w:r>$text} if $text;
    $xml       .= qq{<w:r><w:fldChar w:fldCharType="end"/></w:r>};

    return $xml;
  },

);




sub TT2_engine {
  my ($self, $vars) = @_;

  require Template::AutoFilter; # a subclass of Template that adds automatic html filtering


  # assemble args to be passed to the constructor
  my %TT2_args = @{$self->engine_args};
  $TT2_args{BLOCKS}{$_} //= $precompiled_blocks{$_} for keys %precompiled_blocks;


  # at the first invocation, create a TT2 compiled template and store it in the stash.
  # Further invocations just reuse the TT2 object in stash.
  my $stash                     = $self->{engine_stash} //= {};
  $stash->{TT2}               //= Template::AutoFilter->new(\%TT2_args);
  $stash->{compiled_template} //= $stash->{TT2}->template(\$self->{template_text});

  # generate new XML by invoking the template on $vars
  my $new_XML = $stash->{TT2}->context->process($stash->{compiled_template}, $vars);

  return $new_XML;
}


#======================================================================
# UTILITY ROUTINES (not methods)
#======================================================================


sub fix_bookmark_name {
  my $name = shift;

  # see https://stackoverflow.com/questions/852922/what-are-the-limitations-for-bookmark-names-in-microsoft-word

  $name =~ s/[^\w_]+/_/g;                              # only digits, letters or underscores
  $name =~ s/^(\d)/_$1/;                               # cannot start with a digit
  $name = substr($name, 0, 40) if length($name) > 40;  # max 40 characters long

  return $name;
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Template - generate Microsoft Word documents from Word templates

=head1 SYNOPSIS

  my $template = MsOffice::Word::Template->new($filename);
  my $new_doc  = $template->process(\%data);
  $new_doc->save_as($path_for_new_doc);

=head1 DESCRIPTION

=head2 Purpose

This module treats a Microsoft Word document as a template for generating other documents. The idea is
similar to the "mail merge" functionality in Word, but with much richer possibilities, because the
whole power of a Perl templating engine can be exploited, for example for

=over

=item *

dealing with complex, nested datastructures

=item *

using control directives for loops, conditionals, subroutines, etc.

=back


Template authors just have to use the highlighing function in MsWord to
mark the templating directives :

=over

=item *

fragments highlighted in B<yelllow> are interpreted as I<data>
directives, i.e. the template result will be inserted at that point in
the document, keeping the current formatting properties (bold, italic,
font, etc.).

=item *

fragments highlighted in B<green> are interpreted as I<control>
directives that do not directly generate content, like loops, conditionals,
etc. Paragraphs or table rows around such directives are dismissed,
in order to avoid empty paragraphs or empty rows in the resulting document.

=back

The syntax of data and control directives depends on the backend
templating engine.  The default engine is the L<Perl Template Toolkit|Template>;
other engines can be specified through parameters
to the L</new> method -- see the L</TEMPLATE ENGINE> section below.


=head2 Status

This first release is a proof of concept. Some simple templates have
been successfully tried; however it is likely that a number of
improvements will have to be made before this system can be used at
large scale in production.  If you use this module, please keep me
informed of your difficulties, tricks, suggestions, etc.


=head1 METHODS

=head2 new

  my $template = MsOffice::Word::Template->new($docx);
  # or : my $template = MsOffice::Word::Template->new($surgeon);   # an instance of MsOffice::Word::Surgeon
  # or : my $template = MsOffice::Word::Template->new(docx => $docx, %options);

In its simplest form, the constructor takes a single argument which
is either a string (path to a F<docx> document), or an instance of
L<MsOffice::Word::Surgeon>. Otherwise the constructor takes a list of named parameters,
which can be


=over

=item docx

path to a MsWord document in F<docx> format. This will automatically create
an instance of L<MsOffice::Word::Surgeon> and pass it to the constructor
through the C<surgeon> keyword.

=item surgeon

an instance of L<MsOffice::Word::Surgeon>. This is a mandatory parameter, either
directly through the C<surgeon> keyword, or indirectly through the C<docx> keyword.

=item data_color

the Word highlight color for marking data directives (default : yellow)

=item control_color

the Word highlight color for marking control directives (default : green).
Such directives should produce no content. They are treated outside of the regular text flow.

=back

In addition to the attributes above, other attributes can be passed to the
constructor for specifying a templating engine different from the 
default L<Perl Template Toolkit|Template>.
These are described in section L</TEMPLATE ENGINE> below.


=head2 process

  my $new_doc = $template->process(\%data);
  $new_doc->save_as($path_for_new_doc);

Process the template on a given data tree, and return a new document
(actually, a new instance of L<MsOffice::Word::Surgeon>).
That document can then be saved  using L<MsOffice::Word::Surgeon/save_as>.


=head1 AUTHORING TEMPLATES

A template is just a regular Word document, in which the highlighted
fragments represent templating directives.

The data directives, i.e. the "holes" to be filled must be highlighted
in B<yellow>. Such zones must contain the names of variables to fill the
holes. If the template engine supports it, names of variables can be paths
into a complex datastructure, with dots separating the levels, like
C<foo.3.bar.-1> -- see L<Template::Manual::Directive/GET> and
L<Template::Manual::Variables> if you are using the Template Toolkit.

Control directives like C<IF>, C<FOREACH>, etc. must be highlighted in
B<green>. When seeing a green zone, the system will remove XML markup for
the surrounding text and run nodes. If the directive is the only content
of the paragraph, then the paragraph node is also removed. If this
occurs within the first cell of a table row, the markup for that row is also
removed. This mechanism ensures that the final result will not contain
empty paragraphs or empty rows at places corresponding to control directives.

In consequence of this distinction between yellow and green
highlights, templating zones cannot mix data directives with control
directives : a data directive within a green zone would generate output
outside of the regular XML flow (paragraph nodes, run nodes and text
nodes), and therefore MsWord would generate an error when trying to
open such content. There is a workaround, however : data directives
within a green zone will work if they I<also generate the appropriate markup>
for paragraph nodes, run nodes and text nodes; but in that case you must
also apply the "none" filter from L<Template::AutoFilter> so that
angle brackets in XML markup do not get translated into HTML entities.


=head1 TEMPLATE ENGINE

This module invokes a backend I<templating engine> for interpreting the
template directives. In order to use an engine different from the default
L<Template Toolkit|Template>, you must supply the following parameters
to the L</new> method :

=over

=item start_tag

The string for identifying the start of a template directive

=item end_tag

The string for identifying the end of a template directive

=item engine

A reference to a method that will perform the templating operation (explained below)

=item engine_args

An optional list of parameters that may be used by the engine

=back

Given a datatree in C<$vars>, the engine will be called as :

  my $engine  = $self->engine;
  my $new_XML = $self->$engine($vars);

It is up to the engine method to exploit C<< $self->engine_args >> if needed.

If the engine is called repetively, it may need to store some data to be
persistent between two calls, like for example a compiled version of the
parsed template. To this end, there is an internal hashref attribute
called C<engine_stash>. If necessary the stash can be cleared through
the C<clear_stash> method.

Here is an example using L<Template::Mustache> :

  my $template = MsOffice::Word::Template->new(
    docx      => $template_file,
    start_tag => "{{",
    end_tag   => "}}",
    engine    => sub {
      my ($self, $vars) = @_;

      # at the first invocation, create a Mustache compiled template and store it in the stash.
      # Further invocations will just reuse the object in stash.
      my $stash            = $self->{engine_stash} //= {};
      $stash->{mustache} //= Template::Mustache->new(
        template => $self->{template_text},
        @{$self->engine_args},   # for ex. partials, partial_path, context
                                 # -- see L<Template::Mustache> documentation
       );

      # generate new XML by invoking the template on $vars
      my $new_XML = $stash->{mustache}->render($vars);

      return $new_XML;
      },
   );

The engine must make sure that ampersand characters and angle brackets
are automatically replaced by the corresponding HTML entities
(otherwise the resulting XML would be incorrect and could not be
opened by Microsoft Word).  The Mustache engine does this
automatically.  The Template Toolkit would normally require to
explicitly add an C<html> filter at each directive :

  [% foo.bar | html %]

but thanks to the L<Template::AutoFilter>
module, this is performed automatically.


=head1 AUTHORING NOTES SPECIFIC TO THE TEMPLATE TOOLKIT

This chapter just gives a few hints for authoring Word templates with the
Template Toolkit.

The examples below use [[double square brackets]] to indicate
segments that should be highlighted in B<green> within the Word template.


=head2 Bookmarks

The template processor is instantiated with a predefined wrapper named C<bookmark>
for generating Word bookmarks. Here is an example:

  Here is a paragraph with [[WRAPPER bookmark name="my_bookmark"]]bookmarked text[[END]].

The C<name> argument is automatically truncated to 40 characters, and non-alphanumeric
characters are replaced by underscores, in order to comply with the limitations imposed by Word
for bookmark names.

=head2 Internal hyperlinks

Similarly, there is a predefined wrapper named C<link_to_bookmark> for generating
hyperlinks to bookmarks. Here is an example:

  Click [[WRAPPER link_to_bookmark name="my_bookmark" tooltip="tip top"]]here[[END]].

The C<tooltip> argument is optional.

=head2 Word fields

A predefined block C<field> generates XML markup for Word fields, like for example :

  Today is [[PROCESS field code="DATE \\@ \"h:mm am/pm, dddd, MMMM d\""]]

Beware that quotes or backslashes must be escaped so that the Template Toolkit parser
does not interpret these characters.

The list of Word field codes is documented at 
L<https://support.microsoft.com/en-us/office/list-of-field-codes-in-word-1ad6d91a-55a7-4a8d-b535-cf7888659a51>.

When used as a wrapper, the C<field> block generates a Word field with alternative
text content, displayed before the field gets updated. For example :

  [[WRAPPER field code="TOC \o \"1-3\" \h \z \u"]]Table of contents – press F9 to update[[END]]


=head1 TROUBLESHOOTING

If the document generated by this module cannot open in Word, it is probably because the XML
generated by your template is not equilibrated and therefore not valid.
For example a template like this :

  This paragraph [[ IF condition ]]
     may have problems
  [[END]]

is likely to generate incorrect XML, because the IF statement starts in the middle
of a paragraph and closes at a different paragraph -- therefore when the I<condition>
evaluates to false, the XML tag for closing the initial paragraph will be missing.

Compound directives like IF .. END, FOREACH .. END,  TRY .. CATCH .. END should therefore
be equilibrated, either all within the same paragraph, or each directive on a separate 
paragraph. Examples like this should be successful :

  This paragraph [[ IF condition ]]has an optional part[[ ELSE ]]or an alternative[[ END ]].
  
  [[ SWITCH result ]]
  [[ CASE 123 ]]
     Not a big deal.
  [[ CASE 789 ]]
     You won the lottery.
  [[ END ]]



=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020-2022 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


