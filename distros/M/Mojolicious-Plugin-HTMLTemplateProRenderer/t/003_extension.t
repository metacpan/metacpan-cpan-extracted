use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'HTMLTemplateProRenderer', tmpl_opts => {use_extension => 1};

my $test1 = 'Hello Mojo!';
my $test2 = 'HTML::Template::Pro Inline test';
my $test3 = 'HTML::Template::Pro Template test';
my $test4 = 'HTML::Template::Pro Base App Template test';
my $test5 = 'HTML::Template::Pro Inline __DATA__ test';

get '/' => sub {
  my $self = shift;
  $self->render(text => $test1);
};

get '/slash_var' => sub {
  my $self = shift;
  $self->stash(t1 => $test2);
  $self->render(inline => '<p><TMPL_VAR NAME="t1">pippo</TMPL_VAR></p>',
  handler => 'tmpl', plugins => ['SLASH_VAR']);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is($test1);
$t->get_ok('/slash_var')->status_is(200)->content_like(qr/$test2/);

done_testing();
