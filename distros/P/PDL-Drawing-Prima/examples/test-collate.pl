use strict;
use warnings;
;
use PDL;
use PDL::Drawing::Prima;

my $N_entries = 10;

my $x = zeroes($N_entries,2)->grandom * 3 + 10;
my $xRadii = ($x->grandom * 3 + 1)->floor->short->abs;
my $yRadii = ($x->grandom * 3 + 1)->floor->short->abs;
my $y = $x->sequence;
my $colors = $x->sequence;

print "x is $x\nxRadii is $xRadii\n";

# Randomly mark one element of each piddle as bad:
for (0,1) {
#	$x->setbadat(int rand $N_entries, $_);
#	$xRadii->setbadat(int rand $N_entries, $_);
	$yRadii->setbadat(int rand $N_entries, $_);
	$y->setbadat(int rand $N_entries, $_);
	$colors->setbadat(int rand $N_entries, $_);
}



 my ($blob_x_min, $blob_x_max)
     = PDL::collate_min_max_wrt_many(
         $x, $xRadii,    # min and index
         $x, $xRadii,    # max and index
         $xRadii->max,   # only need the number of pixels corresponding to the widget
         $y,             # \
         $yRadii,        #  |- ignore x-values if any of these are bad
         $colors,        # /
     );

# OK, now print out what we expect:
my $bad_idx = $x->isbad() | $xRadii->isbad() | $yRadii->isbad()
		| $y->isbad() | $colors->isbad();
print "bad_idx are $bad_idx\n";
$x = $x->setbadif($bad_idx);
$xRadii = $xRadii->setbadif($bad_idx);

print "x is $x\nxRadii is $xRadii\n";
print "blob_x_min: $blob_x_min\nblob_x_max: $blob_x_max\n";

print "blob_x_min's dims are ", join(', ', $blob_x_min->dims), "\n";

# overall, we have
$blob_x_min = $blob_x_min->mv(0,-1);
$blob_x_min = $blob_x_min->minimum while $blob_x_min->ndims > 1;
$blob_x_max = $blob_x_max->mv(0,-1);
$blob_x_max = $blob_x_max->minimum while $blob_x_max->ndims > 1;

print "Collapsed, we get $blob_x_min\nand $blob_x_max\n";

# Finally, run the trim_collated function on them:
my $min = $blob_x_min->cat($blob_x_min->sequence, $blob_x_min)->whereND($blob_x_min->isgood);
my $max = $blob_x_max->cat($blob_x_max->sequence, $blob_x_max)->whereND($blob_x_max->isgood);

my $min_mask = PDL::trim_collated_min($min);
my $max_mask = PDL::trim_collated_max($max);
print "combined and trimmed, we have\nmin: ", $min->whereND($min_mask), "\n";
print "max: ", $max->whereND($max_mask), "\n";
