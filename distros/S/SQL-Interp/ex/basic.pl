# one.pl
# simple tests of SQL::Interp.

use strict;
use Data::Dumper;
use SQL::Interp qw(:all);

my @colors = ('blue', 'green');
my $x = 5;
my($sql, @bind) = sql_interp qq[
    SELECT * FROM table
    WHERE color IN], \@colors, qq[
          AND y = ], \$x,
    "LIMIT", \10, "OFFSET", \0
;
print "$sql\n" . Dumper(\@bind);

@colors = ();
($sql, @bind) = sql_interp qq[
    SELECT * FROM table
    WHERE color IN], \@colors, qq[
          AND y = ], \$x,
    "LIMIT", \10, "OFFSET", \0
;
print "$sql\n" . Dumper(\@bind);

my $new_color = 'red';
my $new_shape = 'square';
($sql, @bind) = sql_interp qq[
    INSERT INTO table ], {
        color => $new_color,
        shape => $new_shape}
;
print "$sql\n" . Dumper(\@bind);

my $color = 'yellow';
($sql, @bind) = sql_interp qq[
    UPDATE table SET ], {
        color => $new_color,
        shape => $new_shape}, qq[
    WHERE color <> ], \$color
;
print "$sql\n" . Dumper(\@bind);

