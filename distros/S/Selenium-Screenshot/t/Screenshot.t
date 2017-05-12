#! /usr/bin/perl

use strict;
use warnings;
use FindBin;
use Imager;
use MIME::Base64;
use Test::More;

BEGIN: {
    unless (use_ok('Selenium::Screenshot')) {
        BAIL_OUT("Couldn't load Selenium::Screenshot");
        exit;
    }
}

my $string = 'fake-encoded-string';
my $fixture_dir = $FindBin::Bin . '/screenshots/';

cleanup_test_dir();
my $basic_args = {
    png => Imager->new( xsize => 16, ysize => 16 ),
    folder => $fixture_dir
};
my $screenshot = Selenium::Screenshot->new(%$basic_args);

my $sample_png = $FindBin::Bin . '/sample.png';
open (my $image_fh, "<", $sample_png) or die 'cannot open: ' . $!;
binmode $image_fh;
my $png_string = encode_base64( do{ local $/ = undef; <$image_fh>; } );
close ($image_fh);

FILENAME: {
    my $timestamp = Selenium::Screenshot->new(
        %$basic_args
    )->filename;
    cmp_ok($timestamp , '=~', qr/\d+\.png/, 'filename works for timestamp');

    my $metadata = Selenium::Screenshot->new(
        %$basic_args,
        metadata => {
            key => 'value'
        }
    )->filename;
    cmp_ok($metadata , '=~', qr/value\.png/, 'filename works for metadata');

    my $shadow = Selenium::Screenshot->new(
        %$basic_args,
        metadata => {
            key => 'value'
        }
    )->filename(
        key => 'shadow'
    );
    cmp_ok($shadow , '=~', qr/shadow\.png/, 'filename works for shadowed metadata');

    my $ref = Selenium::Screenshot->new(
        %$basic_args,
        png => $png_string
    );

    cmp_ok($ref->reference, '=~', qr/-reference\.png$/, 'reference filename works');
    ok( ! $ref->find_opponent, 'can find out that reference is missing');

    $ref->save_reference;
    ok(-e $ref->reference, 'saving reference writes to disk');
    ok( $ref->find_opponent, 'can find out that reference is present');
}

OPPONENT: {
    my $screenshot = Selenium::Screenshot->new(
        png => $png_string,
        metadata => {
            something => 'unique'
        },
        folder => $fixture_dir
    );

    my $undef = $screenshot->_set_opponent;
    ok( ! $undef, 'no opponent and no reference is short circuited' );

    my $def = $screenshot->_set_opponent( Imager->new( file => $sample_png ) );
    ok( $def, 'an opponent without a reference is found');

    $screenshot->save_reference;
    ok ($screenshot->_set_opponent, 'no reference with an opponent is found');
}

METADATA: {
    my $meta_args = $basic_args;
    $meta_args->{png} = $png_string;
    $meta_args->{metadata} = {
        url     => 'http://fake.url.com',
        build   => 'random-12347102.238402-build',
        browser => 'firefox'
    };
    my $meta_shot = Selenium::Screenshot->new(%$meta_args);
    my $filename = $meta_shot->save(override => 'extra');
    ok(-e $filename, 'save function writes to disk');
    ok($filename =~ /fake.url/, 'meta data is used in filename');
    ok($filename =~ /random\-1234/, 'meta data is used in filename');
    ok($filename =~ /firefox/, 'meta data is used in filename');
    ok($filename =~ /extra/, 'override metadata is used in filename');
}

DIRTY_STRINGS: {
    my %tests = (
        'pass-through.123'                => 'pass-through.123',
        'spaces '                         => 'spaces-',
        'http://www.url-like.com'         => 'http---www.url-like.com',
        'builds-pass-4.7.4.20141030-1916' => 'builds-pass-4.7.4.20141030-1916'
    );

    foreach (keys %tests) {
        my $cleaned = $screenshot->_sanitize_string($_);
        cmp_ok($cleaned, 'eq', $tests{$_}, $_ . ' is properly sanitized');
    }
}

