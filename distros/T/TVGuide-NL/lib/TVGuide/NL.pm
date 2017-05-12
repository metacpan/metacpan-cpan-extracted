package TVGuide::NL;

# TVGids.pm - retrieve tv schedule for dutch television
# Copyright (c) 2004-2006 by Bas Zoetekouw <bas@debian.org>
# $Id: NL.pm 83 2006-09-13 14:10:23Z bas $
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of either the Artistic license, or
# version 2 of the GNU General Public License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#


=pod
=encoding utf8

=head1 NAME

TVGuide::NL - fetch Dutch TV schedule from http://gids.omroep.nl/

=head1 SYNOPSIS

  use TVGuide::NL;
  $g = TVGuide::NL->new();
  print for $g->whats_on('ned1','rtl5','bbc2','cnn');
  print for $g->whats_next('ned1','rtl5','bbc2','cnn');

=head1 DESCRIPTION

The TVGuide::NL module is a perl interface to the TV schedules of
http://gids.omroep.nl/.  

Please note that you are allowed to use the data from
http://gids.omroep.nl/ for your personal use only.  
Please refer to http://gids.omroep.nl/info/help.php#faq7 for more
information on the copyright of the program scedule data.

=head1 METHODS

=over 4

=cut

use warnings;
use strict;

# require perl 5.8 to handle all the unicode stuff
require 5.008_001;
use encoding 'utf8';
use utf8;

# set the version of this module
our $VERSION;
$VERSION = '0.14';

# load modules we need
use Carp;
use File::Spec;
use Storable qw{ lock_store lock_retrieve };
use Time::Local qw{ timegm_nocheck timelocal timelocal_nocheck };
use HTML::Entities;
require LWP::UserAgent;
require HTML::TreeBuilder;
require HTML::TokeParser;
require Encode;

# public methods
sub new;				# constuctor
sub is_valid_station;	# check if a station name, code or abbrev is valid
sub all_station_codes;	# returns a list of all station codes
sub all_station_names;	# returns a list of all station names
sub station_name;		# returns the full name of the station
sub station_code;		# returns the Z-code of the station
sub station_abbr;		# returns the abbreviation of the station
sub update_schedule;	# updates the schedule
sub update_movies;		# updates the list of movies
sub movies_today;		# returns list of movies on certain stations today
sub whats_on_today;		# returns list of programs on certains stations
sub whats_on;			# returns nicely formatted current program
sub whats_next;			# returns nicely formatted next program
sub timestamp;			# returns timestamp of last update of station


# private methods
sub _debug;					# display debugging output
sub _write_cache;			# write cache to disk
sub _read_cache;			# read cache from disk
sub _sort_stations;			# sort stations in the correct order for omroep.nl/
sub _update_session_cookie;	# updates the session cookie
sub _update_schedule_10;	# update the schedule, 10 stations max
sub _get_page;				# retrieves a page from the web
sub _parse_schedule;		# parses the schedule page
sub _parse_movies;			# parses the movie page
sub _get_page;				# fetch a page from omroep.nl
sub _whats_on_generic;		# returns next program

# non-object private methods
sub __is_today;		# check if a timestamp is today
sub __uniq;			# uniq(1)ify a list
sub __min;			# return the minimum of a list
sub __comp_times;	# compare two times of format hh:mm


# private globals
my $HTTP_USERAGENT = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5a) Gecko";
my %HTTP_HEADERS = ( 
		'Accept' => 'text/xml,application/xml,application/xhtml+xml,'.
				    'text/html;q=0.9,text/plain;q=0.8,video/x-mng,'.
					'image/png,image/jpeg,image/gif;q=0.2,*/*;q=0.1',
		'Accept-Language' => 'en,en-us;q=0.5' 
);
my $HTTP_TIMEOUT = 3;
my $TMPDIR = File::Spec->tmpdir();
my $DEFAULT_CACHE_FILE = 
	File::Spec->catfile($TMPDIR,"tvguide.nl.$VERSION.$>.cache");


