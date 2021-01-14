use strict;
use warnings;

use Test::More;

{
  package Local::R1;
  use Role::Tiny;
  sub method { 1 };
}

{
  package Local::R2;
  use Role::Tiny;
  sub method { 2 };
}

ok(
  !eval {
    package Local::C1;
    use Role::Tiny::With;
    with qw(Local::R1 Local::R2);
    1;
  },
  'method conflict dies',
);

like(
  $@,
  qr{^Due to a method name conflict between roles 'Local::R.' and 'Local::R.', the method 'method' must be implemented by 'Local::C1'},
  '... with correct error message',
);

ok(
  eval {
    package Local::C2;
    use Role::Tiny::With;
    with qw(Local::R1 Local::R2);
    sub method { 3 };
    1;
  },
  '... but can be resolved',
);

is(
  "Local::C2"->method,
  3,
  "... which works properly",
);

done_testing;
