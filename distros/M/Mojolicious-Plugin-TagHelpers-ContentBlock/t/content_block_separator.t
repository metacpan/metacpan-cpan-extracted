use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use lib '.', 't';

plugin 'TagHelpers::ContentBlock';

ok(!app->content_block_ok('admin'), 'Nothing in the content block');

my $template =<< 'NAVI';
% if (content_block_ok('admin')) {
  <nav>
  %= content_block 'admin', separator => '<hr />'
  </nav>
% };
NAVI

get '/' => sub {
  my $c = shift;
  $c->content_block(admin => {
    inline => '<p>second &amp; third</p>',
    position => 100
  });
  $c->content_block(admin => {
    inline => '<p>first</p>',
    position => 20
  });
  $c->render(inline => $template);
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(200)
  ->text_is('nav p:nth-of-type(1)', 'first')
  ->text_is('nav p:nth-of-type(2)', 'second & third')
  ->element_exists('nav > hr')
  ;

done_testing();
__END__
