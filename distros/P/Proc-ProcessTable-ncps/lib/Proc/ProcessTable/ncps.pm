package Proc::ProcessTable::ncps;

use 5.006;
use strict;
use warnings;
use Proc::ProcessTable::Match;
use Proc::ProcessTable;
use Text::ANSITable;
use Term::ANSIColor;
use Statistics::Basic qw(:all);
use List::Util qw( min max sum );
use Proc::ProcessTable::InfoString;

=head1 NAME

Proc::ProcessTable::ncps - New Colorized(optional) PS, a enhanced version of PS with advanced searching capabilities

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';


=head1 SYNOPSIS

    use Proc::ProcessTable::ncps;
    
    my $args={
                  cmajor_faults=>0,
                  cminor_faults=>0,
                  major_faults=>1,
                  minor_faults=>0,
                  numthr=>0,
                  tty=>0,
                  jid=>0,
                  stats=>1,
                  match=>{
                          checks=>\@filters,
                         }
                  };
    
    my $ncps = Proc::ProcessTable::ncps->new( \%args );
    
    print $ncps->run

The info column is provided by L<Proc::ProcessTable::InfoString>. That
POD has the information on what they all mean.

=head1 METHODS

=head2 new

This initiates the object.

=head3 args hash ref

=head4 match

This is a hash to pash to L<Proc::ProcessTable::Match>. If not specified,
this it will not be used all processes will be displayed.

=head4 cmajor_faults

Boolean for if the children major faults column should be shown.

Default: 0

=head4 cminor_faults

Boolean for if the children minor faults column should be shown.

Default: 0

=head4 major_faults

Boolean for if the major faults column should be shown.

Default: 0

=head4 minor_faults

Boolean for if the minor faults column should be shown.

Default: 0

=head4 jid

Boolean for if the JIDs column should be shown.

Default: 0

=head4 stats

Boolean for if stats for PctCPU, PctMem, VSZ, RSS
and time should be shown at the end.

Default: 0

=head4 tty

Boolean for if the TTY column should be shown.

Default: 0

=cut

sub new {
	my %args;
	if (defined($_[1])) {
		%args= %{$_[1]};
	}


	my $self = {
				invert=>0,
				match=>undef,
				minor_faults=>0,
				major_faults=>0,
				cminor_faults=>0,
				cmajor_faults=>0,
				colors=>[
						 'BRIGHT_YELLOW',
						 'BRIGHT_CYAN',
						 'BRIGHT_MAGENTA',
						 'BRIGHT_BLUE'
						 ],
				timeColors=>[
							 'GREEN',
							 'BRIGHT_GREEN',
							 'RED',
							 'BRIGHT_RED'
							 ],
				vszColors=>[
							'GREEN',
							'YELLOW',
							'RED',
							'BRIGHT_BLUE'
							],
				rssColors=>[
							'BRIGHT_GREEN',
							'BRIGHT_YELLOW',
							'BRIGHT_RED',
							'BRIGHT_BLUE'
							],
				processColor=>'BRIGHT_RED',
				nextColor=>0,
				stats=>0,
				jid=>0,
				tty=>0,
				numthr=>0,
				};
    bless $self;

	if (
		defined( $args{match} ) &&
		defined( $args{match}{checks} ) &&
		defined( $args{match}{checks}[0] )
		){
		$self->{match}=Proc::ProcessTable::Match->new( $args{match} );
	}

	my @bool_feed=(
				   'major_faults', 'minor_faults', 'cmajor_faults',
				   'cminor_faults', 'numthr', 'tty', 'jid', 'stats'
				   );

	foreach my $feed ( @bool_feed ){
		$self->{$feed}=$args{$feed};
	}

	return $self;
}

=head2 run

This runs it.

The return value is a string.

    print $ncps->run

=cut

