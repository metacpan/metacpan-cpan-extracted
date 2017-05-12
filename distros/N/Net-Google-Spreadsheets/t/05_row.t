use t::Util;
use Test::More;

ok my $ws = spreadsheet->add_worksheet, 'add worksheet';

{
    is scalar $ws->rows, 0;
    $ws->batchupdate_cell(
        {col => 1, row => 1, input_value => 'name'},
        {col => 2, row => 1, input_value => 'mail address'},
        {col => 3, row => 1, input_value => 'nick'},
    );
    is scalar $ws->rows, 0;
    my $value = {
        name => 'Nobuo Danjou',
        mailaddress => 'nobuo.danjou@gmail.com',
        nick => 'lopnor',
    };
    ok my $row = $ws->add_row($value);
    isa_ok $row, 'Net::Google::Spreadsheets::Row';
    is_deeply $row->content, $value;

    is_deeply $row->param, $value;
    is $row->param('name'), $value->{name};
    my $newval = {name => '檀上伸郎'};
    is_deeply $row->param($newval), {
        %$value,
        %$newval,
    };

    my $value2 = {
        name => 'Kazuhiro Osawa',
        nick => 'yappo',
        mailaddress => '',
    };
    $row->content($value2);
    is_deeply $row->content, $value2;
    is scalar $ws->rows, 1;
    ok $row->delete;
    is scalar $ws->rows, 0;
}

{
    $ws->add_row( { name => $_ } ) for qw(danjou lopnor soffritto);
    is scalar $ws->rows, 3;
    my $row = $ws->row({sq => 'name = "lopnor"'});
    isa_ok $row, 'Net::Google::Spreadsheets::Row';
    is_deeply $row->content, {name => 'lopnor', nick => '', mailaddress => ''};
}

ok $ws->delete, 'delete worksheet';

done_testing;
