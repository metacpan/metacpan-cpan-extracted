package Proc::ProcessTable::Colorizer;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use	Proc::ProcessTable;
use Term::ANSIColor;
use Text::Table;
use Term::Size;

=head1 NAME

Proc::ProcessTable::Colorizer - Like ps, but with colored columns and enhnaced functions for searching.

=head1 VERSION

Version 0.3.1

=cut

our $VERSION = '0.3.1';


=head1 SYNOPSIS

    use Proc::ProcessTable::Colorizer;

    my $cps = Proc::ProcessTable::Colorizer->new;
    print $cps->colorize;

This module uses L<Error::Helper> for error reporting.

As of right now this module is not really user friend and will likely be going through lots of changes as it grows.

=head1 METHODS

=head2 new

Creates a new object. This method will never error.

    my $cps=Proc::ProcessTable::Colorizer->new;

=cut

sub new {
	my $self={
			perror=>undef,
			error=>undef,
			errorString=>'',
			errorExtra=>{
				1=>'badTimeString',
				2=>'badPctcpuString',
			},
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
			processColor=>'WHITE',
			fields=>[
				'pid',
				'uid',
				'pctcpu',
				'pctmem',
				'size',
				'rss',
				'info',
				'nice',
				'start',
				'time',
				'proc',
				],
			header=>1,
			search=>undef,
			resolveUser=>1,
			nextColor=>0,
			showIdle=>0,
			proc_search=>undef,
			user_search=>[],
			wait_search=>[],
			self_ignore=>2,
			zombie_search=>0,
			swapped_out_search=>0,
			time_search=>[],
			pctcpu_search=>[],
	};
	bless $self;

	# Proc::ProcessTable does not return a nice value for Linux
	if ($^O =~ /linux/){
		$self->{fields}=[
				'pid',
				'uid',
				'pctcpu',
				'pctmem',
				'size',
				'rss',
				'info',
				'start',
				'time',
				'proc',
				];
	}

	if ($^O =~ /bsd/){
		$self->{physmem}=`/sbin/sysctl -a hw.physmem`;
		chomp($self->{physmem});
		$self->{physmem}=~s/^.*\: //;
	}

	return $self;
}

=head2 colorize

This colorizes it and returns a setup Text::Table object with everything already setup.

    use Proc::ProcessTable::Colorizer;
    my $cps = Proc::ProcessTable::Colorizer->new;
    print $cps->colorize;

=cut

