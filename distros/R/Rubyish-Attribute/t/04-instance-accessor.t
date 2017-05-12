use strict;
use warnings;

use lib 't/lib';
use Animal;

use Test::More;

plan tests => 5;

my $oreo = Animal->new({
  name  => "oreo",
  color => "black",
  type  => "unknown",
});

can_ok  $oreo,                              qw(__name__ __color__ __type__);

is      $oreo->instant_name("hello"),       "hello";
is      $oreo->instant_color,               "black";
is      $oreo->instant_type,                "unknown";

eval { $oreo->__name__ };
like    $@,                                 qr(protected),                          $@;

