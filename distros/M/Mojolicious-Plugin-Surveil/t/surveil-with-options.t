use Mojo::Base -base;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin 'surveil' => { enable_param => '_surveil' };
  get '/' => 'index';
}

my $t = Test::Mojo->new;

$t->get_ok('/')->element_exists_not('script');
$t->get_ok('/?_surveil=1')->element_exists('script');

done_testing;
__DATA__
@@ index.html.ep
<html>
<head>
<title>test surveil</title>
</head>
<body>
<button id="foo" class="bar baz">does this work?</button>
</html>