# Load TVGuide::NL::Names and make sure everyting we need is in there.
BEGIN
{
	eval {
		use TVGuide::NL::Names qw( 
			%STATION_LOOKUP
			%CODE_LOOKUP 
			%STATION_PIC_LOOKUP 
			%STATION_ORDER 
			%STATION_NAMES 
		);
	};
	if ($@) { 
		croak "Error while importing names from `TVGuide::NL::Names': $@"; 
	}
	
	croak '%STATION_LOOKUP not found'		unless exists $STATION_LOOKUP{ned1};
	croak '%CODE_LOOKUP not found' 			unless exists $CODE_LOOKUP{Z1};
	croak '%STATION_PIC_LOOKUP not found'	unless exists $STATION_PIC_LOOKUP{'tv-nl1'};
	croak '%STATION_ORDER not found' 		unless exists $STATION_ORDER{Z1};
	croak '%STATION_NAMES not found' 		unless exists $STATION_NAMES{Z1};
}


END   { }


=item $g = TVGuide::NL->new( %options );

This is the constructor of the TVGuide::NL object.

The options hash allows you to specify certain behavioral changes of the
modules.  The following options are available:

=over 4

=item cache

By default, a TVGuide::NL object caches the data it fetched from the web to a
file 'tvguide.nl.$>.cache' in a temporary directory (usually /tmp/ on
UNIX-flavored systems).  This is done mainly to improve performance of the
module.

The cache filename can be changed by setting this option.  If the filename you
specify does not contain any directory separators, the cache file is placed in
a temporary directory.  If you want to put the cache file in the current
directory, prepend './' to the filename you specify.

Caching to disk can be disabled altogether by setting this option to a FALSE
value.  Note that this does not disable caching of the data in memory.

=item debug

Set the debug options to a true value to see noisy debug output.

=back

=cut

sub new
{
	my $class   = shift;
	my %options = @_;

	my $self = {};

	# initialize options to their default values
	$self->{DEBUG} = 0;
	$self->{CACHE} = $DEFAULT_CACHE_FILE;
	# init variables
	$self->{session_cookie}	 = undef;   # session cookie will be stored here
	$self->{session_stamp} 	 = 0;       # time() of last session_cookie update
	$self->{session_timeout} = 900;     # timeout for refreshing session_cookie
	# this contains the schedule; it's a hash of hashes: 
	# schedule: {schedule}->{today}->{Z2}->{schedule}->[2]->{title}
	# station name: {schedule}->{today}->{Z2}->{name}
	# timestamp: {schedule}->{today}->{Z2}->{timestamp}
	$self->{schedule}->{today} = (); 
	# TODO: tomorrow, etc

	bless($self, $class);

	# now examine the options
	$self->{DEBUG} = 1
		if (exists $options{debug} and $options{debug});

    # cache option
    if (exists $options{cache})
    {
		# do we want cache?
		if ($options{cache})
		{
			$self->{CACHE} = $options{cache};

			# now see if we need to add a TMP path
			my $dir = ( File::Spec->splitpath( $self->{CACHE} ) )[1];
			$self->{CACHE} = File::Spec->catfile('', $TMPDIR, $self->{CACHE})
				unless ($dir);
		}
		else
		{
			$self->{CACHE} = '';
		}

    }

	return $self;
}


########################################################################
## first define some small helper functions
########################################################################

# just like uniq(1)
# taken from /usr/share/perl/5.8/pod/perlfaq4.pod
sub __uniq
{
	return undef if (not exists($_[0]));
	my $prev = "not equal to $_[0]";
	return grep($_ ne $prev && ($prev = $_, 1), @_);
}

# return minimum of list
sub __min
{
	my $min = shift;
	foreach my $item (@_)
	{
		($min = $item) if ($item<$min);
	}
	return $min;
}

# check if a timestamp is today (i.e. > 6am Europe/Amsterdam time)
# return 1 if today, 0 otherwise
sub __is_today($)
{
	my $timestamp = shift;
	my $day_start = 6;  # hour at which day starts

	# this is the POSIX compliant way of saying 'Europe/Amsterdam'
	local $ENV{TZ} = 'CET-1CEST,M3.5.0/2,M10.5.0/2';

	# get (in UTC time) the start of today and tomorrow in .nl
	# offset is to make sure days start at 5am
	my @now = localtime(time()-$day_start*3600);
	# today started at 6am this morning, Amsterdam time
	my $today_start = timelocal(10,0,$day_start, @now[3..5]);
	# tomorrow starts at 6am tomorrow morning, Amsterdam time
	my $tomorrow_start = timelocal_nocheck(10,0,$day_start, 
		$now[3]+1,@now[4..5]);

	# compare the timestamp against the timestamp of day start
	return -1 
		if ($timestamp <= $today_start);
	return 1
		if ($timestamp > $tomorrow_start);
	return 0;
}

