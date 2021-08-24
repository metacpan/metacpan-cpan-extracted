#!/usr/bin/env perl

use strict;
use warnings;
use 5.010_000;
use utf8;
binmode STDOUT, ":encoding(utf8)";

use FindBin;
use lib $FindBin::Bin . '/../lib';
use Net::Google::Spreadsheets::V4;
use URI::Escape;

my $gs = Net::Google::Spreadsheets::V4->new(
    client_id      => "YOUR_CLIENT_ID",
    client_secret  => "YOUR_CLIENT_SECRET",
    refresh_token  => "YOUR_REFRESH_TOKEN",

    spreadsheet_id => "YOUR_SPREADSHEET_ID",
);

my($content, $res);

my $title = 'My sheet';

my $sheet = $gs->get_sheet(title => $title);

# read data
($content, $res) = $gs->request(
    GET => sprintf("/values/%s", uri_escape($gs->a1_notation(
        sheet_title => $title,
    )))
);

for my $row (@{ $content->{values} }) {
    say join(', ', @$row);
}

exit;
