# test script for Solaris::MapDev

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Solaris::MapDev qw(:ALL);
$loaded = 1;
print "ok 1\n";

my $failed = undef;
foreach my $inst (get_inst_names())
   {
   if (dev_to_inst(inst_to_dev($inst)) ne $inst)
      {
      $failed = $inst;
      last;
      }
   }
print($failed ? "not ok 2: $inst\n" : "ok 2\n");

$failed = undef;
foreach my $dev (get_dev_names())
   {
   if (inst_to_dev(dev_to_inst($dev)) ne $dev)
      {
      $failed = $dev;
      last;
      }
   }
print($failed ? "not ok 3: $inst\n" : "ok 3\n");
exit(0);
