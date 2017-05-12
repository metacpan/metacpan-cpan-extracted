#!/Utils/bin/perl5.00502
#!/usr/bin/perl
#!/Utils/bin/perl5

print "1..7\n";
$i = 1;

use Statistics::MaxEntropy qw($debug
			      $NEWTON_max_it
			      $NEWTON_min
			      $KL_max_it
			      $KL_min
			      $SAMPLE_size);

use Statistics::Candidates;
use strict;
use vars qw($scaling
	    $sampling
	    $i
	    $TMP
	    $events_file
	    $int_events
	    $bin_events
            $parameters_file
            $candidates_file
	    $new_events_file
            $new_candidates_file
            $int_dump_file
            $bin_dump_file);

# debugging messages; default 0
$debug = 0;
# maximum number of iterations for IIS; default 100
$NEWTON_max_it = 25;
# minimal distance between new and old x for Newton's method; default 0.001
$NEWTON_min = 0.0001;
# maximum number of iterations for Newton's method; default 100
$KL_max_it = 100;
# minimal distance between new and old x; default 0.0001
$KL_min = 0.00001;

$TMP = "/tmp";
$events_file = "data/events.txt";
$parameters_file = "data/parameters.txt";
$new_events_file = "$TMP/new.events.txt";
$bin_dump_file = "$TMP/bin.dump.txt";
$int_dump_file = "$TMP/int.dump.txt";


# test the scalers for each of the sampling methods
$bin_events=Statistics::MaxEntropy->new("binary", $events_file);
$int_events=Statistics::MaxEntropy->new("integer", $events_file);
$SAMPLE_size = 100;
for $sampling ("enum", "corpus", "mc") {
    for $scaling ("iis", "gis") {
 	$bin_events->clear();
 	$bin_events->scale($sampling, $scaling);
	if (($sampling ne "enum") && ($sampling ne "mc")) {
	    # no enumeration for int vectors
	    $int_events->clear();
	    $int_events->scale($sampling, $scaling);
	}
 	print "ok $i\n";
	$i++;
    }
}

# dump the event space
$bin_events->dump($bin_dump_file);
$int_events->dump($int_dump_file);
print "ok $i\n";

__END__
