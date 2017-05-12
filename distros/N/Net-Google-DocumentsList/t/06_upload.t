use t::Util;
use Test::More;
use utf8;
use Encode;
use File::Temp;
use File::BOM;

my $service = service();

my $bom = $File::BOM::enc2bom{'UTF-8'};


{
    my $title = join(' - ', 'test for upload', scalar localtime);
    ok my $doc = $service->add_item(
        {
            title => $title,
            file => 't/data/foobar.txt',
        }
    );
    is $doc->title, $title;
    {
        ok my $found = $service->item({title => $title});
    }
    my $file = File::Temp->new;

    ok eval {
        $doc->export(
            {
                format => 'txt',
                file => $file,
            }
        )
    };
    close $file;
    open my $fh, "<:via(File::BOM)", $file->filename;
    my $content = do {local $/; <$fh>};
    is $content, "foobar";

    ok $doc->update_content('t/data/hogefuga.txt');

    ok my $export = eval { $doc->export({format => 'txt'}) };
    is Encode::encode('utf-8', $export), $bom.'hogefuga';

    ok $doc->delete({delete => 'true'});
}
{
    my $title = join(' - ', 'test for upload', scalar localtime);
    ok my $doc = $service->add_item(
        {
            title => $title,
            file => 't/data/test.docx',
            kind => 'document',
        }
    );
    is $doc->title, $title;
    {
        ok my $found = $service->item({title => $title});
        note $found->alternate;
#        system('open', $found->alternate);
    }
    ok $doc->delete({delete => 'true'});
}
{
    my $title = join(' - ', 'test for upload', scalar localtime);
    ok my $doc = $service->add_item(
        {
            title => $title,
            file => 't/data/test.doc',
            kind => 'document',
        }
    );
    is $doc->title, $title;
    {
        ok my $found = $service->item({title => $title});
        note $found->alternate;
#        system('open', $found->alternate);
    }
    ok $doc->delete({delete => 'true'});
}
{
    my $title = join(' - ', 'test for upload', scalar localtime);
    ok my $doc = $service->add_item(
        {
            title => $title,
            file => 't/data/test.xls',
            kind => 'spreadsheet',
        }
    );
    is $doc->title, $title;
    {
        ok my $found = $service->item({title => $title});
        note $found->alternate;
#        system('open', $found->alternate);
    }
    ok $doc->delete({delete => 'true'});
}

done_testing;
