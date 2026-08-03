package Proc::ProcessTable::ncps;

use 5.010001;
use strict;
use warnings;
use Proc::ProcessTable::Match;
use Proc::ProcessTable;
use Text::ANSITable;
use Term::ANSIColor;
use Statistics::Basic qw(:all);
use List::Util        qw( min max sum );
use Proc::ProcessTable::InfoString;
use POSIX ();

=head1 NAME

Proc::ProcessTable::ncps - New Colorized(optional) PS, an enhanced version of PS with advanced searching capabilities

=head1 VERSION

Version 0.2.2

=cut

our $VERSION = '0.2.2';

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

This is a hash to pass to L<Proc::ProcessTable::Match>. If not specified,
it will not be used and all processes will be displayed.

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

=head4 numthr

Boolean for if the number of threads column should be shown.

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
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	my $self = {
		match         => undef,
		minor_faults  => 0,
		major_faults  => 0,
		cminor_faults => 0,
		cmajor_faults => 0,
		colors        => [ 'BRIGHT_YELLOW', 'BRIGHT_CYAN',   'BRIGHT_MAGENTA', 'BRIGHT_BLUE' ],
		timeColors    => [ 'GREEN',         'BRIGHT_GREEN',  'RED',            'BRIGHT_RED' ],
		vszColors     => [ 'GREEN',         'YELLOW',        'RED',            'BRIGHT_BLUE' ],
		rssColors     => [ 'BRIGHT_GREEN',  'BRIGHT_YELLOW', 'BRIGHT_RED',     'BRIGHT_BLUE' ],
		processColor  => 'BRIGHT_RED',
		nextColor     => 0,
		stats         => 0,
		jid           => 0,
		tty           => 0,
		numthr        => 0,
	};
	bless $self;

	if (   defined( $args{match} )
		&& defined( $args{match}{checks} )
		&& defined( $args{match}{checks}[0] ) )
	{
		$self->{match} = Proc::ProcessTable::Match->new( $args{match} );
	}

	my @bool_feed
		= ( 'major_faults', 'minor_faults', 'cmajor_faults', 'cminor_faults', 'numthr', 'tty', 'jid', 'stats' );

	foreach my $feed (@bool_feed) {
		if ( defined( $args{$feed} ) ) {
			$self->{$feed} = $args{$feed};
		}
	}

	return $self;
} ## end sub new

=head2 run

This runs it.

The return value is a string.

    print $ncps->run

=cut

