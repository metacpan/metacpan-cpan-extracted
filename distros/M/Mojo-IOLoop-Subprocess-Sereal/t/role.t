use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;

my $subprocess = Mojo::IOLoop->subprocess;
my $old_serialize = $subprocess->serialize;
my $old_deserialize = $subprocess->deserialize;
$subprocess->with_roles('Mojo::IOLoop::Subprocess::Role::Sereal')->with_sereal;
isnt 0+$old_serialize, 0+$subprocess->serialize, 'different serialize code';
isnt 0+$old_deserialize, 0+$subprocess->deserialize, 'different deserialize code';

my ($fail, $result);
$subprocess->run(
  sub { qr/$$/ },
  sub {
    my ($subprocess, $err, $re) = @_;
    $fail = $err;
    $result = qr/\A(?:$result|$re)\z/;
  }
);
$result = qr/$$/;
Mojo::IOLoop->start;
ok !$fail, 'no error';
like $$, $result, 'regex matches parent pid';
like $subprocess->pid, $result, 'regex matches subprocess pid';

done_testing;
