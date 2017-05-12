Spreadsheet::HTML
=================
Just another HTML table generator. [![CPAN Version](https://badge.fury.io/pl/Spreadsheet-HTML.svg)](https://metacpan.org/pod/Spreadsheet::HTML) [![Build Status](https://api.travis-ci.org/jeffa/Spreadsheet-HTML.svg?branch=master)](https://travis-ci.org/jeffa/Spreadsheet-HTML)

Description
-----------
Generate HTML tables with ease (HTML4, XHTML and HTML5). Can generate
landscape and other rotated views, Handsontable tables, HTML calendars,
checkerboard patterns, games such as sudoku, banners and mazes, and can
create animations of cell values and backgrounds via jQuery. Transform
Excel, HTML, JSON, CSV, YAML, PNG, JPEG and GIF files instantly into HTML tables.

Synopsis
--------
```
# portrait is default generation method
mktable --param file=data.xls --param preserve=1 > out.html

# display output to browser with HTML::Display
mktable landscape --param data=[[a..d],[1..4],[5..8]] --display

mktable conway --param data=[1..300] --param wrap=20 --param matrix=1 --display

mktable sudoku --display
```

Backend API
-----------
```perl
use Spreadsheet::HTML;

my @data = ( [qw(foo b&r b&z)], [1,2,3], [4,5,6], [7,8,9] );
my $gen  = Spreadsheet::HTML->new( data => \@data, encode => 1 );

print $gen->portrait( indent => '   ' );
print $gen->landscape( indent => "\t" );

# load from file
$gen = Spreadsheet::HTML->new( file => 'data.xls', worksheet => 2 );
print $gen->generate( preserve => 1 );
```

Installation
------------
To install this module, you should use CPAN. A good starting
place is [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

If you truly want to install from this github repo, then
be sure and create the manifest before you test and install:
```
perl Makefile.PL
make
make manifest
make test
make install
```

Support and Documentation
-------------------------
After installing, you can find documentation for this module with the
perldoc command.
```
perldoc Spreadsheet::HTML
```
You can also find documentation at [metaCPAN](https://metacpan.org/pod/Spreadsheet::HTML).

License and Copyright
---------------------
See [source POD](/lib/Spreadsheet/HTML.pm).
