use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  my $premature_connection_error_counter = 0;
  get 'premature_connection_error' => sub {
    if ($premature_connection_error_counter) {
      return shift->render( text => $premature_connection_error_counter );
    }
    else {
      $premature_connection_error_counter++;
      return;
    }
  };
}

my $t = Test::Mojo->new;
$t->ua(
  Mojo::UserAgent->with_roles('+Retry')->new( retries => 1 )->request_timeout(1)
);
$t->get_ok('/premature_connection_error')->status_is(200)->content_is(1);

done_testing;
