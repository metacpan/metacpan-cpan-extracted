use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'HTMLTemplateProRenderer';

my $test1 = 'Hello Mojo!';
my $test2 = 'HTML::Template::Pro Inline test';
my $test3 = 'HTML::Template::Pro Template test';
my $test4 = 'HTML::Template::Pro Base App Template test';
my $test5 = 'HTML::Template::Pro Inline __DATA__ test';

get '/' => sub {
  my $self = shift;
  $self->render(text => $test1);
};

get '/inline' => sub {
  my $self = shift;
  $self->stash(t1 => $test2);
  $self->render(inline => '<p><TMPL_VAR NAME="t1"></p>', handler => 'tmpl');
};

get '/template1' => sub {
  my $self = shift;
  $self->stash(t1 => $test3);
  $self->render('template1', handler => 'tmpl');
};

get '/template_base_app' => sub {
  my $self = shift;
  $self->stash(t1 => $test4);
  $self->render('template_base_app', handler => 'tmpl',use_home_template => 1);
};

get '/inline_data' => sub {
  my $self = shift;
  $self->stash(t1 => $test5);
  $self->render('inline_data', handler => 'tmpl');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is($test1);
$t->get_ok('/inline')->status_is(200)->content_like(qr/$test2/);
$t->get_ok('/template1')->status_is(200)->content_like(qr/$test3/);
$t->get_ok('/template_base_app')->status_is(200)->content_like(qr/$test4/);
$t->get_ok('/inline_data')->status_is(200)->content_like(qr/$test5/);

done_testing();

__DATA__

@@inline_data.html.tmpl
<p><TMPL_VAR NAME="t1"></p>
