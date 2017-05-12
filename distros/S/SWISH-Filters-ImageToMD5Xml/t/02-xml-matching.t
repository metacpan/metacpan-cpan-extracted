#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::MockObject;

use_ok('SWISH::Filters::ImageToMD5Xml');

my $subject  = SWISH::Filters::ImageToMD5Xml->new;
my $filtered = $subject->filter( get_doc() );

is $filtered, undef, "leaves XML with no <b64_data> element untouched";

done_testing();

sub get_doc {
    my $meta_data = shift;

    my $xml = "<doc><foo>no base64 data here</foo></doc>";

    my $doc = Test::MockObject->new;
    $doc->mock( 'fetch_filename',   sub { return $xml } );
    $doc->mock( 'set_content_type', sub { return 'application/xml' } );
    $doc->mock( 'meta_data',        sub { return $meta_data } );
    $doc->mock( 'is_binary',        sub { return 0 } );

    return $doc;
}
