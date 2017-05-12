package Solaris::Kstat;
use strict;
use DynaLoader;
use vars qw($VERSION @ISA);
$VERSION = '0.02';
@ISA = qw(DynaLoader);
bootstrap Solaris::Kstat $VERSION;
1;
__END__

=head1 NAME

Solaris::Kstat - access Solaris Kstats from Perl

=head1 SYNOPSIS

   use Solaris::Kstat;
   my $kstat = Solaris::Kstat->new();
   my ($usr1, $sys1, $wio1, $idle1) =
      @{$kstat->{cpu_stat}{0}{cpu_stat0}}{qw(user kernel wait idle)};
   print("usr sys wio idle\n");
   while (1)
      {
      sleep 5;
      if ($kstat->update()) { print("Configuration changed\n"); }
      my ($usr2, $sys2, $wio2, $idle2) =
         @{$kstat->{cpu_stat}{0}{cpu_stat0}}{qw(user kernel wait idle)};
      printf(" %.2d  %.2d  %.2d  %.2d\n",
             ($usr2 - $usr1) / 5, ($sys2 - $sys1) / 5,
             ($wio2 - $wio1) / 5, ($idle2 - $idle1) / 5);
      $usr1 = $usr2; $sys1 = $sys2; $wio1 = $wio2; $idle1 = $idle2;
      }

=head1 DESCRIPTION

This module provides a tied hash interface to the Solaris kstats library.  The
kstats library allows you to get access to all the stats used by sar, iostat,
vmstat etc, plus a lot of others that aren't accessible through the usual
utilities.

Solaris categorises statistics using a 3-part key - module, instance and name.
For example, the root disk stats can be found under sd.0.sd0, and the cpu
statistics can be found under cpu_stat.0.cpu_stat0, as in the above example.
The method C<Solaris::Kstats->new()> creates a new 3-layer tree of perl hashes
with exactly the same structure - i.e. the stats for disk 0 can be accessed as
C<$ks->{sd}{0}{sd0}>.  The bottom (4th) layer is a tied hash used to hold the
individual statistics values for a particular system resource.

Creating a Solaris::Kstat object doesn't actually read all the possible
statistics in, as this would be horribly slow and inefficient.  Instead it
creates a 3-layer structure as described above, and only reads in the
individual statistics as you reference them.  For example, accessing
C<$ks->{sd}{0}{sd0}{reads} will read in all the statistics for sd0, including
writes, bytes read/written, service times etc.  Once you have accessed a bottom
level statitics value, calling $ks->update() will automatically update all the
individual values of any statistics that you have accessed.

Note that there are two values per bottom-level hash that can be read without
causing the full set of statistics to be read from the kernel.  These are
"class" which is the kstat class of the statistics and "crtime" which is the
time that the kstat was created.  See kstat(3K) for full details of these
fields.

=head1 PROBLEMS WITH 64-BIT VALUES

Several of the statistics returned by the Solaris kstat mechanism are stored as
64-bit integer values.  Perl doesn't fully support 64-bit integers (yet), so a
workaround had to be found to allow 64-bit values to be stored within Perl.
There are two classes of 64-bit value that have to be dealt with:

=head2 64-bit intervals and times

These are the crtime and snaptime fields of all the statistics hashes, and the
wtime, wlentime, wlastupdate, rtime, rlentime and rlastupdate fields of the
kstat disk statistics structures .  These are expressed by the Solaris kstats
library in nanoseconds.  If these values are stored in a 32-bit integer they
will wrap after about 4 seconds, so this is obviously not a useful thing to do.
The other alternative is to store the values as floating-point numbers, which
on both the Sparc & Intel architectures offer ~53 bits of precision.  I have
therefore decided to save all 64-bit intervals and timers as floating-point
values expressed in seconds.

=head2 64-bit counters

Again, it is not useful to store these values as 32-bit values.  However, as
noted above floating-point values offer 53 bits of precision.  Accordingly, all
64-bit counters are stored as floating-point values.

=head1 METHODS

=head2 new()

Create a new kstat statistics hierarchy and return a reference to the top-level
hash.  Use it like any normal hash to access the statistics.

=head2 refresh()

Update all the ststistics that have been accessed so far.  Note that as the
statistics are stored in a tied hash you can't use references to members of the hash, e.g. C<my $ref = \$ks->{sd}{0}{sd0}{reads}> followed by
C<print("$$ref\n");>, as the reference gets a copy of the value and won't be
updated by refresh().

=head1 CAVEATS

Due to several bugs in Perl 5.004_04, this module won't work with that verison
of Perl - Sorry.  Use 5.005_02 or above, or 5.004_05 when it is available.

See the warning above about 64-bit values.  Don't forget that hires times are
stored in seconds, not nanoseconds.

See the warning above about references.

This isn't a tutorial on Solaris statistics and tuning - please refer to the
book below.

=head1 AUTHOR

Alan Burlison, <Alan.Burlison@uk.sun.com>

=head1 SEE ALSO

L<perl(1)>, L<kstat(3K)>, L<kstat_open(3K)>, L<kstat_close(3K)>,
L<kstat_read(3K)>, L<kstat_chain_update(3K)>.

"Sun Performance And Tuning - Java And The Internet" 2nd ed. by Adrian Cockroft
and Richard Pettit - ISBN 0-13-095249-4.  This explains what most of the
individual statistics actually mean.

=cut
