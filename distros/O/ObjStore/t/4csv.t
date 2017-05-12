# imagine, -*-perl-*- does reports too!
use Test;
BEGIN { plan tests => 2 }

use strict;
use ObjStore::CSV;

sub mk_table {
    my @rows;
    for (1..3) {
	push(@rows, { c1 => $_, c2 => $_ * 2, c3 => 'c3', c4 => ('B' x $_) });
    }
    @rows;
}

my $file = "/tmp/t$$";

my $fh = new IO::File "> $file";
print_csv([mk_table()], fh => $fh);
$fh->close;
my $out = `cat $file`;
#warn $out;
ok(1); #should diff it XXX

$fh = new IO::File "> $file";
print_csv({ map { $_->{c1} / 2.0, $_ } mk_table() }, fh => $fh,
	  cols => [qw(c2 c1)]);
$fh->close;
$out = `cat $file`;
#warn $out;
ok(1);

unlink $file;

# yes this test sucks! :-)
