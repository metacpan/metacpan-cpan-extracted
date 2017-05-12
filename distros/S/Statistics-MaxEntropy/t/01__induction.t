#!/usr/bin/perl
#!/Utils/bin/perl5.00502

print "1..5\n";
$i=1;

use Statistics::MaxEntropy qw($debug
			      $NEWTON_max_it
			      $NEWTON_min
			      $KL_max_it
			      $KL_min
			      $SAMPLE_size);

use Statistics::Candidates;

use vars qw($scaling
	    $sampling
	    $i
	    $TMP
	    $events_file
            $parameters_file
            $candidates_file
	    $new_events_file
            $new_candidates_file
            $dump_file_1
            $dump_file_2);


# debugging messages; default 0
$debug = 0;
# maximum number of iterations for IIS; default 100
$NEWTON_max_it = 100;
# minimal distance between new and old x for Newton's method; default 0.001
$NEWTON_min = 0.0001;
# maximum number of iterations for Newton's method; default 100
$KL_max_it = 100;
# minimal distance between new and old x; default 0.0001
$KL_min = 0.00001;

$TMP = "/tmp";
$events_file = "data/events.txt";
$parameters_file = "data/parameters.txt";
$candidates_file = "data/candidates.txt";
$new_events_file = "$TMP/new.events.txt";
$new_candidates_file = "$TMP/new.candidates.txt";
$dump_file_1 = "$TMP/dump.1.txt";
$dump_file_2 = "$TMP/dump.2.txt";


# test the feature induction for each of the scaling/sampling methods
$events=Statistics::MaxEntropy->new("binary", $events_file);
$candidates = Statistics::Candidates->new($candidates_file);
for $sampling ("enum", "corpus") {
    for $scaling ("gis", "iis") {
	$candidates->clear();
	$events->clear();
	$events->fi($scaling, $candidates, 2, $sampling);
	print "ok $i\n";
	$i++;
    }
}

$events->dump($dump_file_2);
$events->write($new_events_file);
$events->write_parameters($parameters_file);
$candidates->write($new_candidates_file);
print "ok $i\n";

__END__
