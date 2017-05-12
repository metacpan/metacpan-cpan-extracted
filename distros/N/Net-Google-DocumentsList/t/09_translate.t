use t::Util;
use Test::More;
use LWP::Simple;
plan skip_all => 'does not work with resumable upload for now?';

my $service = service();

{
    my $title = join(' - ', 'test for translate', scalar localtime);
    ok my $doc = $service->add_item( 
        {
            title => $title, 
            kind => 'document',
            file => 't/data/japanese.txt',
            source_language => 'ja',
            target_language => 'en',
        } 
    );
    is $doc->title, $title;

    like $doc->export({format => 'txt'}), qr{Hello};

    ok $doc->delete({delete => 1});
}
{
    my $title = join(' - ', 'test for translate', scalar localtime);
    ok my $doc = $service->add_item( 
        {
            title => $title, 
            kind => 'document',
            file => 't/data/english.txt',
            source_language => 'en',
            target_language => 'de',
        } 
    );
    is $doc->title, $title;

    like $doc->export({format => 'txt'}), qr{Hallo, Welt!};

    ok $doc->delete({delete => 1});
}

done_testing;
