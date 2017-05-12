# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use warnings;
no warnings qw(void);       # Because +, -, ++, --, <<, and >> are overloaded, it's ok to use them in a void context.
use Spreadsheet::TieExcel;
my $loaded = 1;

use Test::Simple tests => 30;

ok ($loaded, 'Loaded successfully');

#============================================================
# Tied scalars
#============================================================

tie my $x, 'Spreadsheet::TieExcel::Scalar';
my $X = tied $x; 

ok (1, 'Tied a scalar...');

ok ($X->row(1), 'Positioned in row 1');
ok ($X->column(1), 'Positioned in column 1');

ok ($x = 2, '...wrote to it successfully...');
ok ($x == 2, '...and read it too');

#--------------------------------------------------
# Moving around
#--------------------------------------------------

$X >> 2; $X + 6;

ok ($X->row == 7, 'Moved successfully down...');
ok ($X->column == 3, 'and right');

#============================================================
# Tied filehandles
#============================================================

tie *XL, 'Spreadsheet::TieExcel::File', {row => 1, column => 1, width => 1, height => 5};

ok (1, 'tied a filehandle');

my @t = (1..5);

for (@t) {
    ok ((print XL $_), 'writing successful')
}


while (<XL>) {
    my $t = shift @t;
    ok ($t == $_, 'reading successful');
}

#============================================================
# Tied array
#============================================================

tie my @x, 'Spreadsheet::TieExcel::Array', {row => 1, column => 1, width => 1, height => 5};

ok (1, 'tied an array');
my $v = 1;

for (@x) {
    ok ($_ == $v++, 'array read successful')
};

#============================================================
# Tied hash
#============================================================

tie my %x, 'Spreadsheet::TieExcel::Hash';

ok (1, 'Tied a hash');
$x{'foo'} = [12, 4];
ok (1, 'Assigned a range to a hash element');
$x{'foo'} = 'foo';
ok (1 , 'assigned to the element');
ok ($x{'foo'} eq 'foo', 'read the element');
$X->row(12), $X->column(4);

ok ($x eq 'foo', 'read the element again through a scalar');
