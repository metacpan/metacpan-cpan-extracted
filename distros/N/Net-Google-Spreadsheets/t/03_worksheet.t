use t::Util;
use Test::More;

ok my $spreadsheet = spreadsheet, 'getting spreadsheet';

{
    ok my @ws = $spreadsheet->worksheets, 'getting worksheet';
    ok scalar @ws;
    isa_ok($ws[0], 'Net::Google::Spreadsheets::Worksheet');
}

my $args = {
    title => 'new worksheet '. scalar localtime,
    row_count => 10,
    col_count => 3,
};

{
    my $before = scalar $spreadsheet->worksheets;

    ok my $ws = $spreadsheet->add_worksheet($args), "adding worksheet named '$args->{title}'";
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
    is $ws->title, $args->{title}, 'title is correct';
    is $ws->row_count, $args->{row_count}, 'row_count is correct';
    is $ws->col_count, $args->{col_count}, 'col_count is correct';

    my @ws = $spreadsheet->worksheets;
    is scalar @ws, $before + 1;
    ok grep {$_->title eq $args->{title} } @ws;
}

{
    my $ws = $spreadsheet->worksheet({title => $args->{title}});
    isa_ok $ws, 'Net::Google::Spreadsheets::Worksheet';
    is $ws->title, $args->{title};
    is $ws->row_count, $args->{row_count};
    is $ws->col_count, $args->{col_count};

    $args->{title} = "title changed " .scalar localtime;
    ok $ws->title($args->{title}), "changing title to $args->{title}";
    is $ws->title, $args->{title};
    is $ws->atom->title, $args->{title};

    for (1 .. 2) {
        my $col_count = $ws->col_count + 1;
        my $row_count = $ws->row_count + 1;
        is $ws->col_count($col_count), $col_count, "changing col_count to $col_count";
        is $ws->atom->get($ws->service->ns('gs'), 'colCount'), $col_count;
        is $ws->col_count, $col_count;
        is $ws->row_count($row_count), $row_count, "changing row_count to $row_count";
        is $ws->atom->get($ws->service->ns('gs'), 'rowCount'), $row_count;
        is $ws->row_count, $row_count;
    }
}

{
    my $ws = $spreadsheet->worksheet({title => $args->{title}});
    my @before = $spreadsheet->worksheets;
    ok grep {$_->id eq $ws->id} @before;
    ok grep {$_->title eq $ws->title} @before;
    ok $ws->delete, 'deleting worksheet';
    my @ws = $spreadsheet->worksheets;
    is scalar @ws, (scalar @before) - 1, '(worksheet count)--';
    ok ! grep({$_->id eq $ws->id} @ws), 'id disappeared';
    ok ! grep({$_->title eq $ws->title} @ws), 'title disappeared';
    is $spreadsheet->worksheet({title => $args->{title}}), undef, "shouldn't be able to get the worksheet";
}

done_testing;
