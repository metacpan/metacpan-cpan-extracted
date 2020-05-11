#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 7;

use OCR::OcrSpace;


BEGIN {
    use_ok( 'OCR::OcrSpace' ) || print "Bail out!\n";
}

print "Running mocked test\n";
diag( "Testing OCR::OcrSpace $OCR::OcrSpace::VERSION, Perl $], $^X" );
{
    no warnings 'redefine';
    local *OCR::OcrSpace::get_result = sub {
        return
'{"ParsedResults":[{"TextOverlay":{"Lines":[{"LineText":"Current","Words":[{"WordText":"Current","Left":11.666666030883789,"Top":59.166664123535156,"Height":14.999999046325684,"Width":54.999996185302734}],"MaxHeight":14.999999046325684,"MinTop":59.166664123535156},{"LineText":"59","Words":[{"WordText":"59","Left":32.5,"Top":239.99998474121094,"Height":20.833332061767578,"Width":29.166666030883789}],"MaxHeight":20.833332061767578,"MinTop":239.99998474121094}],"HasOverlay":true,"Message":"Total lines: "2"},"TextOrientation":"0","FileParseExitCode":1,"ParsedText":"Current\t\r\n59\t\r\n","ErrorMessage":"","ErrorDetails":""}],"OCRExitCode":1,"IsErroredOnProcessing":false,"ProcessingTimeInMilliseconds":"437","SearchablePDFURL":""}';
    };

    my $param = {
        base64Image => 'data:image/png;base64,iVBORw0KGgoAx7/7LNuCQS0posnocgEAFpySUVORK5CYII=',

        # file                           => '/tmp/image.png',
        ocr_space_url                => "https://api.ocr.space/parse/image",
        apikey                       => 'XXXXXXXXXXXXXXXXXX',
        isOverlayRequired            => 'True',
        language                     => 'eng',
        scale                        => 'True',
        isTable                      => 'True',
        OCREngine                    => 2,
        filetype                     => 'PNG',
        detectOrientation            => 'False',
        isCreateSearchablePdf        => 'True',
        isSearchablePdfHideTextLayer => 'True',
    };
    my $ocr = OCR::OcrSpace->new();
    ok( $ocr->get_result( $param ), "ok" );
    local *OCR::OCROcrSpace::_validate = sub { return $param };
    ok( $ocr->_validate( $param ), "ok" );
    local *OCR::OCROcrSpace::_generate_request = sub { return $param };
    ok( $ocr->_generate_request( $param ), "ok" );

}

{
    no warnings 'redefine';

    local *OCR::OcrSpace::get_result = sub {
        return
'{"ParsedResults":[{"TextOverlay":{"Lines":[{"LineText":"Current","Words":[{"WordText":"Current","Left":11.666666030883789,"Top":59.166664123535156,"Height":14.999999046325684,"Width":54.999996185302734}],"MaxHeight":14.999999046325684,"MinTop":59.166664123535156},{"LineText":"59","Words":[{"WordText":"59","Left":32.5,"Top":239.99998474121094,"Height":20.833332061767578,"Width":29.166666030883789}],"MaxHeight":20.833332061767578,"MinTop":239.99998474121094}],"HasOverlay":true,"Message":"Total lines: "2"},"TextOrientation":"0","FileParseExitCode":1,"ParsedText":"Current\t\r\n59\t\r\n","ErrorMessage":"","ErrorDetails":""}],"OCRExitCode":1,"IsErroredOnProcessing":false,"ProcessingTimeInMilliseconds":"437","SearchablePDFURL":""}';
    };

    my $param = {
        url                          => 'http://www.google.com/1010.jpg',
        ocr_space_url                => "https://api.ocr.space/parse/image",
        apikey                       => 'XXXXXXXXXXXXXXXXXX',
        isOverlayRequired            => 'True',
        language                     => 'eng',
        scale                        => 'True',
        isTable                      => 'True',
        OCREngine                    => 2,
        filetype                     => 'JPG',
        detectOrientation            => 'False',
        isCreateSearchablePdf        => 'True',
        isSearchablePdfHideTextLayer => 'True',
    };

    local *OCR::OCROcrSpace::_validate = sub { return $param };

    ok( get_result( $param ), "ok" );
    local *OCR::OCROcrSpace::_validate = sub { return $param };
    ok( OCR::OCROcrSpace::_validate( $param ), "ok" );
    local *OCR::OCROcrSpace::_generate_request = sub { return $param };
    ok( OCR::OCROcrSpace::_generate_request( $param ), "ok" );
}

done_testing(7);