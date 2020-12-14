package MsOffice::Word::Template;
use Moose;
use MooseX::StrictConstructor;
use Carp                           qw(croak);
use HTML::Entities                 qw(decode_entities);
use Template::AutoFilter;
use MsOffice::Word::Surgeon;

use namespace::clean -except => 'meta';


our $VERSION = '1.0';

has 'surgeon'         => (is => 'ro',   isa => 'MsOffice::Word::Surgeon', required => 1);
has 'data_color'      => (is => 'ro',   isa => 'Str',                     default  => "yellow");
has 'directive_color' => (is => 'ro',   isa => 'Str',                     default  => "green");
has 'template_config' => (is => 'ro',   isa => 'HashRef',                 default  => sub { {} });

has 'template_text'   => (is => 'bare', isa => 'Str',                     init_arg => undef);


#======================================================================
# BUILDING THE TEMPLATE
#======================================================================


# syntactic sugar for supporting ->new($surgeon) instead of ->new(surgeon => $surgeon)
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # if there is a unique arg without any keyword ...
  if ( @_ == 1) {

    # if the unique arg is an instance of Surgeon, pass it to the regular constructor
    return $class->$orig(surgeon => $_[0])
      if $_[0]->isa('MsOffice::Word::Surgeon');

    # if the unique arg is a string, treat it as pathname for a new surgeon
    return $class->$orig(surgeon => MsOffice::Word::Surgeon->new(docx => $_[0]))
      if $_[0] && !ref $_[0];

    # if reaching here, the unique arg is just wrong
    croak "invalid arg to MsOffice::Word::Template->new()";
  }

  # ... otherwise call the regular Moose constructor
  else {
    return $class->$orig(@_);
  }
};


sub BUILD {
  my ($self) = @_;

  # assemble the template text and store it into the bare attribute
  $self->{template_text} = $self->build_template_text;
}


sub template_fragment_for_run { # given an instance of Surgeon::Run, build a template fragment
  my ($self, $run) = @_;

  my $props           = $run->props;
  my $data_color      = $self->data_color;
  my $directive_color = $self->directive_color;

  # if this run is highlighted in yellow or green, it must be translated into a TT2 directive
  # NOTE:  the translation code has much in common with Surgeon::Run::as_xml() -- maybe
  # part of the code could be shared in a future version
  if ($props =~ s{<w:highlight w:val="($data_color|$directive_color)"/>}{}) {
    my $color       = $1;
    my $xml         = $run->xml_before;

    my $inner_texts = $run->inner_texts;
    if (@$inner_texts) {
      $xml .= "<w:r>";                                              # opening tag for run node
      $xml .= "<w:rPr>" . $props . "</w:rPr>" if $props;            # optional run properties
      $xml .= "<w:t>";                                              # opening tag for text node
      $xml .= "[% ";                                                # start of TT2 directive
      foreach my $inner_text (@$inner_texts) {
        my $txt = decode_entities($inner_text->literal_text);
        $xml .= $txt . "\n";
        # NOTE : adding "\n" because the Template Toolkit parser may need them for identifying end of comments
      }


      $xml .= " %]";                                                # end of TT2 directive
      $xml .= "<!--TT2_directive-->" if $color eq $directive_color; # XML comment for marking TT2 directives -- used in regexes below
      $xml .= "</w:t>";                                             # closing tag for text node
      $xml .= "</w:r>";                                             # closing tag for run node
    }

    return $xml;
  }

  # otherwise this run is just regular MsWord content
  else {
    return $run->as_xml;
  }
}


sub build_template_text {
  my ($self) = @_;

  # regex for matching paragraphs that contain TT2 directives
  my $regex_paragraph = qr{
    <w:p               [^>]*>                  # start paragraph node
      (?: <w:pPr> .*? </w:pPr>     (*SKIP) )?  # optional paragraph properties
      <w:r             [^>]*>                  # start run node
        <w:t           [^>]*>                  # start text node
          (\[% .*? %\])            (*SKIP)     # template directive
          <!--TT2_directive-->                 # followed by an XML comment
        </w:t>                                 # close text node
      </w:r>                                   # close run node
    </w:p>                                     # close paragraph node
   }sx;

  # regex for matching table rows that contain TT2 directives
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

  # remove markup for rows around TT2 directives
  $template_text =~ s/$regex_row/$1/g;

  # remove markup for pagraphs around TT2 directives
  $template_text =~ s/$regex_paragraph/$1/g;

  return $template_text;
}



#======================================================================
# PROCESSING THE TEMPLATE
#======================================================================



