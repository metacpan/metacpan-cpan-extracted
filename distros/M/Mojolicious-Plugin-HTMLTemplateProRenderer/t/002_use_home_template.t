use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'HTMLTemplateProRenderer', tmpl_opts => {use_home_template => 1};

my $test4 = 'HTML::Template::Pro Base App Template test';

get '/template_base_app' => sub {
  my $self = shift;
  $self->stash(t1 => $test4);
  $self->render('template_base_app', handler => 'tmpl');
};

my $t = Test::Mojo->new;
$t->get_ok('/template_base_app')->status_is(200)->content_like(qr/$test4/);

done_testing();
