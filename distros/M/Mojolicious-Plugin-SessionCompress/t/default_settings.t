BEGIN {
  $ENV{MOJO_NO_IPV6} = 1;
}

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojolicious::Lite;
use Test::Mojo;


plugin 'SessionCompress';
get '/sessionsmall' => sub {
  my $self = shift;

  return $self->render(text => 'Hello ' . $self->session('user_name')) if ($self->session('user_name'));
  $self->session(user_name => 'Small_user');
  $self->render(text => 'Session set');
};

get '/sessionbig' => sub {
  my $self = shift;

  return $self->render(text => 'Hello ' . $self->session('user_name')) if ($self->session('user_name'));
  $self->session(user_name => 'Big_user', big_session =>
    '3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679' .
    '8214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196' .
    '4428810975665933446128475648233786783165271201909145648566923460348610454326648213393607260249141273' .
    '724587006606315588174881520920962829254091715364367892590360011330530548820466521384146951941511609' x 3);
  $self->render(text => 'Session set');
};

my $t = Test::Mojo->new;
$t->get_ok('/sessionsmall')->status_is(200)->content_is('Session set');
$t->get_ok('/sessionsmall')->status_is(200)->content_is('Hello Small_user');
$t->reset_session;
$t->get_ok('/sessionbig')->status_is(200)->content_is('Session set');
$t->get_ok('/sessionbig')->status_is(200)->content_is('Hello Big_user');
done_testing();