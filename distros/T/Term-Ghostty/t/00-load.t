use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Term::Ghostty') || BAIL_OUT("Failed to load Term::Ghostty");
}

like(Term::Ghostty->lib_version, qr/^\d+\.\d+\.\d+/, 'lib_version');

diag("Testing Term::Ghostty $Term::Ghostty::VERSION, libghostty-vt "
   . Term::Ghostty->lib_version . ", Perl $], $^X");
