#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use PFT::Content;
use PFT::Header;
use PFT::Date;

use File::Temp qw/tempdir/;
use File::Spec;

use Encode;
use Encode::Locale;

use Test::More;

my $use_utf8 = $Encode::Locale::ENCODING_LOCALE =~ /UTF-8/i;

my $dir = tempdir(CLEANUP => 1);
my $path = $use_utf8 ? File::Spec->catfile($dir, 'öéåñ') : ''.$dir;

mkdir encode(locale => $path);
my $tree = PFT::Content->new($path);

do {
    my $date = PFT::Date->new(0, 12, 25);
    my $p = $tree->new_entry(PFT::Header->new(
        title => ($use_utf8 ? 'foo-♥-baz' : 'foo-baz'),
        date => $date,
    ));
    is_deeply($tree->detect_date($p), $date, 'Path-to-date')
};
do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => ($use_utf8 ? 'foo-bar-☺az' : 'foo-bar-baz'),
    ));
    is($tree->detect_date($p), undef, 'Path-to-date, no date')
};

# Testing blog_at and blog_back
do {
    my @entered;
    for my $y (2014, 2015) {
        for my $m (1, 2, 3) {
            for my $d (10, 11, 12, 13) {
                push @entered, $tree->new_entry(PFT::Header->new(
                    title => 'who cares of titles',
                    date => PFT::Date->new($y, $m, $d),
                ));
            }
        }
    }

    my @found;
    @found = $tree->blog_at(PFT::Date->new(undef, undef, 11));
    is(scalar @found, 2 * 3, "blog_at: right amount for day 11");
    is(scalar @found, grep($_->header->date->d == 11, @found),
        "blog_at: all of day 11"
    );

    @found = $tree->blog_at(PFT::Date->new(undef, 3, undef));
    is(scalar @found, 2 * 4, "blog_at: right amount for month 3");
    is(scalar @found, grep($_->header->date->m == 3, @found),
        "blog_at: all of month 3"
    );

    @found = $tree->blog_at(PFT::Date->new(2014, undef, undef));
    is(scalar @found, 3 * 4, "blog_at: right amount for year 2014");
    is(scalar @found, grep($_->header->date->y == 2014, @found),
        "blog_at: all of year 2014"
    );

    for (my $i = 0; $i < @entered; $i ++) {
        @found = $tree->blog_back($i);
        is(scalar @found, 1, "blog_back($i) has one entry");
        cmp_ok($found[0] => cmp => $entered[-$i], "blog_back($i) compares well");
    }

    # We add this, so 2015/3/12 (one day before last entry) has two entries.
    push @entered, $tree->new_entry(PFT::Header->new(
        title => 'I care of titles!',
        date => PFT::Date->new(2015, 3, 12),
    ));

    @found = $tree->blog_back(1);
    is(scalar @found, 2, "blog_back(1) with additional entry");
    cmp_ok($found[0] => cmp => $entered[-2], 'compares well');
    cmp_ok($found[1] => cmp => $entered[-1], 'compares really well');

};

# Testing slug detection
do {
    my $title = $use_utf8 ? 'foo-öar-baz' : 'foo-plah-baz';
    my $p = $tree->new_entry(PFT::Header->new(
        title => $title
    ));
    diag($tree->detect_slug($p));
    is($tree->detect_slug($p), $title, 'Path-to-slug 1');
};
do {
    my $p = $tree->new_entry(PFT::Header->new(
        title => $use_utf8 ? 'foo²bar☺baz' : 'foo/bar\baz',
        date => PFT::Date->new(0, 12, 25),
    ));
    is($tree->detect_slug($p), 'foo-bar-baz', 'Path-to-slug 2')
};

# Testing make_consistent function
do {
    my $hdr = PFT::Header->new(
        title => 'one',
        date => PFT::Date->new(10, 11, 12),
    );

    my $e = $tree->new_entry($hdr);
    $e->set_header(PFT::Header->new(
        title => 'two',
        date => PFT::Date->new(10, 12, 14),
    ));

    ok($e->path =~ /0010-11.*12-one/, 'Original path');
    my $orig_path = $e->path;
    $e->make_consistent;
    ok($e->path !~ /0010-11.*12-one/, 'Not original path');
    ok(!-e $orig_path && -e $e->path, 'Actually moved');
    ok($e->path =~ /0010-12.*14-two/, 'New path');
};

done_testing()
