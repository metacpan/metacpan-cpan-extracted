
# NOTE: I couldn't reproduce the locale issues reported in 
# 
# https://rt.cpan.org/Ticket/Display.html?id=100943&results=5e852469797988f08410e6f642a6a5c8
# http://www.cpantesters.org/cpan/report/88d524a8-6322-11e4-b29a-6ad5dfbfc7aa
# 
# I was trying things like LC_ALL=de_DE.utf8; sudo locale-gen de_DE.utf8
# and it was messing up my vim sessions, but not the tests …

use strict;
no warnings;

# from SREZIC commit:
# https://github.com/eserte/statistics--basic/commit/5a4b4c434a53e4315c74ab120ca82498f54987a0

    use Statistics::Basic ();
    # Make sure Number::Format is using a decimal point.
    # See https://rt.cpan.org/Ticket/Display.html?id=100943
    $Statistics::Basic::fmt = Number::Format->new(-decimal_point => '.');


# another SREZIC suggestion, which may not be as portable
#   use POSIX qw(setlocale LC_NUMERIC);
#   setlocale LC_NUMERIC, (
#       $ENV{BREAK_TESTS_WITH_GERMAN}
#       ? "de_DE"
#       : "C"
#   );

1;
