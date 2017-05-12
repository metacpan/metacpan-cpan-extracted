#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
use Moose::Test::Case;

my @calls;

my $tester = Moose::Test::Case->new;

$tester->run_tests(
    map {
        my $hook = $_;

        $hook => sub {
            push @calls, [ $hook => @_ ]
        },
    } qw/before_first_pm before_pm after_pm after_last_pm
         before_first_t  before_t  after_t  after_last_t/
);

is_deeply([splice @calls], [
    [ before_first_pm => () ],
    [ before_pm       => $tester->test_dir->file('001_Foo.pm')->stringify ],
    [ after_pm        => $tester->test_dir->file('001_Foo.pm')->stringify ],
    [ before_pm       => $tester->test_dir->file('002_Bar.pm')->stringify ],
    [ after_pm        => $tester->test_dir->file('002_Bar.pm')->stringify ],
    [ after_last_pm   => () ],

    [ before_first_t => () ],
    [ before_t       => $tester->test_dir->file('001_test_Foo.pl')->stringify ],
    [ after_t        => $tester->test_dir->file('001_test_Foo.pl')->stringify ],
    [ before_t       => $tester->test_dir->file('002_test_Bar.pl')->stringify ],
    [ after_t        => $tester->test_dir->file('002_test_Bar.pl')->stringify ],
    [ after_last_t   => () ],
], "we can hook into any interesting point in run_tests");

