use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use lib '.', 't';

plugin 'TagHelpers::ContentBlock';

# Add own plugin namespace
unshift @{app->plugins->namespaces}, 'ExamplePlugin';

my $navi_template =<< 'NAVI';
<nav>
%= content_block 'administration'
</nav>
NAVI

app->defaults(
  email_address => 'akron@sojolicious.example'
);

get '/' => sub {
  shift->render(inline => $navi_template);
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(200)
  ->element_count_is('nav > *', 0);

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
  ->text_is('nav > a[rel=email]', 'akron@sojolicious.example')
  ->text_is('nav > a:nth-of-type(1)', 'Admin')
  ->text_is('nav > a:nth-of-type(2)', 'akron@sojolicious.example')
  ;

get '/withhome' => sub {
  my $c = shift;

  $c->content_block(
    administration => {
      inline => q!<%= link_to 'Home' => '/home', rel => 'home' %>!,
      position => 20
    }
  );

  $c->render(inline => $navi_template);
};


$t->get_ok('/withhome')
  ->status_is(200)
  ->element_count_is('nav > *', 3)
  ->text_is('nav > a', 'Admin')
  ->text_is('nav > a:nth-of-type(1)', 'Admin')
  ->text_is('nav > a:nth-of-type(2)', 'Home')
  ->text_is('nav > a:nth-of-type(3)', 'akron@sojolicious.example')
  ;

app->plugin('Preferences');

$t->get_ok('/withhome')
  ->status_is(200)
  ->element_count_is('nav > *', 4)
  ->text_is('nav > a:nth-of-type(1)', 'Admin')
  ->text_is('nav > a:nth-of-type(2)', 'Preferences')
  ->text_is('nav > a:nth-of-type(3)', 'Home')
  ->text_is('nav > a:nth-of-type(4)', 'akron@sojolicious.example')
  ;

$t->get_ok('/')
  ->status_is(200)
  ->element_count_is('nav > *', 3)
  ->text_is('nav > a:nth-of-type(1)', 'Admin')
  ->text_is('nav > a:nth-of-type(2)', 'Preferences')
  ->text_is('nav > a:nth-of-type(3)', 'akron@sojolicious.example')
  ;


done_testing;
__END__
