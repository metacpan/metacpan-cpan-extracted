package t::Utils;

use strict;
use warnings;
use utf8;
use lib './t/lib';
use FindBin;
use Test::More;

sub import {
    my $caller = caller;
    {
        no strict 'refs';
        no warnings 'redefine';
        *{ $caller.'::get_file_contents' } = \&get_file_contents;
        *{ $caller.'::get_file_path' } = \&get_file_path;
        *{ $caller.'::tests' } = sub (&) {
            my ($code) = @_;

            if ($ENV{LEAK_TEST}) {
                eval "use Test::LeakTrace ();"; die $@ if $@;
                no warnings 'prototype';
                *{ $caller . '::' . $_ } = sub {}
                    for grep { $_ ne 'done_testing' } @Test::More::EXPORT;
                use warnings;
                Test::LeakTrace::no_leaks_ok(sub { $code->() }, 'no leaks ok');
            }
            else {
                $code->();
            }
        }
    }
    strict->import;
    warnings->import;
    utf8->import;
}

sub get_file_contents {
    my $filepath = $FindBin::Bin.'/'.shift;
    open my $fh, $filepath or die "$!: $filepath";
    my $data = do { local $/; <$fh> };
    close $fh;
    return $data;
}

sub get_file_path {
    return $FindBin::Bin.'/'.shift;
}

1;
