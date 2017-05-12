#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Exception;

BEGIN {
    eval "use DateTime;";
    plan skip_all => "DateTime is required for this test" if $@;
    plan tests => 12;
    use_ok('Path::Class::Versioned');
}

{
    package AdHoc::DateTime::Formatter;
    use Moose;

    sub format_datetime {
        my ($self, $datetime) = @_;
        $datetime->strftime("%Y-%m-%d");
    }
}

my @FILES_TO_DELETE;

my $SCRATCH_DIR = Path::Class::Dir->new($FindBin::Bin, 'scratch');

my $date = DateTime->now(formatter => AdHoc::DateTime::Formatter->new);

my $v = Path::Class::Versioned->new(
    version_format => '%02d',
    name_pattern   => [ 'Baz-', $date ,'-v', undef, '.txt' ],
    parent         => $SCRATCH_DIR
);
isa_ok($v, 'Path::Class::Versioned');

foreach my $i (1 .. 5) {
    push @FILES_TO_DELETE => $v->next_name;
    is($v->next_name, ("Baz-${date}-v" . sprintf("%02d", $i) . ".txt"), '... got the right next filename');
    my $f = $v->next_file;
    isa_ok($f, 'Path::Class::File');
    $f->touch;
}

$SCRATCH_DIR->file($_)->remove foreach @FILES_TO_DELETE;