sub run{
	my $self=$_[0];

	my $ppt = Proc::ProcessTable->new( 'cache_ttys' => 1 );
	my $pt = $ppt->table;

	my $procs;
	if ( defined( $self->{match} ) ){
		$procs=[];
		foreach my $proc ( @{ $pt } ){
			eval{
				if ( $self->{match}->match( $proc ) ){
					push( @{ $procs }, $proc );
				}
			};
		}
	}else{
		$procs=$pt;
	}

	# figures out if this systems reports nice or not
	my $have_nice=0;
	if (
		defined( $procs->[0] ) &&
		defined($procs->[0]->{nice} )
		){
		$have_nice=1;
	}

	# figures out if this systems reports priority or not
	my $have_pri=0;
	if (
		defined( $procs->[0] ) &&
		defined($procs->[0]->{priority} )
		){
		$have_pri=1;
	}

	my $physmem;
	if ( $^O =~ /bsd/ ){
		$physmem=`/sbin/sysctl -a hw.physmem`;
		chomp( $physmem );
		$physmem=~s/^.*\: //;
	}

	my $tb = Text::ANSITable->new;
	$tb->border_style('ASCII::None');
	# this seems to be a bit broken currently
	#$tb->color_theme();

	#
	# assemble the headers
	#
	my @headers;
	my $header_int=0;
	my $padding=0;
	push( @headers, 'User' );
	$tb->set_column_style($header_int, pad => 0); $header_int++;
	push( @headers, 'PID' );
	$tb->set_column_style($header_int, pad => 1); $header_int++;
	push( @headers, 'CPU' );
	$tb->set_column_style($header_int, pad => 0); $header_int++;
	push( @headers, 'MEM' );
	$tb->set_column_style($header_int, pad => 1); $header_int++;
	push( @headers, 'VSZ' );
	$tb->set_column_style($header_int, pad => 0); $header_int++;
	push( @headers, 'RSS' );
	$tb->set_column_style($header_int, pad => 1); $header_int++;
	push( @headers, 'Info' );
	# add nice if needed
	if ( $have_nice ){
		push( @headers, 'Nic' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add priority if needed
	if ( $have_pri ){
		push( @headers, 'Pri' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add major faults if needed
	if ( $self->{major_faults} ){
		push( @headers, 'MajF' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add minor faults if needed
	if ( $self->{minor_faults} ){
		push( @headers, 'minF' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add children major faults if needed
	if ( $self->{cmajor_faults} ){
		push( @headers, 'cMajF' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add children minor faults if needed
	if ( $self->{cminor_faults} ){
		push( @headers, 'cminF' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add children minor faults if needed
	if ( $self->{numthr} ){
		push( @headers, 'Thr' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add children minor faults if needed
	if ( $self->{tty} ){
		push( @headers, 'TTY' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	# add jail ID if needed
	if ( $self->{jid} ){
		push( @headers, 'JID' );
		if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
		$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	}
	if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
	$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	push( @headers, 'Start' );
	if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
	$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	push( @headers, 'Time' );
	if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
	$tb->set_column_style($header_int, pad => $padding ); $header_int++;
	push( @headers, 'Command' );
	if (( $header_int % 2 ) != 0){ $padding=1; }else{ $padding=0; }
	$tb->set_column_style($header_int, pad => $padding, formats=>[[wrap => {ansi=>1, mb=>1}]]);

	$tb->columns( \@headers );

	my @stats_rss;
	my @stats_vsz;
	my @stats_time;
	my @stats_pctcpu;
	my @stats_pctmem;

	my @td;
	foreach my $proc ( @{ $procs } ) {
		my @new_line;

		#
		# handle username column
		#
		my $user=getpwuid($proc->{uid});
		if ( ! defined( $user ) ) {
			$user=$proc->{uid};
		}
		$user=color($self->nextColor).$user.color('reset');
		push( @new_line, $user );

		#
		# handles the PID
		#
		push( @new_line,  color($self->nextColor).$proc->{pid}.color('reset') );

		#
		# handles the %CPU
		#
		push( @new_line,  color($self->nextColor).$proc->{pctcpu}.color('reset') );
		if ( $self->{stats} ){ push( @stats_pctcpu, $proc->{pctcpu} ); }

		#
		# handles the %MEM
		#
		if ( $^O =~ /bsd/ ) {
			my $mem=(($proc->{rssize} * 1024 * 4 ) / $physmem) * 100;
			push( @new_line,  color($self->nextColor).sprintf('%.2f', $mem).color('reset') );
			if ( $self->{stats} ){ push( @stats_pctmem, $mem ); }
		} else {
			push( @new_line,  color($self->nextColor).sprintf('%.2f', $proc->{pctmem}).color('reset') );
			if ( $self->{stats} ){ push( @stats_pctmem, $proc->{pctmem} ); }
		}

		#
		# handles VSZ
		#
		push( @new_line,  $self->memString( $proc->{size}, 'vsz') );
		if ( $self->{stats} ){ push( @stats_vsz, $proc->{size} ); }

		#
		# handles the rss
		#
		push( @new_line, $self->memString( $proc->{rss}, 'rss')  );
		if ( $self->{stats} ){ push( @stats_rss, $proc->{rss} ); }

		#
		# handles the info
		#
		my $is = Proc::ProcessTable::InfoString->new({
													  flags_color=>$self->nextColor,
													  wchan_color=>$self->nextColor,
													 });
		push( @new_line, $is->info( $proc ) );

		#
		# handle the nice column
		#
		if ( $have_nice ) {
			push( @new_line, color($self->nextColor).$proc->{nice}.color('reset') );
		}

		#
		# handle the priority column
		#
		if ( $have_pri ) {
			push( @new_line, color($self->nextColor).$proc->{priority}.color('reset') );
		}

		#
		# major faults
		#
		if ( $self->{major_faults} ) {
			push( @new_line, color($self->nextColor).$proc->{majflt}.color('reset') );
		}

		#
		# major faults
		#
		if ( $self->{minor_faults} ) {
			push( @new_line, color($self->nextColor).$proc->{minflt}.color('reset') );
		}

		#
		# children major faults
		#
		if ( $self->{cmajor_faults} ) {
			push( @new_line, color($self->nextColor).$proc->{cmajflt}.color('reset') );
		}

		#
		# children major faults
		#
		if ( $self->{cminor_faults} ) {
			push( @new_line, color($self->nextColor).$proc->{cminflt}.color('reset') );
		}

		#
		# number of threads
		#
		if ( $self->{numthr} ) {
			push( @new_line, color($self->nextColor).$proc->{numthr}.color('reset') );
		}

		#
		# number of threads
		#
		if ( $self->{tty} ) {
			push( @new_line, color($self->nextColor).$proc->{ttydev}.color('reset') );
		}

		#
		# jail ID
		#
		if ( $self->{jid} ) {
			push( @new_line, color($self->nextColor).$proc->{jid}.color('reset') );
		}

		#
		# handles the start column
		#
		push( @new_line, color($self->nextColor).$self->startString( $proc->{start} ).color('reset') );

		#
		# handles the time column
		#
		push( @new_line,  $self->timeString( $proc->{time} ) );
		if ( $self->{stats} ){ push( @stats_time, $proc->{time} ); }

		#
		# handle the command
		#
		my $command=color($self->{processColor});
		if ( $proc->{cmndline} =~ /^$/ ) {
			$command=$command.'['.$proc->{fname}.']';
		} else {
			$command=$command.$proc->{cmndline};
		}
		push( @new_line, $command.color('reset') );

		push( @td, \@new_line );
		$self->{nextColor}=0;
	}

	$tb->add_rows( \@td );

	my $stats='';
	if ( $self->{stats} ){
		my $stb = Text::ANSITable->new;
		$stb->border_style('Default::none_ascii');
		$stb->color_theme('Default::no_color');

		#
		# assemble the headers
		#
		my @stats_headers;
		push( @stats_headers, ' ' );
		$stb->set_column_style($header_int, pad => 0);
		push( @stats_headers, 'Min' );
		$stb->set_column_style($header_int, pad => 1);
		push( @stats_headers, 'Avg' );
		$stb->set_column_style($header_int, pad => 0);
		push( @stats_headers, 'Med' );
		$stb->set_column_style($header_int, pad => 1);
		push( @stats_headers, 'Max' );
		$stb->set_column_style($header_int, pad => 0);
		push( @stats_headers, 'StdDev' );
		$stb->set_column_style($header_int, pad => 1);
		push( @stats_headers, 'Sum' );
		$stb->set_column_style($header_int, pad => 0);

		$stb->columns( \@stats_headers );

		my @std;

		my $stats_avg=avg(@stats_pctcpu);
		$stats_avg=~s/\,//g;
		my $stats_median=median(@stats_pctcpu);
		$stats_median=~s/\,//g;
		my $stats_stddev=stddev(@stats_pctcpu);
		$stats_stddev=~s/\,//g;
		push( @std, [
					 'CPU%',
					 sprintf('%.2f', min( @stats_pctcpu )),
					 $stats_avg,
					 $stats_median,
					 sprintf('%.2f', max( @stats_pctcpu )),
					 $stats_stddev,
					 sprintf('%.2f', sum( @stats_pctcpu )),
					 ]);

		$stats_avg=avg(@stats_pctmem);
		$stats_avg=~s/\,//g;
		$stats_median=median(@stats_pctmem);
		$stats_median=~s/\,//g;
		$stats_stddev=stddev(@stats_pctmem);
		$stats_stddev=~s/\,//g;
		push( @std, [
					 'Mem%',
					 sprintf('%.2f', min( @stats_pctmem )),
					 $stats_avg,
					 $stats_median,
					 sprintf('%.2f', max( @stats_pctmem )),
					 $stats_stddev,
					 sprintf('%.2f', sum( @stats_pctmem )),
					 ]);

		$stats_avg=avg(@stats_vsz);
		$stats_avg=~s/\,//g;
		$stats_median=median(@stats_vsz);
		$stats_median=~s/\,//g;
		$stats_stddev=stddev(@stats_vsz);
		$stats_stddev=~s/\,//g;
		push( @std, [
					 'VSZ',
					 $self->memString( min( @stats_vsz), 'vsz'),
					 $self->memString( $stats_avg, 'vsz'),
					 $self->memString( $stats_median, 'vsz'),
					 $self->memString( max( @stats_vsz ), 'vsz'),
					 $self->memString( $stats_stddev, 'vsz'),
					 $self->memString( sum( @stats_vsz), 'vsz'),
					 ]);

		$stats_avg=avg(@stats_rss);
		$stats_avg=~s/\,//g;
		$stats_median=median(@stats_rss);
		$stats_median=~s/\,//g;
		$stats_stddev=stddev(@stats_rss);
		$stats_stddev=~s/\,//g;
		push( @std, [
					 'RSS',
					 $self->memString( min( @stats_rss ), 'rss'),
					 $self->memString( $stats_avg, 'rss'),
					 $self->memString( $stats_median, 'rss'),
					 $self->memString( max( @stats_rss ), 'rss'),
					 $self->memString( $stats_stddev, 'rss'),
					 $self->memString( sum( @stats_rss ), 'rss'),
					 ]);

		$stats_avg=avg(@stats_time);
		$stats_avg=~s/\,//g;
		$stats_median=median(@stats_time);
		$stats_median=~s/\,//g;
		$stats_stddev=stddev(@stats_time);
		$stats_stddev=~s/\,//g;
		push( @std, [
					 'Time',
					 $self->timeString( min( @stats_time ) ),
					 $self->timeString( $stats_avg ),
					 $self->timeString( $stats_median ),
					 $self->timeString( max( @stats_time ) ),,
					 $self->timeString( $stats_stddev ),
					 $self->timeString( sum( @stats_time ) ),
					 ]);

		$stb->add_rows( \@std );

		$stats="\n".$stb->draw;
	}

	return $tb->draw.$stats;
}

=head2 startString

Generates a short time string based on the supplied unix time.

=cut

sub startString{
        my $self=$_[0];
        my $startTime=$_[1];

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($startTime);
        my ($csec,$cmin,$chour,$cmday,$cmon,$cyear,$cwday,$cyday,$cisdst) = localtime(time);

        #add the required stuff to make this sane
        $year += 1900;
        $cyear += 1900;
        $mon += 1;
        $cmon += 1;

        #find the most common one and return it
        if ( $year ne $cyear ){
                return $year.sprintf('%02d', $mon).sprintf('%02d', $mday).'-'.sprintf('%02d', $hour).':'.sprintf('%02d', $min);
        }
        if ( $mon ne $cmon ){
                return sprintf('%02d', $mon).sprintf('%02d', $mday).'-'.sprintf('%02d', $hour).':'.sprintf('%02d', $min);
        }
        if ( $mday ne $cmday ){
                return sprintf('%02d', $mday).'-'.sprintf('%02d', $hour).':'.sprintf('%02d', $min);
        }

        #just return this for anything less
        return sprintf('%02d', $hour).':'.sprintf('%02d', $min);
}

=head2 timeString

Turns the raw run string into something usable.

=cut

sub timeString{
        my $self=$_[0];
        my $time=$_[1];

		if ( $^O =~ /^linux$/ ){
			$time=$time/1000000;
		}

        my $hours=0;
        if ( $time >= 3600 ){
                $hours = $time / 3600;
        }
        my $loSeconds = $time % 3600;
        my $minutes=0;
        if ( $time >= 60 ){
                $minutes = $loSeconds / 60;
        }
        my $seconds = $loSeconds % 60;

        #nicely format it
        $hours=~s/\..*//;
        $minutes=~s/\..*//;
        $seconds=sprintf('%.f',$seconds);

        #this will be returned
        my $toReturn='';

        #process the hours bit
        if ( $hours == 0 ){
                #don't do anything if time is 0
        }elsif(
                $hours >= 10
                ){
                $toReturn=color($self->{timeColors}->[3]).$hours.':';
        }else{
                $toReturn=color($self->{timeColors}->[2]).$hours.':';
        }

        #process the minutes bit
        if (
                ( $hours > 0 ) ||
                ( $minutes > 0 )
                ){
                $toReturn=$toReturn.color( $self->{timeColors}->[1] ). $minutes.':';
        }

        $toReturn=$toReturn.color( $self->{timeColors}->[0] ).$seconds.color('reset');

        return $toReturn;
}

=head2 memString

Turns the raw run string into something usable.

=cut

sub memString{
        my $self=$_[0];
        my $mem=$_[1];
		my $type=$_[2];

		my $toReturn='';

		if ( $mem < '10000' ){
			$toReturn=color( $self->{$type.'Colors'}[0] ).$mem;
		}elsif(
			   ( $mem >= '10000' ) &&
			   ( $mem < '1000000' )
			   ){
			$mem=$mem/1000;

			$toReturn=color( $self->{$type.'Colors'}[0] ).$mem.
			color( $self->{$type.'Colors'}[3] ).'k';
		}elsif(
			   ( $mem >= '1000000' ) &&
			   ( $mem < '1000000000' )
			   ){
			$mem=($mem/1000)/1000;
			$mem=sprintf('%.3f', $mem);
			my @mem_split=split(/\./, $mem);

			$toReturn=color( $self->{$type.'Colors'}[1] ).$mem_split[0].'.'.color( $self->{$type.'Colors'}[0] ).$mem_split[1].
			color( $self->{$type.'Colors'}[3] ).'M';
		}elsif( $mem >= '1000000000' ){
			$mem=(($mem/1000)/1000)/1000;
			$mem=sprintf('%.3f', $mem);
			my @mem_split=split(/\./, $mem);

			$toReturn=color( $self->{$type.'Colors'}[2] ).$mem_split[0].'.'.color( $self->{$type.'Colors'}[1] ).$mem_split[1].
			color( $self->{$type.'Colors'}[3] ).'G';
		}

        return $toReturn.color('reset');
}


=head2 nextColor

Returns the next color.

=cut

sub nextColor{
	my $self=$_[0];

	my $color;

	if ( defined( $self->{colors}[ $self->{nextColor} ] ) ) {
		$color=$self->{colors}[ $self->{nextColor} ];
		$self->{nextColor}++;
	} else {
		$self->{nextColor}=0;
		$color=$self->{colors}[ $self->{nextColor} ];
		$self->{nextColor}++;
	}

	return $color;
}


=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-processtable-ncps at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-ProcessTable-ncps>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Proc::ProcessTable::ncps


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Proc-ProcessTable-ncps>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Proc-ProcessTable-ncps>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Proc-ProcessTable-ncps>

=item * Search CPAN

L<https://metacpan.org/release/Proc-ProcessTable-ncps>

=item * Repository

L<https://github.com/VVelox/Proc-ProcessTable-ncps>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Proc::ProcessTable::ncps
