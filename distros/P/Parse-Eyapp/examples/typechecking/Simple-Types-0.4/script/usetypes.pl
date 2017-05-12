#!/usr/bin/perl -w
use strict;
use Simple::Types;
use Parse::Eyapp::Base qw(:all);
my $filename = shift || die "Usage:\n$0 file.c\n";
my $debug = shift;
$debug = 0 unless defined($debug);
my $input = slurp_file($filename, "c");
print numbered($input) if ($debug);
my $parser = Simple::Types->new();
my $t = $parser->compile($input);
Simple::Types::show_trees($t, $debug);
