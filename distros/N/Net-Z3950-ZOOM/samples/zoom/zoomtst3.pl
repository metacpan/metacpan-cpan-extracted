# See ../README for a description of this program.
# perl -I../../blib/lib -I../../blib/arch zoomtst3.pl <t1> [...] <tN> <query>
# for example:
# perl -I../../blib/lib -I../../blib/arch zoomtst3.pl z3950.loc.gov:7090/Voyager z3950.indexdata.com:210/gils endeavor.flo.org:7090/Voyager mineral

use strict;
use warnings;
use ZOOM;

if (@ARGV < 2) {
    print STDERR "Usage: $0 target1 target2 ... targetN query\n";
    print STDERR "	eg. $0 z3950.indexdata.dk/gils localhost:9999 fish\n";
    exit 1;
}

my $n = @ARGV-1;
my(@z, @r);			# connections, result sets
my $o = new ZOOM::Options();
$o->option(async => 1);

# Get first 10 records of result set (using piggyback)
$o->option(count => 10);

# Preferred record syntax
$o->option(preferredRecordSyntax => "usmarc");
$o->option(elementSetName => "F");

# Connect to all targets: options are the same for all of them
for (my $i = 0; $i < $n; $i++) {
    $z[$i] = create ZOOM::Connection($o);
    $z[$i]->connect($ARGV[$i]);
}

# Search all
for (my $i = 0; $i < $n; $i++) {
    $r[$i] = $z[$i]->search_pqf($ARGV[-1]);
}

# Network I/O.  Pass number of connections and array of connections
while ((my $i = ZOOM::event(\@z)) != 0) {
    my $ev = $z[$i-1]->last_event();
    print("connection ", $i-1, ": event $ev (", ZOOM::event_str($ev), ")\n");
    # It would be nice to display results as they come in, but the
    # ability to do so is dependent on the END event, which was
    # introduced only in YAZ 2.1.17.  If you have a sufficiently new
    # YAZ, please use the alternative "async.pl", which is similar to
    # this program except in its asynchronous display.
}

# No more to be done.  Inspect results
for (my $i = 0; $i < $n; $i++) {
    my $tname = $ARGV[$i];
    my($error, $errmsg, $addinfo, $diagset) = $z[$i]->error_x();
    if ($error) {
	print STDERR "$tname error: $errmsg ($error) $addinfo\n";
	next;
    }

    # OK, no major errors.  Look at the result count
    my $size = $r[$i]->size();
    print "$tname: $size hits\n";

    # Go through all records at target
    $size = 10 if $size > 10;
    for (my $pos = 0; $pos < $size; $pos++) {
	print "$tname: fetching ", $pos+1, " of $size\n";
	my $tmp = $r[$i]->record($pos);
	if (!defined $tmp) {
	    print "$tname: can't get record ", $pos+1, "\n";
	    next;
	}
	my $rec = $tmp->render();
	if (!defined $rec) {
	    print "$tname: can't render record ", $pos+1, "\n";
	    next;
	}
	print $pos+1, "\n", $rec, "\n";
    }
}

# Housekeeping
for (my $i = 0; $i < $n; $i++) {
    $r[$i]->destroy();
    $z[$i]->destroy();
}

$o->destroy();
