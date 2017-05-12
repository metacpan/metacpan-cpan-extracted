#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 8 + 1;
use Test::Warnings;
use Data::Dumper qw/Dumper/;

my $module = 'Tail::Tool::Plugin::Spacing';
use_ok( $module );

my $space = $module->new(
    times => [ 5, 50 ],
    lines => [ 2, 18 ],
);
ok $space, 'Can create a new object';

my $line = "test\n";
my @lines = $space->process($line);
ok @lines == 1, 'Get one line back for first time';
is $lines[0], $line, 'Get the line passed in back';

$space->last_time( time - 6 );
@lines = $space->process($line);
ok @lines == 3, 'Get 3 lines back for first time';
is_deeply \@lines, ["\n", "\n", $line], 'Get the line passed in back preceeded by 2 blank lines';

$space->last_time( time - 60 );
@lines = $space->process($line);
ok @lines == 21, 'Get 21 lines back for first time';
is_deeply \@lines, [ ( "\n" ) x 20, $line], 'Get the line passed in back preceeded by 20 blank lines';

