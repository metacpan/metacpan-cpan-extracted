#!perl -T

package ElipsedBackground;
use Moose::Role;

sub draw_background {
	my ($self, $x, $y, $gfx, $txt) = @_;
	$gfx->linewidth(0);
	$gfx->fillcolor('yellow');
	$gfx->ellipse($x+$self->width/2, $y-$self->height/2, $self->width/2, $self->height/2);
	$gfx->fill();
}

package ImageContent;
use Moose::Role;
use PDF::API2;

sub draw_content {
	my ($self, $x, $y, $gfx, $txt) = @_;
	$y -= ($self->padding->[0] + 200);
	$x += $self->padding->[3];
	
	my $image_object = $gfx->{' api'}->image_jpeg( $self->content );
	$gfx->image($image_object, $x, $y, 200, 200);
	$self->height(200+$self->padding->[0]+$self->padding->[2]);
	
	return (200, $self->height, 0);
}

sub _get_min_width { 200 + $_[0]->padding->[1] + $_[0]->padding->[3]}
sub _get_reg_width { 200 + $_[0]->padding->[1] + $_[0]->padding->[3]}


use Test::More;
use Moose::Util qw( apply_all_roles does_role);

use PDF::TableX;
use PDF::API2;

my $table = PDF::TableX->new(2,2);
my $pdf = PDF::API2->new();
$pdf->mediabox('a4');
my $page = $pdf->page;

$table
	->padding(10)
	->border_width(1)
	->text_align('center');
$table->[0]->border_width(0);

apply_all_roles( $table->[0][0], 'ElipsedBackground' );
apply_all_roles( $table->[0][1], 'ElipsedBackground' );
$table->[0][0]->content("Some text");
$table->[0][1]->content("Some other text");

apply_all_roles( $table->[1][0], 'ImageContent' );
apply_all_roles( $table->[1][1], 'ImageContent' );
$table->[1][0]->content("t/06-extend-role-functionality.jpeg");
$table->[1][1]->content("t/06-extend-role-functionality.jpeg");

$table->draw($pdf, $page);
$pdf->saveas('t/06-extend-role-functionality.pdf');

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );

is(does_role($table->[0][0], 'ElipsedBackground'), 1);
is(does_role($table->[0][1], 'ElipsedBackground'), 1);

done_testing;
