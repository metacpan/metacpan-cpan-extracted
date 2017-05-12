#!perl
use strict;
use warnings;
BEGIN {
    unshift @INC, 'inc';

    # author requires, or bundled modules
    my @devmods = qw(
        Module::Install::AuthorTests
        Module::Install::Repository
    );

    my @not_available;

    {
        $|=1; # ref RT #115206
        local *STDOUT;
        eval qq{use inc::Module::Install; 1;} or push @not_available, 'inc::Module::Install';
    }

    for my $mod (@devmods) {
        eval qq{require $mod} or push @not_available, $mod;
    }
    if (@not_available) {
        print qq{# The following modules are not available.\n};
        print qq{# `$^X $0 | cpanm` will install them:\n};
        print $_, "\n" for @not_available;
        print "\n";
        exit -1;
    }
}
use inc::Module::Install;
$Module::Install::AUTHOR = 0 if $ENV{TRAVIS};

all_from 'lib/Test/Deep/Cond.pm';

requires 'Test::Deep';
requires 'Exporter::Lite';

test_requires 'Test::More'     => '0.88';
test_requires 'Test::Requires' => '0.06';
test_requires 'Test::Tester';

auto_set_repository;

tests_recursive;
author_tests 'xt';


clean_files qw(
    Test-Deep-Cond-*
    *.stackdump
    cover_db *.gcov *.gcda *.gcno
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
