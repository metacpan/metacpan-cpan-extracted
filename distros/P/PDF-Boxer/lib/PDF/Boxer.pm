package PDF::Boxer;
{
  $PDF::Boxer::VERSION = '0.004';
}
use Moose;

# ABSTRACT: Create PDFs from a simple box markup language.


use namespace::autoclean;

use PDF::Boxer::Doc;
use PDF::Boxer::Content::Box;
use PDF::Boxer::Content::Text;
use PDF::Boxer::Content::Image;
use PDF::Boxer::Content::Row;
use PDF::Boxer::Content::Column;
use PDF::Boxer::Content::Grid;
use Try::Tiny;
use Scalar::Util qw/weaken/;
use Moose::Util::TypeConstraints;

coerce 'PDF::Boxer::Doc'
  => from 'HashRef'
    => via { PDF::Boxer::Doc->new($_) };

has 'debug'   => ( isa => 'Bool', is => 'ro', default => 0 );

has 'doc' => ( isa => 'PDF::Boxer::Doc', is => 'ro', coerce => 1, lazy_build => 1 );

has 'max_width' => ( isa => 'Int', is => 'rw', default => 595 );
has 'max_height'  => ( isa => 'Int', is => 'rw', default => 842 );

has 'box_register' => ( isa => 'HashRef', is => 'ro', default => sub{{}} ); 

sub _build_doc{
  my ($self) = @_;
  return PDF::Boxer::Doc->new;
}

sub register_box{
  my ($self, $box) = @_;
  return unless $box->name;
  weaken($box);
  $self->box_register->{$box->name} = $box;
}

sub box_lookup{
  my ($self, $name) = @_;
  return $self->box_register->{$name};
}

sub add_to_pdf{
  my ($self, $spec) = @_;

  my $weak_me = $self;
  weaken($weak_me);
  $spec->{boxer} = $weak_me;
  $spec->{debug} = $self->debug;

  if ($spec->{type} eq 'Doc'){
    foreach my $page (@{$spec->{children}}){
      $page->{boxer} = $weak_me;
      $page->{debug} = $self->debug;
      
      my $class = 'PDF::Boxer::Content::'.$page->{type};
      my $node = $class->new($page);
      $self->register_box($node);
      $node->initialize;
      $node->render;
      $self->doc->new_page;
    }
  } else {
    my $class = 'PDF::Boxer::Content::'.$spec->{type};
    my $node = $class->new($spec);
    $self->register_box($node);
    $node->initialize;
    $node->render;
  }

  return 1;
  #return $node;
}

