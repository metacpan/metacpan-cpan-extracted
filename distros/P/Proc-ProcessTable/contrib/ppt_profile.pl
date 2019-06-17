#!/usr/bin/env perl

use warnings;
use strict;
use Time::HiRes;
use Proc::ProcessTable;

use Pod::Usage;
use Getopt::Long qw(:config auto_help);
use IO::Handle;

my %opt = (
  interval  => 1,
  num_steps => 3,
);

GetOptions( \%opt, 'process_id|pid|p', 'help|?', 'interval=f', 'num_steps=i' ) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 2 ) if ( $opt{help} );
pod2usage(2) unless ( @ARGV && @ARGV > 1 );

my ( $log_fn, @cmd ) = @ARGV;

my $poll_intervall    = int($opt{interval} * 1000 * 1000);
my $num_steps         = $opt{num_steps};
my $script_start_time = [ Time::HiRes::gettimeofday() ];

my $pid;

if ( $opt{process_id} ) {
  $pid = shift @cmd;
} else {
  $SIG{CHLD} = 'IGNORE';

  $pid = fork;
  die "cannot fork" unless defined $pid;
}

if ( $pid == 0 ) {
  #child

  system(@cmd);
  exit;

} else {
  #main

  my $time_point = 1;
  my @start_time;
  my @cpu_time;

  my $ppt = Proc::ProcessTable->new;

  say STDERR "tracking PID $pid";
  my $log_fh;
  if ( $log_fn eq '-' ) {
    $log_fh = \*STDOUT;
  } else {
    open $log_fh, '>', $log_fn or die "Can't open filehandle: $!";
  }

  print $log_fh join( "\t", qw/tp time pids rss vsz pcpu/ ), "\n";

  while ( kill( 0, $pid ) ) {
    my $t  = Time::HiRes::tv_interval($script_start_time);
    my $pt = parse_ppt( $ppt->table );

    my @pids;
    my $sum_rss   = 0;
    my $sum_vsz   = 0;
    my $sum_cpu   = 0;
    my $sum_start = 0;

    my %childs = map { $_ => 1 } subproc_ids( $pid, $pt );
    $childs{$pid}++ if ( $opt{process_id} );
    for my $p (@$pt) {
      #[0] pid
      #[1] ppid
      #[2] rss
      #[3] size
      #[4] time
      #[5] start
      if ( $childs{ $p->[0] } ) {
        $sum_rss += $p->[2];
        $sum_vsz += $p->[3];
        # utime + stime (cutime and cstime not needed, because we iterate through children
        $sum_cpu += $p->[4];
        push @pids, $p->[0];
      }
    }

# calc pct cpu per interval:
# we need seconds since
#https://stackoverflow.com/questions/16726779/how-do-i-get-the-total-cpu-usage-of-an-application-from-proc-pid-stat

    #pctcpu = ( 100.0f * sum over all (prs->utime + prs->stime ) * 1/1e6 ) / (time(NULL) - prs->start_time);

    shift @cpu_time if ( @cpu_time > $num_steps );
    push @cpu_time, $sum_cpu;

    shift @start_time if ( @start_time > $num_steps );
    push @start_time, $t;

    my $ratio = 0;
    if ( @start_time >= $num_steps ) {
      my $diff_cpu   = ( $cpu_time[-1] - $cpu_time[0] ) / 1e6;
      my $diff_start = ( $start_time[-1] - $start_time[0] );
      $ratio = $diff_cpu / $diff_start if ( $diff_start > 0 );
    }
    print $log_fh join( "\t", $time_point, $t, join( ",", @pids ), $sum_rss, $sum_vsz, $ratio ), "\n";
    $log_fh->flush;

    Time::HiRes::usleep($poll_intervall);
    $time_point++;
  }
  $log_fh->close;
}

sub parse_ppt {
  my $ppt_table = shift;

  my @table = map { [ $_->pid, $_->ppid, $_->rss, $_->size, $_->time, $_->start ] } @$ppt_table;
  return \@table;
}

sub subproc_ids {
  my ( $pid, $procs ) = @_;
  #[ pid, parentid ]
  my @childs;
  for my $c ( grep { $_->[1] == $pid } @$procs ) {
    push @childs, $c->[0];
    push @childs, subproc_ids( $c->[0], $procs );
  }
  return @childs;
}

__END__

=head1 NAME

ppt_profile_cmd.pl - track the cpu and memory usage of a command

=head1 SYNOPSIS

ppt_profile_cmd.pl [OPTIONS] <log file> <command|process_id> [<arg1> <arg2> ... <argn>]

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
