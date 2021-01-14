package MsOffice::Word::Template;
use Moose;
use MooseX::StrictConstructor;
use Carp                           qw(croak);
use HTML::Entities                 qw(decode_entities);
use MsOffice::Word::Surgeon;

use namespace::clean -except => 'meta';

our $VERSION = '1.01';

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

  # regex for matching paragraphs that contain directives to be treated outside the text flow.
  # Such directives are identified through a specific XML comment -- this comment is
  # inserted by method "template_fragment_for_run()" below.
  my $regex_paragraph = qr{
    <w:p               [^>]*>                  # start paragraph node
      (?: <w:pPr> .*? </w:pPr>     (*SKIP) )?  # optional paragraph properties
      <w:r             [^>]*>                  # start run node
        <w:t           [^>]*>                  # start text node
          ($rx_start .*? $rx_end)  (*SKIP)     # template directive
          <!--OUTSIDE_TEXT_FLOW-->             # specific XML comment
        </w:t>                                 # close text node
      </w:r>                                   # close run node
    </w:p>                                     # close paragraph node
   }sx;

  # regex for matching table rows that contain such paragraphs.
  my $regex_row = qr{
    <w:tr              [^>]*>                  # start row node
      <w:tc            [^>]*>                  # start cell node
         (?:<w:tcPr> .*? </w:tcPr> (*SKIP) )?  # cell properties
         $regex_paragraph                      # paragraph in cell
      </w:tc>                                  # close cell node
      (?:<w:tc> .*? </w:tc>        (*SKIP) )*  # possibly other cells on the same row
    </w:tr>                                    # close row node
   }sx;

  # NOTE : the (*SKIP) instructions in regexes above are used to avoid backtracking
  # after a closing tag for the subexpression has been found. Otherwise the .*? inside
  # could possibly match across boundaries of the current XML node, we don't want that.

  # assemble template fragments from all runs in the document into a global template text
  $self->surgeon->cleanup_XML;
  my @template_fragments = map {$self->template_fragment_for_run($_)}  @{$self->surgeon->runs};
  my $template_text      = join "", @template_fragments;

  # remove markup for rows around directives
  $template_text =~ s/$regex_row/$1/g;

  # remove markup for pagraphs around directives
  $template_text =~ s/$regex_paragraph/$1/g;

  return $template_text;
}


sub template_fragment_for_run { # given an instance of Surgeon::Run, build a template fragment
  my ($self, $run) = @_;

  my $props         = $run->props;
  my $data_color    = $self->data_color;
  my $control_color = $self->control_color;

  # if this run is highlighted in yellow or green, it must be translated into a template directive
  # NOTE:  the code below has much in common with Surgeon::Run::as_xml() -- maybe
  # part of it could be shared in a future version
  if ($props =~ s{<w:highlight w:val="($data_color|$control_color)"/>}{}) {
    my $color       = $1;
    my $xml         = $run->xml_before;

    my $inner_texts = $run->inner_texts;
    if (@$inner_texts) {
      $xml .= "<w:r>";                                                # opening XML tag for run node
      $xml .= "<w:rPr>" . $props . "</w:rPr>" if $props;              # optional run properties
      $xml .= "<w:t>";                                                # opening XML tag for text node
      $xml .= $self->start_tag;                                       # start a template directive
      foreach my $inner_text (@$inner_texts) {
        my $txt = decode_entities($inner_text->literal_text);
        $xml .= $txt . "\n";
        # NOTE : adding "\n" because the template parser may need them for identifying end of comments
      }

      $xml .= $self->end_tag;                                         # end of template directive
      $xml .= "<!--OUTSIDE_TEXT_FLOW-->" if $color eq $control_color; # XML comment for marking
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


sub TT2_engine {
  my ($self, $vars) = @_;

  require Template::AutoFilter; # a subclass of Template that adds automatic html filtering

  # at the first invocation, create a TT2 compiled template and store it in the stash.
  # Further invocations just reuse the TT2 object in stash.
  my $stash                     = $self->{engine_stash} //= {};
  $stash->{TT2}               //= Template::AutoFilter->new(@{$self->engine_args});
  $stash->{compiled_template} //= $stash->{TT2}->template(\$self->{template_text});

  # generate new XML by invoking the template on $vars
  my $new_XML = $stash->{TT2}->context->process($stash->{compiled_template}, $vars);

  return $new_XML;
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
templating engine.  The default engine is the L<Perl Template
Toolkit|Template>; other engines can be specified through parameters
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
B<green>. When seeing a green zone, the system will remove markup for
the surrounding XML nodes (text, run and paragraph nodes). If this
occurs within a table, the markup for the current row is also
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
to the N</new> method :

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

=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020, 2021 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


