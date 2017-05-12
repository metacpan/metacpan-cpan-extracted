use t::Util;
use Test::More;

my $ws_title = 'test worksheet for table '.scalar localtime;
my $table_title = 'test table '.scalar localtime;
my $ss = spreadsheet;
ok my $ws = $ss->add_worksheet({title => $ws_title}), 'add worksheet';
is $ws->title, $ws_title;

my @t = $ss->tables;
my $previous_table_count = scalar @t;

{
    ok my $table = $ss->add_table(
        {
            title => $table_title,
            summary => 'this is summary of this table',
            worksheet => $ws,
            header => 1,
            start_row => 2,
            num_rows => 15,
            columns => [
            {index => 1, name => 'name'},
            {index => 2, name => 'mail address'},
            {index => 3, name => 'nick'},
            ],
        }
    );
    isa_ok $table, 'Net::Google::Spreadsheets::Table';
}

{
    my @t = $ss->tables;
    ok scalar @t;
    is scalar @t, $previous_table_count + 1;
    isa_ok $t[0], 'Net::Google::Spreadsheets::Table';
}

{
    ok my $t = $ss->table({title => $table_title});
    isa_ok $t, 'Net::Google::Spreadsheets::Table';
    is $t->title, $table_title;
    is $t->summary, 'this is summary of this table';
    is $t->worksheet, $ws->title;
    is $t->header, 1;
    is $t->start_row, 2;
    is $t->num_rows, 15;
    is scalar @{$t->columns}, 3;
    ok grep {$_->name eq 'name' && $_->index eq 'A'} @{$t->columns};
    ok grep {$_->name eq 'mail address' && $_->index eq 'B'} @{$t->columns};
    ok grep {$_->name eq 'nick' && $_->index eq 'C'} @{$t->columns};
}

{
    ok my $t = $ss->table;
    isa_ok $t, 'Net::Google::Spreadsheets::Table';

    ok $t->delete;
    my @t = $ss->tables;
    is scalar @t, $previous_table_count;
}
ok $ws->delete, 'delete worksheet';

for my $mode (qw(overwrite insert)) {
    ok my $ws2 = $ss->add_worksheet(
        {
            title => 'insertion mode test '.scalar localtime,
            col_count => 3,
            row_count => 3,
        }
    ), 'add worksheet';
    ok $ss->add_table(
        {
            title => 'foobarbaz',
            worksheet => $ws2,
            insertion_mode => $mode,
            start_row => 3,
            columns => ['foo', 'bar', 'baz'],
        }
    );
    ok my $t = $ss->table({title => 'foobarbaz', worksheet => $ws2->title});
    isa_ok $t, 'Net::Google::Spreadsheets::Table';
    is $t->title, 'foobarbaz', 'table title';
    is $t->worksheet, $ws2->title, 'worksheet name';
    is $t->insertion_mode, $mode, 'insertion mode';
    is $t->start_row, 3, 'start row';
    my @c = @{$t->columns};
    is scalar @c, 3, 'column count is 3';
    ok grep({$_->name eq 'foo' && $_->index eq 'A'} @c), 'column foo exists';
    ok grep({$_->name eq 'bar' && $_->index eq 'B'} @c), 'column bar exists';
    ok grep({$_->name eq 'baz' && $_->index eq 'C'} @c), 'column baz exists';
    for my $i (1 .. 3) {
        ok $t->add_record(
            {
                foo => 1,
                bar => 2,
                baz => 3,
            }
        );
        is $t->num_rows, $i;
    }
    ok $ws2->delete;
}

done_testing;
