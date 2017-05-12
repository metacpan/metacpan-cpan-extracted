BEGIN {
  $ENV{MOJO_NO_IPV6} = 1;
}

use Test::More tests => 22;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojolicious::Lite;
use Test::Mojo;

use Compress::Zlib qw(deflateInit inflateInit Z_STREAM_END);
use Data::Dumper 'Dumper';
$Data::Dumper::Terse = 1;


plugin session_compress => {
  compress => sub {
    my $string = shift;

    ok(1, 'Used custom compress');
    my $d = deflateInit(-Level => 1, -memLevel => 5, -WindowBits => -15);
    return $d->deflate($string) . $d->flush;
  },
  decompress => sub {
    my $string = $_[0];

    ok(1, 'Used custom decompress');
    my $d = inflateInit(-WindowBits => -15);
    my ($inflated, $status) = $d->inflate($string);
    # Check to see if it's actually compressed
    return $_[0] if $status != Z_STREAM_END || length($inflated) <= 1;
    return $inflated;
  },
  serialize => sub {
    my $hashref = shift;

    ok(1, 'Used custom serialize');
    return Dumper($hashref);
  },
  deserialize => sub {
    my $string = shift;

    ok(1, 'Used custom deserialize');
    eval $string;
  },
  min_size => 100
};

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
    '3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679');
  $self->render(text => 'Session set');
};

my $t = Test::Mojo->new;
$t->get_ok('/sessionsmall')->status_is(200)->content_is('Session set');
$t->get_ok('/sessionsmall')->status_is(200)->content_is('Hello Small_user');
$t->reset_session;
$t->get_ok('/sessionbig')->status_is(200)->content_is('Session set');
$t->get_ok('/sessionbig')->status_is(200)->content_is('Hello Big_user');
done_testing();