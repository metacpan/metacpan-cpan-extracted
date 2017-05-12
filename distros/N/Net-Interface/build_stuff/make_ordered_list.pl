#!/usr/bin/perl

#use diagnostics;

#	Copyright 2008 - 2009, Michael Robinton
#
#	This library is free software; you can redistribute it
#	and/or modify it under the same terms as Perl itself.
#

my $debug = 0;	# set to 1 for restricted debug output
		# set to 2 for trace print
my $last  = 2;	# set to the number of included files to process

my $usage = q|
usage:
create #include list files by grep'ing

grep -e \#[:space:]*include *.c > ifile

cat files together, edit the list and 
use the result as the script argument

	|. $0 . q| filename

|;

die $usage unless @ARGV;
open(F,$ARGV[0]) || die $usage;

my @have = qw(
        <errno.h>
        <sys/types.h>
        <sys/stat.h>
	<stdio.h>
        <stdlib.h>
        <stddef.h>
        <memory.h>
        <string.h>
        <strings.h>
        <inttypes.h>
        <stdint.h>
        <unistd.h>
	<sys/socket.h>
);

my $start = @have;

my(%have,%defaults);
foreach(0..$#have) {
  my $hf = $have[$_];
  $have{$hf} = $_;	# mark index in array
  $defaults{$hf} = 1;	# mark default exclusion
}

my %exclude = (
# headers that we do not want at all because
# they redefine stuff in PERL
	'<err.h>'		=> 1,
	'<assert.h>'		=> 1,
	'<net/if_bridgevar.h>'	=> 1,
	'<termios.h>'		=> 1,
);

my(@f,%f);
foreach(<F>) {
  next unless $_ =~ m|/([^/:]+):#\s*include.+\<\s*(.+\.h)\s*>|;
  my $hf = '<'. $2 .'>';
  next if exists $exclude{$hf};
  if (exists $f{$1}) {
    push @{$f{$1}}, $hf;
  } else {
    $f{$1} = [$hf];
    push @f, $1;		# save order of files processed
  }
}
close F;

# samples
#'netrom.c' => qw(sys/types.h sys/ioctl.h sys/socket.h net/if_arp.h netax25/ax25.h linux/ax25.h stdlib.h stdio.h ctype.h errno.h fcntl.h string.h termios.h unistd.h),
#'ether_addr.c' => qw(features.h ctype.h stdio.h stdlib.h netinet/ether.h netinet/if_ether.h),

# return index into have if header file exists
sub havit {
  my($p,$hf) = @_;
  foreach ($p..$#have) {
    return $_ if $hf eq $have[$_];
  }
  return -1;
}

foreach my $cf (@f) {		# for each surveyed file
  my $bef = 0;
  my(@stash,%stash);
  foreach my $hf (@{$f{$cf}}) {
    print "$cf: $hf  " if $debug > 1;
    my $have = havit($bef,$hf);
    if ($have < 0) {			# can't find it in remaining array
      if (exists $have{$hf}) {		# if passed it by
	$have = $have{$hf};		# for debug
      } else {
	print "stashing  " if $debug > 1;
	unshift @stash, $hf;
	$stash{$hf} = $bef;		# mark insertion point
      }
    } else {				# have it
      $bef = $have;
    }
    print "have = $have\n" if $debug > 1;
  }

  foreach(@stash) {
# always insert beyond permanent unless no perceeding permanent members
    my $ix = ($stash{$_} && $stash{$_} < $start) ? $start : $stash{$_};
    print "revadd $_ at stsh = $stash{$_}, ix = $ix\n" if $debug > 1;
    ++$start unless $ix;		# if the permanent list is longer, move end pointer;
    splice @have,$ix,0,$_;
    $have{$_} = $ix;
  }
  if ($debug) {
    --$last;
    last unless $last > 0;
  }
}

foreach (@have) {
  print "$_\n" unless 1 && exists $defaults{$_};
}
  