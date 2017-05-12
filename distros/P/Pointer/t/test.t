use lib 'lib';
use strict;
use Test::More tests => 6;
use Config;
use Pointer;
use Pointer::int;
use Pointer::sv;

ok(pointer('sv')->of_scalar('12345')->sv_flags & SVf_POK);

is(pointer->of_scalar('Hello')->get_pointer->get_pointer->get_string,
   'Hello',
  );

my $xyz = 42;
is((pointer('int')->of_scalar($xyz) - 1)->type, 'int');
my $flags = '01010501';
$flags = join '', reverse $flags =~ /(..)/g
  if $Config{byteorder} =~ /^1234/;
is((pointer('int')->of_scalar($xyz) + 2)->get_hex, $flags);

is((pointer->of_scalar(42)->get_pointer('int') + 3)->get, 42);

my $x = 1;
my $rx = \$x;
is((pointer('int')->of_scalar($x) + 1)->get, 2);
