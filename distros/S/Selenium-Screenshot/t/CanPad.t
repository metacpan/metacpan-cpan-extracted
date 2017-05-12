#! /usr/bin/perl

use strict;
use warnings;
use Test::Spec;
use Imager;

{
    package Padder;
    use Moo;
    with 'Selenium::Screenshot::CanPad';
    1;
}

describe 'Image padding role' => sub {
    my ($padder, $tall, $wide, $square);
    before each => sub {
        $padder = Padder->new;

        $wide = Imager->new( xsize => 20, ysize => 10 );
        $tall = Imager->new( xsize => 10, ysize => 20 );
        $square = Imager->new( xsize => 10, ysize => 10 );
    };

    it 'should pad the dimensions of both images' => sub {
        my ($square1, $square2) = $padder->coerce_image_size(
            $tall, $wide
        );

        is( $square1->getwidth, $square2->getwidth );
        is( $square1->getheight, $square2->getheight );
    };

    describe 'private subs' => sub {
        it 'should determine when the images are the same size' => sub {
            my $same = $padder->cmp_image_dims( $square, $square );
            ok( $same );
        };

        it 'should determine when the images are different sizes' => sub {
            my $different = $padder->cmp_image_dims( $tall, $square );
            ok( ! $different );
        };

        it 'should get the largest dimensions from either image' => sub {
            my $dims = Selenium::Screenshot::CanPad::_get_largest_dimensions( $tall, $wide );
            is_deeply( $dims, { width => 20, height => 20 } );
        };

        it 'should indicate if neither dimension is smaller' => sub {
            my $larger = Selenium::Screenshot::CanPad::_is_smaller(
                $square,
                { width => 10, height => 10 }
            );
            ok( ! $larger );
        };

        it 'should indiciate when at least one dimension is smaller' => sub {
            my $smaller = Selenium::Screenshot::CanPad::_is_smaller(
                $square,
                { width => 30, height => 30 }
            );
            ok( $smaller );
        };

        it 'should pad an image to the appropriate dimensions' => sub {
            my $padded = Selenium::Screenshot::CanPad::_pad_image(
                $square,
                { width => 30, height => 31 }
            );

            is( $padded->getheight, 31 );
            is( $padded->getwidth, 30 );
            is( $square->getheight, 10 );
            is( $square->getwidth, 10 );
        };



    };


};

  runtests;
