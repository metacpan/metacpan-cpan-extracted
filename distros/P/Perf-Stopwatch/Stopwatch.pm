package Perf::Stopwatch;
require Exporter;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Time::HiRes qw(gettimeofday tv_interval);

$VERSION   = '0.10';
@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw(start stop lap clear getTime getLaps getMinLap getMaxLap);
%EXPORT_TAGS = (
    normal => [qw(start stop getTime)],
    burst  => [qw(start stop clear getTime)],
    lap    => [qw(start stop lap getTime getLaps getMinLap getMaxLap)],
    all    => [qw(start stop lap clear getTime getLaps getMinLap getMaxLap)]
);

sub new {
	my $inv = shift;
    my $cls = ref($inv) || $inv;

    # Possible $types are: normal, lap, burst
    my $obj = {
        type  => "normal",
        laps  => 100,
        c_lap => 0,
        final => 0,
        @_
    };

    # convert common string to efficient number comparison
    if( $obj->{type} eq "normal" ){
        $obj->{type} = 0;
    } elsif( $obj->{type} eq "lap" ){
        $obj->{type} = 1;
    } elsif( $obj->{type} eq "burst" ){
        $obj->{type} = 2;
    }
    $obj->{lap}[$obj->{laps}-1] = undef if( $obj->{type} == 1 );

    return bless $obj, $cls;
}

sub start {
    shift->{t_beg} = [gettimeofday];
}

sub stop {
    my $self = shift;
    $self->{t_end} = [gettimeofday];

    if( $self->{type} == 2 ){
        $self->{final} += tv_interval( $self->{t_beg}, $self->{t_end} );
    } elsif( $self->{type} == 1 ){
        $self->{lap}[$self->{c_lap}++] = tv_interval( $self->{t_beg}, $self->{t_end} );
    } elsif( $self->{type} == 0 ){
        $self->{final} = tv_interval( $self->{t_beg}, $self->{t_end} );
    }
}

sub lap {
    my $self = shift;
    $self->{t_end} = [gettimeofday];
    $self->{lap}[$self->{c_lap}++] = tv_interval( $self->{t_beg}, $self->{t_end} );
    $self->{t_beg} = [gettimeofday];
}

sub clear {
    shift->{final} = 0;
}

sub getTime {
    my $self = shift;

    if( $self->{type} == 1 ){
        $self->{final} = 0;
        $self->{final} += $_ foreach( @{$self->{lap}} );
    }
    return $self->{final};
}

sub numLaps {
    return shift->{c_lap};
}

sub getLaps {
    return shift->{lap};
}

sub getMaxLap {
    my @t = reverse sort { $a <=> $b } @{shift->{lap}};
    return $t[0];
}

sub getMinLap {
    my @t = sort { $a <=> $b } @{shift->{lap}};
    return $t[0];
}

1;
__END__

=head1 NAME

Perf::Stopwatch - A Simple Time Management module

=head1 SYNOPSIS

  use Perf::Stopwatch qw( :normal :burst );

  $sw_norm  = new Perf::Stopwatch();
  $sw_burst = new Perf::Stopwatch( type=> "burst" );

  $sw_norm->start();
  for( $i=0; $i<$max_iter; $i++ ){
      $sw_burst->start();
      # do something...
      $sw_burst->stop();
      # do some more...
  }
  $sw_norm->stop();

  $elapsed1 = $sw_norm->getTime();
  $elapsed2 = $sw_burst->getTime();

  use Perf::Stopwatch qw( :lap );

  $sw_lap = new Perf::Stopwatch( type => "lap", laps => $max_iter );

  for( $i=0, $sw_lap->start(); $i<$max_iter; $i++ ){
      # do something ...
      $sw_lap->lap();
  }

  $elapsed3 = $sw_lap->getTime();
  @all_laps = @{$sw_lap->getLaps()};
  $num_laps = $sw_lap->numLaps();
  $min_lap  = $sw_lap->getMinLap();
  $max_lap  = $sw_lap->getMaxLap();
  $avg_lap  = $elapsed / $num_laps;

=head1 DESCRIPTION

The three types of Stopwatches are C<normal>, C<burst>, and C<lap>.

A C<normal> Stopwatch has only C<start()> and C<stop()> abilities
and C<getTime()> returns the difference between these two times.

A C<burst> Stopwatch uses the C<start> and C<stop> as well, but
does not reset the time with every call, but keeps a cumulative
time difference. Such as stop1-start1 + stop2-start2 + ... = final.
This is useful for measuring a part of the loop without calculating
the overall time of the loop, as in C<normal> and C<lap>, thus
allowing you to diagnose which portion of the loop is causing the
slowdown.

A C<lap> Stopwatch uses C<start()> and C<lap()> to mark intervals
in the overall time. This is useful for getting statistics on minimum,
maximum, and average loop times so you can determine best-case,
worst-case, and average-runs on sections of code.

Uses Time::HiRes to calculate the most accurate results within fast loops

=over 4

=item new( type => ("normal"|"lap"|"burst"), [laps => N] )

Creates a Stopwatch object of type C<type> if specified, with 
a default type of "normal". You may also give a number of laps to
optimize the array handling, the default number of laps is 100.

=item start()

