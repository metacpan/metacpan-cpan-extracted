#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use Test::More;

eval { require Config::Pit; Config::Pit->import(); };
plan(skip_all => "Config::Pit not installed: $@; skipping") if $@;

my $credential = pit_get('google-oauth2');
my $spreadsheet_id = '1h_XP86fHrviYJ_TYNRGzpmEghFPcrTvGHMFNGa1tKKk';

require Net::Google::Spreadsheets::V4;
Net::Google::Spreadsheets::V4->import;

my $gs = new_ok("Net::Google::Spreadsheets::V4" => [
    %$credential,
    spreadsheet_id => $spreadsheet_id,
]);

my $sheet_title = 'foo';
my $sheet;
my($content, $res);

$sheet = $gs->get_sheet(title => $sheet_title);
ok($sheet, 'get_sheet by title') or diag explain $sheet;
is($sheet->{properties}{sheetId}, 0);
is($sheet->{properties}{title}, $sheet_title);

$sheet = $gs->get_sheet(sheet_id => 0);
ok($sheet, 'get_sheet by id') or diag explain $sheet;
is($sheet->{properties}{sheetId}, 0);
is($sheet->{properties}{title}, $sheet_title);

($content, $res) = $gs->clear_sheet(sheet_id => 0);
ok($res->is_success, 'clear_sheet');

my $sheet_prop = $sheet->{properties};
my @requests = ();
my $idx = 0;
my @rows = (
    [qw(name age favorite)], # header
    [qw(tarou 31 curry)],
    [qw(jirou 18 gyoza)],
    [qw(saburou 27 ramen)],
);

for my $row (@rows) {
    push @requests, {
        pasteData => {
            coordinate => {
                sheetId     => $sheet_prop->{sheetId},
                rowIndex    => $idx++,
                columnIndex => 0,
            },
            data => $gs->to_csv(@$row),
            type => 'PASTE_NORMAL',
            delimiter => ',',
        },
    };
}

# format a header row
push @requests, {
    repeatCell => {
        range => {
            sheetId       => $sheet_prop->{sheetId},
            startRowIndex => 0,
            endRowIndex   => 1,
        },
        cell => {
            userEnteredFormat => {
                backgroundColor => {
                    red   => 0.0,
                    green => 0.0,
                    blue  => 0.0,
                },
                horizontalAlignment => 'CENTER',
                textFormat => {
                    foregroundColor => {
                        red   => 1.0,
                        green => 1.0,
                        blue  => 1.0
                    },
                    bold => \1,
                },
            },
        },
        fields => 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)',
    },
};

($content, $res) = $gs->request(
    POST => ':batchUpdate',
    {
        requests => \@requests,
    },
);
ok($res->is_success, 'POST :batchUpdate');

($content, $res) = $gs->request(
    GET => sprintf('/values/%s', $sheet_title),
);
ok($res->is_success, 'GET values');

my @got = @{ $content->{values} // [] };
is(scalar(@got), scalar(@rows));
is_deeply(\@got, \@rows);

done_testing;
