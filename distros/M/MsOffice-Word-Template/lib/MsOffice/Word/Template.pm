package MsOffice::Word::Template;
use 5.024;
use Moose;
use MooseX::StrictConstructor;
use Carp                           qw(croak);
use HTML::Entities                 qw(decode_entities);
use MsOffice::Word::Surgeon 2.0;

# syntactic sugar for attributes
sub has_inner ($@) {my $attr = shift; has($attr => @_, init_arg => undef, lazy => 1, builder => "_$attr")}

use namespace::clean -except => 'meta';

our $VERSION = '2.0';

#======================================================================
# ATTRIBUTES
#======================================================================

# constructor attributes for interacting with MsWord
# See also BUILDARGS: the constructor can also take a "docx" arg
# that will be automatically translated into a "surgeon" attribute
has 'surgeon'       => (is => 'ro', isa => 'MsOffice::Word::Surgeon', required => 1);
has 'data_color'    => (is => 'ro', isa => 'Str',                     default  => "yellow");
has 'control_color' => (is => 'ro', isa => 'Str',                     default  => "green");
has 'part_names'    => (is => 'ro', isa => 'ArrayRef[Str]',           lazy     => 1,
                        default  => sub {[keys shift->surgeon->parts->%*]});

# constructor attributes for building a templating engine
has 'engine_class'  => (is => 'ro', isa => 'Str',                     default  => 'TT2');
has 'engine_args'   => (is => 'ro', isa => 'ArrayRef',                default  => sub {[]});

# attributes lazily constructed by the module -- not received through the constructor
has_inner 'engine'  => (is => 'ro', isa => 'MsOffice::Word::Template::Engine');

#======================================================================
# GLOBALS
#======================================================================

my $XML_COMMENT_FOR_MARKING_DIRECTIVES = '<!--TEMPLATE_DIRECTIVE_ABOVE-->';


#======================================================================
# BUILDING INSTANCES
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


#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================


sub _engine {
  my ($self) = @_;

  # instantiate the templating engine
  my $engine_class = $self->engine_class;
  my $engine;
  my @load_errors;
 CLASS:
  for my $class ("MsOffice::Word::Template::Engine::$engine_class", $engine_class) {
    eval "require $class; 1"                        or  push @load_errors, $@ and next CLASS;
    $engine = $class->new($self->engine_args->@*)                             and last CLASS;
  }
  $engine or die "could not load engine class '$engine_class'", @load_errors;

  # compile regexes based on the start/end tags
  my ($start_tag, $end_tag) = ($engine->start_tag, $engine->end_tag);
  my @xml_regexes = $self->_xml_regexes($start_tag, $end_tag);

  # tell the engine to build a compiled template for each document part
  foreach my $part_name ($self->part_names->@*) {
    my $part = $self->surgeon->part($part_name);

    # assemble template fragments from all runs in the part into a global template text
    $part->cleanup_XML;
    my @template_fragments = map {$self->_template_fragment_for_run($_, $start_tag, $end_tag)}
                                 $part->runs->@*;
    my $template_text      = join "", @template_fragments;

    # remove markup around directives, successively for table rows, for paragraphs, and finally
    # for remaining directives embedded within text runs.
    $template_text =~ s/$_/$1/g foreach @xml_regexes;

    # compile and store the template
    $engine->compile_template($part_name => $template_text);
  }

  return $engine;
}



#======================================================================
# UTILITY METHODS
#======================================================================



