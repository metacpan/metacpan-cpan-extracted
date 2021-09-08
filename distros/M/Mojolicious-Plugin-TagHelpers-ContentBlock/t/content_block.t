use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use lib '.', 't';

plugin 'TagHelpers::ContentBlock';

# Add own plugin namespace
unshift @{app->plugins->namespaces}, 'ExamplePlugin';

ok(!app->content_block_ok('administration'), 'Nothing in the content block');

my $navi_template =<< 'NAVI';
% if (content_block_ok('administration')) {
  <nav>
  %= content_block 'administration'
  </nav>
% };
NAVI

my $navi_nonopt_template =<< 'NAVI';
<nav>
%= content_block 'administration'
</nav>
NAVI

my $navi_dynamic_template =<< 'NAVI';
<title>Dynamic</title>
% if (content_block_ok('dynamic')) {
  <ul>
  %= content_block 'dynamic'
  </ul>
% };
NAVI

app->defaults(
  email_address => 'akron@sojolicious.example'
);

get '/' => sub {
  shift->render(inline => $navi_template);
};

get '/nonopt' => sub {
  shift->render(inline => $navi_nonopt_template);
};

my $t = Test::Mojo->new;

my $err = $t->get_ok('/')
  ->status_is(200)
  ->element_exists_not('nav')
  ->element_count_is('nav > *', 0)
  ->tx->res->dom->at('#error')
  ;
is(defined $err ? $err->text : '', '');

$err = $t->get_ok('/nonopt')
  ->status_is(200)
  ->element_exists('nav')
  ->element_count_is('nav > *', 0)
  ->tx->res->dom->at('#error')
  ;
is(defined $err ? $err->text : '', '');

app->plugin('Admin');

$t->get_ok('/')
  ->status_is(200)
  ->element_count_is('nav > *', 1)
  ->text_is('nav > a', 'Admin')
  ->text_is('nav > a[rel=admin]', 'Admin');

app->plugin('Email');

$t->get_ok('/')
  ->status_is(200)
  ->element_count_is('nav > *', 2)
  ->text_is('nav > a', 'Admin')
  ->text_is('nav > a[rel=admin]', 'Admin')
  ->text_is('nav > a[rel=email]', 'akron@sojolicious.example');

get '/newmail' => sub {
  my $c = shift;
  $c->stash(email_address => 'peter@sojolicious.example');
  $c->render(inline => $navi_template);
};

$t->get_ok('/newmail')
  ->status_is(200)
  ->element_count_is('nav > *', 2)
  ->text_is('nav > a', 'Admin')
  ->text_is('nav > a[rel=admin]', 'Admin')
  ->text_is('nav > a[rel=email]', 'peter@sojolicious.example');

get '/withhome' => sub {
  my $c = shift;

  $c->content_block(
    administration => {
      inline => q!<%= link_to 'Home' => '/home', rel => 'home' %>!,
      position => 1000
    }
  );

  $c->render(inline => $navi_template);
};

ok(app->content_block_ok('administration'), 'Nothing in the content block');

$t->get_ok('/withhome')
  ->status_is(200)
  ->element_count_is('nav > *', 3)
  ->text_is('nav > a', 'Admin')
  ->text_is('nav > a[rel=admin]', 'Admin')
  ->text_is('nav > a[rel=email]', 'akron@sojolicious.example')
  ->text_is('nav > a[rel=home]', 'Home');

$t->get_ok('/')
  ->status_is(200)
  ->element_count_is('nav > *', 2)
  ->text_is('nav > a', 'Admin')
  ->text_is('nav > a[rel=admin]', 'Admin')
  ->text_is('nav > a[rel=email]', 'akron@sojolicious.example');


# Check dynamic templates
get '/dynamic' => sub {
  my $c = shift;
  if ($c->param('key')) {
    $c->content_block(dynamic => {
      inline => '<li>Huhu!</li>'
    });
  };
  $c->render(inline => $navi_dynamic_template);
};

$t->get_ok('/dynamic')
  ->text_is('title', 'Dynamic')
  ->element_exists_not('ul')
  ->element_exists_not('li')
  ;

$t->get_ok('/dynamic?key=1')
  ->text_is('title', 'Dynamic')
  ->element_exists('ul')
  ->element_exists('li')
  ->text_is('li', 'Huhu!')
  ;


done_testing();
__END__