WITH_REAL_PNG: {
    my $screenshot = Selenium::Screenshot->new(
        png => $png_string,
        metadata => {
            test => 'compare',
            and  => 'diff'
        },
        folder => $fixture_dir
    );

    my $fail_image = $fixture_dir . 'diff-compare-reference.png';

  COMPARE: {
        ok($screenshot->compare, 'no argument compare passes the first try');
        ok($screenshot->compare, 'no argument compare actually compares the second time');

        # overwrite the reference image with a black box such that
        # when ->compare looks for its default opponent, it will find
        # our black box and fail the comparison.
        Imager->new( xsize => 16, ysize => 16 )->write(
            file => $fail_image
        );

        ok( ! $screenshot->compare, 'no argument compare properly fails a comparison');

        ok($screenshot->compare($sample_png), 'comparing to self passes');
        ok(! $screenshot->compare( $fail_image ), 'comparing two different images fails!');
    }

  CONTRAST: {
        # get the difference file
        my $diff_file = $screenshot->difference( $fail_image );
        ok( -e $diff_file, 'diff file exists' );
        cmp_ok( $diff_file, '=~', qr/-diff\.png/, 'diff is named differently' );
    }

  CASTING: {
        my $file = $FindBin::Bin . '/sample.png';
        my $tests = {
            file => $file,
            imager => Imager->new(file => $file),
            screenshot => Selenium::Screenshot->new(png => $png_string)
        };

        foreach my $type (keys %$tests) {
            my $extracted = Selenium::Screenshot->_extract_image($tests->{$type});
            ok($extracted->isa('Imager'), 'we can convert ' . $type . ' to Imager');
        }
    }

  EXCLUDE: {
      UNIT: {
            my $exclude = [{
                size     => { width => 8, height => 8 },
                location => { x => 4, y => 4 }
            }, {
                size     => { width => 1, height => 1 },
                location => { x => 0, y => 0 }
            }];

            my $img = Imager->new(file => $sample_png);
            my $copy = $img->copy;

            $img = Selenium::Screenshot->_img_exclude($img, $exclude);

            my $cmp = Image::Compare->new(method => &Image::Compare::EXACT);
            $cmp->set_image1(img => $img, type => 'PNG');
            $cmp->set_image2(img => $copy, type => 'PNG');
            ok( ! $cmp->compare, 'exclusion makes images different' );

            $copy = Selenium::Screenshot->_img_exclude($copy, $exclude);
            $cmp->set_image2(img => $copy, type => 'PNG');

            ok( $cmp->compare, 'excluding two images makes them the same' );
        }

      E2E: {
            my $exclude = [{
                size => { width => 16, height => 16 },
                location => { x => 0, y => 0 }
            }];

            my $exclude_shot = Selenium::Screenshot->new(
                png => $png_string,
                exclude => $exclude
            );

            my $copy = $screenshot->png;
            ok( $exclude_shot->compare($screenshot), 'we automatically exclude the opponent as well');
            ok( $screenshot->compare($copy), 'without mutating the opponent');

            # The exclusion is done during the construction of the
            # _cmp attribute of Selenium::Screenshot. While it is
            # implicitly called behind the scenes automatically by
            # compare, it needs to be lazy due to its dependencies. If
            # you need to move this section above the
            # $exclude_shot->compare invocation, you must manually
            # instantiate $exclude_shot->_cmp.
            my $cmp = Image::Compare->new(method => &Image::Compare::EXACT);
            $cmp->set_image1(type => 'PNG', img => $exclude_shot->png );
            $cmp->set_image2(type => 'PNG', img => $screenshot->png );
            ok( ! $cmp->compare, 'having an exclusion in the constructor mutates its own png');
        }

    }

  TARGET: {
      UNIT: {
            my $target = {
                size     => { width => 10, height => 10 },
                location => { x => 0, y => 0 }
            };

            my $img = Imager->new(file => $sample_png);
            $img = Selenium::Screenshot->_crop_to_target($img, $target);

            cmp_ok($img->getwidth, 'eq', 10, 'target crops the png to x size');
            cmp_ok($img->getheight, 'eq', 10, 'target crops the png to y size');

            my $screenshot = Selenium::Screenshot->new(
                png => $img,
                target => $target
            );

            is($screenshot->png->getwidth, 10,
               'target crops the png to the proper getwidth in BUILDARGS');
            is($screenshot->png->getheight, 10,
               'target crops the png to the proper getheight in BUILDARGS');
        }

      E2E: {
            my $left_half = {
                size => { width => 8, height => 16 },
                location => { x => 0, y => 0 }
            };

            my $right_half_black = Selenium::Screenshot->new(
                png => $png_string,
                target => $left_half,
                exclude => [{
                    size => { width => 8, height => 16 },
                    location => { x => 8, y => 0 }
                }]
            );

            my $target_left_half = Selenium::Screenshot->new(
                png => $png_string,
                target => $left_half
            );

            ok($target_left_half->compare($right_half_black), 'target crops a screenshot as desired');
        }
    }

}

cleanup_test_dir();
sub cleanup_test_dir {
    my @leftover_files = glob($fixture_dir . '*');
    map { unlink } @leftover_files;
    rmdir $fixture_dir;
}

done_testing;
