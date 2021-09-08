use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use lib '.', 't';

plugin Config => {
  default => {
    'TagHelpers-ContentBlock' => {
      footer => {
        inline => '<%= link_to "Copyright" => "/copyright" %>',
        position => 10
      }
    }
  }
};

plugin 'TagHelpers::ContentBlock' => {
  admin => [
    {
      inline => '<%= link_to "Edit" => "/edit" %>',
      position => 10
    },
    {
      inline => '<%= link_to "Logout" => "/logout" %>',
      position => 15
    }
  ],
  footer => {
    inline => '<%= link_to "Privacy" => "/privacy" %>',
    position => 5
  }
};

# Add own plugin namespace
unshift @{app->plugins->namespaces}, 'ExamplePlugin';

ok(app->content_block_ok('admin'), 'Only init in the content block');

my $navi_admin_template =<< 'NAVI';
% if (content_block_ok('admin')) {
  <nav>
  %= content_block 'admin'
  </nav>
% };
NAVI

my $navi_footer_template =<< 'NAVI';
<nav>
%= content_block 'footer'
</nav>
NAVI

get '/admin' => sub {
  shift->render(inline => $navi_admin_template);
} => 'admin';

get '/footer' => sub {
  shift->render(inline => $navi_footer_template);
};

get '/footer2' => sub {
  my $c = shift;
  $c->content_block(footer => {
    inline => '<%= link_to "Admin" => "admin" %>',
    position => 2
  });
  $c->render(inline => $navi_footer_template);
};

my $t = Test::Mojo->new;

my $err = $t->get_ok('/admin')
  ->status_is(200)
  ->element_exists('nav')
  ->element_count_is('nav > *', 2)
  ->text_is('nav > a:nth-of-type(1)', 'Edit')
  ->text_is('nav > a:nth-of-type(2)', 'Logout')
  ->tx->res->dom->at('#error')
  ;
is(defined $err ? $err->text : '', '');
  ;

$err = $t->get_ok('/footer')
  ->status_is(200)
  ->element_exists('nav')
  ->element_count_is('nav > *', 2)
  ->tx->res->dom->at('#error')
  ;
is(defined $err ? $err->text : '', '');


$err = $t->get_ok('/footer2')
  ->status_is(200)
  ->element_exists('nav')
  ->element_count_is('nav > *', 3)
  ->text_is('nav > a:nth-of-type(1)', 'Admin')
  ->text_is('nav > a:nth-of-type(2)', 'Privacy')
  ->text_is('nav > a:nth-of-type(3)', 'Copyright')
  ->tx->res->dom->at('#error')
  ;
is(defined $err ? $err->text : '', '');


$err = $t->get_ok('/footer')
  ->status_is(200)
  ->element_exists('nav')
  ->element_count_is('nav > *', 2)
  ->tx->res->dom->at('#error')
  ;
is(defined $err ? $err->text : '', '');

done_testing;
__END__


