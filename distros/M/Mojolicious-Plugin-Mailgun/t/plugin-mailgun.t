use Mojolicious::Lite;
BEGIN { $ENV{MAILGUN_TEST} = 1; }

plugin 'Mailgun', main => {domain => 'test.no', api_key => 123};

get '/' => sub {
  my $self = shift;

  $self->delay(
    sub {
      my $delay = shift;
      my $res
        = $self->mailgun->send(main => {subject => 'Test'}, $delay->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      $self->render(json => $tx->result->json);
    }
  );
};

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/', "Get testing")->status_is(200)
  ->json_is('/params/subject', 'Test');

done_testing;
