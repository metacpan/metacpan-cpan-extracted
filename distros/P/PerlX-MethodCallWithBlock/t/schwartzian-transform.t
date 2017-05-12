#!/usr/bin/env perl
#
# The purpose of this test is to see now many different kinds of code indentation
# of the same schwartzian transform are supported.
#
# Therefore, do not re-indent the code.
#
use strict;
use warnings;
use 5.010;
use PerlX::MethodCallWithBlock;
use Test::More;
use autobox;
use autobox::Core;

my $data = [];

while(<DATA>) { chomp; push @$data, $_ }

my $sorted = $data
    ->map(sub { [$_, split/ /] })
    ->sort(sub { $_[0]->[-1] cmp $_[1]->[-1] })
    ->map(sub { $$_[0] });


my $sorted2 = $data->map { [$_, split/ /] }
    ->sort { $_[0]->[-1] cmp $_[1]->[-1] }
    ->map  { $$_[0] };

foreach (0..$#$sorted) {
    is($sorted->[$_], $sorted2->[$_]);
}

done_testing;

__DATA__
admin:Charlie Root
gugod:Kang-min Liu
ingy:Ingy dot Net
miyagawa:Miyagawa Tatsuhiko
