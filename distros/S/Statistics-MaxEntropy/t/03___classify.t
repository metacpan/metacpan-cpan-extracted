#!/Utils/bin/perl5.00502
#!/usr/bin/perl
#!/Utils/bin/perl5

print "1..128\n";
$i = 1;

use Statistics::MaxEntropy qw($debug
			      $NEWTON_max_it
			      $NEWTON_min
			      $KL_max_it
			      $KL_min
			      $SAMPLE_size);
use Statistics::SparseVector;
use strict;
use vars qw($scaling
	    $sampling
	    $i
	    $TMP
	    $events_file
	    $bin_events
            $parameters_file
            $candidates_file
	    $new_events_file
            $new_candidates_file
            $bin_dump_file
	    $vec
	    $vec1
	    $vec2
	    $vec3
	    %table);


# debugging messages; default 0
$debug = 0;
# maximum number of iterations for IIS; default 100
$NEWTON_max_it = 25;
# minimal distance between new and old x for Newton's method; default 0.001
$NEWTON_min = 0.0001;
# maximum number of iterations for Newton's method; default 100
$KL_max_it = 25;
# minimal distance between new and old x; default 0.0001
$KL_min = 0.001;

$TMP = "/tmp";
$events_file = "data/events.txt";
#$events_file = "/home/parlevink/terdoest/tmp/bitlist";
$parameters_file = "data/parameters.txt";
$new_events_file = "$TMP/new.events.txt";
$bin_dump_file = "$TMP/bin.dump.txt";

# test the scalers for each of the sampling methods
$bin_events = Statistics::MaxEntropy->new("binary", $events_file);
$sampling = "enum";
$vec = Statistics::SparseVector->new(4130);
for $scaling ("gis", "iis") {
    $bin_events->clear();
    $bin_events->scale("corpus", $scaling);
    for ($i = 0; $i < 2**6; $i++) {
	my($y, $w) = $bin_events->classify($vec);
        if ($y) {
            print $y->to_Bin(''), "\t$w\n";
        }
        print "ok\n";
	$vec->increment();
    }
}


