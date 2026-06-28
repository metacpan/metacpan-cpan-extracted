#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

BEGIN { use_ok('PDF::Make::Builder') }

my $img_file = 't/fixtures/images/test.png';

SKIP: {
    skip 'test image not found', 6 unless -f $img_file;

    # ── Image with auto height (aspect ratio) ──────────

    {
        my $f = tmpnam() . '.pdf';
        my $b = PDF::Make::Builder->new(file_name => $f);
        $b->add_page(page_size => 'Letter');

        # Only width, no height → triggers aspect ratio branch
        eval { $b->add_image(image => $img_file, w => 100) };
        ok(!$@, 'image with auto height') or diag $@;

        $b->save;
        ok(-f $f, 'image auto-height PDF');
        unlink $f;
    }

    # ── Image with explicit y coordinate ────────────────

    {
        my $f = tmpnam() . '.pdf';
        my $b = PDF::Make::Builder->new(file_name => $f);
        $b->add_page(page_size => 'Letter');

        eval { $b->add_image(image => $img_file, w => 80, h => 80, y => 500) };
        ok(!$@, 'image with explicit y') or diag $@;

        $b->save;
        ok(-f $f, 'image explicit-y PDF');
        unlink $f;
    }

    # ── Image with center alignment ─────────────────────

    {
        my $f = tmpnam() . '.pdf';
        my $b = PDF::Make::Builder->new(file_name => $f);
        $b->add_page(page_size => 'Letter');

        eval { $b->add_image(image => $img_file, w => 100, h => 100, align => 'center') };
        ok(!$@, 'image center aligned') or diag $@;

        $b->save;
        ok(-f $f, 'image center PDF');
        unlink $f;
    }
}

done_testing;