sub colorize{
    my $self=$_[0];
	$self->errorblank;

	#the feilds to use
	my $fields=$self->fieldsGet;

	#array of colored items
	my @colored;

	#
	my $fieldInt=0;
	my $header;
	if ( $self->{header} ){
		my @header;
		while ( defined( $fields->[$fieldInt] ) ){
			my $field=color('underline white');

			if ( $fields->[$fieldInt] eq 'pid' ){
				$field=$field.'PID';
			}elsif( $fields->[$fieldInt] eq 'uid' ){
				$field=$field.'User';
			}elsif( $fields->[$fieldInt] eq 'pctcpu' ){
				$field=$field.'CPU%';
			}elsif( $fields->[$fieldInt] eq 'pctmem' ){
				$field=$field.'Mem%';
			}elsif( $fields->[$fieldInt] eq 'size' ){
				$field=$field.'VM Size';
			}elsif( $fields->[$fieldInt] eq 'rss' ){
				$field=$field.'RSS';
			}elsif( $fields->[$fieldInt] eq 'proc' ){
				$field=$field.'Command';
			}else{
				$field=$field.ucfirst($fields->[$fieldInt]);
			}

			push( @header, $field.color('reset') );

			$fieldInt++;
		}

		push( @colored, \@header );
	}

	#get the process table
	my $pt=Proc::ProcessTable->new;

	#an array of procs
	my @procs;

	#goes through it all and gathers the information
	foreach my $proc ( @{$pt->table} ){

		#process the requested fields
		$fieldInt=0;
		my %values;
		while ( defined( $fields->[$fieldInt] ) ){
			my $field=$fields->[$fieldInt];

			if (
				($^O =~ /bsd/) &&
				( $field =~ /pctmem/ )
				){
				my $rss=$proc->{rssize};
				if ( defined( $rss ) ){
					$rss=$rss*1024*4;
					$values{pctmem}=($rss / $self->{physmem})*100;
				}else{
					$values{pctmem}=0;
				}
			}elsif(
				($^O =~ /bsd/) &&
				( $field =~ /rss/ )
				){
				$values{rss}=$proc->{rssize};
				if (!defined $values{rss} ){
					$values{rss}=0;
				}else{
					#not sure why this needs done :/
					$values{rss}=$values{rss}*4;
				}
			}elsif(
				$field eq 'proc'
				){
				my $fname=$proc->fname;
				my $cmndline=$proc->cmndline;

				#save it for possible future use
				$values{fname}=$fname;
				$values{cmndline}=$cmndline;

				#set the proc value
				if ( $cmndline =~ /^$/ ){
					my $kernel_proc=1; #just assuming yet, unless it is otherwise

					#may possible be a zombie, run checks for on FreeBSD
					if (
						($^O =~ /bsd/) &&
						( hex($proc->flags) & 0x00200000 )
						){
						$kernel_proc=1;
					}

					#need to find something similar as above for Linux

					#
					if ( $kernel_proc ){
						$values{'proc'}='['.$fname.']';
						if ( $fname eq 'idle' ){
							$values{'idle'}=1;
						}
					}else{
						#most likely a zombie
						$values{'proc'}=$fname;
					}
				}else{
					if ( $cmndline =~ /^su *$/ ){
						$values{'proc'}=$cmndline.'('.$fname.')';
					}else{
						$values{'proc'}=$cmndline;
					}
				}
			}elsif(
				$field eq 'info'
				){
				$values{wchan}=$proc->wchan;
				$values{state}=$proc->state;

				if ($^O =~ /bsd/){
					$values{is_session_leader}=0;
					$values{is_being_forked}=0;
					$values{working_on_exiting}=0;
					$values{has_controlling_terminal}=0;
					$values{is_locked}=0;
					$values{traced_by_debugger}=0;
					#$values{is_stopped}=0;
					$values{posix_advisory_lock}=0;

					if ( hex($proc->flags) & 0x00002 ){ $values{controlling_tty_active}=1; }
					if ( hex($proc->flags) & 0x00000002 ){$values{is_session_leader}=1; }
					#if ( hex($proc->flags) &  ){$values{is_being_forked}=1; }
					if ( hex($proc->flags) & 0x02000 ){$values{working_on_exiting}=1; }
					if ( hex($proc->flags) & 0x00002 ){$values{has_controlling_terminal}=1; }
					if ( hex($proc->flags) & 0x00000004 ){$values{is_locked}=1; }
					if ( hex($proc->flags) & 0x00800 ){$values{traced_by_debugger}=1; }
					if ( hex($proc->flags) & 0x00001 ){$values{posix_advisory_lock}=1; }
				}

			}else{
				$values{$field}=$proc->$field;
			}


			$fieldInt++;
		}

		if ( ! defined( $values{pctmem} ) ){
			$values{pctmem} = 0;
		}
		if ( ! defined( $values{pctcpu} ) ){
			$values{pctcpu} = 0;
		}

		if ( ! defined( $values{size} ) ){
			$values{size} = 0;
		}

		$values{pctmem}=sprintf('%.2f', $values{pctmem});
		$values{pctcpu}=sprintf('%.2f', $values{pctcpu});

		$values{size}=$values{size}/1024;

		push( @procs, \%values );

	}

	#sort by CPU percent and then RAM
	@procs=sort {
		$a->{pctcpu} <=> $b->{pctcpu} or
			$a->{pctmem} <=> $b->{pctmem} or
			$a->{rss} <=> $b->{rss} or
			$a->{size} <=> $b->{size} or
			$a->{time} <=> $b->{time}
	} @procs;
	@procs=reverse(@procs);

	#put together the colored colums, minus the proc column which will be done later
	my @proc_column;
	foreach my $proc (@procs){
		my @line;
		$self->nextColorReset;

		my $show=0;

		#checks if it is the idle proc and if it should show it
		if (
			defined ( $proc->{idle} ) &&
			( ! $self->{showIdle} )
			){
			$show = 0;
		}else{
			my $required_hits=0; #number of hits required to print it
			my $hits=0; #default to zero so we print it unless we increment this for a search item

			#checks if we need to do a proc search
			my $proc_search=$self->{proc_search};
			if ( defined( $proc_search ) ){
				$required_hits++;
				#cehck if the cmndline or fname matches
				if ( $proc->{proc} =~ /$proc_search/ ){
					$hits++;
				}
			}

			#check to see if it needs to search for users
			my $user_search_array=$self->userSearchGet;
			if ( defined( $user_search_array->[0] ) ){
				my $user=getpwuid($proc->{uid});
				$required_hits++;
				my $user_search_int=0;
				my $matched=0;
				#search while we have a user defined and it has not already been matched
				while( 
					defined( $user_search_array->[ $user_search_int ] ) &&
					( $matched == 0 )
					){
					my $to_match=$user_search_array->[ $user_search_int ];
					my $to_invert=0;
					if ( $to_match=~ /^\!/ ){
						$to_invert=1;
						$to_match=~s/^\!//;
					}

					#check if it matches
					if ( $to_invert ){
						if ( $to_match ne $user ){
							$hits++;
							$matched=1;
						}
					}else{
						if ( $to_match eq $user ){
							$hits++;
							$matched=1;
						}
					}

					$user_search_int++;
				}
			}

			#check to see if it needs to search for wait channels
			my $wait_search_array=$self->waitSearchGet;
			if ( defined( $wait_search_array->[0] ) ){
				$required_hits++;
				my $wait_search_int=0;
				my $matched=0;
				#search while we have a wait channel defined and it has not already been matched
				while( 
					defined( $wait_search_array->[ $wait_search_int ] ) &&
					( $matched == 0 )
					){
					my $to_match=$wait_search_array->[ $wait_search_int ];
					my $to_invert=0;
					if ( $to_match=~ /^\!/ ){
						$to_invert=1;
						$to_match=~s/^\!//;
					}

					#check if it matches
					if ( $to_invert ){
						if ( $to_match ne $proc->{wchan} ){
							$hits++;
							$matched=1;
						}
					}else{
						if ( $to_match eq $proc->{wchan} ){
							$hits++;
							$matched=1;
						}
					}

					$wait_search_int++;
				}

			}

			#check to see if it needs to search for CPU time usage
			my $time_search_array=$self->timeSearchGet;
			if ( defined( $time_search_array->[0] ) ){
				$required_hits++;
				my $time_search_int=0;
				my $matched=0;
				#search while we have a CPU time defined and it has not already been matched
				while( 
					defined( $time_search_array->[ $time_search_int ] ) &&
					( $matched == 0 )
					){
					my $checked=0;
					my $to_match=$time_search_array->[ $time_search_int ];
					my $time=$proc->{time};
					#checks for less than or equal
					if (
						( $to_match =~ /^\<\=/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\<\=//;
						if ( $time <= $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for less than
					if (
						( $to_match =~ /^\</ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\<//;
						if ( $time < $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for greater than or equal
					if (
						( $to_match =~ /^\>=/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\>\=//;
						if ( $time >= $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for greater than
					if (
						( $to_match =~ /^\>/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\>//;
						if ( $time > $to_match ){
							$hits++;
							$matched++;
						}
					}
					$time_search_int++;
				}
			}

			#check to see if it needs to search for CPU percent
			my $pctcpu_search_array=$self->pctcpuSearchGet;
			if ( defined( $pctcpu_search_array->[0] ) ){
				$required_hits++;
				my $pctcpu_search_int=0;
				my $matched=0;
				#search while we have a CPU usage defined and it has not already been matched
				while( 
					defined( $pctcpu_search_array->[ $pctcpu_search_int ] ) &&
					( $matched == 0 )
					){
					my $checked=0;
					my $to_match=$pctcpu_search_array->[ $pctcpu_search_int ];
					my $time=$proc->{pctcpu};
					#checks for less than or equal
					if (
						( $to_match =~ /^\<\=/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\<\=//;
						if ( $time <= $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for less than
					if (
						( $to_match =~ /^\</ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\<//;
						if ( $time < $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for greater than or equal
					if (
						( $to_match =~ /^\>=/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\>\=//;
						if ( $time >= $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for greater than
					if (
						( $to_match =~ /^\>/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\>//;
						if ( $time > $to_match ){
							$hits++;
							$matched++;
						}
					}

					$pctcpu_search_int++;
				}
			}

			#check to see if it needs to search for memory percent
			my $pctmem_search_array=$self->pctmemSearchGet;
			if ( defined( $pctmem_search_array->[0] ) ){
				$required_hits++;
				my $pctmem_search_int=0;
				my $matched=0;
				#search while we have a memory usage defined and it has not already been matched
				while( 
					defined( $pctmem_search_array->[ $pctmem_search_int ] ) &&
					( $matched == 0 )
					){
					my $checked=0;
					my $to_match=$pctmem_search_array->[ $pctmem_search_int ];
					my $pctmem=$proc->{pctmem};
					#checks for less than or equal
					if (
						( $to_match =~ /^\<\=/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\<\=//;
						if ( $pctmem <= $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for less than
					if (
						( $to_match =~ /^\</ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\<//;
						if ( $pctmem < $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for greater than or equal
					if (
						( $to_match =~ /^\>=/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\>\=//;
						if ( $pctmem >= $to_match ){
							$hits++;
							$matched++;
						}
					}

					#checks for greater than
					if (
						( $to_match =~ /^\>/ ) &&
						( $checked == 0 )
						){
						$checked++;
						$to_match =~ s/^\>//;
						if ( $pctmem > $to_match ){
							$hits++;
							$matched++;
						}
					}
					
					$pctmem_search_int++;
				}
			}		
			
			#show zombie procs
			if ( $self->{zombie_search} ){
				$required_hits++;
				if ( $proc->{state} eq 'zombie' ){
					$hits++;
				}
			}

			#show swapped out procs
			if ( $self->{swapped_out_search} ){
				$required_hits++;
				if (
					( $proc->{state} ne 'zombie' ) &&
					( $proc->{rss} == '0' )
					){
					$hits++;
				}
			}

			#checks to see if it should ignore its self
			my $self_ignore=$self->{self_ignore};
			if (
				#if it is set to 1
				( $self_ignore == 1 ) &&
				( $proc->{pid} == $$ )
				){
				$required_hits++;
			}elsif(
				#if it is set to 2... we only care if we are doing a search...
				#meaning required hits are greater than zero
				( $required_hits > 0 ) &&
				( $self_ignore == 2 ) &&
				( $proc->{pid} == $$ )
				){
				#increment this so it will always be off by one for this proc, meaning it is ignored
				$required_hits++;
			}

			if ( $required_hits == $hits ){
				$show=1;
			}
		}

		if (
			( $show )
			){

			foreach my $field ( @{$fields} ){
				my $item='';
				if ( defined( $proc->{$field} ) ){
					$item=$proc->{$field};
				}
				#we will add proc later once we know the size of the table
				if ($field ne 'proc'){
					if ( $field eq 'start' ){
						$item=$self->startString($item);
					}

					if (
						( $field eq 'uid' ) &&
						$self->{resolveUser}
						){
						$item=getpwuid($item);
					}

					#colorizes it
					if ( $field eq 'time' ){
						if ( $^O =~ 'linux' ){
							$item=$item/1000000;
						}
						$item=$self->timeString($item);
					}elsif( $field eq 'proc' ){
						$item=color($self->processColorGet).$item;
					}elsif( $field eq 'info'){
						my $left=$proc->{state};
						if ( 
							$left eq 'sleep' 
							){
							$left='S';
						}elsif(
							$left eq 'zombie'
							){
							$left='Z';
						}elsif(
							$left eq 'wait'
							){
							$left='W';
						}elsif(
							$left eq 'run'
						){
							$left='R';
						}

						#checks if it is swapped out
						if (
							( $proc->{state} ne 'zombie' ) &&
						( $proc->{rss} == '0' )
							){
							$left=$left.'O';
						}

						#waiting to exit
						if (
						( defined( $proc->{working_on_exiting} ) ) &&
							$proc->{working_on_exiting}
							){
							$left=$left.'E';
						}

						#session leader
						if (
							( defined( $proc->{is_session_leader} ) ) &&
							$proc->{is_session_leader}
							){
							$left=$left.'s';
						}

						#checks to see if any sort of locks are present
						if (
							( defined( $proc->{is_locked} ) || defined( $proc->{posix_advisory_lock} ) )&&
							( $proc->{is_locked} || $proc->{posix_advisory_lock} )
							){
							$left=$left.'L';
						}

						#checks to see if has a controlling terminal
						if (
							( defined( $proc->{has_controlling_terminal} ) ) &&
							$proc->{has_controlling_terminal}
							){
							$left=$left.'+';
						}

						#if it is being forked
						if (
							( defined( $proc->{is_being_forked} ) ) &&
							$proc->{is_being_forked}
							){
							$left=$left.'F';
						}

						#checks if it knows it is being traced
						if (
							( defined( $proc->{traced_by_debugger} ) ) &&
							$proc->{traced_by_debugger}
							){
							$left=$left.'X';
						}

						if ( $^O =~ 'linux' ){
							$item=color($self->nextColor).$left.' '.color($self->nextColor);
						}else{
							$item=color($self->nextColor).$left.' '.color($self->nextColor).$proc->{wchan};
						}

					}else{
						$item=color($self->nextColor).$item;
					}

					push( @line, $item.color('reset') );
				}else{
					push( @proc_column, $item );
				}
			}

			push( @colored, \@line );
		}
	}

	#get table width info
	my $tb = Text::Table->new;
	$tb->load( @colored );
	my $width=$tb->width;
	my ($columns, $rows) = Term::Size::chars *STDOUT{IO};
	$tb->clear;

	#add 120 as Text::Table appears to be off by that much
	$columns=$columns+128;

	if ( $^O =~ 'linux' ){
		$columns=$columns-12;
	}

	#this is 
	my $procwidth=$columns-$width;

	#process each colored item and shove the proc info in
	my $colored_int=1;
	my $proc_column_int=0;
	while ( defined( $colored[$colored_int] ) ){
		my $item=$proc_column[$proc_column_int];
		#remove all the newlines
		$item=~s/\n//g;

		$item=substr( $item, 0, $procwidth);

		push( @{$colored[$colored_int]}, $item );

		$proc_column_int++;
		$colored_int++;
	}

	return $tb->load( @colored );
}

=head2 fields

Gets a hash of possible fields from Proc::ProcessTable as an hash.

This is really meant as a internal function.

=cut

sub fields{
	my $self=$_[0];
	$self->errorblank;

	my $p=Proc::ProcessTable->new;
	my @fields=$p->fields;

	my $int=0;
	my %toReturn;
	while( defined($fields[$int]) ){
		$toReturn{$fields[$int]}=1;

		$int++;
	}

	return %toReturn;
}

=head2 fieldsGet

Gets the currently set fields.

Returns a array ref of current fields to be printed.

    my $fields=$cps->fieldsGet;

=cut

sub fieldsGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{fields};
}

=head2 nextColor

Returns the next color.

    my $nextColor=$cps->nextColor;

=cut

sub nextColor{
	my $self=$_[0];
	$self->errorblank;

	my $color;

	if( defined( $self->{colors}[ $self->{nextColor} ] ) ){
		$color=$self->{colors}[ $self->{nextColor} ];
		$self->{nextColor}++;
	}else{
		$self->{nextColor}=0;
		$color=$self->{colors}[ $self->{nextColor} ];
		$self->{nextColor}++;
	}

	return $color;
}

=head2 nextColor

Resets the next color to the first one.

    my $nextColor=$cps->nextColor;

=cut

sub nextColorReset{
	my $self=$_[0];
	$self->errorblank;

	$self->{nextColor}=0;

	return 1;
}

=head2 fieldsSet

Gets the currently set fields.

Returns a list of current fields to be printed.

    my @fields=$cps->fieldsGet;

=cut

sub fieldsSet{
	my $self=$_[0];
	$self->errorblank;


}

=head2 pctcpuSearchGet

Returns the current value for the PCT CPU search.

The return is a array ref.

    my $pctcpu_search=$cps->pctcpuSearchGet;

=cut

sub pctcpuSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{pctcpu_search};
}

=head2 pctcpuSearchSetString

Search for procs based on the CPU usage.

The following equalities are understood.

    <=
    <
    >
    >=

The string may contain multiple values seperated by a comma. Checking will stop after the first hit.

If the string is undef, all procs will be shown.

    #search for procs with less than 60% of CPU usage
    $cps->pctcpuSearchSetString('<60');
    #shows procs with greater than 60% of CPU usage
    $cps->pctcpuSearchSetString('>60');

=cut

sub pctcpuSearchSetString{
	my $self=$_[0];
	my $pctcpu_search_string=$_[1];
	$self->errorblank;

	my @pctcpu_search_array;
	if ( ! defined( $pctcpu_search_string ) ){
		$self->{pctcpu_search}=\@pctcpu_search_array;
	}else{
		@pctcpu_search_array=split(/\,/, $pctcpu_search_string);

		foreach my $item ( @pctcpu_search_array ){
			if (
				( $item !~ /^\>[0123456789]*$/ ) &&
				( $item !~ /^\>[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\>\.[0123456789]*$/ ) &&
				( $item !~ /^\>\=[0123456789]*$/ ) &&
				( $item !~ /^\>\=[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\>\=\.[0123456789]*$/ ) &&
				( $item !~ /^\<[0123456789]*$/ ) &&
				( $item !~ /^\<[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\<\.[0123456789]*$/ ) &&
				( $item !~ /^\<\=[0123456789]*$/ ) &&
				( $item !~ /^\<\=[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\<\=\.[0123456789]*$/ )
				){
				$self->{error}=2;
				$self->{errorString}='"'.$item.'"" is not a valid value for use in a PCT CPU search';
				$self->warn;
				return undef;
			}

		}

		$self->{pctcpu_search}=\@pctcpu_search_array;
	}

	return 1;
}

=head2 pctmemSearchGet

Returns the current value for the PCT MEM search.

The return is a array ref.

    my $pctmem_search=$cps->pctmemSearchGet;

=cut

sub pctmemSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{pctmem_search};
}

=head2 pctmemSearchSetString

Search for procs based on the memory usage.

The following equalities are understood.

    <=
    <
    >
    >=

The string may contain multiple values seperated by a comma. Checking will stop after the first hit.

If the string is undef, all procs will be shown.

    #search for procs with less than 60% of the memory
    $cps->pctmemSearchSetString('<60');
    #shows procs with greater than 60% of the memory
    $cps->pctmemSearchSetString('>60');

=cut

sub pctmemSearchSetString{
	my $self=$_[0];
	my $pctmem_search_string=$_[1];
	$self->errorblank;

	my @pctmem_search_array;
	if ( ! defined( $pctmem_search_string ) ){
		$self->{pctmem_search}=\@pctmem_search_array;
	}else{
		@pctmem_search_array=split(/\,/, $pctmem_search_string);

		foreach my $item ( @pctmem_search_array ){
			if (
				( $item !~ /^\>[0123456789]*$/ ) &&
				( $item !~ /^\>[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\>\.[0123456789]*$/ ) &&
				( $item !~ /^\>\=[0123456789]*$/ ) &&
				( $item !~ /^\>\=[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\>\=\.[0123456789]*$/ ) &&
				( $item !~ /^\<[0123456789]*$/ ) &&
				( $item !~ /^\<[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\<\.[0123456789]*$/ ) &&
				( $item !~ /^\<=[0123456789]*$/ ) &&
				( $item !~ /^\<\=[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\<\=\.[0123456789]*$/ )
				){
				$self->{error}=3;
				$self->{errorString}='"'.$item.'"" is not a valid value for use in a PCT MEM search';
				$self->warn;
				return undef;
			}

		}

		$self->{pctmem_search}=\@pctmem_search_array;
	}

	return 1;
}

=head2 processColorGet

    my $timeColors=$cps->processColorGet;

=cut

sub processColorGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{processColor};
}

=head2 procSearchGet

This returns the search string value that will be used
for matching the proc column.

The return is undefined if one is not set.

    my $search_regex=$cps->procSearchGet;
    if ( defined( $search_regex ) ){
        print "search regex: ".$search_regex."\n";
    }else{
        print "No search regex.\n";
    }

=cut

sub procSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{proc_search};
}

=head2 procSearchSet

This sets the proc column search regex to use.

If set to undef(the default), then it will show all procs.

    #shows everything
    $cps->procSearchSet( undef );

    #search for only those matching musicpd
    $cps->procSeearchSet( 'musicpd' );

    #search for those that match /[Zz]whatever/
    $cps->procSearchSet( '[Zz]whatever' );

=cut

sub procSearchSet{
	my $self=$_[0];
	my $proc_search=$_[1];
	$self->errorblank;

	$self->{proc_search}=$proc_search;

	return 1;
}

=head2 selfIgnoreGet

=cut

sub selfIgnoreGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{self_ignore};
}

=head2 selfIgnoreSet

Wether or not to show the PID of this processes in the list.

=head3 undef

Resets it to the default, 2. 

=head3 0

Always show self PID in the list.

=head3 1

Never show self PID in the list.

=head3 2

Don't show self PID if it is a search.

This is the default.

=cut

sub selfIgnoreSet{
	my $self=$_[0];
	my $self_ignore=$_[1];
	$self->errorblank;

	if ( ! defined( $self_ignore ) ){
		$self_ignore='2';
	}

	$self->{self_ignore}=$self_ignore;

	return 1;
}

=head2 startString

Generates a short time string based on the supplied unix time.

=cut

sub startString{
	my $self=$_[0];
	my $startTime=$_[1];
	$self->errorblank;

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

=head2 swappedOutSearchGet

Returns the current value for the swapped out search.

The return is a Perl boolean.

    my $swappedOut_search=$cps->swappedOutSearchGet;
    if ( $swappedOut_search ){
        print "only swapped out procs will be shown";
    }

=cut

sub swappedOutSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{swapped_out_search};
}

=head2 swappedOutSearchSet

Sets the swapped out search value.

The value taken is a Perl boolean.

    $cps->swappedOutSearchSet( 1 );

=cut

sub swappedOutSearchSet{
	my $self=$_[0];
	my $swapped_out_search=$_[1];
	$self->errorblank;

	$self->{swapped_out_search}=$swapped_out_search;

	return 1;
}

=head2 timeColorsGet

    my $timeColors=$cps->timeColorsGet;

=cut

sub timeColorsGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{timeColors};
}

=head2 timeSearchGet

Returns the current value for the time search.

The return is a array ref.

    my $time_search=$cps->waitSearchGet;

=cut

sub timeSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{time_search};
}

=head2 timeSearchSetString

Search for procs based on the CPU time value.

The following equalities are understood.

    <=
    <
    >
    >=

The string may contain multiple values seperated by a comma. Checking will stop after the first hit.

If the string is undef, all wait channels will be shown.

    #search for procs with less than 60 seconds of CPU time
    $cps->waitSearchSetString('<69');
    #shows procs with less than 60 seconds and greater 120 seconds
    $cps->waitSearchSetString('<60,>120');

=cut

sub timeSearchSetString{
	my $self=$_[0];
	my $time_search_string=$_[1];
	$self->errorblank;

	my @time_search_array;
	if ( ! defined( $time_search_string ) ){
		$self->{time_search}=\@time_search_array;
	}else{
		@time_search_array=split(/\,/, $time_search_string);

		foreach my $item ( @time_search_array ){
			if (
				( $item !~ /^\>[0123456789]*$/ ) &&
				( $item !~ /^\>[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\>\.[0123456789]*$/ ) &&
				( $item !~ /^\>=[0123456789]*$/ ) &&
				( $item !~ /^\>\=[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\>\=\.[0123456789]*$/ ) &&
				( $item !~ /^\<[0123456789]*$/ ) &&
				( $item !~ /^\<[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\<\.[0123456789]*$/ ) &&
				( $item !~ /^\<=[0123456789]*$/ ) &&
				( $item !~ /^\<\=[0123456789]*\.[0123456789]*$/ ) &&
				( $item !~ /^\<\=\.[0123456789]*$/ )
				){
				$self->{error}=1;
				$self->{errorString}='"'.$item.'"" is not a valid value for use in a time search';
				$self->warn;
				return undef;
			}

		}

		$self->{time_search}=\@time_search_array;
	}

	return 1;
}

=head2 timeString

Turns the raw run string into something usable.

This returns a colorized item.

    my $time=$cps->timeString( $seconds );

=cut

sub timeString{
	my $self=$_[0];
	my $time=$_[1];
	$self->errorblank;

	my $colors=$self->timeColorsGet;

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
		$toReturn=color($colors->[3]).$hours.':';
	}else{
		$toReturn=color($colors->[2]).$hours.':';
	}

	#process the minutes bit
	if (
		( $hours > 0 ) ||
		( $minutes > 0 )
		){
		$toReturn=$toReturn.color( $colors->[1] ). $minutes.':';
	}

	$toReturn=$toReturn.color( $colors->[0] ).$seconds;

	return $toReturn;
}

=head1 userSearchGet

This gets the user to be searched for and if it should be inverted or not.

This returns an array reference of users to search for.

An selection can be inverted via !.

    my $user_search=$cps->userSearchGet;

=cut

sub userSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{user_search};
}

=head1 userSearchSetString

This takes a string to set the user search for.

An selection can be inverted via !.

The string may contain multiple users seperated by a comma.

If the string is undef, all users will be shown.

    #search for user foo and bar
    $cps->userSearchSetString('foo,bar');
    #show users not matching foo
    $cps->userSearchSetString('!foo');
    #show all users, clearing any previous settings
    $cps->userSearchSetString;

=cut

sub userSearchSetString{
	my $self=$_[0];
	my $user_search_string=$_[1];
	$self->errorblank;

	my @user_search_array;
	if ( ! defined( $user_search_string ) ){
		$self->{user_search}=\@user_search_array;
	}else{
		@user_search_array=split(/\,/, $user_search_string);
		$self->{user_search}=\@user_search_array;
	}

	return 1;
}

=head2 waitSearchGet

Returns the current value for the wait search.

The return is a array ref.

    my $wait_search=$cps->waitSearchGet;

=cut

sub waitSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{wait_search};
}

=head2 waitSearchSetString

This takes a string to set the wait channel search for.

An selection can be inverted via !.

The string may contain multiple users seperated by a comma.

If the string is undef, all wait channels will be shown.

    #search for wait channel wait and sleep
    $cps->waitSearchSetString('wait,sleep');
    #shows wait channels not matching sbwait
    $cps->waitSearchSetString('!sbwait');
    #show all users, clearing any previous settings
    $cps->waitSearchSetString;

=cut

sub waitSearchSetString{
	my $self=$_[0];
	my $wait_search_string=$_[1];
	$self->errorblank;

	my @wait_search_array;
	if ( ! defined( $wait_search_string ) ){
		$self->{wait_search}=\@wait_search_array;
	}else{
		@wait_search_array=split(/\,/, $wait_search_string);
		$self->{wait_search}=\@wait_search_array;
	}

	return 1;
}

=head2 zombieSearchGet

Returns the current value for the zombie search.

The return is a Perl boolean.

    my $zombie_search=$cps->zombieSearchGet;
    if ( $zombie_search ){
        print "only zombie procs will be shown";
    }

=cut

sub zombieSearchGet{
	my $self=$_[0];
	$self->errorblank;

	return $self->{zombie_search};
}

=head2 zombieSearchSet

Sets the zombie search value.

The value taken is a Perl boolean.

    $cps->zombieSearchSet( 1 );

=cut

sub zombieSearchSet{
	my $self=$_[0];
	my $zombie_search=$_[1];
	$self->errorblank;

	$self->{zombie_search}=$zombie_search;

	return 1;
}

=head1 COLORS

These corresponds to L<Term::ANSIColor> colors.

=head2 Time

The color column is not a single color, but multiple depending on the amount of time.

The default is as below.

    'GREEN', seconds
    'BRIGHT_GREEN', minutes
    'RED', hours
    'BRIGHT_RED', 10+ hours

=head2 Columns

The non-proc/time columns are colored in a rotating color sequence.

The default is as below.

    BRIGHT_YELLOW
    BRIGHT_CYAN
    BRIGHT_MAGENTA
    BRIGHT_BLUE

=head1 ERROR CODES/FLAGS

=head2 1 / badTimeString

The time search string contains errors.

=head2 2 / badPctcpuString

The PCT CPU search string contains errors.

=head2 3 / badPctmemString

The PCT MEM search string contains errors.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-proc-processtable-colorizer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-ProcessTable-Colorizer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Proc::ProcessTable::Colorizer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Proc-ProcessTable-Colorizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Proc-ProcessTable-Colorizer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Proc-ProcessTable-Colorizer>

=item * Search CPAN

L<http://search.cpan.org/dist/Proc-ProcessTable-Colorizer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Zane C. Bowers-Hadley.

This program is distributed under the (Simplified) BSD License:
L<http://www.opensource.org/licenses/BSD-2-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Proc::ProcessTable::Colorizer
