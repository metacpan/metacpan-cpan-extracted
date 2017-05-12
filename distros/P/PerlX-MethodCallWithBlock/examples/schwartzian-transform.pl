#!/usr/bin/env perl -w
use strict;
use warnings;
use lib '../lib';
use 5.010;

use PerlX::MethodCallWithBlock;
use autobox;
use autobox::Core;

my $data = [];
while(<DATA>) { chomp; push @$data, $_ };

my $sorted = $data->map { [$_, split/[: ]/] }
    ->sort { $_[0]->[-1] cmp $_[1]->[-1] }
    ->map  { $$_[0] };

$sorted->each{say @_};

__DATA__
admin:Charlie Root
gugod:Kang-min Liu
ingy:Ingy dot Net
miyagawa:Miyagawa Tatsuhiko
