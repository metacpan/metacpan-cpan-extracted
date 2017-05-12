#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use PerlX::MethodCallWithBlock;
use Test::More;
use autobox;
use autobox::Core;

[0..9]->map {
    2 * $_
}->map {
    is($_ % 2, 0, "$_ mod 2 is 0");
};

my $z = [0..10]
->map { $_ * 13 }
->map { $_ % 17 }
->sort { $_[0] <=> $_[1] }
->map { pass("test $_"); $_ };

is_deeply($z, ["0","1","2","5","6","9","10","11","13","14","15"], "verify the content after the transform");

done_testing;

