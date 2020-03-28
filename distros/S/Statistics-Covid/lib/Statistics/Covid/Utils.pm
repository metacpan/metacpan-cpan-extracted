package Statistics::Covid::Utils;

# various stand-alone utils (static subs so-to-speak)

use 5.006;
use strict;
use warnings;

our $VERSION = '0.21';

use DateTime;
use DateTime::Format::Strptime;
use File::Path;
#use JSON qw/decode_json/;
use JSON::Parse qw/parse_json/;
use Try::Tiny;
use Data::Dump qw/dump pp/;
use File::Find;

# DBIx::Class specific sub to check if a table exists
# just tries to create a resultset based on this table
# which will fail if table does not exist (within the eval).
# the 1st param is a schema-obj (what you get when you do MyApp::Schema->connect($dsn))
# the 2nd is the table name (which accepts % wildcards)
# returns 1 if table exists in db,
#         0 if table does not exist in db
sub	table_exists_dbix_class {
	my ($schema, $tablename) = @_;
	return Statistics::Covid::Utils::table_exists_dbi($schema->storage->dbh, $tablename)
}
# DBI specific sub to check if a table exists
# just tries to create a resultset based on this table
# which will fail if table does not exist (within the eval).
# the 1st param is a DB handle (like the one you get from DBI->connect($dsn)
# the 2nd is the table name (which accepts % wildcards)
# returns 1 if table exists in db,
#         0 if table does not exist in db
# from https://www.perlmonks.org/bare/?node=DBI%20Recipes
sub	table_exists_dbi {
	my ($dbh, $tablename) = @_;
	my @tables = $dbh->tables('','','','TABLE');
	if (@tables) {
		for (@tables) {
			next unless $_;
			return 1 if $_ eq $tablename
		}
	} else {
		eval {
			local $dbh->{PrintError} = 0;
			local $dbh->{RaiseError} = 1;
			$dbh->do(qq{SELECT * FROM $tablename WHERE 1 = 0 });
		};
		return 1 unless $@;
	}
	return 0
}
# returns an arrayref of the files inside the input dir(s) specified
# by $indirs (which can be a scalar for a signle dir or an arrayref for one or more dirs)
# and further, matching the $pattern regex (if specified,
# else no check is made and all files are returned)
# $pattern can be left undefined or it can be a string containing a
# regex pattern, e.g. '\.json$' or can be a precompiled regex
# which apart from the added speed (possibly) offers the flexibility
# of using regex switches, e.g. qr/\.json$/i
sub	find_files {
	# an input dir to search in as a string
	# or one or more input dirs as a hashref
	# is the 1st input parameter:
	my @indirs = (ref($_[0]) eq 'ARRAY') ? @{$_[0]} : ($_[0]);

	# an optional regex pattern as the 2nd param:
	my $pattern = $_[1];

	my $qpattern = undef;
	if( defined $pattern ){
		if( ref($pattern) eq 'Regexp' ){ $qpattern = $pattern }
		else {
			$qpattern = qr/${pattern}/;
			if( ! defined $qpattern ){ warn "error, failed to compile regex '$pattern'."; return undef }
		}
	}

	my @filesfound;
	File::Find::find(defined $pattern ?
	# now this chdir, so -f $File::Find::name does not work!
	sub {
		push @filesfound, $File::Find::name
			if( (-f $_)
			 && ($File::Find::name =~ ${qpattern})
			)
	}
	: 
	sub {
		push @filesfound, $File::Find::name
			if (-f $_)
	}
	, @indirs
	); # and of File::Find::find
	return \@filesfound
}
sub	make_path {
	my $adir = $_[0];
	if( ! -d $adir ){
		if( ! File::Path::make_path($adir) ){
			warn "error, failed to create dir '$adir', $!";
			return 0
		}
	}
	return 1 # success
}
sub	configfile2perl {
	my $infile = $_[0];
	my $fh;
	if( ! open $fh, '<:encoding(UTF-8)', $infile ){ warn "error, failed to open file '$infile' for reading, $!"; return undef }
	my $json_contents = undef;
	{local $/ = undef; $json_contents = <$fh> } close($fh);
	my $inhash = Statistics::Covid::Utils::configstring2perl($json_contents);
	if( ! defined $inhash ){ warn "error, call to ".'Statistics::Covid::Utils::configstring2perl()'." has failed for file '$infile'."; return undef }
	return $inhash
}
sub	configstring2perl {
	my $json_contents = $_[0];
	# now remove comments
	$json_contents =~ s/#.*$//mg;
	my $inhash = Statistics::Covid::Utils::json2perl($json_contents);
	if( ! defined $inhash ){ warn $json_contents."\n\nerror, call to ".'Statistics::Covid::Utils::json2perl()'." has failed for above json string."; return undef }
	return $inhash
}
#sub json2perl { return JSON::decode_json($_[0]) }
sub json2perl { return JSON::Parse::parse_json($_[0]) }
sub	save_perl_var_to_localfile {
	my ($avar, $outfile) = @_;
	my $outfh;
	if( ! open $outfh, '>:encoding(UTF-8)', $outfile ){
		warn "error, failed to open file '$outfile' for writing json content, $!";
		return 0;
	}
	print $outfh Data::Dump::dump $avar;
	close $outfh;
	return 1;
}
sub	save_text_to_localfile {
	my ($text, $outfile) = @_;
	my $outfh;
	if( ! open $outfh, '>:encoding(UTF-8)', $outfile ){
		warn "error, failed to open file '$outfile' for writing text content, $!";
		return 0;
	}
	print $outfh $text;
	close $outfh;
	return 1;
}
# converts an ISO8601 date string to DateTime object
# which is something like:
#	 2020-03-21T22:47:56
# or 2020-03-21T22:47:56Z <<< timezone is UTC
sub iso8601_to_DateTime {
	my $datespec = $_[0];
	my $ret = undef;
	# check if we have timezone, else we add a UTC ('UTC' or 'Z')
	if( $datespec !~ m/(Z|[+-](?:2[0-3]|[01][0-9])(?::?(?:[0-5][0-9]))?)$/ ){ $datespec .= 'UTC' }
	try {
		my $parser = DateTime::Format::Strptime->new(
			# %Z covers both string timezone (e.g. 'UTC') and '+08:00'
			pattern => '%FT%T%Z',
			locale => 'en_GB',
			time_zone => 'UTC',
			on_error => sub { warn "error, failed to parse date: ".$_[1] }
		);
		if( ! defined $parser ){ warn "error, call to ".'DateTime::Format::Strptime->new()'." has failed."; return undef }
		$ret = $parser->parse_datetime($datespec);
	} catch {
		warn "error, failed to parse date '$datespec': $_";
		return undef
	};
	warn "error, call to ".'epoch_seconds_to_DateTime()'." has failed for spec '$datespec'." unless defined $ret;
	return $ret
}
# converts a time that data from the BBC contains (not their fault as they probably get it from the government)
# which is something like:
#   09:00 GMT, 25 March 
sub epoch_stupid_date_format_from_the_BBC_to_DateTime {
	my $datespec = $_[0];
	my $ret = undef;
	try {
		if( $datespec !~ /\:/ ){ 
			warn "date has no time, setting time to morning, 09:00 GMT";
			$datespec = '09:00 GMT, '.$datespec;
		}
		my $parser = DateTime::Format::Strptime->new(
			pattern => '%H:%M %Z, %d %b %Y', # hour:minute tz, day weekday (our addition: the year!)
			locale => 'en_GB',
			on_error => sub { warn "error, failed to parse date: ".$_[1] }
		);
		if( ! defined $parser ){ warn "error, call to ".'DateTime::Format::Strptime->new()'." has failed."; return undef }
		$ret = $parser->parse_datetime($datespec.' 2020'); # assuming it's the 2020! surely an optimist :(
		if( ! defined $ret ){ warn "error, call to ".'DateTime::Format::Strptime->parse_datetime()'." has failed for date spec: '$datespec'."; return undef }
	} catch {
		warn "error, failed to parse date '$datespec'";
		return undef
	};
	warn "error, call to ".'epoch_seconds_to_DateTime()'." has failed for spec '$datespec'." unless defined $ret;
	return $ret
}
# converts a time in MILLISECONDS since the Unix Epoch to a DateTime obj
sub epoch_milliseconds_to_DateTime {
	my $datespec = $_[0];
	$datespec = substr($datespec, 0,-3); # convert millis to seconds, remove last 3 chars
	my $ret = Statistics::Covid::Utils::epoch_seconds_to_DateTime($datespec);
	warn "error, call to ".'epoch_seconds_to_DateTime()'." has failed for spec '$datespec'." unless defined $ret;
	return $ret
}
# converts a time epoch in SECONDS since the Unix Epoch to a DateTime obj
sub epoch_seconds_to_DateTime {
	my $datespec = $_[0];

	my $ret = undef;
	try {
		$ret = DateTime->from_epoch(
			epoch => $datespec,
			locale => 'en_GB',
			time_zone => 'Europe/London'
		);
	} catch {
		warn "error, call to ".'DateTime->from_epoch()'." has failed for input epoch '$datespec': $_";
		return undef
	};
	return $ret
}
sub	objects_equal { return Statistics::Covid::IO::DualBase::objects_equal(@_) }
sub	dbixrow2string {
	my %rowhash = @_; # get_columns() returns this hash
	my $ret = "";
	$ret .= $_ . '=>' . $rowhash{$_} . "\n" for sort { $a cmp $b } keys %rowhash;
	return $ret;
}
# create a string timestamp of current (now)
# date and time as a string, to be used in creating filenames for example.
# it takes an optional timezone parameter ($tz) which L<DateTime> must understand
# or do not specify one for using the default, at your local system
sub	make_timestamped_string {
	my $tz = $_[0];
	my %dtparams = ();
	$dtparams{time_zone} = $tz if defined $tz;
	my $dt = DateTime->now(%dtparams);
	if( ! defined $dt ){ warn pp(\%dtparams)."\nerror, call to DateTime->now() has failed for the above params."; return undef }
	return $dt->ymd('-') . '_' . $dt->hms('.')
}
# this will take an array of Datum objects and a set of one or more
# (table) column names (attributes of each object), e.g. 'confirmed'
# and will create a hash, where keys are column names
# and values are arrays of the values for that column name for each object
# in the order they appear in the input array.
sub	datums2dataframe {
	my $objs = $_[0];
	my @groupby = defined($_[1]) ? @{$_[1]} : ();
	my @column_names = @{$_[2]};

	if( ! defined($objs) || (scalar(@$objs)==0) ){ warn "warning, no datum objects supplied."; return undef }
	# make sure that all column_names exist
	my $anobj = $objs->[0];
	my ($acn, $agn, $agv, $m);
	foreach $acn (@column_names){ if( ! $anobj->column_name_is_valid($acn) ){ warn "error, column name '$acn' does not exist."; return undef } }
	foreach $agn (@groupby){ if( ! $anobj->column_name_is_valid($agn) ){ warn "error, group-by columns name '$agn' does not exist."; return undef } }

	my %ret;
	for $anobj (@$objs){
		$agv = "";
		for $agn (@groupby){
			$agv .= $anobj->column_value($agn).'|';
		} $agv =~ s/\|$//;
		if( ! exists $ret{$agv} ){
			$ret{$agv} = $m = {};
			for $acn (@column_names){ $m->{$acn} = [] }
		} else { $m = $ret{$agv} }
		for $acn (@column_names){
			push @{$m->{$acn}}, $anobj->column_value($acn)
		}
	}
	return \%ret
}
1;
__END__
# end program, below is the POD
