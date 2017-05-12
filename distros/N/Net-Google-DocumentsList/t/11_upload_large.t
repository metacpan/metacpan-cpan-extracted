use t::Util;
use Test::More;
use utf8;
use Encode;
use File::Temp;
use File::BOM;

my $file = $ENV{TEST_UPLOAD_FILE};

unless ($file && -r $file) {
    plan skip_all => 'set TEST_UPLOAD_FILE=your_pdf_larger_than_512kb.pdf to run this test';
}

my $service = service();

{
    ok my $doc = $service->add_item({ file => $file });
    ok $doc->delete({delete => 'true'});
}
{
    ok my $doc = $service->add_item({ file => 't/data/foobar.pdf' });
    ok $doc->update_content($file);
    ok $doc->delete({delete => 'true'});
}

done_testing;
