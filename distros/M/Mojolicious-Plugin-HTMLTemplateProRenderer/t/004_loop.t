use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

#plugin 'HTMLTemplateProRenderer', tmpl_opts => {use_extension => 1};
plugin 'HTMLTemplateProRenderer';

my $test1 = [{row => 'First row'},{row => 'Second row'}];

get '/' => sub {
  my $self = shift;
  $self->stash(loop => $test1);
  $self->render(inline => '<ul><TMPL_LOOP NAME="loop"><li><TMPL_VAR NAME="row"></li></TMPL_LOOP></ul>',
  handler => 'tmpl');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_like(qr/$test1->[1]->{row}/);

done_testing();
