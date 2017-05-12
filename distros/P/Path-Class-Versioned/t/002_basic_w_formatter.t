#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More tests => 16;
use Test::Exception;

BEGIN {
    use_ok('Path::Class::Versioned');
}

my @FILES_TO_DELETE;
my $SCRATCH_DIR = Path::Class::Dir->new($FindBin::Bin, 'scratch');

my $v = Path::Class::Versioned->new(
    version_format => '%04d',
    name_pattern   => [ 'Bar-2008-05-14-v', undef, '.txt' ],
    parent         => $SCRATCH_DIR
);
isa_ok($v, 'Path::Class::Versioned');

foreach my $i (4 .. 10) {
    push @FILES_TO_DELETE => $v->next_name;
    is($v->next_name, ('Bar-2008-05-14-v' . (sprintf "%04d" => $i) . '.txt'), '... got the right next filename');
    my $f = $v->next_file;
    isa_ok($f, 'Path::Class::File');
    $f->touch;
}

$SCRATCH_DIR->file($_)->remove foreach @FILES_TO_DELETE;