# compare two program times (format ab:cd)
# return -1 if first time is earliest, 
# 0 if times are equal, 
# 1 if second time is earliest
sub __comp_times
{
	my $time1 = shift;
	my $time2 = shift;

	return undef unless ($time1 and $time2);
	
	my ($hour1,$min1) = split ':', $time1, 2;
	my ($hour2,$min2) = split ':', $time2, 2;

	$hour1+=24 if ($hour1<6);
	$hour2+=24 if ($hour2<6);
	
	return -1 if ($hour1<$hour2 or $hour1==$hour2 and $min1<$min2);
	return 0  if ($hour1==$hour2 and $min1==$min2);
	return 1;
}


########################################################################
## some small object helpers
########################################################################

# write out debugging code
sub _debug
{
	my $self = shift;
	return unless ($self->{DEBUG});
	print STDERR @_, "\n";
}

# sort tv station indices (Z1, Z2, etc)
# we need to sort this in a specific order (specified by %StationSort),
# or otherwise the omroep.nl web interface will b0rk
sub _sort_stations
{
	my $self = shift;
	return sort { $STATION_ORDER{$a} <=> $STATION_ORDER{$b} } @_;
}

########################################################################
## functions having to do with the names and codes of stations
########################################################################

=item $g->is_valid_station( $s )

