#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 92;

use lib 'lib';
use Perl6::Caller;

my @methods = qw/package filename line subroutine hasargs
  wantarray evaltext is_require/;

my %pos_for;
foreach my $i ( 0 .. $#methods ) {
    $pos_for{ $methods[$i] } = $i;
}

can_ok 'Perl6::Caller', 'new';
my $caller = Perl6::Caller->new;
isa_ok $caller, 'Perl6::Caller',
  '... and the object it returns';

is $caller->package, undef,
  '... and it should return the correct package name when asked';
is $caller->package, scalar CORE::caller,
  '... and match what CORE::caller says';

$caller = caller;
isa_ok $caller, 'Perl6::Caller',
  '... and the object it returns';

is $caller->package, undef,
  '... and it should return the correct package name when asked';

my $line1 = $caller->line;
my $line2 = $caller->line;
is $line1, $line2,
  '... calling methods on the same object respect original caller position';

run_frame1_tests();
eval {
    for ( 0 .. 2 ) {
        my @caller = caller($_);
        foreach my $method (@methods) {
            is_deeply caller($_)->$method, $caller[ $pos_for{$method} ],
              "eval {} Caller should have the correct frame ($_) result for '$method'";
        }
    }
};

sub run_frame1_tests {
    my @caller = caller(0);
    foreach my $method (@methods) {
        is( caller->$method, $caller[ $pos_for{$method} ],
            "Caller should have the correct result for '$method'"
        );
    }
    for ( 0 .. 2 ) {
        my @caller = caller($_);
        foreach my $method (@methods) {
            is_deeply caller($_)->$method, $caller[ $pos_for{$method} ],
              "Caller should have the correct frame ($_) result for '$method'";
        }
    }

    {
        package Frame2;
        ::run_frame2_tests(3);
    }
}

sub run_frame2_tests {
my $caller = Perl6::Caller->new;
isa_ok $caller, 'Perl6::Caller',
  '... and the object it returns';

is $caller->package, 'Frame2',
  '... and it should return the correct package name when asked';
is $caller->package, scalar CORE::caller,
  '... and match what CORE::caller says';

$caller = caller;
isa_ok $caller, 'Perl6::Caller',
  '... and the object it returns';

is $caller->package, 'Frame2',
  '... and it should return the correct package name when asked';

    for ( 0 .. 2 ) {
        my @caller = caller($_);
        foreach my $method (@methods) {
            is_deeply caller($_)->$method, $caller[ $pos_for{$method} ],
              "Caller should have the correct frame ($_) result for '$method'";
        }
    }
}
