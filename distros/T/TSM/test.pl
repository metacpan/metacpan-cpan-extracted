# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use TSM;
$loaded = 1;
print "ok 1\n";
my $tsm = TSM->new();
print "ok 2\n" if $tsm;
print "not ok 2\n" unless $tsm;


my %volumes = ('000923' => {STGPOOL_NAME => "TESTPOOL"});

print "Vorher: 0000923 -> $volumes{'000923'}{STGPOOL_NAME}\n";

my $retval = $tsm->select_hash(\%volumes, "* from volumes where volume_name>'000920'");

print "$retval (new) elements (changed)\n";
foreach my $element (sort keys %volumes)
{
	print "$element: $volumes{$element}{STGPOOL_NAME}\n";
};




my $array = $tsm->select("* from volumes where volume_name>'000930'");
foreach my $element2 (@$array)
{
	print "$element2->{VOLUME_NAME}:\t $element2->{STGPOOL_NAME}\n";
};


my @columns = $tsm->get_columns(volumes);

foreach my $element (@columns)
{
        print "$element\n";
};

my $output = $tsm->select_single("* from status");

foreach my $hashkey (sort keys %$output)
{
	print "$hashkey:\t $output->{$hashkey}\n";
};

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

