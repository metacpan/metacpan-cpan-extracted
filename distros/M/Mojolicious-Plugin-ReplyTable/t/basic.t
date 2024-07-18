use Mojolicious::Lite;

use Test2::V0;
use Test::Mojo;
use Test::Without::Module;

use Text::CSV;
use Mojo::Collection 'c';
use Mojo::Util 'trim';

plugin 'ReplyTable';

my $data = [
  [qw/head1 head2 head3/],
  [qw/r1c1  r1c2  r1c3 /],
  [qw/r2c1  r2c2☃ r2c3 /],
];

app->log->level('fatal');

my @format = eval { Mojolicious->VERSION('9.11') } ? [format => 1] : ();

any '/table' => @format => sub {
  my $c = shift;
  $c->stash('reply_table.tablify' => 1) if $c->param('tablify');
  $c->stash('reply_table.csv_options' => { sep_char => "|" }) if $c->param('format_as_psv');
  $c->stash('reply_table.csv_options' => { invalid => 1 }) if $c->param('invalid_csv_opt');

  $c->reply->table($data);
};
any '/json'     => @format => sub { shift->reply->table(json => $data) };
any '/header'   => @format => sub { shift->stash('reply_table.header_row' => 1)->reply->table($data) };
any '/override' => @format => sub { shift->reply->table(txt => $data, txt => { text => 'hello world' }) };

my $t = Test::Mojo->new;

# defaults

$t->get_ok('/table')
  ->status_is(200)
  ->content_type_like(qr'text/html');

$t->get_ok('/table.json')
  ->status_is(200)
  ->content_type_like(qr'application/json');

$t->get_ok('/json')
  ->status_is(200)
  ->content_type_like(qr'application/json');

$t->get_ok('/json.html')
  ->status_is(200)
  ->content_type_like(qr'text/html');

# overrides

$t->get_ok('/override')
  ->status_is(200)
  ->content_type_like(qr'text/plain')
  ->content_is('hello world');

# json

$t->get_ok('/table.json')
  ->status_is(200)
  ->content_type_like(qr'application/json')
  ->json_is($data);

# csv

$t->get_ok('/table.csv')
  ->status_is(200)
  ->content_type_like(qr'text/csv');

{
  my $csv = Text::CSV->new({binary => 1});
  my $res = $t->tx->res->body;
  open my $fh, '<', \$res;
  is $csv->getline_all($fh), $data, 'data returned as csv';
}

# csv with options

$t->get_ok('/table.csv?format_as_psv=1')
  ->status_is(200)
  ->content_type_like(qr'text/csv');

{
  my $csv = Text::CSV->new({binary => 1, sep_char => "|" });
  my $res = $t->tx->res->body;
  open my $fh, '<', \$res;
  is $csv->getline_all($fh), $data, 'data returned as psv';
}

# invalid csv options

$t->get_ok('/table.csv?invalid_csv_opt=1')
  ->status_is(500)
  ->text_like('#error' => qr/unknown attribute/i);

# html

$t->get_ok('/table.html')
  ->status_is(200)
  ->content_type_like(qr'text/html');

{
  my $res = $t->tx->res->dom->find('tbody tr')->map(sub{ $_->find('td')->map('text')->to_array })->to_array;
  is $res, $data, 'data returned as html';
}

$t->get_ok('/header.html')
  ->status_is(200)
  ->content_type_like(qr'text/html');

{
  my $head = $t->tx->res->dom->find('thead tr th')->map('text')->to_array;
  is $head, $data->[0], 'correct html table headers';
  my $body = $t->tx->res->dom->find('tbody tr')->map(sub{ $_->find('td')->map('text')->to_array })->to_array;
  is $body, [@$data[1..$#$data]], 'correct html table body';
}

# text

{
  Test::Without::Module->import('Text::Table::Tiny');
  $t->get_ok('/table.txt')
    ->status_is(200)
    ->content_type_like(qr'text/plain');

  my $res = trim $t->tx->res->text;
  $res =~ s/\s++/ /g;
  my $expect = c(@$data)->flatten->join(' ');
  is $res, "$expect", 'text table has correct information';
  Test::Without::Module->unimport('Text::Table::Tiny');
}

SKIP: {
  skip 'test requires Text::Table::Tiny', 5
    unless eval { require Text::Table::Tiny; 1 };

  $t->get_ok('/table.txt')
    ->status_is(200)
    ->content_type_like(qr'text/plain');

  my $res = $t->tx->res->text;
  ok +($res =~ s/[+|-]//g), 'content had some styling';
  $res = trim $res;
  $res =~ s/\s++/ /g;
  my $expect = c(@$data)->flatten->join(' ');
  is $res, $expect, 'text table has correct information';
}

SKIP: {
  skip 'test requires Text::Table::Tiny', 5
    unless eval { require Text::Table::Tiny; 1 };

  $t->get_ok('/table.txt?tablify=1')
    ->status_is(200)
    ->content_type_like(qr'text/plain');

  my $res = $t->tx->res->text;
  ok !($res =~ s/[+|-]//g), 'content did not have styling when tablify is requested';
  $res = trim $res;
  $res =~ s/\s++/ /g;
  my $expect = c(@$data)->flatten->join(' ');
  is $res, $expect, 'text table has correct information';
}

# xls

{
  Test::Without::Module->import('Spreadsheet::WriteExcel');
  $t->get_ok('/table.xls')
    ->status_is(406);
  Test::Without::Module->unimport('Spreadsheet::WriteExcel');
}

SKIP: {
  skip 'test requires Spreadsheet::WriteExcel', 4
    unless eval { require Spreadsheet::WriteExcel; 1 };
  $t->get_ok('/table.xls')
    ->status_is(200)
    ->content_type_like(qr'application/vnd.ms-excel');
  cmp_ok $t->tx->res->body_size, '>', 0, 'has non-zero size';
}

# xlsx

{
  Test::Without::Module->import('Excel::Writer::XLSX');
  $t->get_ok('/table.xlsx')
    ->status_is(406);
  Test::Without::Module->unimport('Excel::Writer::XLSX');
}

SKIP: {
  skip 'test requires Excel::Writer::XLSX', 4
    unless eval { require Excel::Writer::XLSX; 1 };
  $t->get_ok('/table.xlsx')
    ->status_is(200)
    ->content_type_like(qr'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  cmp_ok $t->tx->res->body_size, '>', 0, 'has non-zero size';
}

done_testing;

