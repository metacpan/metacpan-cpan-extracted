#!/usr/bin/env perl

use strict;
use warnings;
use 5.010_000;
use utf8;
binmode STDOUT, ":encoding(utf8)";

use Text::CSV_XS;
use FindBin;
use lib $FindBin::Bin . '/../lib';
use Net::Google::Spreadsheets::V4;

my $gs = Net::Google::Spreadsheets::V4->new(
    client_id      => "YOUR_CLIENT_ID",
    client_secret  => "YOUR_CLIENT_SECRET",
    refresh_token  => "YOUR_REFRESH_TOKEN",

    spreadsheet_id => "YOUR_SPREADSHEET_ID",
);

my($content, $res);

my $title = 'My sheet';

my $sheet = $gs->get_sheet(title => $title);

# create a sheet if does not exit
unless ($sheet) {
    ($content, $res) = $gs->request(
        POST => ':batchUpdate',
        {
            requests => [
                {
                    addSheet => {
                        properties => {
                            title => $title,
                            index => 0,
                        },
                    },
                },
            ],
        },
    );

    $sheet = $content->{replies}[0]{addSheet};
}

my $sheet_prop = $sheet->{properties};

# clear all cells
$gs->clear_sheet(sheet_id => $sheet_prop->{sheetId});

# import data
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

exit;
