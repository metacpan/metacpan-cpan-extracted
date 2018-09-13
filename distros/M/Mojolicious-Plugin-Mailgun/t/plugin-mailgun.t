use Mojolicious::Lite;
BEGIN { $ENV{MAILGUN_TEST} = 1; }

plugin 'Mailgun', main => {domain => 'test.no', api_key => 123};

get '/' => sub {
  my $self = shift;

    $self->render_later;
    $self->mailgun->send(main => {subject => 'Test'}, sub  {
      my ($ua, $tx)=@_;
      $self->render(json => $tx->result->json);
    }
  );
};

get '/promise' => sub {
  my $self = shift;

    $self->render_later;
    $self->mailgun->send_p(main => {subject => 'Test'})->then(
    sub {
      my $tx=shift;
      $self->render(json => $tx->result->json);
    }
  );
};


use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/', "Get testing")->status_is(200)
  ->json_is('/params/subject', 'Test');
$t->get_ok('/promise', "Get testing")->status_is(200)
  ->json_is('/params/subject', 'Test');

done_testing;
