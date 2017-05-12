use strict;
use warnings;

use Test;
use IPC::Run 'run';

my $tests = 4;
plan tests => $tests;

my @cmd = ($^X, -CA => qw(bin/hi test\\d+ _hashed_ test: ocean));

my $in;
   $in .= "test: test$_\n" for 1 .. $tests;
   $in .= "test: test3 test4 test1 test2\n";

run \@cmd, \$in, \my $out, sub { die "@_" };

my @lines = split m/\s*[\x0d\x0a]\s*/, $out;

my @t;
for( 1 .. $tests ) {
    my $t = shift @lines;
    $t =~ s/.*test:\S*\s//;
    push @t, $t;
}

for( @t ) {
    ok( $lines[0] =~ m/\Q$_\E/ );
}
