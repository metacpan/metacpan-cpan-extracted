use t::Util;
use Test::More;

ok my $service = service();

{
    ok my $spreadsheet = $service->add_item(
        {
            title => join(' - ', 'test for export', scalar localtime),
            kind => 'spreadsheet',
            file => 't/data/upload.csv',
        }
    );

    for my $format (qw(xls csv pdf ods tsv html)) {
        my $target = 't/data/export.'.$format;
        ok $spreadsheet->export(
            {
                format => $format,
                file => $target,
            }
        ), "exporting $format - spreadsheet - ".$spreadsheet->title;
        ok -r $target;
        ok unlink $target;
    }

    ok $spreadsheet->delete({delete => 'true'});
}
{
    ok my $doc = $service->add_item(
        {
            title => join(' - ', 'test for export', scalar localtime),
            kind => 'document',
            file => 't/data/foobar.txt',
        }
    );

    for my $format (qw(doc html odt pdf png rtf txt zip)) {
        my $target = 't/data/export.'.$format;
        ok $doc->export(
            {
                format => $format,
                file => $target,
            }
        ), "exporting $format - doc - ". $doc->title;
        ok -r $target;
        ok unlink $target;
    }

    ok $doc->delete({delete => 'true'});
}
{
    ok my $presentation = $service->add_item(
        {
            title => join(' - ', 'test for export', scalar localtime),
            kind => 'presentation',
            file => 't/data/lolspeak.ppt',
        }
    );

    for my $format (qw(pdf png ppt txt)) { # no swf now?
        my $target = 't/data/export.'.$format;
        ok eval {$presentation->export(
            {
                format => $format,
                file => $target,
            }
        )}, "exporting $format - presentation - ".$presentation->title;
        ok -r $target;
        ok unlink $target;
    }

    ok $presentation->delete({delete => 'true'});
}
{
    ok my $pdf = $service->add_item(
        {
            title => join(' - ', 'test for export', scalar localtime),
            file => 't/data/foobar.pdf',
            convert => 'false',
        }
    );

    for my $format (qw(pdf png ppt swf txt)) {
        my $target = 't/data/export.'.$format;
        ok eval {$pdf->export(
            {
                format => $format,
                file => $target,
            }
        )}, "exporting $format - pdf - ". $pdf->title;
        ok -r $target;
        ok unlink $target;
    }

    ok $pdf->delete({delete => 'true'});
}

done_testing;
