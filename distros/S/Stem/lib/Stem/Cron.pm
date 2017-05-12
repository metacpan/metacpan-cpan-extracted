#  File: Stem/Cron.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA

package Stem::Cron ;

use strict ;
use Data::Dumper ;

use Stem::Vars ;
use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;

Stem::Route::register_class( __PACKAGE__, 'cron' ) ;

my %cron_entries ;
my $cron_timer ;
my $last_time ;


my @set_names = qw( minutes hours month_days months week_days ) ;

{
	my $t = time ;

	my $interval = 60 ;
	my $delay = 59 - $t % 60 ;

	if ( $Env{ 'cron_interval' } ) {

		$interval = $Env{ 'cron_interval' } ;
		$delay = 0 ;
	}

#	my $lt = localtime $t ;
#	print "$t $lt ",  $t % 60, "\n" ;

	$cron_timer = Stem::Event::Timer->new(
		'object'	=> __PACKAGE__,
		'method'	=> 'cron_triggered',
		'interval'	=> $interval,
		'delay'		=> $delay,
		'repeat'	=> 1,			
		'hard'		=> 1,
	) ;
}

die "Stem::Cron $cron_timer" unless ref $cron_timer ;


my $attr_spec = [
	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'msg',
		'class'		=> 'Stem::Msg',
		'required'	=> 1,
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'minutes',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'hours',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'month_days',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'months',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'week_days',
		'help'		=> <<HELP,
HELP
	},

] ;

my %ranges = (

	'minutes'	=> [0, 59],
	'hours'		=> [0, 23],
	'month_days'	=> [1, 31],
	'months'	=> [1, 12],
	'week_days'	=> [0, 6],
) ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	$self->{'msg'}->from_cell( $self->{'reg_name'} || 'cron' ) ;

# make sets for each time part. if one isn't created because it is
# empty, it is a wild card with behaves as if all the slots are set.

	foreach my $set_name ( @set_names ) {

		$self->_make_cron_set( $set_name, @{$ranges{$set_name}} )
	}

# keep track of all the active cron entries.

	$cron_entries{ $self } = $self ;

	TraceStatus Dumper($self) ;

####################
####################
# why return cron entry? it should not be registered as you can't send
# it messages.  do we need a way to cancel a cron entry? could we
# register in internally to cron and not need external registration?
####################
####################

	return $self ;
}

sub _make_cron_set {

	my( $self, $set_name, $min, $max ) = @_ ;

	my $cron_list = $self->{$set_name} ;

	return unless ref $cron_list eq 'ARRAY' ;

	my( @cron_vals ) ;

	foreach my $cron_val ( @{$cron_list} ) {

		if ( $cron_val =~ /^(\d+)$/ &&
		     $min <= $1 && $1 <= $max ) {

			push @cron_vals, $1 ;
			next ;
		}

		if ( $cron_val =~ /^(\d+)-(\d+)$/ &&
		     $min <= $1 && $1 <= $2 && $2 <= $max ) {

			push @cron_vals, $1 .. $2 ;
			next ;
		}

##################
##################
##################
# this is for normal cron entries with names like days of week and
# months.  the name translation tables will be passed in or defaulted
# to american names. it needs work.
#
# also to be done is fancy entries like first thursday of month or
# weekend days, etc. it will be a filter to run when the numeric days
# of week or month days filter is run.
##################
##################
##################

#  		if ( $convert_to_num &&
#  		     exists( $convert_to_num->{$cron_val} ) ) {

#  			push @cron_vals, $convert_to_num->{$cron_val} ;
#  			next ;
#  		}

		TraceError "bad cron value '$cron_val'" ;
	}

	if ( @cron_vals ) {

		my @cron_set ;

		@cron_set[@cron_vals] = (1) x @cron_vals ;

		$self->{"${set_name}_set"} = \@cron_set ;
	}
}


sub cron_triggered {

	my $this_time = time() ;

	my %set_times ;

	TraceStatus scalar localtime( $this_time ) ;

# get the current time part into a hash

	@set_times{ @set_names } = (localtime( $this_time ))[ 1, 2, 3, 4, 6 ] ;

# one base the months

	$set_times{'months'}++ ;

	my( $set ) ;

# loop over all the entries

	CRON:
	foreach my $cron ( values %cron_entries ) {

# loop over all the possible time sets

		foreach my $name ( @set_names ) {

#  my $s = $cron->{"${name}_set"} || [] ;
#  print "C $name $set_times{ $name } @$s\n" ;

# we don't trigger unless we have a set with data and the time slot
# for the current time is true

			next CRON if $set = $cron->{"${name}_set"} and
			           ! $set->[$set_times{ $name }] ;
		}

#print "C disp $cron\n" ;

# we must have passed all the time filters, so send the message

		$cron->{'msg'}->dispatch() ;
	}
}

sub status_cmd {

Dumper(\%cron_entries) ;

}

1 ;