This function can be used to check if a certain station name (e.g. 'BBC
World'), code (e.g. 'Z44') or abbreviation (e.g. 'bbcw') is valid.

It returns 0 if the input is not a valid station, 1 if it is a name of a
station, 2 if it is a station code and 3 if it is a station abbreviation.
	
=cut
sub is_valid_station
{
	my $self = shift;
	my $station = shift 
		or croak "is_valid_station called with <2 arguments";

	return 2
		if (exists $CODE_LOOKUP{$station} or exists $CODE_LOOKUP{uc $station});
	return 1
		if (exists $STATION_LOOKUP{$station});
	return 3
		if (exists $STATION_PIC_LOOKUP{$station});

	return 0;
}

=item $g->all_station_codes

Returns a list of Z-codes of all known stations.
	
=cut
sub all_station_codes
{
	my $self = shift;
	return $self->_sort_stations( keys %STATION_NAMES );
}

=item $g->all_station_names

Returns a list of the names of all known stations.
	
=cut
sub all_station_names
{
	my $self = shift;
	my @names = ();
	foreach my $code ($self->all_stations_codes)
	{
		push @names, $self->station_name($code);
	}
	return @names;
}


=item @c = $g->station_code( @s )

This function converts a list of stations codes and/or abbreviations to
the corresponding list of codes.

If this function is used in scalar context, and it is called with exactly 1
argument, it returns a scalar rather than a list.

The result is set to undef is the station is invalid or unknown.

For example:

	@c = $g->station_code( 'bbcw', 'z44', 'bbw', 'foobar');

returns ('Z44','Z44','Z44',undef), while

	$c = $g->station( 'bbcw' );

returns 'Z44'.  
	
=cut
sub station_code
{
	my $self = shift;
	my @in = @_;
	my @out = ();

	$self->_debug("(station_code) ==> in: @in");

	foreach my $station (@in)
	{
		my $code;
		my $res = $self->is_valid_station($station);

		if (!$res)
		{
			$code = undef;
		}
		elsif ($res == 1)
		{
			$code = $STATION_LOOKUP{$station};
		}
		elsif ($res == 2)
		{
			$code = uc $station;
		}
		elsif ($res == 3)
		{
			$code = $STATION_PIC_LOOKUP{$station};
		}

		$self->_debug("(station_code) ==> $station --> $res, $code");
		
		push @out, $code;
	}

	return $out[0]
		if (@in == 1 and not wantarray);
		
	return @out;
}

=item $n = $g->station_name( $c )

Returns the full name of the station with code or abbreviation $c.

=cut
sub station_name
{
	my $self = shift;
	my $station = lc shift;

	return undef unless $self->is_valid_station($station);

	# convert station name to code, if it is a name
	($station) = $self->station_code($station);

	return $STATION_NAMES{$station} || undef;
}

=item $n = $g->station_abbr( $c )

Returns the abbreviation of the station $c.

=cut
sub station_abbr
{
	my $self = shift;
	my $station = lc shift;

	return undef unless $self->is_valid_station($station);

	# convert station name to code, if it is a name
	($station) = $self->station_code($station);

	return $CODE_LOOKUP{$station} || undef;
}

########################################################################
## cache functions
########################################################################

# write cache to file
# returns undef on error, 1 on success, 2 when no cache used
sub _write_cache
{
	my $self = shift;

	return 2 unless ($self->{CACHE});
	
	my %to_store;
	$to_store{schedule} = $self->{schedule};
	$to_store{session_cookie} = $self->{session_cookie};
	$to_store{session_stamp} = $self->{session_stamp};
	
	# and then store the entire thing
	unless ( lock_store(\%to_store, $self->{CACHE}) )
	{
		carp "Error while writing cache ".$self->{CACHE}.": $!\n";
		return undef
	}
	return 1;
}

# retrieve cache
sub _read_cache()
{
	my $self = shift;
	
	# don't read the cache if we already have data
	if ($self->{session_cookie})
	{
		$self->_debug("(_read_cache) ==> already have data");
		return;
	}
	# don't read the cache if the cache file doesn't exist
	unless ($self->{CACHE} and -e $self->{CACHE})
	{
		$self->_debug('(_read_cache) ==> No cache file found');
		return;
	}

	$self->_debug('(_read_cache) ==> reading cache...');

	my %retrieved = %{lock_retrieve($self->{CACHE})};
	unless (%retrieved)
	{
		$self->{schedule}->{today} = {};
		$self->{session_cookie} = undef;
		$self->{session_stamp} = 0;
		return;
	}

	# ok, put the data back
	$self->{schedule} = $retrieved{schedule};
	$self->{session_cookie} = $retrieved{session_cookie};
	$self->{session_stamp} = $retrieved{session_stamp};
}


########################################################################
## function for retrieving and parsing the web pages
########################################################################

# get an url from the gids.omroep.nl site
# if necessary, get a new cookie first;
sub _get_page
{
	my $self = shift;
	my $url = shift;

	# udate session cookie, if necessary
	$self->_update_session_cookie;

	# initialize HTTP client funtion
	my $ua = LWP::UserAgent->new;
	$ua->agent($HTTP_USERAGENT);
	$ua->timeout($HTTP_TIMEOUT);
	$ua->env_proxy;

	# GET content
	my $response = $ua->get($url, %HTTP_HEADERS, 
			"Cookie" => $self->{session_cookie});
	if (!$response->is_success) { 
		$self->_debug("Error while retrieving url $url: ",
				$response->status_line);
		return undef;
	}

	# page is in latin1, we return utf8
	return Encode::decode('iso-8859-1', $response->content);
}

# connect to the server to get a session ID
# return 2 if there's no need to update (timeout not reached)
# return 1 if the cookie was successfully updated
# return 0 if something went wrong while updating
sub _update_session_cookie
{
	my $self = shift;
	
	# read the cache
	$self->_read_cache();

	# Let's see if the session cookie needs updating
	if ($self->{session_cookie} and
		time() < $self->{session_stamp} + $self->{session_timeout} )
	{
		# it's still valid, so return
		$self->_debug('--> Cookie is still valid!');
		return 2;
	}
		
	# this will contain the cookie, if we find it
	my $cookie = undef;
	
	# initialize HTTP client funtion
	my $ua = LWP::UserAgent->new;
	$ua->agent($HTTP_USERAGENT);
	$ua->timeout($HTTP_TIMEOUT);
	$ua->env_proxy;

	# GET http://gids.omroep.nl/ to get a PHPSESSID
	my $response = $ua->get('http://gids.omroep.nl/', %HTTP_HEADERS);
	if ($response->is_success) { 
		if ($response->header('Set-Cookie') =~ m/^EPGSESSID=(.*?);/)
		{
			$cookie = "EPGSESSID=$1";
		}
	}

	# check if everyting went ok
	if ($cookie)
	{
		# set the cookie and the timestamp
		$self->{session_cookie} = $cookie;
		$self->{session_stamp} = time();
		return 1;
	}

	# we couldn't get a session cookie
	carp 'Something went wrong wgile udating the session_cookie';
	return 0;
}

# parse the content of a gids.omroep.nl/core/content.php page 
sub _parse_schedule
{
	my $self = shift;
	my $content = shift;

	# now parse the html file
	my $htmltree = HTML::TreeBuilder->new();
	$htmltree->parse($content);
	$htmltree->eof;

	# find the currently displayed stations
	my %stations;
	my $subtree;

	# first find the table containing the stations
	$subtree = $htmltree->look_down(
			'_tag' => 'table', 
			'summary' => 'Zenderoverzicht'
	);
	unless ($subtree){
		carp 'Oops, no `Zenderoverzicht\' table found';
		return undef;
	}

	# use the name attributes in the input tags
	foreach ( $subtree->look_down(
				'_tag' => 'input',
				sub { $_[0]->attr('name') =~ m/^Z/ and $_[0]->attr('checked') } 
	))
	{
		my $code = $_->attr('name');
		my $name = $_->parent->left->content->[0];
		$stations{$code} = decode_entities( $name );
	}

	# now parse the schedule

	# the programs will be put into this array.  
	# Index is the number of the column in the html file
	my @programs;
	for (my $i=0; $i<scalar(keys(%stations)); $i++)
	{
		$programs[$i] = [];
	}
		
	# find the table containing the schedule
	$subtree = $htmltree->look_down(
			'_tag' => 'table', 
			'summary' => 'Programmaoverzicht'
	);
	foreach my $foo ( $subtree->look_down('_tag','td', 'class','pt')) 
	{
		my $time  = $foo->as_text;
		
		my $cell  = $foo->right;
		my $title = $cell->find('b')->as_text;
		my $desc  = $cell->find('a')->as_text;
		my $info  = $cell->content->[0]->attr('href');

		# ugly hack to correct s///'s behaviour with use encoding;
		substr($desc,0,length $title)='' if (0 == index $desc,$title);

		# this is the number of the column this particular cell is in
		# (i.e. the index of the station)
		my $stationidx = ($foo->parent->parent->parent->pindex) -1;

		my $omroep = '';
		$omroep = $1 if ($desc =~ s/^\((.*?)\)\s?//);
		
		push @{$programs[$stationidx]}, {
			'time'		=>	$time, 
			'title'		=>	$title, 
			'desc'		=>	$desc, 
			'info'		=>	$info, 
			'omroep'	=>	$omroep
		};
	}

	# now put the info we found into the schedule
	my $stationidx = -1;
	foreach my $station ($self->_sort_stations(keys %stations))
	{
		$stationidx++;
		$self->{schedule}->{today}->{$station}->{timestamp} = time();
		$self->{schedule}->{today}->{$station}->{schedule} = 
			[ @{$programs[$stationidx]} ];
	}

	return 1;
}

# parse the content of 
# http://gids.omroep.nl/core/content.php?guide=Filmgids&medium=TV
sub _parse_movies
{
	my $self = shift;
	my $content = shift;

	# now parse the html file
	my $htmltree = HTML::TreeBuilder->new();
	$htmltree->parse($content);
	$htmltree->eof;

	# movies will be put in here
	my @movies = ();


	# find all movies
	my $subtree;
	# first find the table containing the schedule
	$subtree = $htmltree->look_down(
		'_tag' => 'table', 
		'summary'=> 'Programmaoverzicht'
	);
	# loop over the rows in the table (first 2 are headers)
	for (my $i=2; exists $subtree->content->[$i]; $i++)
	{
		my $row = $subtree->content->[$i];

		if ($row->content_list != 5)
		{
			carp "Parse error in row $i of movie page";
			next;
		}

		# extract some info
		my $time  = $row->content->[1]->as_trimmed_text;
		my $title = $row->address('.2.0.0')->as_trimmed_text;
		my $url   = $row->address('.2.0')->{'href'};
		my $desc  = $row->address('.2')->as_text;
		my $station = $row->address('.3.0.0')->{'src'};

		## fix misc things
		# title is repeated in the description
		# ugly hack to correct s///'s behaviour with use encoding;
		substr($desc,0,length $title)='' if (0 == index $desc,$title);
		# convert the station picture to a Z-code
		$station =~ s{^/Z/(tvs?-.+)\.gif}{$1};
		$station = $self->station_code($station);

		# remove stupid title additions
		$title =~ s/^(?:Filmfan|Telefilm|KRO Filmtheater|Filmhuis):\s+//  
			if ($station eq 'Z1' or $station eq 'Z2' or $station eq 'Z3');
		$title =~ s/- .*$//  
			if ($station eq 'Z1' or $station eq 'Z2' or $station eq 'Z3');
		$title =~ s/^(?:Zomergast[^:]+|Cinema 3):\s+//  
			if ($station eq 'Z3');
		$title =~ s/^(?:Erotiek op [^:]+):\s+//  
			if ($station eq 'Z4' or $station eq 'Z5' or $station eq 'Z6');
		$title =~ s/^[^:]+:\s+//  
			if ($station eq 'Z5');
		$title =~ s/^(?:[^:]+ Night|Filmhuis):\s+//  
			if ($station eq 'Z7' or $station eq 'Z8' or $station eq 'Z9');
		$title =~ s/^(?:Film[^:]+|[^:]*Vrijzinnige Omroep):\s+//  
			if ($station eq 'Z16' or $station eq 'Z17');
		$title =~ s/^(?:MTV [^:]+):\s+//
			if ($station eq 'Z11');

		# extract start/stop time
		my ($start,$stop) = (undef,undef);
		if ($time =~ m/(\d+:\d+)\s-\s(\d+:\d+)/)
		{
			($start,$stop) = ($1,$2);
		}
		else
		{
			carp "Couldn't find times at row $i";
			next;
		}

		# extract year
		my $year = '';
		$year = $1 if ($desc =~ m/^[^.]+\b(\d{4})\b[^.]*\./);

		# extract director
		my $director = '';
		$director = $1 if ($desc =~ m/^[^.]+\bvan\s([-\w\s]+)\./);

		push @movies, {
			 'time'		=>	$start, 
			 'stop'		=>	$stop, 
			 'title'	=>	$title, 
			 'desc'		=>	$desc, 
			 'info'		=>	$url,
			 'station'	=>	$station,
			 'year'		=>	$year,
			 'director'	=>	$director
		 };
	}

	$self->{schedule}->{today}->{Z0}->{timestamp} = time();
	$self->{schedule}->{today}->{Z0}->{schedule} = [ @movies ];

	return 1;
}

=item $g->update_schedule( @s );

This method updates the schedules of the stations given in the arguments.

=cut
sub update_schedule
{
	my $self = shift;
	my @stations = @_;
	my $fout = 0;

	# call Update_Schedule_10 for 10 stations at a time
	for(my $first=0; $first<=$#stations; $first+=10)
	{
		my $last = __min($first+9,$#stations);
		my @these = @stations[$first..$last];

		$self->_debug("(update_schedule) --> getting @these");
		$fout = 1 unless ($self->_update_schedule_10(@these))
	}

	if ($fout != 0)
	{
		print "FOUT!\n";
		return undef;
	}
	$self->_write_cache();
	return 1;
}

=item $g->update_movies( @s );

This method updates the movie schedule, retaining only movies that are 
broadcast on stations given in the arguments.

=cut
sub update_movies
{
	my $self = shift;
	# read cache, if needed
	$self->_read_cache();

	# bail out if no need for updating
	if (exists($self->{schedule}->{today}->{Z0}) and 
		__is_today($self->{schedule}->{today}->{Z0}->{timestamp}) == 0 )
	{ 
		$self->_debug('Already cached: MOVIES');
		return 2;
	}

	my $url = 'http://gids.omroep.nl/core/content.php'.
		'?guide=Filmgids&medium=TV&dag=0&tijd=hele+dag';

	# get page
	$self->_debug("Getting URL `$url'");
	my $content = $self->_get_page($url);
	# We need to reset the cookie after getting the filmgids, because the
	# stupid omroep.nl guys keep server-side records of whether we are looking
	# at the film guide or the regular TV guide
	$self->{session_stamp} = 0;
	if (!$content) 
	{
		carp "Couldn't get url `$url'";
		return undef;
	}

	# parse page into schedule
	if (! $self->_parse_movies($content))
	{
		carp "Couldn't parse `$url'";
		return undef;
	}

	$self->_write_cache();

	return 1;
}
	
# Get today's schedule (max 10 stations)
sub _update_schedule_10
{
	my $self = shift;
	my @stations = $self->station_code(@_);

	if ($self->{DEBUG})
	{
		$self->_debug("(_update_schedule_10) --> found stations @stations");
	}

	$self->_read_cache();

	if (scalar(@stations) > 10) 
	{
		carp 'Warning: More than 10 stations not supported';
		carp "         Dropping ".(@stations-10)." station(s)";
		@stations = @stations[0..9]
	}
	
	# find out which schedules we need to get, and put the codes in @codes
	my @codes = ();
	foreach my $station (@stations)
	{
		if ($station eq 'Z0')
		{
			$self->update_movies();
			next;
		}
		
		# do we have today's schedule for this station in cache already?
		if (
			exists($self->{schedule}->{today}->{$station}) 
			and 
			__is_today($self->{schedule}->{today}->{$station}->{timestamp}) == 0
		   )
		{ 
			$self->_debug("Already cached: $station");
			next;
		}
		$self->_debug("Getting: $station");
		
		push @codes, $station;
	}
	
	# return if there's nothing more to fetch
	return 1 unless (@codes);

	# uniquify the codes
	@codes = __uniq $self->_sort_stations(@codes);

	# construct the url to get
	my $url = "http://gids.omroep.nl/core/content.php?Z=&".
			  "dag=0&tijd=hele+dag&genre=Alle+genres";
	foreach my $zender (@codes)
	{
		$url .= "&$zender=on";
	}
	
	# get page
	my $content = $self->_get_page($url);
	return undef unless ($content);
	
	# parse page into schedule
	if (! $self->_parse_schedule($content))
	{
		carp "Error while parsing content of $url\n";
		return undef;
	}

	return 1;
}

########################################################################
## function for showing the data to the end user
########################################################################

=item @p = $g->whats_on( @s )

returns an array containing the programs that are currently being shown on the
channels @s.

=cut
sub whats_on
{
	my $self = shift;
	return $self->_whats_on_generic(0,@_);
}

=item @p = $g->whats_next( @s )

returns an array containing the programs that will be shown next on the
channels @s.

=cut
sub whats_next
{
	my $self = shift;
	return $self->_whats_on_generic(1,@_);
}

# first argument is 0 for current program, 1 for next program, etc
# next arguments are tv stations to check
sub _whats_on_generic
{
	my $self = shift;
	my $number = shift;
	my @stations = @_;

	# hours and minutes
	my @now = (localtime())[2,1];
	if ($now[0]<6) { $now[0]+=24 }; # fix times after 0am

	# check if the stations are valid
	for my $i (0..$#stations)
	{
		if (not $self->is_valid_station($stations[$i]))
		{
			carp "No such station '$stations[$i]'";
			delete $stations[$i];
		}
	}

	# make sure the requested stations are cached
	$self->update_schedule(@stations);

	my @result;
	# iterate over the specified stations
	foreach my $station (@stations)
	{
		my $code = $self->station_code($station);

		# loop over the schedule until we find the program that starts next
		my $i;
		for ($i=0; $i<@{$self->{schedule}->{today}->{$code}->{schedule}}; $i++)
		{
			my $program = $self->{schedule}->{today}->{$code}->{schedule}->[$i];
			my @time = split ':', $program->{time}, 2;
			if ($time[0]<6) { $time[0]+=24 }; # fix times after 0am

			next if ( $time[0]<$now[0] or
				$time[0]==$now[0] and $time[1]<$now[1] );
			last;
		}
		# decrease by 1, because we want the current program 
		# instead of the next one
		$i += $number-1;

		push @result, $station.": ".
			$self->{schedule}->{today}->{$code}->{schedule}->[$i]->{time}." - ".
			$self->{schedule}->{today}->{$code}->{schedule}->[$i]->{title};
			
	}

	return @result;
	
}

=item $p = $g->whats_on_today( $s )

Returns an array containing the programs that are to be broadcast on the
stations $s for the remainder of the day.

=cut
sub whats_on_today
{
	my $self = shift;
	my $station = shift;

	my @now = localtime();

	my $code;
	# check if the stations are valid
	return undef unless ($self->is_valid_station($station));
	$code = $self->station_code($station);

	# make sure the requested stations are cached
	$self->update_schedule($station);

	# loop over the schedule until we find the program that starts next
	my $i;
	my $num = @{$self->{schedule}->{today}->{$code}->{schedule}} - 1;
	for ($i=0; $i<=$num; $i++)
	{
		my $program = $self->{schedule}->{today}->{$code}->{schedule}->[$i];
		my $nowtime = $now[2].':'.$now[1];
		next unless ( __comp_times($program->{time}, $nowtime) == 1);
		last;
	}
	# decrease by 1, because we want the current program instead of the next one
	$i-=1;

	return @{ $self->{schedule}->{today}->{$code}->{schedule} }[$i..$num];
}

=item @p = $g->movies_today( $showall, @s )

This functions returns an array of movies that are on TV on the stations @s
today.  If $showall is true, all movies are returned, if it is false, only
movies that have not ended yet are returned.

=cut
sub movies_today
{
	my $self = shift;
	my $showended = shift;
	my @stations = @_;

	my @now = localtime();

	# check if the stations are valid
	for(my $i=0; $i<@stations; $i++)
	{
		unless ($self->is_valid_station($stations[$i]))
		{
			carp "=> Unknown station `$stations[$i]'";
			delete $stations[$i];
		}
	}
	my @codes = $self->station_code(@stations);

	$self->_debug("(movies_today) ==> stations @codes\n");

	# make sure the movies are cached
	$self->update_movies;

	# loop over the schedule until we find the program that starts next
	my $i;
	my $num = @{$self->{schedule}->{today}->{Z0}->{schedule}} - 1;

	my @movies = ();
	my $nowtime = $now[2].':'.$now[1];
	for ($i=0; $i<=$num; $i++)
	{
		my $program = $self->{schedule}->{today}->{Z0}->{schedule}->[$i];

		# check the stop time of the program
		if (!$showended and __comp_times($program->{stop}, $nowtime) != 1)
		{
			$self->_debug('(movies_today) ==> ', $program->{title}, '...ended');
			next;
		}

		# check the station
		unless ( grep { $_ eq $program->{station} } @codes )
		{
			$self->_debug('(movies_today) ==> ', $program->{title}, 
					'...wrong station ', $program->{station});
			next;
		}

		push @movies, $program;
			$self->_debug('(movies_today) ==> ', $program->{title}, 'ok');
	}

	return @movies;
}

=item $t = $g->timestamp( $stat );

Returns the timestamp when the data for station $stat was last updated.

Returns undef if the station was invalid, 0 if the station was never updated.

=cut

sub timestamp
{
	my $self = shift;
	my $s = shift;
	
	my $c = $self->station_code( $s );

	return undef unless $c;
	return 0 unless exists $self->{schedule}->{today}->{$c};
	return $self->{schedule}->{today}->{$c}->{timestamp};
}


42;

__END__

=back

=head1 DATA STRUCTURES

If you don't like the ready-to-use functions for displaying the data, you can
also access the TV schedule directly.  For example:

    use TVGuide::NL;
    use Data::Dumper;
    $g = TVGuide::NL->new;
    $g->update_schedule('ned1','ned2','ned3','bbc1','bbc2');
    $g->update_movies();
    print Data::Dumper($g->{schedule}->{today});

The structure of the $g->{schedule} hash is quite straightforward:

    $p = $g->{schedule}->{today}->{Z1}->{schedule}->[0]

is the record of the first program that's on station 'Z1' today; Z1
corresponds to 'ned1'; you can find this out by looking at the
%TVGuide::NL::STATION_NAMES or %TVGuide::NL::CODE_LOOKUP hashes, or by 
calling %TVGuide::NL->station_name('Z1').  

Schedules for other days than `today' are not currently implemented.

The field of this record are as follows:

    $p->{time}    the time at which the program starts
    $p->{title}   the name of the show
    $p->{desc}    a short description of the program (see CAVEATS)
    $p->{info}    an url with more info (prepend `http://gids.omroep.nl/')
    $p->{omroep}  the broadcasting association 

The movies are in the table with stations code `Z0'.  These records are a bit
different and have somewhat more information:

    $p->{time}      start time of the movie
    $p->{stop}      end time of the movie
    $p->{title}     title of the movie
    $p->{station}   station code (Znn) at which the movie is broadcast
    $p->{desc}      synopsis of the movies 
    $p->{info}      url for more infomation
    $p->{director}  the director of the movie
    $p->{year}      the year in which the movie was first released

=head1 EXAMPLES

For some examples on how to use this library, see the example CGI 
scripts that are included in the distribution.

=head1 NOTES

This module has currently only been tested with Perl 5.8.4.  It might work
with Perl 5.6, but it probably won't work with earlier versions because of the
utf8-encoding issues.  If you can confirm that it does or does not work using
a specific pre-5.8 Perl version, please let me know.

=head1 CAVEATS

The descriptions of the programs is cut off after a (very limited) number of
chars.  This happens because the omroep.nl page simple doesn't show larger
descriptions on their main schedule pages.  It might be improved by parsing
the print-ready page instead (which is on my TODO list).

=head1 BUGS

Many, most probably.

=head1 AUTHOR

TVGuide::NL was written by Bas Zoetekouw in 2005.  Feel free to contact me at
bas@debian.org with any questions, suggestions or patches.

=head1 COPYRIGHT

Copyright © 2005 by Bas Zoetekouw <bas@debian.org>.  All rights reserved.

This program is free software; you may use it, (re)distribute it and/or modify
it under either the terms of version 2 of the GNU General Public License or
the terms of the Artistic License.

=cut

# vim:ft=perl:ts=4:sw=4:noexpandtab:fileencoding=utf-8

