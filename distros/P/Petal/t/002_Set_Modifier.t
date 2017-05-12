#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/set_modifier';
$Petal::MEMORY_CACHE = 0;
$Petal::DISK_CACHE   = 0;

my $petal = new Petal ('index.xml');

my $res = $petal->process (
    title => '__TAG__',
    settest => 'blah'
);

# test that we have __TAG__ twice
my @capture = ($res =~ /(__TAG__)/g);
is (scalar @capture,2);


1;


__END__
