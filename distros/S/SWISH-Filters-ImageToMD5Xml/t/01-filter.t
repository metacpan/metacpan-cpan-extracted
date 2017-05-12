use strict;
use warnings;
use Test::More;
use Search::Tools;
use Search::Tools::XML;
use MIME::Base64 qw(encode_base64);
use SWISH::Filter::Document;

use_ok('SWISH::Filters::ImageToMD5Xml');

my $filename = 't/test.jpg';
my $subject  = SWISH::Filters::ImageToMD5Xml->new;
my $xml      = $subject->filter( get_doc($filename) );
my $md5      = qq/ &#163; L&#142;&#135;&#142;G&#176;&#189;QS&#34;F  /;

like( $$xml, qr/$md5/, "filtered XML contained MD5 checksum" );

done_testing();

sub get_doc {
    my $filename     = shift;
    my $bin_data     = Search::Tools->slurp($filename);
    my $base_64_data = encode_base64($bin_data);
    my $xml = '<doc><b64_data>' . $base_64_data . '</b64_data></doc>';
    my $doc = SWISH::Filter::Document->new( \$xml, "application/xml" );
    return $doc;
}