Starts the Stopwatch, or (code-wise) saves the current time in a 
local 'start' reference.

=item stop()

Stops the Stopwatch, or (code-wise) saves the current time in a local 
'stop' reference, and does the following based on type of Stopwatch.
If C<normal>, saves the difference of the start and stop. If C<burst>,
calculates the difference and adds it to the running total. If C<lap>,
saves the difference as the current lap and increments lap counter.

=item lap()

Records a lap time, or (code-wise) saves the difference as the current
lap and increments lap counter.

=item clear()

Resets the running total to 0. Useful when using a C<burst> Stopwatch
and want to re-use the same object for another area of the script.

=item getTime()

Returns the time value of the Stopwatch to the 6th decimal place (10e-6)
or in microseconds, the smallest time unit available to Time::HiRes.

=item numLaps()

Returns the number of laps actually executed. Useful for when you exit a
loop before you pre-declared number of laps is completed.

=item getLaps()

Returns a reference to the lap-array with a size of the pre-declared
number of laps, or more if you ran over. Use C<numLaps()> to finde the 
final valid index of the lap-array.

=item getMaxLap()

Returns the maximum time found on the lap-array.

=item getMinLap()

Returns the minimum time found in the lap-array.

=back

=head1 EXAMPLES

    use strict;
    use Perf::Stopwatch qw( :all );

    my $max = @ARGV ? shift @ARGV : 500;

    my $nrm = new Perf::Stopwatch( type => "normal" );
    my $brs = new Perf::Stopwatch( type => "burst" );
    my $lap = new Perf::Stopwatch( type => "lap", laps => $max );

    my( $i, $j, $x, $y );

    $nrm->start();
    $lap->start();
    for( $i=0; $i<$max; $i++ ){

        while( int(rand()*1000) < 975 ){
            $brs->start();
            for( $j=0; $j<10; $j++ ){ 
                $x = cos(rand()*360)+cos(rand()*360); 
                $y = sin(rand()*360)+sin(rand()*360); 
            }
            $brs->stop();
    	}

        $lap->lap();
    }
    $nrm->stop();

    my( $l_time, $l_avg, $l_min,  $l_max );
    my( $b_time, $b_avg, $n_time, $n_avg );
    $l_time = sprintf "%.7f", $lap->getTime();
    $l_avg  = sprintf "%.7f", ($l_time/$lap->numLaps());
    $l_min  = sprintf "%.7f", $lap->getMinLap();
    $l_max  = sprintf "%.7f", $lap->getMaxLap();

    $b_time = sprintf "%.7f", $brs->getTime();
    $b_avg  = sprintf "%.7f", ($b_time/$lap->numLaps());

    $n_time = sprintf "%.7f", $nrm->getTime();
    $n_avg  = sprintf "%.7f", ($n_time/$lap->numLaps());

    print qq~
    Times from $max runs are:

        [ Burst] Avg: $b_avg  Tot: $b_time

        [ Lap  ] Min: $l_min
                 Avg: $l_avg
                 Max: $l_max  Tot: $l_time

        [ Norm ] Avg: $n_avg  Tot: $n_time

    ~;

=head1 OUTPUT

Using the EXAMPLE code as is:
  
  Times from 500 runs are:
  [ Burst] Avg: 0.0016151  Tot: 0.8075600

  [ Lap  ] Min: 0.0000080
           Avg: 0.0021507
           Max: 0.0167070  Tot: 1.0753620

  [ Norm ] Avg: 0.0021624  Tot: 1.0812210

Using the EXAMPLE code after moving the C<burst> Stopwatch outside of 
the while-loop and then removing the inner-most while-loop:

  Times from 500 runs are:
  [ Burst] Avg: 0.0000053  Tot: 0.0026270

  [ Lap  ] Min: 0.0000240
           Avg: 0.0000244
           Max: 0.0000500  Tot: 0.0121820

  [ Norm ] Avg: 0.0000357  Tot: 0.0178360

As seen above, just starting and stopping the Stopwatch takes a few 
microseconds. Im sure that these can be optimized further, but it is
useful for comparisons and references.

=head1 NOTES

This was created to be inserted quickly into any script as a reference
(SEE CAVEATS), since it requires very little modification of the original
code that is being debugged, and is just as easy to remove when code
is put into production. It is not designed for benchmarking or serious
calculations since the module code itself is not optimized. As mentioned
in CAVEATS, a simple for-loop takes about 5 microseconds to just start
and stop a C<lap> Stopwatch on my test systems.

=head1 CAVEATS

Uses Time::HiRes and is thus succeptible to all CAVEATS listed therein. 
Another known issue unreliable results in a multi-thread environment 
that also propagates from Time::HiRes. 

This is just a simple B<reference> of time elapsed throughout a script
and should be used for debugging and optimiziation purposes only. In only
a simple loop, Perf::Stopwatch has a minimum number of microseconds that it
takes to copy the retrieve and copy time-values and increment lap-indices.
In my test cases, this has been approximately 5 microseconds in a simple 
for-loop. This only becomes a factor when comparing already optimized loops. 
If your loops have execution times in the 100ths of a second or more, then
the time use by Perf::Stopwatch is neglible.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2003 Kit DeKat.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
