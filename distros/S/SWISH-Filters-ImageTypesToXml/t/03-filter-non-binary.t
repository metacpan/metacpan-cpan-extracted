use strict;
use warnings;
use Test::More;
use Test::MockObject;
use File::Slurp;
use MIME::Base64 qw(encode_base64);

use_ok( 'SWISH::Filters::ImageTypesToXml' );

my $subject = SWISH::Filters::ImageTypesToXml->new;
my $xml = $subject->filter(get_doc({ image_types_config => {generate_histogram => 0 }}));

#open my $fh, ">", 't/image_base64_data.xml';
#print $fh $xml;
#close $fh;

is $xml, read_file('t/image_base64_data.xml');


done_testing;

sub get_doc {
    my $meta_data = shift;

    my $bin_data        = read_file( 't/test.jpg', binmode => ':raw' ) ;
    my $base_64_data    = encode_base64($bin_data);
    my $xml             = '<doc><b64_data>' . $base_64_data .  '</b64_data></doc>';

    my $doc = Test::MockObject->new;
    $doc->mock('fetch_filename', sub { return $xml } );
    $doc->mock('set_content_type', sub { return 'application/xml' } );
    $doc->mock('meta_data', sub { return $meta_data });
    $doc->mock('is_binary', sub { return 0 } );
    
    return $doc

}
