# See ../README for a description of this program.
# perl -I../../blib/lib -I../../blib/arch zoomtst3.pl <t1> [...] <tN> <query>
# for example:
# perl -I../../blib/lib -I../../blib/arch async.pl z3950.loc.gov:7090/Voyager z3950.indexdata.com:210/gils endeavor.flo.org:7090/Voyager mineral

use strict;
use warnings;
use Net::Z3950::ZOOM;

if (@ARGV < 2) {
    print STDERR "Usage: $0 target1 target2 ... targetN query\n";
    print STDERR "	eg. $0 z3950.indexdata.dk/gils localhost:9999 fish\n";
    exit 1;
}

my $n = @ARGV-1;
my(@z, @r);			# connections, result sets
my $o = Net::Z3950::ZOOM::options_create();
Net::Z3950::ZOOM::options_set($o, async => 1);

# Get first 10 records of result set (using piggyback)
Net::Z3950::ZOOM::options_set($o, count => 10);

# Preferred record syntax
Net::Z3950::ZOOM::options_set($o, preferredRecordSyntax => "usmarc");
Net::Z3950::ZOOM::options_set($o, elementSetName => "B");

# Connect to all targets: options are the same for all of them
for (my $i = 0; $i < $n; $i++) {
    $z[$i] = Net::Z3950::ZOOM::connection_create($o);
    Net::Z3950::ZOOM::connection_connect($z[$i], $ARGV[$i], 0);
}

# Search all
for (my $i = 0; $i < $n; $i++) {
    $r[$i] = Net::Z3950::ZOOM::connection_search_pqf($z[$i], $ARGV[-1]);
}

# Network I/O.  Pass number of connections and array of connections
my $nremaining = $n;
AGAIN:
my $i;
while (($i = Net::Z3950::ZOOM::event(\@z)) != 0) {
    my $ev = Net::Z3950::ZOOM::connection_last_event($z[$i-1]);
    print("connection ", $i-1, ": event $ev (",
	  Net::Z3950::ZOOM::event_str($ev), ")\n");
    last if $ev == Net::Z3950::ZOOM::EVENT_END;
}

if ($i != 0) {
    # Not the end of the whole loop; one server is ready to display
    $i--;
    my($error, $errmsg, $addinfo) = (undef, "dummy", "dummy");
    my $tname = $ARGV[$i];

    # Display errors if any
    $error = Net::Z3950::ZOOM::connection_error($z[$i], $errmsg, $addinfo);
    if ($error) {
	print STDERR "$tname error: $errmsg ($error) $addinfo\n";
	goto MAYBE_AGAIN;
    }

    # OK, no major errors.  Look at the result count
    my $size = Net::Z3950::ZOOM::resultset_size($r[$i]);
    print "$tname: $size hits\n";

    # Go through all records at target
    $size = 10 if $size > 10;
    for (my $pos = 0; $pos < $size; $pos++) {
	print "$tname: fetching ", $pos+1, " of $size\n";
	my $tmp = Net::Z3950::ZOOM::resultset_record($r[$i], $pos);
	if (!defined $tmp) {
	    print "$tname: can't get record ", $pos+1, "\n";
	    next;
	}
	my $rec = Net::Z3950::ZOOM::record_get($tmp, "render");
	if (!defined $rec) {
	    print "$tname: can't render record ", $pos+1, "\n";
	    next;
	}
	print $pos+1, "\n", $rec, "\n";
    }
}

MAYBE_AGAIN:
if (--$nremaining > 0) {
    goto AGAIN;
}

# Housekeeping
for (my $i = 0; $i < $n; $i++) {
    Net::Z3950::ZOOM::resultset_destroy($r[$i]);
    Net::Z3950::ZOOM::connection_destroy($z[$i]);
}

Net::Z3950::ZOOM::options_destroy($o);
