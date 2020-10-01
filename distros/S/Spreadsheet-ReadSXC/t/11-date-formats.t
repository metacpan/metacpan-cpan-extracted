#!/usr/bin/perl

use strict;
use warnings;

use strict;
use Test::More;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

my %fmt = (
    A1 => [ "08. Aug",			"dd. mmm"			],
    A2 => [ "12. Aug",			"dd. mmm"			],
    A3 => [ "08. Dez",			"dd. mmm"			],
    A4 => [ "13. Aug",			"dd. mmm"			],
    A6 => [ "Short: dd-MM-yyyy",	undef			],
    A7 => [ "13.08.2008",		"dd.mm.yyyy"		],
    B1 => [ 20080808,			"yyyymmdd"		],
    B2 => [ 20080812,			"yyyymmdd"		],
    B3 => [ 20081208,			"yyyymmdd"		],
    B4 => [ 20080813,			"yyyymmdd"		],
    B6 => [ "Long: ddd, dd MMM yyyy",	undef			],
    B7 => [ "Mi, 13 Aug 2008",		"ddd, dd mmm yyyy"	],
    C1 => [ "08.08.2008",		"dd.mm.yyyy"		],
    C2 => [ "12.08.2008",		"dd.mm.yyyy"		],
    C3 => [ "08.12.2008",		"dd.mm.yyyy"		],
    C4 => [ "13.08.2008",		"dd.mm.yyyy"		],
    C6 => [ "Default format 0x0E",	undef			],
    C7 => [ "8.13.08",			"m.d.yy"		],   # at least that's what LibreOffice with German settings creates
    D1 => [ "08/08/2008",		"mm/dd/yyyy"		],
    D2 => [ "08/12/2008",		"mm/dd/yyyy"		],
    D3 => [ "12/08/2008",		"mm/dd/yyyy"		],
    D4 => [ "08/13/2008",		"mm/dd/yyyy"		],
    E1 => [ "08 Aug 2008",		undef			],
    E2 => [ "12 Aug 2008",		undef			],
    E3 => [ "08 Dec 2008",		undef			], # this is plain text, so no format, no localization
    E4 => [ "13 Aug 2008",		undef			],
);

plan tests => 108;

my $wb = Spreadsheet::ParseODS->new()->parse( "$d/Dates.ods" );
my $sheet = $wb->worksheet('DateTest');

#my @date = ( 39668,             39672,         39790,        39673);
my @date = ( '2008-08-08', '2008-08-12', '2008-12-08', '2008-08-13');
my @fmt  = ( "dd. mmm", "yyyymmdd", "dd.mm.yyyy", "mm/dd/yyyy");

foreach my $r (0 .. 3) {
    for (0..3) {
        my $cell = $sheet->get_cell($r,$_);
        is ($cell->unformatted,  $date[$r], "Date value  row $r col $_");
        is ($cell->type,         "date",    "Date type   row $r col $_");
        my $style =  $cell->style || '-none-';
        is ($cell->get_format,   $fmt[$_],  "Date format row $r col $_ (style '$style')");
    };
}

foreach my $r (0..3,5..6) {
    foreach my $c (0..4) {
        my $cell = $sheet->get_cell($r, $c);
        my $addr = sprintf '%s%d', chr(ord('A')+$c), $r+1;
        my $fmt  = $cell->format;
        is ($cell->value, $fmt{$addr}[0], "$addr content");
        my $style =  $cell->style || '-none-';
        is ($fmt,         $fmt{$addr}[1], "$addr format ($style)");
    }
}


