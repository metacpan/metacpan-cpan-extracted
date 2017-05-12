use Mojolicious::Lite;
use Test::More;
use Test::Mojo;

plugin 'PPI';

my $overall = '.ppi { display: none; }';
app->ppi->style($overall);
app->ppi->class_style({
  myinline => { display => 'inline', color => 'white' },
  myblack  => 'black',
});

any '/' => 'test';

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->text_like(style => qr/\Q$overall\E/)
  ->text_like(style => qr/\Q.ppi-code .myinline { color: white; display: inline; }\E/)
  ->text_like(style => qr/\Q.ppi-code .myblack { color: black; }\E/);

done_testing;

__DATA__

@@ test.html.ep

%= ppi_css

