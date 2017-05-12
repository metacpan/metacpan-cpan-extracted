#!/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 6 };
use Speech::Recognizer::ScLite;
ok(1); # If we made it this far, we're ok.

#########################

use Speech::Recognizer::ScLite::Line;

ok(2); # successfully loaded Speech::Recognizer::ScLite::Line

my ($testdir) = 'blib/test';
if (! -d $testdir) {
    use File::Path 'mkpath';
    mkpath ([ $testdir ], 1) or die "can't make directory $testdir: $! \n";
}

Speech::Recognizer::ScLite->executable( 'sclite' );

my ($scorer) = 
  Speech::Recognizer::ScLite->new(result_location => $testdir);

ok(3); # successfully created an instance of Speech::Recognizer::ScLite

my (%correct_readings) = read_trans('t/test.ref');
my (%hyp_readings) = read_trans('t/test.hyp');

ok(4); # successfully read test files

foreach my $line (sort keys %hyp_readings) {
    # construct an object to represent this version
    # construct any sort key you want. Here we assume that we're
    # interested in breaking out the files based on which directory
    # they're in.
    my ($l) = 
      Speech::Recognizer::ScLite::Line->new( 
					     ref => $correct_readings{$line},
					     hyp => $hyp_readings{$line},
					     sort_key =>
					       getSort($line),
					     wf_id => $line
					     );
					 
    $scorer->lines_push($l);
    
} # end of looping over the filenames.

ok(5);

# computes actual ASR performance, given above information
my ($rc) = $scorer->score();

ok($rc == 0); # executed score() function without bad return value

# check that files exist where they should.


##################################################################
sub read_trans {
    my (%transcriptions);
    my ($file) = shift;
    open (FILE, $file) or die "couldn't open $file: $!\n";
    while (<FILE>) {
	chomp;
	my ($trans, $fileID) = split /\t/;
	$transcriptions{$fileID} = $trans;
    }
    close FILE; # or die, of course
    return %transcriptions;
}
##################################################################
# this toy sort routine returns the sex of the speaker as the sort
# key, rather than the (default) speaker directory.
sub getSort {
    my ($filename) = shift;
    return ($filename =~ /female/i ? 'Female' : 'Male');
}
##################################################################
