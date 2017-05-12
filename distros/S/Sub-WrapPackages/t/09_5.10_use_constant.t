#!/usr/bin/perl -w

my $r;
my $skip;

use strict;

BEGIN {
  eval 'use 5.010';
  $skip = $@;
  $| = 1; print "1..1\n" unless($skip);
}

if ($skip) {
    $skip =~ s/--.*$//xs;
    print "1..0\n";
    print "skip ... $skip\n";
    exit;
}

eval '
  use lib "t/lib"; use breakuseconstant;
  use Sub::WrapPackages (
    packages => [qw(breakuseconstant)],
    pre => sub {
        $r .= "before";
    },
    post => sub {
        $r .= "after";
    }
  );

my $test = 0;

$r .= breakuseconstant::FOO;

print "not " unless($r eq "i am a constant i am i am");
print "ok ".(++$test)." use constant does not wrap\n";
';