sub _template_fragment_for_run { # given an instance of Surgeon::Run, build a template fragment
  my ($self, $run, $start_tag, $end_tag) = @_;

  my $props         = $run->props;
  my $data_color    = $self->data_color;
  my $control_color = $self->control_color;

  # if this run is highlighted in data or control color, it must be translated into a template directive
  if ($props =~ s{<w:highlight w:val="($data_color|$control_color)"/>}{}) {
    my $color       = $1;
    my $xml         = $run->xml_before;

    # re-build the run, removing the highlight, and adding the start/end tags for the template engine
    my $inner_texts = $run->inner_texts;
    if (@$inner_texts) {
      $xml .= "<w:r>";                                                # opening XML tag for run node
      $xml .= "<w:rPr>" . $props . "</w:rPr>" if $props;              # optional run properties
      $xml .= "<w:t>";                                                # opening XML tag for text node
      $xml .= $start_tag;                                             # start a template directive
      foreach my $inner_text (@$inner_texts) {                        # loop over text nodes
        my $txt = decode_entities($inner_text->literal_text);         # just take inner literal text
        $xml .= $txt . "\n";
        # NOTE : adding "\n" because the template parser may need them for identifying end of comments
      }

      $xml .= $end_tag;                                               # end of template directive
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




sub _xml_regexes {
  my ($self, $start_tag, $end_tag) = @_;

  # start and end character sequences for a template fragment
  my $rx_start = quotemeta  $start_tag;
  my $rx_end   = quotemeta  $end_tag;

  # Regexes for extracting template directives within the XML.
  # Such directives are identified through a specific XML comment -- this comment is
  # inserted by method "template_fragment_for_run()" below.
  # The (*SKIP) instructions are used to avoid backtracking after a
  # closing tag for the subexpression has been found. Otherwise the
  # .*? inside could possibly match across boundaries of the current
  # XML node, we don't want that.

  # regex for matching directives to be treated outside the text flow.
  my $rx_outside_text_flow = qr{
      <w:r\b           [^>]*>                  # start run node
        (?: <w:rPr> .*? </w:rPr>   (*SKIP) )?  # optional run properties
        <w:t\b         [^>]*>                  # start text node
          ($rx_start .*? $rx_end)  (*SKIP)     # template directive
          $XML_COMMENT_FOR_MARKING_DIRECTIVES  # specific XML comment
        </w:t>                                 # close text node
      </w:r>                                   # close run node
   }sx;

  # regex for matching paragraphs that contain only a directive
  my $rx_paragraph = qr{
    <w:p\b             [^>]*>                  # start paragraph node
      (?: <w:pPr> .*? </w:pPr>     (*SKIP) )?  # optional paragraph properties
      $rx_outside_text_flow
    </w:p>                                     # close paragraph node
   }sx;

  # regex for matching table rows that contain only a directive in the first cell
  my $rx_row = qr{
    <w:tr\b            [^>]*>                  # start row node
      <w:tc\b          [^>]*>                  # start cell node
         (?:<w:tcPr> .*? </w:tcPr> (*SKIP) )?  # cell properties
         $rx_paragraph                         # paragraph in cell
      </w:tc>                                  # close cell node
      (?:<w:tc> .*? </w:tc>        (*SKIP) )*  # ignore other cells on the same row
    </w:tr>                                    # close row node
   }sx;

  return ($rx_row, $rx_paragraph, $rx_outside_text_flow);
  # Note : the order is important
}





#======================================================================
# PROCESSING THE TEMPLATE
#======================================================================

sub process {
  my ($self, $vars) = @_;

  # create a clone of the original 
  my $new_doc = $self->surgeon->clone;

  foreach my $part_name ($self->part_names->@*) {
    my $new_doc_part = $new_doc->part($part_name);
    my $new_contents = $self->engine->process($part_name, $new_doc_part, $vars);
    $new_doc_part->contents($new_contents);
  }

  return $new_doc;
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


Template authors just use the highlighing function in MsWord to
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
other engines can be specified as subclasses -- see the L</TEMPLATE ENGINE> section below.


=head2 Status

This second release is a major refactoring of the first version, together with
a refactoring of L<MsOffice::Word::Surgeon>. New features include support
for headers and footers and for image insertion. The internal object-oriented
structure has been redesigned.

This module has been used successfully for a pilot project in my organization,
generating quite complex documents from deeply nested datastructures.
Yet this has not been used yet at large scale in production, so it is quite likely
that some youth defects may still be discovered.
If you use this module, please keep me
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

Processes the template on a given data tree, and returns a new document
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

See also L<MsOffice::Word::Template::Engine::TT2> for
additional advice on authoring templates based on the
L<Template Toolkit|Template>.



=head1 TEMPLATE ENGINE

This module invokes a backend I<templating engine> for interpreting the
template directives. The default engine is
L<MsOffice::Word::Template::Engine::TT2>, built on top of
L<Template Toolkit|Template>. Another engine supplied in this distribution is
L<MsOffice::Word::Template::Engine::Mustache>, mostly as an example.
To implement another engine, just subclass
L<MsOffice::Word::Template::Engine>.

To use an engine different from the default, the following arguments
must be supplied to the L</new> method :

=over

=item engine_class

The name of the engine class. If the class is within the L<MsOffice::Word::Template::Engine>
namespace, just the suffix is sufficient; otherwise, specify the fully qualified class name.

=item engine_args

An optional list of parameters that may be used for initializing the engine

=back

The engine will get a C<compile_template> method call for each part in the
C<.docx> document (main 

Given a datatree in C<$vars>, the engine will be called as :


The engine must make sure that ampersand characters and angle brackets
are automatically replaced by the corresponding HTML entities
(otherwise the resulting XML would be incorrect and could not be
opened by Microsoft Word).  The Mustache engine does this
automatically.  The Template Toolkit would normally require to
explicitly add an C<html> filter at each directive :

  [% foo.bar | html %]

but thanks to the L<Template::AutoFilter>
module, this is performed automatically.



This module invokes a backend I<templating engine> for interpreting the
template directives. The default engine is
L<MsOffice::Word::Template::Engine::TT2>, built on top of
L<Template Toolkit|Template>. Another engine supplied in this distribution is
L<MsOffice::Word::Template::Engine::Mustache>, mostly as an example.
To implement another engine, just subclass
L<MsOffice::Word::Template::Engine>.

To use an engine different from the default, the following arguments
must be supplied to the L</new> method :

=over

=item engine_class

The name of the engine class. If the class sits within the L<MsOffice::Word::Template::Engine>
namespace, just the suffix is sufficient; otherwise, specify the fully qualified class name.

=item engine_args

An optional list of parameters that may be used for initializing the engine

=back

After initialization the engine will receive a C<compile_template> method call for each part in the
C<.docx> document, i.e. not only the main document body, but also headers and footers.

Then the main C<process()> method, given a datatree in C<$vars>, will call
the engine's C<process()> method on each document part.

The engine must make sure that ampersand characters and angle brackets
are automatically replaced by the corresponding HTML entities
(otherwise the resulting XML would be incorrect and could not be
opened by Microsoft Word).  The Mustache engine does this
automatically.  The Template Toolkit would normally require to
explicitly add an C<html> filter at each directive :

  [% foo.bar | html %]

but thanks to the L<Template::AutoFilter>
module, this is performed automatically.

=head1 TROUBLESHOOTING

If a document generated by this module cannot open in Word, it is probably because the XML
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


