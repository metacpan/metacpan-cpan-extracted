use t::Util;
use Test::More;

my $ws_title = 'test worksheet for record '.scalar localtime;
my $table_title = 'test table '.scalar localtime;
my $ss = spreadsheet;
ok my $ws = $ss->add_worksheet({title => $ws_title}), 'add worksheet';
is $ws->title, $ws_title;

ok my $table = $ss->add_table(
    {
        worksheet => $ws,
        columns => [
            'name',
            'mail address',
            'nick',
        ]
    }
);

{
    my $value = {
        name => 'Nobuo Danjou',
        'mail address' => 'info@example.com',
        nick => 'lopnor',
    };
    ok my $record = $table->add_record($value);
    isa_ok $record, 'Net::Google::Spreadsheets::Record';
    is_deeply $record->content, $value;
    is_deeply $record->param, $value;
    is $record->param('name'), $value->{name};
    my $newval = {name => '檀上伸郎'};
    is_deeply $record->param($newval), {
        %$value,
        %$newval,
    };
    is_deeply $record->content,{
        %$value,
        %$newval,
    };
    {
        ok my $r = $table->record({sq => '"mail address" = "info@example.com"'});
        isa_ok $r, 'Net::Google::Spreadsheets::Record';
        is $r->param('mail address'), $value->{'mail address'};
    }

    my $value2 = {
        name => 'Kazuhiro Osawa',
        nick => 'yappo',
        'mail address' => 'foobar@example.com',
    };
    $record->content($value2);
    is_deeply $record->content, $value2;
    is scalar $table->records, 1;
    ok $record->delete;
    is scalar $table->records, 0;
}

{
    $table->add_record( { name => $_ } ) for qw(danjou lopnor soffritto);
    is scalar $table->records, 3;
    ok my $record = $table->record({sq => 'name = "lopnor"'});
    isa_ok $record, 'Net::Google::Spreadsheets::Record';
    is_deeply $record->content, {name => 'lopnor', nick => '', 'mail address' => ''};
}


ok $ws->delete, 'delete worksheet';

done_testing;
