#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($^O eq 'VMS' or $^O eq 'os2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w
!GROK!THIS!
# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
#                              -*- Mode: Perl -*- 
# mm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sat Nov  2 17:28:28 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon Mar 24 10:59:58 1997
# Language        : CPerl
# Update Count    : 84
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
# 
eval 'exec perl -w -S $0 "$@"'
    if 0;

use Getopt::Long;
use IO::File;
use strict;
use vars qw(%OPT);
use NNML::Config qw($Config);

my $home = $ENV{'HOME'} || $ENV{'LOGDIR'} ||
    (getpwuid($<))[7] || die "You're homeless!\n";

my $conf = $Config->base . "/NNML.conf";
my $date = $Config->base . "/NNML.date";

GetOptions(\%OPT,
           'nono!'
           ) or die "Usage: $0 ...\n";

my $cf = new IO::File "<$conf";
die "Could not read '$conf': $!\n" unless $cf;

$/ = '';                        # read paragraph mode

my %date = read_dates($date);
my %new_date;                   # we append anyway
my %key;                        # pid -> from;to
my %start;                      # pid -> start time

$SIG{CHLD} = sub {
  my $pid    = wait;
  my $status = $? >> 8;
  print "Child $pid terminated with status $status\n";
  if ($key{$pid}) {
    $new_date{$key{$pid}} = $start{$pid} unless $status;
    print "Key was $key{$pid}, start time was $start{$pid}\n";
    delete $key{$pid};
  } else {
    print "No key for this child!?\n";
  }
};

my $job;
while (defined ($job = <$cf>)) {
  my %job;
  my $line;
  for $line (split /\n/, $job) {
    next if $line =~ /^\#/;
    next if $line =~ /^\s*$/;
    my ($cmd,@fld) = split ' ', $line;
    for (@fld) {
      $_ = '' if $_ eq '*';
    }
    if      ($cmd eq 'from') {
      @job{qw(fhost fuser fpass fport only)} = @fld;

      if ($job{only}) {
        if ($job{only} =~ s/^!//) {
          $job{ignore} = $job{only};
          delete $job{only};
        }
      } else {
        delete $job{only};
      }
    } elsif ($cmd eq 'to') {
      @job{qw(thost tuser tpass tport)} = @fld;
    } elsif ($cmd eq '*') {
      push @{$job{group}}, @fld;
    }
  }
  run_job(%job) if scalar %job;
}

print "Waiting for children to die\n";
while (keys %key) {
  sleep 1;
}

write_dates($date, %new_date);

print "\a\a\aAll childs terminated. You may shut down the connection now\n";

exit 0;

sub run_job {
  my %parm = @_;
  my $from = "$parm{fhost}:$parm{fport}";
  my $to   = "$parm{thost}:$parm{tport}";
  my $last = $date{$from,$to} || 0;
  my ($sec,$min,$hour,$mday,$mon,$year) = localtime($last);
  my $date = sprintf "%02d%02d%02d", $year, $mon+1, $mday;
  my $time = sprintf "%02d%02d%02d", $hour, $min, $sec;
  my @args = ('-date', $date, '-time', $time);

  if ($parm{group}) {
    for (@{$parm{group}}) {
      push @args, '-group', $_;
    }
    delete $parm{group};
  }
  for (sort keys %parm) {
    push @args, '-'.$_, $parm{$_};
  }
  print "nnmirror ", join(':', @args), "\n";
  my $key = "$from$;$to";
  my $pid;

  if ($pid = fork()) {
    if ($pid<0) {
      warn "Could not fork: $!\n";
      return;
    }
    print "started child pid=$pid\n";
    $start{$pid} = time;
    $key{$pid}   = $key;
  } else {
    sleep(1);
    exec $^X, '-S', 'nnmirror', @args;
  }
}

sub read_dates {
  my $date = shift;
  my %date;
  
  if (-e $date) {
    my $cf = new IO::File "<$date";
    die "Could not read '$date': $!\n" unless $cf;
    local $/ = "\n";
    while (defined ($job = <$cf>)) {
      next if $job =~ /^\#/;
      my($from,$to,$mtime) = split ' ', $job;
      next unless $to;          # sanity check
      $date{$from,$to} = $mtime;
    }
  } else {
    warn "\aNo dates file found: '$date'\tAssuming epoch!\n";
  }
  %date;
}

sub write_dates {
  my $date = shift;
  my %date = @_;

  #if (-e $date) {
  #  rename $date, "$date~"
  #    or warn "Could not rename old '$date': $!\n";
  #}
  my $cf = new IO::File ">>$date";
  die "Could not write '$date': $!\n" unless $cf;
  for (keys %date) {
    my ($from, $to) = split /$;/, $_;
    my $mtime = $date{$_};
    $cf->printf("%s\t%s\t%d\t%s\n", $from, $to, $mtime,
                scalar(localtime $mtime));
  }
}






!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