sub run {
	my $self = $_[0];

	# cache_ttys is not used as Proc::ProcessTable keeps that cache in a
	# Storable file under /tmp that is shared by every perl on the machine
	# with the same byte order, so a cache written by a perl built with a
	# differing double size makes Storable::retrieve die with
	# 'Double size is not compatible'
	my $ppt = Proc::ProcessTable->new;
	my $pt  = $ppt->table;

	# if this platform does not provide the rss field, compute it from
	# rssize, which is in pages, so it is usable for both matching and
	# display... no such fallback is possible for the size field as
	# tsize+dsize+ssize misses shared libraries and other mappings
	if (   defined( $pt->[0] )
		&& ( !defined( $pt->[0]->{rss} ) )
		&& defined( $pt->[0]->{rssize} ) )
	{
		my $pagesize;
		eval { $pagesize = POSIX::sysconf( POSIX::_SC_PAGESIZE() ); };
		if ($pagesize) {
			foreach my $proc ( @{$pt} ) {
				my $rssize = $proc->{rssize};
				if ( !defined($rssize) ) { $rssize = 0; }
				$proc->{rss} = $rssize * $pagesize;
			}
		}
	} ## end if ( defined( $pt->[0] ) && ( !defined( $pt...)))

	# if this platform does not provide the pctmem field, compute it
	# if possible so it is usable for both matching and display,
	# using rss as Proc::ProcessTable provides it in bytes everywhere
	if (   defined( $pt->[0] )
		&& ( !defined( $pt->[0]->{pctmem} ) )
		&& defined( $pt->[0]->{rss} ) )
	{
		my $physmem = $self->physmem;
		if ( defined($physmem) ) {
			foreach my $proc ( @{$pt} ) {
				my $rss = $proc->{rss};
				if ( !defined($rss) ) { $rss = 0; }
				$proc->{pctmem} = ( $rss / $physmem ) * 100;
			}
		}
	} ## end if ( defined( $pt->[0] ) && ( !defined( $pt...)))

	my $procs;
	if ( defined( $self->{match} ) ) {
		$procs = [];
		my $match_error;
		foreach my $proc ( @{$pt} ) {
			eval {
				if ( $self->{match}->match($proc) ) {
					push( @{$procs}, $proc );
				}
			};
			if ( $@ && ( !defined($match_error) ) ) {
				$match_error = $@;
			}
		} ## end foreach my $proc ( @{$pt} )
		if ( defined($match_error) ) {
			warn( 'One or more processes errored during matching... first error... ' . $match_error );
		}
	} else {
		$procs = $pt;
	}

	# figures out if this systems reports nice or not
	my $have_nice = 0;
	if (   defined( $procs->[0] )
		&& defined( $procs->[0]->{nice} ) )
	{
		$have_nice = 1;
	}

	# figures out if this systems reports priority or not
	my $have_pri = 0;
	if (   defined( $procs->[0] )
		&& defined( $procs->[0]->{priority} ) )
	{
		$have_pri = 1;
	}

	# disable optional columns for fields this platform does not support
	my %optional_column_fields = (
		jid           => 'jid',
		numthr        => 'numthr',
		tty           => 'ttydev',
		major_faults  => 'majflt',
		minor_faults  => 'minflt',
		cmajor_faults => 'cmajflt',
		cminor_faults => 'cminflt',
	);
	foreach my $optional_column ( keys(%optional_column_fields) ) {
		my $required_field = $optional_column_fields{$optional_column};
		if (
			$self->{$optional_column}
			&& (   !defined( $procs->[0] )
				|| !defined( $procs->[0]->{$required_field} ) )
			)
		{
			$self->{$optional_column} = 0;
		}
	} ## end foreach my $optional_column ( keys(%optional_column_fields...))

	# figures out which of the standard columns this platform supports
	my %have_field;
	foreach my $standard_field ( 'pctcpu', 'pctmem', 'size', 'rss', 'time', 'start' ) {
		$have_field{$standard_field} = 0;
		if (   defined( $procs->[0] )
			&& defined( $procs->[0]->{$standard_field} ) )
		{
			$have_field{$standard_field} = 1;
		}
	}

	my $tb = Text::ANSITable->new;
	$tb->border_style('ASCII::None');
	$tb->color_theme('NoColor');

	#
	# assemble the headers
	#
	my @headers;
	my $header_int = 0;
	my $padding    = 0;
	push( @headers, 'User' );
	if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
	else                              { $padding = 0; }
	$tb->set_column_style( $header_int, pad => $padding );
	$header_int++;
	push( @headers, 'PID' );
	if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
	else                              { $padding = 0; }
	$tb->set_column_style( $header_int, pad => $padding );
	$header_int++;
	# add CPU percent if needed
	if ( $have_field{pctcpu} ) {
		push( @headers, 'CPU' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add memory percent if needed
	if ( $have_field{pctmem} ) {
		push( @headers, 'MEM' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add VSZ if needed
	if ( $have_field{size} ) {
		push( @headers, 'VSZ' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add RSS if needed
	if ( $have_field{rss} ) {
		push( @headers, 'RSS' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	push( @headers, 'Info' );
	if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
	else                              { $padding = 0; }
	$tb->set_column_style( $header_int, pad => $padding );
	$header_int++;
	# add nice if needed
	if ($have_nice) {
		push( @headers, 'Nic' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add priority if needed
	if ($have_pri) {
		push( @headers, 'Pri' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add major faults if needed
	if ( $self->{major_faults} ) {
		push( @headers, 'MajF' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add minor faults if needed
	if ( $self->{minor_faults} ) {
		push( @headers, 'minF' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add children major faults if needed
	if ( $self->{cmajor_faults} ) {
		push( @headers, 'cMajF' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add children minor faults if needed
	if ( $self->{cminor_faults} ) {
		push( @headers, 'cminF' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add number of threads if needed
	if ( $self->{numthr} ) {
		push( @headers, 'Thr' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add TTY if needed
	if ( $self->{tty} ) {
		push( @headers, 'TTY' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add jail ID if needed
	if ( $self->{jid} ) {
		push( @headers, 'JID' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add start time if needed
	if ( $have_field{start} ) {
		push( @headers, 'Start' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	# add CPU time if needed
	if ( $have_field{time} ) {
		push( @headers, 'Time' );
		if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
		else                              { $padding = 0; }
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}
	push( @headers, 'Command' );
	if   ( ( $header_int % 2 ) != 0 ) { $padding = 1; }
	else                              { $padding = 0; }
	$tb->set_column_style( $header_int, pad => $padding, formats => [ [ wrap => { ansi => 1, mb => 1 } ] ] );

	$tb->columns( \@headers );

	my @stats_rss;
	my @stats_vsz;
	my @stats_time;
	my @stats_pctcpu;
	my @stats_pctmem;

	my @td;
	foreach my $proc ( @{$procs} ) {
		my @new_line;

		#
		# handle username column
		#
		my $user = getpwuid( $proc->{uid} );
		if ( !defined($user) ) {
			$user = $proc->{uid};
		}
		$user = color( $self->nextColor ) . $user . color('reset');
		push( @new_line, $user );

		#
		# handles the PID
		#
		push( @new_line, color( $self->nextColor ) . $proc->{pid} . color('reset') );

		#
		# handles the %CPU
		#
		if ( $have_field{pctcpu} ) {
			my $pctcpu = $proc->{pctcpu};
			# Proc::ProcessTable reports inf/nan for freshly started processes
			if ( ( !defined($pctcpu) ) || ( $pctcpu !~ /^\s*[0-9]*\.?[0-9]+\s*$/ ) ) { $pctcpu = 0; }
			push( @new_line, color( $self->nextColor ) . sprintf( '%.2f', $pctcpu ) . color('reset') );
			if ( $self->{stats} ) { push( @stats_pctcpu, $pctcpu ); }
		}

		#
		# handles the %MEM
		#
		if ( $have_field{pctmem} ) {
			my $pctmem = $proc->{pctmem};
			if ( !defined($pctmem) ) { $pctmem = 0; }
			push( @new_line, color( $self->nextColor ) . sprintf( '%.2f', $pctmem ) . color('reset') );
			if ( $self->{stats} ) { push( @stats_pctmem, $pctmem ); }
		}

		#
		# handles VSZ
		#
		if ( $have_field{size} ) {
			my $size = $proc->{size};
			if ( !defined($size) ) { $size = 0; }
			push( @new_line, $self->memString( $size, 'vsz' ) );
			if ( $self->{stats} ) { push( @stats_vsz, $size ); }
		}

		#
		# handles the rss
		#
		if ( $have_field{rss} ) {
			my $rss = $proc->{rss};
			if ( !defined($rss) ) { $rss = 0; }
			push( @new_line, $self->memString( $rss, 'rss' ) );
			if ( $self->{stats} ) { push( @stats_rss, $rss ); }
		}

		#
		# handles the info
		#
		my $is = Proc::ProcessTable::InfoString->new(
			{
				flags_color => $self->nextColor,
				wchan_color => $self->nextColor,
			}
		);
		push( @new_line, $is->info($proc) );

		#
		# handle the nice column
		#
		if ($have_nice) {
			push( @new_line, color( $self->nextColor ) . $proc->{nice} . color('reset') );
		}

		#
		# handle the priority column
		#
		if ($have_pri) {
			push( @new_line, color( $self->nextColor ) . $proc->{priority} . color('reset') );
		}

		#
		# major faults
		#
		if ( $self->{major_faults} ) {
			push( @new_line, color( $self->nextColor ) . $proc->{majflt} . color('reset') );
		}

		#
		# minor faults
		#
		if ( $self->{minor_faults} ) {
			push( @new_line, color( $self->nextColor ) . $proc->{minflt} . color('reset') );
		}

		#
		# children major faults
		#
		if ( $self->{cmajor_faults} ) {
			push( @new_line, color( $self->nextColor ) . $proc->{cmajflt} . color('reset') );
		}

		#
		# children minor faults
		#
		if ( $self->{cminor_faults} ) {
			push( @new_line, color( $self->nextColor ) . $proc->{cminflt} . color('reset') );
		}

		#
		# number of threads
		#
		if ( $self->{numthr} ) {
			push( @new_line, color( $self->nextColor ) . $proc->{numthr} . color('reset') );
		}

		#
		# TTY
		#
		if ( $self->{tty} ) {
			push( @new_line, color( $self->nextColor ) . $proc->{ttydev} . color('reset') );
		}

		#
		# jail ID
		#
		if ( $self->{jid} ) {
			push( @new_line, color( $self->nextColor ) . $proc->{jid} . color('reset') );
		}

		#
		# handles the start column
		#
		if ( $have_field{start} ) {
			my $start = $proc->{start};
			if ( !defined($start) ) { $start = 0; }
			push( @new_line, color( $self->nextColor ) . $self->startString($start) . color('reset') );
		}

		#
		# handles the time column
		#
		if ( $have_field{time} ) {
			my $proc_time = $proc->{time};
			if ( !defined($proc_time) ) { $proc_time = 0; }
			push( @new_line, $self->timeString($proc_time) );
			if ( $self->{stats} ) { push( @stats_time, $proc_time ); }
		}

		#
		# handle the command
		#
		my $command = color( $self->{processColor} );
		if ( ( !defined( $proc->{cmndline} ) ) || ( $proc->{cmndline} =~ /^$/ ) ) {
			$command = $command . '[' . $proc->{fname} . ']';
		} else {
			$command = $command . $proc->{cmndline};
		}
		push( @new_line, $command . color('reset') );

		push( @td, \@new_line );
		$self->{nextColor} = 0;
	} ## end foreach my $proc ( @{$procs} )

	$tb->add_rows( \@td );

	my $stats = '';
	if ( $self->{stats} && defined( $procs->[0] ) ) {
		my $stb = Text::ANSITable->new;
		#$stb->border_style('Default::none_ascii');
		$stb->border_style('ASCII::None');
		$stb->color_theme('NoColor');

		#
		# assemble the headers
		#
		my @stats_headers;
		my $stats_header_int = 0;
		push( @stats_headers, ' ' );
		$stb->set_column_style( $stats_header_int, pad => 0 );
		$stats_header_int++;
		push( @stats_headers, 'Min' );
		$stb->set_column_style( $stats_header_int, pad => 1 );
		$stats_header_int++;
		push( @stats_headers, 'Avg' );
		$stb->set_column_style( $stats_header_int, pad => 0 );
		$stats_header_int++;
		push( @stats_headers, 'Med' );
		$stb->set_column_style( $stats_header_int, pad => 1 );
		$stats_header_int++;
		push( @stats_headers, 'Max' );
		$stb->set_column_style( $stats_header_int, pad => 0 );
		$stats_header_int++;
		push( @stats_headers, 'StdDev' );
		$stb->set_column_style( $stats_header_int, pad => 1 );
		$stats_header_int++;
		push( @stats_headers, 'Sum' );
		$stb->set_column_style( $stats_header_int, pad => 0 );

		$stb->columns( \@stats_headers );

		my @std;

		my $stats_avg;
		my $stats_median;
		my $stats_stddev;

		if ( $have_field{pctcpu} ) {
			$stats_avg = avg(@stats_pctcpu);
			$stats_avg =~ s/\,//g;
			$stats_median = median(@stats_pctcpu);
			$stats_median =~ s/\,//g;
			$stats_stddev = stddev(@stats_pctcpu);
			$stats_stddev =~ s/\,//g;
			push(
				@std,
				[
					'CPU%',                                sprintf( '%.2f', min(@stats_pctcpu) ),
					$stats_avg,                            $stats_median,
					sprintf( '%.2f', max(@stats_pctcpu) ), $stats_stddev,
					sprintf( '%.2f', sum(@stats_pctcpu) ),
				]
			);
		} ## end if ( $have_field{pctcpu} )

		if ( $have_field{pctmem} ) {
			$stats_avg = avg(@stats_pctmem);
			$stats_avg =~ s/\,//g;
			$stats_median = median(@stats_pctmem);
			$stats_median =~ s/\,//g;
			$stats_stddev = stddev(@stats_pctmem);
			$stats_stddev =~ s/\,//g;
			push(
				@std,
				[
					'Mem%',                                sprintf( '%.2f', min(@stats_pctmem) ),
					$stats_avg,                            $stats_median,
					sprintf( '%.2f', max(@stats_pctmem) ), $stats_stddev,
					sprintf( '%.2f', sum(@stats_pctmem) ),
				]
			);
		} ## end if ( $have_field{pctmem} )

		if ( $have_field{size} ) {
			$stats_avg = avg(@stats_vsz);
			$stats_avg =~ s/\,//g;
			$stats_median = median(@stats_vsz);
			$stats_median =~ s/\,//g;
			$stats_stddev = stddev(@stats_vsz);
			$stats_stddev =~ s/\,//g;
			push(
				@std,
				[
					'VSZ',
					$self->memString( min(@stats_vsz), 'vsz' ),
					$self->memString( $stats_avg,      'vsz' ),
					$self->memString( $stats_median,   'vsz' ),
					$self->memString( max(@stats_vsz), 'vsz' ),
					$self->memString( $stats_stddev,   'vsz' ),
					$self->memString( sum(@stats_vsz), 'vsz' ),
				]
			);
		} ## end if ( $have_field{size} )

		if ( $have_field{rss} ) {
			$stats_avg = avg(@stats_rss);
			$stats_avg =~ s/\,//g;
			$stats_median = median(@stats_rss);
			$stats_median =~ s/\,//g;
			$stats_stddev = stddev(@stats_rss);
			$stats_stddev =~ s/\,//g;
			push(
				@std,
				[
					'RSS',
					$self->memString( min(@stats_rss), 'rss' ),
					$self->memString( $stats_avg,      'rss' ),
					$self->memString( $stats_median,   'rss' ),
					$self->memString( max(@stats_rss), 'rss' ),
					$self->memString( $stats_stddev,   'rss' ),
					$self->memString( sum(@stats_rss), 'rss' ),
				]
			);
		} ## end if ( $have_field{rss} )

		if ( $have_field{time} ) {
			$stats_avg = avg(@stats_time);
			$stats_avg =~ s/\,//g;
			$stats_median = median(@stats_time);
			$stats_median =~ s/\,//g;
			$stats_stddev = stddev(@stats_time);
			$stats_stddev =~ s/\,//g;
			push(
				@std,
				[
					'Time',                                $self->timeString( min(@stats_time) ),
					$self->timeString($stats_avg),         $self->timeString($stats_median),
					$self->timeString( max(@stats_time) ), $self->timeString($stats_stddev),
					$self->timeString( sum(@stats_time) ),
				]
			);
		} ## end if ( $have_field{time} )

		$stb->add_rows( \@std );

		$stats = "\n" . $stb->draw;
	} ## end if ( $self->{stats} && defined( $procs->[0...]))

	return $tb->draw . $stats;
} ## end sub run

=head2 startString

Generates a short time string based on the supplied unix time.

=cut

sub startString {
	my $self      = $_[0];
	my $startTime = $_[1];

	my ( $sec,  $min,  $hour,  $mday,  $mon,  $year,  $wday,  $yday,  $isdst )  = localtime($startTime);
	my ( $csec, $cmin, $chour, $cmday, $cmon, $cyear, $cwday, $cyday, $cisdst ) = localtime(time);

	#add the required stuff to make this sane
	$year  += 1900;
	$cyear += 1900;
	$mon   += 1;
	$cmon  += 1;

	#find the most common one and return it
	if ( $year ne $cyear ) {
		return
			  $year
			. sprintf( '%02d', $mon )
			. sprintf( '%02d', $mday ) . '-'
			. sprintf( '%02d', $hour ) . ':'
			. sprintf( '%02d', $min );
	}
	if ( $mon ne $cmon ) {
		return
			  sprintf( '%02d', $mon )
			. sprintf( '%02d', $mday ) . '-'
			. sprintf( '%02d', $hour ) . ':'
			. sprintf( '%02d', $min );
	}
	if ( $mday ne $cmday ) {
		return sprintf( '%02d', $mday ) . '-' . sprintf( '%02d', $hour ) . ':' . sprintf( '%02d', $min );
	}

	#just return this for anything less
	return sprintf( '%02d', $hour ) . ':' . sprintf( '%02d', $min );
} ## end sub startString

=head2 timeString

Turns the raw run string into something usable.

=cut

sub timeString {
	my $self = $_[0];
	my $time = $_[1];

	if ( $^O =~ /^linux$/ ) {
		$time = $time / 1000000;
	}

	my $hours = 0;
	if ( $time >= 3600 ) {
		$hours = int( $time / 3600 );
	}
	my $loSeconds = $time % 3600;
	my $minutes   = 0;
	if ( $time >= 60 ) {
		$minutes = int( $loSeconds / 60 );
	}
	my $seconds = ( $loSeconds % 60 ) + ( $time - int($time) );

	#nicely format it, rounding seconds to two optional decimal places
	$seconds = sprintf( '%.2f', $seconds );
	$seconds =~ s/0+$//;
	$seconds =~ s/\.$//;

	#this will be returned
	my $toReturn = '';

	#process the hours bit
	if ( $hours == 0 ) {
		#don't do anything if time is 0
	} elsif ( $hours >= 10 ) {
		$toReturn = color( $self->{timeColors}->[3] ) . $hours . ':';
	} else {
		$toReturn = color( $self->{timeColors}->[2] ) . $hours . ':';
	}

	#process the minutes bit
	if (   ( $hours > 0 )
		|| ( $minutes > 0 ) )
	{
		$toReturn = $toReturn . color( $self->{timeColors}->[1] ) . $minutes . ':';
	}

	$toReturn = $toReturn . color( $self->{timeColors}->[0] ) . $seconds . color('reset');

	return $toReturn;
} ## end sub timeString

=head2 memString

Turns the raw run string into something usable.

=cut

sub memString {
	my $self = $_[0];
	my $mem  = $_[1];
	my $type = $_[2];

	my $toReturn = '';

	if ( $mem < 10000 ) {
		$mem = sprintf( '%.2f', $mem );
		$mem =~ s/0+$//;
		$mem =~ s/\.$//;
		$toReturn = color( $self->{ $type . 'Colors' }[0] ) . $mem;
	} elsif ( ( $mem >= 10000 )
		&& ( $mem < 1000000 ) )
	{
		$mem = sprintf( '%.3f', $mem / 1000 );
		$mem =~ s/0+$//;
		$mem =~ s/\.$//;

		$toReturn = color( $self->{ $type . 'Colors' }[0] ) . $mem . color( $self->{ $type . 'Colors' }[3] ) . 'k';
	} elsif ( ( $mem >= 1000000 )
		&& ( $mem < 1000000000 ) )
	{
		$mem = ( $mem / 1000 ) / 1000;
		$mem = sprintf( '%.3f', $mem );
		my @mem_split = split( /\./, $mem );

		$toReturn
			= color( $self->{ $type . 'Colors' }[1] )
			. $mem_split[0] . '.'
			. color( $self->{ $type . 'Colors' }[0] )
			. $mem_split[1]
			. color( $self->{ $type . 'Colors' }[3] ) . 'M';
	} elsif ( $mem >= 1000000000 ) {
		$mem = ( ( $mem / 1000 ) / 1000 ) / 1000;
		$mem = sprintf( '%.3f', $mem );
		my @mem_split = split( /\./, $mem );

		$toReturn
			= color( $self->{ $type . 'Colors' }[2] )
			. $mem_split[0] . '.'
			. color( $self->{ $type . 'Colors' }[1] )
			. $mem_split[1]
			. color( $self->{ $type . 'Colors' }[3] ) . 'G';
	} ## end elsif ( $mem >= 1000000000 )

	return $toReturn . color('reset');
} ## end sub memString

=head2 physmem

Returns the physical memory size in bytes on platforms it is known
how to fetch it on. Otherwise undef is returned.

POSIX::sysconf is tried first and failing that sysctl is used.

    my $physmem=$ncps->physmem;

=cut

sub physmem {
	my $physmem;

	# first try POSIX::sysconf, which requires no external programs,
	# but not every POSIX module exposes _SC_PHYS_PAGES
	eval {
		my $phys_pages = POSIX::sysconf( POSIX::_SC_PHYS_PAGES() );
		my $pagesize   = POSIX::sysconf( POSIX::_SC_PAGESIZE() );
		if ( $phys_pages && $pagesize ) {
			$physmem = $phys_pages * $pagesize;
		}
	};

	# fall back on sysctl, checking the various places it may live
	if ( !defined($physmem) ) {
		# hw.physmem on OpenBSD is truncated to 32 bits, so use hw.physmem64 there
		my $physmem_variable = 'hw.physmem';
		if ( $^O eq 'openbsd' ) {
			$physmem_variable = 'hw.physmem64';
		}
		foreach my $sysctl_bin ( '/sbin/sysctl', '/usr/sbin/sysctl' ) {
			if ( ( !defined($physmem) ) && ( -x $sysctl_bin ) ) {
				my $sysctl_output = `$sysctl_bin -n $physmem_variable 2> /dev/null`;
				if ( defined($sysctl_output) ) {
					chomp($sysctl_output);
					if ( ( $sysctl_output =~ /^[0-9]+$/ ) && ( $sysctl_output > 0 ) ) {
						$physmem = $sysctl_output;
					}
				}
			}
		} ## end foreach my $sysctl_bin ( '/sbin/sysctl', '/usr/sbin/sysctl')
	} ## end if ( !defined($physmem) )

	return $physmem;
} ## end sub physmem

=head2 nextColor

Returns the next color.

=cut

sub nextColor {
	my $self = $_[0];

	my $color;

	if ( defined( $self->{colors}[ $self->{nextColor} ] ) ) {
		$color = $self->{colors}[ $self->{nextColor} ];
		$self->{nextColor}++;
	} else {
		$self->{nextColor} = 0;
		$color = $self->{colors}[ $self->{nextColor} ];
		$self->{nextColor}++;
	}

	return $color;
} ## end sub nextColor

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

=item * Search CPAN

L<https://metacpan.org/release/Proc-ProcessTable-ncps>

=item * Repository

L<https://github.com/VVelox/Proc-ProcessTable-ncps>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Proc::ProcessTable::ncps
