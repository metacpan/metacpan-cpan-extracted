use strict;
use warnings;
use Test::More;
use Test::MockObject;
use File::Slurp;


use_ok( 'SWISH::Filters::ImageTypesToXml' );

my $subject = SWISH::Filters::ImageTypesToXml->new;
my $xml;

$xml = $subject->filter(get_doc({ image_types_config => {generate_histogram => 1 }}));
is $xml, read_file('t/image_with_histo_data.xml');

$xml = $subject->filter(get_doc({ image_types_config => {generate_histogram => 0 }}));
is $xml, read_file('t/image_data.xml');

done_testing;

sub get_doc {
    my $meta_data = shift;

    my $doc = Test::MockObject->new;
    $doc->mock('fetch_filename', sub { return 't/test.jpg' } );
    $doc->mock('set_content_type', sub { return 'test.jpg' } );
    $doc->mock('meta_data', sub { return $meta_data });
    $doc->mock('is_binary', sub { return 1 } );
    
    return $doc

}
