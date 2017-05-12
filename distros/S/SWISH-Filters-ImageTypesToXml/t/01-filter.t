use strict;
use warnings;
use Test::More;
use Test::MockObject;
use File::Slurp;

my $doc = Test::MockObject->new;
$doc->mock('fetch_filename', sub { return 't/test.jpg' } );
$doc->mock('set_content_type', sub { return 'test.jpg' } );
$doc->mock('is_binary', sub { return 1 } );

use_ok( 'SWISH::Filters::ImageTypesToXml' );

my $subject = SWISH::Filters::ImageTypesToXml->new;

my $xml = $subject->filter($doc);

#open my $fh, ">", 't/image_data.xml';
#print $fh $xml;
#close $fh;

is $xml, read_file('t/image_data.xml');

done_testing;