sub finish{
  my ($self) = @_;
  $self->doc->pdf->save;
  $self->doc->pdf->end;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

PDF::Boxer - Create PDFs from a simple box markup language.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  $pdfml = <<'__EOP__';
  <column max_width="595" max_height="842">
    <column border_color="blue" border="2">
      <row>
        <image src="t/lecstor.gif" align="center" valign="center" padding="10" scale="60" />
        <column grow="1" padding="10 10 10 0">
          <text padding="3" align="right" size="20">
            Lecstor Pty Ltd
          </text>
          <text padding="3" align="right" size="14">
            123 Example St, Somewhere, Qld 4879
          </text>
        </column>
      </row>
      <row padding="15 0">
        <text padding="20" size="14">
          Mr G Client
          Shop 2 Some Centre, Retail Rd
          Somewhere, NSW 2000
        </text>
        <column padding="20" border_color="red" grow="1">
          <text size="16" align="right" font="Helvetica-Bold">
            Tax Invoice No. 123
          </text>
          <text size="14" align="right">
            Issued 01/01/2011
          </text>
          <text size="14" align="right" font="Helvetica-Bold">
            Due 14/01/2011
          </text>
        </column>
      </row>
    </column>
    <grid padding="10">
      <row font="Helvetica-Bold" padding="0">
        <text align="center" padding="0 10">Name</text>
        <text grow="1" align="center" padding="0 10">Description</text>
        <text padding="0 10" align="center">GST Amount</text>
        <text padding="0 10" align="center">Payable Amount</text>
      </row>
      <row margin="10 0 0 0">
        <text padding="0 5">Web Services</text>
        <text name="ItemText2" grow="1" padding="0 5">
          a long description which needs to be wrapped to fit in the box
        </text>
        <text padding="0 5" align="right">$9999.99</text>
        <text padding="0 5" align="right">$99999.99</text>
      </row>
    </grid>
  </column>
  __EOP__

  $parser = PDF::Boxer::SpecParser->new;
  $spec = $parser->parse($pdfml);

  $boxer = PDF::Boxer->new( doc => { file => 'test_invoice.pdf' } );

  $boxer->add_to_pdf($spec);
  $boxer->finish;

=head1 DESCRIPTION

PDF::Boxer enables the creation of pdf documents using rows, columns, and grids
for layout. An xml styled document is used to specify the contents of the
document and is parsed into a block of data by PDF::Boxer::SpecParser and
passed to PDF::Boxer

Suggestion: Use L<Template> to dynamically create your PDFML template. 

=head1 METHODS

=head2 add_to_pdf

  $boxer->add_to_pdf($spec);

Coverts markup to PDF.

=head2 finish

Writes the generated PDF to the file specified in the call to new.

=head2 register_box

each named element is added to an internal register upon creation.

=head2 box_lookup

  $boxer->box_lookup('elementName');

get an element from the register.

=head1 MARKUP

For a single page document the parent element may be a row, column, or grid.
Multiple pages can be generated by wrapping more than one of these elements
with a doc element.

=head2 ELEMENTS

=item column

a column stacks elements vertically. Each element will be as wide as the
column's content space. If one or more children have the "grow" attribute
set then they will be stretched vertically to fill the column.

=item row

a row places it's children horizontally. If one or more children have the
"grow" attribute set then they will be stretched horizontally to fill the
row.

=item grid

a grid is a column with rows for children. The width of the rows' child elements
are locked vertically (like an html table).

You can now set the hborder and/or vborder attributes an a grid to display
gridlines.

eg <grid hborder="1" vborder="1">

=item text

the text element contains.. text! Text is wrapped to fith the width of it's
container if necessary.

=item image

the image element places an image in the PDF.. whoda thunkit, eh?
the image can be scaled to a percentage of it's original size.

=head2 ATTRIBUTES

=over

=item align

  align="right"

align right or center instead of the default left.

=item background

  background="#FF0000"

background is set as a hexadecimal color.

=item border_color

  border_color="#FF0000"

border_color is set as a hexadecimal color.

=item font

=item grow

when set to true, the element will expand to take up any available space.

=item margin, padding, border

size set in pixels as a string for top, right, bottom, left.
eg:
  margin="5 10 15 20"; top = 5, right = 10, bottom = 15, left = 20.
  margin="5 10"; top = 5, right = 10, bottom = 5, left = 10.

margin is space outside the border.
padding is space inside the border.
border IS the border..

=item name

I use this for debugging mostly.
It can be used to get an element object via the box_lookup method.

=back

=head1 BUGS

positioning of elements not pixel perfect. eg. in a column the bottom of one
child overlaps the top of the next by 1 pixel.

=head1 TODO

=over

=item paging

- enable a single element to be nominated for paging so if it's content is too
large to fit on a page it is continued on the next page.

- enable elements to be marked as first or last page only.

=back

=head1 SEE ALSO

=over 4

=item *

L<PDF::Boxer::Content::Box>

=item *

L<PDF::Boxer::Content::Row>

=item *

L<PDF::Boxer::Content::Column>

=item *

L<PDF::Boxer::Content::Grid>

=item *

L<PDF::Boxer::Content::Text>

=item *

L<PDF::Boxer::Content::Image>

=back

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

