# Test manipulating sql// objects.
use strict;
BEGIN {require 't/lib.pl';}
use Test::More 'no_plan';
use Data::Dumper;
use SQL::Interpolate FILTER => 1, qw(:all);

my $x = 5;
my @v = ('one', 'two');
my $v = \@v;
my %h = (one => 1, two => 2);
my $h = \%h;
my $s1 = sql[SELECT * FROM mytable WHERE x = $x];
#print Dumper($s1);

# scalar
is(&sql_str(sql[SELECT * FROM mytable WHERE x = $x]),
   &sql_str('SELECT * FROM mytable WHERE x = ', \$x),
   'scalar');

# hash
# IMPROVE: fails if "z" changed to "y" (source filtering)
is(&sql_str(sql[SELECT * FROM mytable WHERE {x => 3, z => 2}]),
   &sql_str('SELECT * FROM mytable WHERE ', {x => 3, z => 2}),
   'inline hashref');
is(&sql_str(sql[SELECT * FROM mytable WHERE %h]),
   &sql_str('SELECT * FROM mytable WHERE ', \%h),
   'hash');
is(&sql_str(sql[SELECT * FROM mytable WHERE $h]),
   &sql_str('SELECT * FROM mytable WHERE ', $h),
   'hashref');

# IN
is(&sql_str(sql[SELECT * FROM mytable WHERE x IN [1, 2, 3]]),
   &sql_str('SELECT * FROM mytable WHERE x IN ', [1, 2, 3]),
   'IN inline arrayref');
is(&sql_str(sql[SELECT * FROM mytable WHERE x IN @v]),
   &sql_str('SELECT * FROM mytable WHERE x IN ', \@v),
   'IN array');
is(&sql_str(sql[SELECT * FROM mytable WHERE x IN $v]),
   &sql_str('SELECT * FROM mytable WHERE x IN ', $v),
   'IN arrayref');
is(&sql_str(sql[SELECT * FROM mytable WHERE x IN $x]),
   &sql_str('SELECT * FROM mytable WHERE x IN ', \$x),
   'IN scalar');

# INSERT
is(&sql_str(sql[INSERT INTO mytable [1, 2, 3]]),
   &sql_str('INSERT INTO mytable ', [1, 2, 3]),
   'INSERT inline arrayref');
is(&sql_str(sql[INSERT INTO mytable @v]),
   &sql_str('INSERT INTO mytable ', \@v),
   'INSERT array');
is(&sql_str(sql[INSERT INTO mytable $v]),
   &sql_str('INSERT INTO mytable ', $v),
   'INSERT arrayref');
is(&sql_str(sql[INSERT INTO mytable {one => 1, two => 2}]),
   &sql_str('INSERT INTO mytable ', $h),
   'INSERT inline hashref');
is(&sql_str(sql[INSERT INTO mytable %h]),
   &sql_str('INSERT INTO mytable ', \%h),
   'INSERT hash');
is(&sql_str(sql[INSERT INTO mytable $h]),
   &sql_str('INSERT INTO mytable ', $h),
   'INSERT hashref');
is(&sql_str(sql[INSERT INTO mytable $x]),
   &sql_str('INSERT INTO mytable ', \$x),
   'INSERT scalar');

# concat
is(&sql_str(sql[SELECT * FROM mytable WHERE x =] . \$x . "AND y=z"),
   &sql_str('SELECT * FROM mytable WHERE x =', \5, 'AND y=z'),
   'concat 1');
is(&sql_str(sql[SELECT * FROM mytable WHERE x IN ] . $v),
   &sql_str('SELECT * FROM mytable WHERE x IN ', $v),
   'concat 2');

