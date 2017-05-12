#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More tests => 31;
use Test::Exception;

BEGIN {
    use_ok('Path::Class::Versioned');
}

my @FILES_TO_DELETE;

my $SCRATCH_DIR = Path::Class::Dir->new($FindBin::Bin, 'scratch');

foreach my $i (1 .. 5) {
    my $time = time();

    foreach my $j (1, 2) {
        my $v = Path::Class::Versioned->new(
            version_format => '%02d',
            name_pattern   => [ 'Baz-', $time ,'-v', undef, '.txt' ],
            parent         => $SCRATCH_DIR
        );
        isa_ok($v, 'Path::Class::Versioned');

        push @FILES_TO_DELETE => $v->next_name;

        is($v->next_name, ("Baz-${time}-v" . sprintf("%02d", $j) . ".txt"), '... got the right next filename');
        my $f = $v->next_file;
        isa_ok($f, 'Path::Class::File');
        $f->touch;
    }

    sleep(1);
}

$SCRATCH_DIR->file($_)->remove foreach @FILES_TO_DELETE;