sub process {
  my ($self, $vars) = @_;

  # invoke the Template Toolkit to generate the new XML
  my $template = Template::AutoFilter->new($self->template_config)
    or die Template::AutoFilter->error(), "\n";

  my $new_XML = "";
  $template->process(\$self->{template_text}, $vars, \$new_XML)
    or die $template->error();

  # insert the generated output into a MsWord document; other zip members are cloned from the original template
  my $new_doc = $self->surgeon->meta->clone_object($self->surgeon);
  $new_doc->contents($new_XML);

  return $new_doc;
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Template - treat a Word document as Template Toolkit document

=head1 SYNOPSIS

  my $template = MsOffice::Word::Template->new($filename);
  my $new_doc  = $template->process(\%data);
  $new_doc->save_as($path_for_new_doc);

=head1 DESCRIPTION

=head2 Purpose

This module treats a Microsoft Word document as a template for generating other documents. The idea is
similar to the "mail merge" functionality in Word, but with much richer possibilities, because the
whole power of the L<Perl Template Toolkit|Template> can be exploited, for example for

=over

=item *

dealing with complex, nested datastructures

=item *

using control directives like IF, FOREACH, CALL, etc.

=back

To distinguish templating directives from regular Word content, just use the Word highlighting function :

=over

=item * 

fragments highlighted in B<yelllow> are interpreted as GET directives, i.e. the data content will be inserted
at that point in the document, keeping the current formatting properties (bold, italic, font, etc.).

=item *

fragments highlighted in B<green> are interpreted as Template Toolkit directives that do not directly
generate content, like IF, FOREACH, etc. The Word formatting around such directives is dismissed, including
the current context (paragraph or table row), in order to avoid empty paragraphs or empty rows in the resulting document.

=back

=head2 Status

This first release is a proof of concept. Some simple templates have been successfully tried; however it is likely
that a number of improvements will have to be made before this system can be used at large scale in production.
If you use this module, please keep me informed of your difficulties, tricks, suggestions, etc.


=head1 METHODS

=head2 Constructor

=head3 new

  my $template = MsOffice::Word::Template->new($filename);
  # or : my $template = MsOffice::Word::Template->new($surgeon);   # an instance of MsOffice::Word::Surgeon
  # or : my $template = MsOffice::Word::Template->new(surgeon => $surgeon, %options);

Possible options are :

=over

=item surgeon

an instance of MsOffice::Word::Surgeon

=item data_color

the Word highlight color for marking GET directives (default : yellow)

=item directive_color

the Word highlight color for marking other directives (default : green)

=item template_config

hashref of configuration options to be passed to L<Template/new> -- see L<Template::Manual::Config>

=back


=head2 Using the template

=head3 process

  my $new_doc = $template->process(\%data);
  $new_doc->save_as($path_for_new_doc);

Process the template on a given data tree, and return a new document (actually, a new instance of L<MsOffice::Word::Surgeon>).
That document can then be saved in a file using L<MsOffice::Word::Surgeon/save_as>.


=head1 WRITING TEMPLATES

A template is just a regular Word document, in which the highlighted fragments represent templating instructions.

The "holes" to be filled must be highlighted in I<yellow>. Fill these zones with the names of variables to fill
the holes. Names of variables can be paths into a complex datastructure, with dots separating the levels,
like C<foo.3.bar.-1> -- see L<Template::Manual::Directive/GET> and L<Template::Manual::Variables>. Thanks
to the L<Template::AutoFilter> module, the builtin C<html> filter of the Template Toolkit is automatically
applied, so that ampersand characters and angle brackets are automatically replaced by the corresponding
HTML entities (otherwise the resulting XML would be incorrect and could not be opened by Microsoft Word).

Control directives like C<IF>, C<FOREACH>, etc. must be highlighted in I<green>. When seeing a green zone, the system
will remove markup for the surrounding text, run and paragraph nodes. If this occurs within a table, the markup for the
current row is also removed. Without this mechanism, the final result would contain an empty paragraph or an empty row for each
templating directive. 

In consequence of this distinction between yellow and green highlights, templating zones cannot mix GET directives with
other directives : a GET directive within a green zone would generate output outside of the regular XML flow (paragraph nodes,
run nodes and text nodes), and therefore MsWord would generate an error when trying to open such content. There is a 
workaround, however : GET directives within a green zone will work if they I<also generate the appropriate markup> for
paragraphs, runs and text nodes; but in that case you must also apply the "none" filter from
L<Template::AutoFilter> so that angle brackets in XML markup do not get translated into HTML entities. 


=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

