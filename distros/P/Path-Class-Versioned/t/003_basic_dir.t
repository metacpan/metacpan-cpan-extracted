#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More tests => 12;
use Test::Exception;

BEGIN {
    use_ok('Path::Class::Versioned');
}

my @FILES_TO_DELETE;
my $SCRATCH_DIR = Path::Class::Dir->new($FindBin::Bin, 'scratch');

my $v = Path::Class::Versioned->new(
    version_format => '%03d',
    name_pattern   => [ 'Test_', undef ],
    parent         => $SCRATCH_DIR
);
isa_ok($v, 'Path::Class::Versioned');

foreach my $i (1 .. 5) {
    push @FILES_TO_DELETE => $v->next_name(dir => 1);
    is($v->next_name(dir => 1), ('Test_' . (sprintf "%03d" => $i)), '... got the right next filename');
    my $f = $v->next_dir;
    isa_ok($f, 'Path::Class::Dir');
    $f->mkpath;
}

$SCRATCH_DIR->subdir($_)->remove foreach @FILES_TO_DELETE;


