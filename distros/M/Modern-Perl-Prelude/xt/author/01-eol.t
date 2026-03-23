use v5.30;
use strict;
use warnings;

use Test::More;

eval {
    require Test::EOL;
    Test::EOL->import;
    1;
} or plan skip_all => 'Test::EOL is required for author tests';

my @files = qw(
    lib/Modern/Perl/Prelude.pm
    t/00-load.t
    t/01-import.t
    t/02-no.t
    t/03-args.t
    t/04-class-defer.t
    t/05-corinna.t
    t/06-always-true.t
    xt/author/00-pod.t
    xt/author/01-eol.t
    xt/author/02-pod-coverage.t
    Makefile.PL
);

eol_unix_ok($_) for @files;

done_testing;
