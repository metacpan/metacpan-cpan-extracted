package
  FakeLogin;

use strict;
use warnings;
use Shell::Guess;

do {
  no warnings 'redefine';

  sub Shell::Guess::login_shell
  {
    return Shell::Guess->bourne_shell();
  }
};

1;
