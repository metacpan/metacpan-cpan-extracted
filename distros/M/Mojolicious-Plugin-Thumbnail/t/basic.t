use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Imager;

plugin 'Thumbnail';

post '/make_thumb' => sub {
	my $self = shift;
	
	$self->thumbnail(
		src    => 't/test.jpg',
		width  => $self->param('width' ) || 0,
		height => $self->param('height') || 0,
		dst    => scalar $self->param('dst')
	);

	my $img = Imager->new()->open(file => $self->param('dst') || 't/test_thumb.jpg');

	$self->render(text => join 'x', ($img->getwidth, $img->getheight));
};

my $t = Test::Mojo->new;
$t
	->post_ok('/make_thumb' => form => { width => 100, height => 100})
	->status_is(200)
	->content_is('100x100');

$t
	->post_ok('/make_thumb' => form => { width => 100 })
	->status_is(200)
	->content_is('100x109');

$t
	->post_ok('/make_thumb' => form => { height => 100 })
	->status_is(200)
	->content_is('92x100');

$t
	->post_ok('/make_thumb' => form => { height => 300, width => 300, dst => 't/dst.jpg' })
	->status_is(200)
	->content_is('300x300');

unlink qw{t/test_thumb.jpg t/dst.jpg};

done_testing();
