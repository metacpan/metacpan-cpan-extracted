package t::lib::ExportComplex;
use strict;
use warnings;

use Exporter;
our @ISA       = qw/Exporter/;
our @EXPORT    = qw/foo bar/;
our @EXPORT_OK = qw/baz bam/;

sub foo { 1 }

sub bar { 2 }

sub baz { 3 }

sub bam { 4 }

sub bamboozle { 99 } # not exported at all

1;

