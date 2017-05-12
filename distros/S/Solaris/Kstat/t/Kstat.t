# test script for Solaris::Kstat
use strict;

# Visit all the leaf nodes -
# will generate a die if there are any structure mismatches
sub visit_all($)
{
my ($ks) = @_;
foreach my $m (sort(keys(%$ks)))
   {
   foreach my $i (sort(keys(%{$ks->{$m}})))
      {
      foreach my $n (sort(keys(%{$ks->{$m}->{$i}})))
         {
         foreach my $k (sort(keys(%{$ks->{$m}->{$i}->{$n}})))
            {
            my $v = $ks->{$m}->{$i}->{$n}->{$k};
            }
         }
      }
   }
return(1);
}

BEGIN { $| = 1; print "1..15\n"; }
my $loaded;
END {print "not ok 1\n" unless $loaded;}
use Solaris::Kstat;
$loaded = 1;
print "ok 1\n";

# Check we can create a Kstat object OK
my ($test, $ks);
$test = 2;
if (! eval { $ks = Solaris::Kstat->new() })
   { print("not ok $test: $@"); }
else
   { print("ok $test\n"); }
$test++;

# Check FIRSTKEY/NEXTKEY/FETCH and for structure mismatches
if (! eval { visit_all($ks) })
   { print("not ok $test: $@"); }
else
   { print("ok $test\n"); }
$test++;

# Find a cpu number
my $cpu = (keys(%{$ks->{cpu_info}}))[0];
my $cpu_info = "cpu_info$cpu";

# Check EXISTS
if (exists($ks->{cpu_info}{$cpu}{$cpu_info}{state}))
   { print("ok $test\n"); }
else
   { print("not ok $test\n"); }
$test++;

# Check DELETE
my $val = delete($ks->{cpu_info}{$cpu}{$cpu_info}{state});
if (defined($val) && ($val eq "on-line" || $val eq "off-line"))
   { print("ok $test\n"); }
else
   { print("not ok $test ($val)\n"); }
$test++;

# 5.004_04 has a broken hv_delete
if ($[ < 5.00405)
   {
   print("ok $test\n");
   $test++;
   print("ok $test\n");
   $test++;
   }
else
   {
   if (! exists($ks->{cpu_info}{$cpu}{$cpu_info}{state}))
      { print("ok $test\n"); }
   else
      { print("not ok $test\n"); }
   $test++;
   $val = $ks->{cpu_info}{$cpu}{$cpu_info}{state};
   if (! defined($val))
      { print("ok $test\n"); }
   else
      { print("not ok $test\n"); }
   $test++;
   }

# Check STORE
$ks->{cpu_info}{$cpu}{$cpu_info}{state} = "california";
if ($ks->{cpu_info}{$cpu}{$cpu_info}{state} eq "california")
   { print("ok $test\n"); }
else
   { print("not ok $test\n"); }
$test++;

# Check CLEAR
%{$ks->{cpu_info}{$cpu}{$cpu_info}} = ();
my @vals = sort(keys(%{$ks->{cpu_info}{$cpu}{$cpu_info}}));
if (@vals == 2 && $vals[0] eq "class" && $vals[1] eq "crtime")
   { print("ok $test\n"); }
else
   { print("not ok $test: (@vals)\n"); }
$test++;

# Check updates
if (! defined(eval { $ks->update() }))
   { print("not ok $test: $@"); }
else
   { print("ok $test\n"); }
$test++;

# Check readonly-ness of hash structure
eval { $ks->{cpu_info}{0}{cpu_info0} = {}; };
print($@ =~ /^Modification of a read-only/i ? "ok $test\n" : "not ok $test\n");
$test++;

eval { $ks->{cpu_info}{0} = {}; };
print($@ =~ /^Modification of a read-only/i ? "ok $test\n" : "not ok $test\n");
$test++;

eval { $ks->{cpu_info} = {}; };
print($@ =~ /^Modification of a read-only/i ? "ok $test\n" : "not ok $test\n");
$test++;

# Check timestamps
my $then = $ks->{cpu_info}{$cpu}{$cpu_info}{snaptime};
sleep(3);
if (! defined(eval { $ks->update() }))
   { print("not ok $test: $@"); }
else
   { print("ok $test\n"); }
$test++;
my $interval = $ks->{cpu_info}{$cpu}{$cpu_info}{snaptime} - $then;
if ($interval >= 2.5 && $interval <= 3.5)
   { print("ok $test\n"); }
else
   { print("not ok $test\n"); }
$test++;

exit(0);
