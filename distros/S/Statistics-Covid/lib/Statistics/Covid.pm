package Statistics::Covid;
use lib 'blib/lib';

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

use Statistics::Covid::Utils;
use Statistics::Covid::Datum;
use Statistics::Covid::Datum::IO;
use Statistics::Covid::Version;
use Statistics::Covid::Version::IO;

use Storable qw/dclone/;

use Data::Dump qw/pp/;

sub	new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $self = {
		'save-to-file' => 1,
		'save-to-db' => 1,
		'debug' => 0,
		# internal variables,
		'p' => {
			'provider-objs' => undef,
			'config-hash' => undef,
			'datum-io' => undef,
			'db-version' => undef,
		},
	};
	bless $self => $class;

	if( exists $params->{'debug'} ){ $self->debug($params->{'debug'}) }
	my $debug = $self->debug();
	if( exists $params->{'save-to-file'} ){ $self->save_to_file($params->{'save-to-file'}) }
	if( exists $params->{'save-to-db'} ){ $self->save_to_db($params->{'save-to-db'}) }

	my $m;
	my $config_hash = undef;
	if( exists($params->{'config-file'}) && defined($m=$params->{'config-file'}) ){
		$config_hash = Statistics::Covid::Utils::configfile2perl($m);
		if( ! defined $config_hash ){ warn "error, failed to read config file '$m'."; return undef }
	} elsif( exists($params->{'config-string'}) && defined($m=$params->{'config-string'}) ){
		$config_hash = Statistics::Covid::Utils::configstring2perl($m);
		if( ! defined $config_hash ){ warn "error, failed to parse config string '$m'."; return undef }
	} elsif( exists($params->{'config-hash'}) && defined($m=$params->{'config-hash'}) ){ $config_hash = Storable::dclone($m) }
	else { warn "error, configuration was not specified using one of 'config-file', 'config-string', 'config-hash'. For an example configuration file see t/example-config.t."; return undef }
	$self->config($config_hash);

	if( exists($params->{'providers'}) && defined($m=$params->{'providers'}) ){
		if( ! $self->providers($m) ){ warn "error, failed to install specified provider(s) (calling providers()) : '".join("','", @$m)."'."; return undef }
	} else {
		if( $debug > 0 ){ warn "warning, 'providers' (like 'UK::GOVUK' and/or 'World::JHU') was not specified, that's ok, but you must insert some before fetching any data - interacting with db will be ok." }
	}

	for(keys %$params){
		$self->{$_} = $params->{$_} if exists $self->{$_}
	}
	if( ! defined($self->{'p'}->{'datum-io'}=$self->_create_Datum_IO()) ){ warn "error, failed to create IO object."; return undef }

	if( ! defined $self->version() ){ warn "error, failed to get the db-version."; return undef }
	if( $debug > 0 ){ warn "db-version: ".$self->version() }

	return $self
}
sub	DESTROY {
	# disconnect just in case, usually this is not required
	my $self = $_[0];
	if( defined $self->{'p'}->{'datum-io'} ){
		$self->{'p'}->{'datum-io'}->db_disconnect();
		$self->{'p'}->{'datum-io'} = undef;
	}
}
# fetch data from the providers and optionally save to file and/or db
# returns undef on failure
# returns the items fetched (that's datum objects) as an arrayref (which can also be empty)
sub	fetch_and_store {
	my $self = $_[0];

	my @retObjs = (); # we are returning the objects we just fetched
	my $debug = $self->debug();
	my $num_fetched_total = 0;
	my $providers = $self->providers();
	if( ! defined $providers ){ warn "error, data providers must be inserted prior to using this, e.g. providers('World::JHU')."; return undef }
	for my $pn (keys %$providers){
		my $providerObj = $providers->{$pn};
		my $datas = $providerObj->fetch();
		if( ! defined $datas ){ warn "$pn : error, failed to fetch()."; return undef }
		if( $debug > 0 ){ warn "$pn : fetched latest data OK." }
		if( $self->save_to_file() ){
			my $outbase = $providerObj->save_fetched_data_to_localfile($datas);
			if( ! defined($outbase) ){ warn "error, failed to save the data just fetched to local file."; return undef }
			if( $debug > 0 ){ warn "$pn : fetched data saved to local file, with this basename '$outbase'." }
		}
		my $objs = $providerObj->create_Datums_from_fetched_data($datas);
		if( ! defined $objs ){ warn "$pn : error, failed to processed fetched data and create Datum objects."; return undef }
		push @retObjs, @$objs;
		my $num_fetched = scalar @$objs;
		$num_fetched_total += $num_fetched;
		if( $debug > 0 ){ warn "$pn : fetched $num_fetched objects." }
		if( $self->save_to_db() ){
			my $io = $self->{'p'}->{'datum-io'};
			my $rows_in_db_before = $io->db_count();
			my $ret = $io->db_insert_bulk($objs);
			my $rows_in_db_after = $io->db_count();
			if( $debug > 0 ){ print STDOUT _db_insert_bulk_toString($ret, $rows_in_db_before, $rows_in_db_after) }
			if( $ret->{'num-failed'} > 0 ){ warn "$pn : error, there were failed inserts into DB." }
			my $dbfilename = $io->db_filename();
			if( $dbfilename ne '' ){ print STDOUT "$pn : fetch_and_store() : saved data to database in '$dbfilename'.\n" }
		}
	}
	if( $debug > 0 ){ warn "fetched $num_fetched_total objects in total and from all providers: '".join("','",sort keys %$providers)."'." }
	# returns an arrayref of all the Datums JUST fetched (after being converted from raw data to objects)
	return \@retObjs
}
# a shortcut to saving an arrayref of Datum Objects to our db
# returns a hashref of statistics on what happened with the insert
# see L<Statistics::Covid::IO::Base::db_insert_bulk>() for details
# returns undef on failure
sub	db_datums_insert_bulk { return $_[0]->{'p'}->{'datum-io'}->db_insert_bulk($_[1]) }
# a shortcut to gettting the count of the Datum table,
# returns -1 on failure
sub	db_datums_count { return $_[0]->{'p'}->{'datum-io'}->db_count() }

# load datums from DB into our own internal storage (appending to whatever we already may have stored)
# use clear() to empty thats storage.
# input params are exactly what Statistics::Covid::IO::Base::db_select($params) takes
# optional: 'conditions', 'attributes', 'debug'
# 'conditions' is a DBIx::Class condition, a DBIx::Class::ResultSet->search() takes
# returns undef on failure
# returns the loaded datum objs on success (can be empty) as a hashref
sub	select_datums_from_db {
	my ($self, $params) = @_;

	my $objs = $self->{'p'}->{'datum-io'}->db_select($params);
	if( ! defined $objs ){ warn pp($params)."\n\nerror, failed to load Datum objects from DB using above parameters."; return -1 }
	return $objs
}
# shortcut to selecting datum objects from db (select_datums_from_db())
# from a single location and ordering the results in time-ascending order.
# it's useful for getting the timeline for a given place
# if successful, it returns an array of Datum objects (sorted on time)
# it returns undef on failure
sub	select_datums_from_db_for_specific_location_time_ascending {
	my $self = $_[0];
	# this can be an exact location name (case sensitive)
	# OR it can be this {'like' => 'Ha%'}
	# which does a wildcard search
	my $location_condition = $_[1];
	#optionally specify a 'belongsto' (e.g. UK)
	# either exact or wildcard, like above
	my $belongsto_condition = $_[2];

	my $conditions = {'name'=>$location_condition};
	$conditions->{'belongsto'} = $belongsto_condition if defined $belongsto_condition;

	my $results = $self->select_datums_from_db({
		'conditions' => $conditions,
		'attributes' => {
			'order_by' => {'-asc' => 'datetimeUnixEpoch'}
		},
	});
	if( ! defined $results ){ warn "error, call to ".'select_datums_from_db()'." has failed."; return undef }
	return $results
}
# read data from data file (original data as fetched by the scrapper)
# given at least a provider string in the input params hash
#         as $params->{'provider'} = 'XYZ'
# in which case all data found in XYZ's datafilesdir will be read
# Now, the files to read will be specified in the
#            $params->{'basename'} = 'ABC' | ['ABC', '123', ...]
# which again can be a scalar if it's a single basename
# or an arrayref for one or more.
# All the basenames will apply to the provider specified.
# Each basename will be used to construct the exact data-file name(s)
# for the specified provider.
# The specified provider string id must correspond to a provider object
# already created and loaded during construction via the 'providers' param
# returns undef on failure
# returns an array of L<Statistics::Covid::Datum> Objects on success
sub	read_data_from_file {
	my $self = $_[0];
	my $params = $_[1];

	my $debug = $self->debug();

	my $providerstr;
	if( ! exists($params->{'provider'}) || ! defined($providerstr=$params->{'provider'}) ){ warn "error, 'provider' was not specified."; return undef }
	my $providerObj = $self->providers($providerstr);
	if( ! defined $providerObj ){ warn "provider does not exist in my list, you may need to load it if indeed the name is correct: '$providerstr'."; return undef }

	# optional list of basenames of data
	# if this is missing then all files in the datafilesdir() of the provider specified
	# will be loaded
	my (@basenames, $m);
	if( exists($params->{'basename'}) && defined($m=$params->{'basename'}) ){
		# basename was specified, we expect an arrayref of basenames or a single basename
		my $r = ref($m);
		if( $r eq '' ){ @basenames = ($m) }
		elsif( $r eq 'ARRAY' ){ @basenames = @{$m} }
		else { warn "error, expected scalar string or arrayref for input 'basename' but got ".$r; return undef }
	} else {
		# no basenames specified, find them
		my $datadir = $providerObj->datafilesdir();
		# TODO : remove this check when stable
		if( ! defined($datadir) ){ die "something wrong here, datafilesdir() is not specified for provider '$providerstr'." }
		my $jsonfiles = Statistics::Covid::Utils::find_files($datadir, qr/\.json$/i);
		@basenames = map { s/\.((data)|(meta))\.json$//; $_ } @$jsonfiles;
	}
	if( scalar(@basenames) == 0 ){
		warn "no files were found or specified for provider '$$providerstr'.";
		return () # not a failure
	}
	my @ret;
	for my $abasename (@basenames){
		my $datas = $providerObj->load_fetched_data_from_localfile($abasename);
		if( ! defined $datas ){ warn "error, call to ".'load_fetched_data_from_localfile()'." has failed for provider '$providerstr' and data-file basename '$abasename'."; return undef }
		# convert datas to datums
		my $datumObjs = $providerObj->create_Datums_from_fetched_data($datas);
		if( $debug > 0 ){ warn "read ".scalar(@$datumObjs)." items from basename '$abasename'.\n"; }
		if( ! defined $datumObjs ){ warn "error, call to ".'create_Datums_from_fetched_data()'." has failed for provider '$providerstr' and data-file basename '$abasename'."; return undef }
		push @ret, @$datumObjs
	}
	if( $debug > 0 ){ warn "read ".scalar(@ret)." items in total for provider '$providerstr'." }
	return \@ret # success
}
# read data from data files given
# an input hashref of $params->{'what'}={providerID => [list-of-basenames]}
# returns a hashref {providerID => $datumObjs}
# or undef on failure, for more information see L<read_data_from_file()>
sub	read_data_from_files {
	my $self = $_[0];
	my $params = $_[1];
	my $inp;

	my @providerstrs;
	if( ! exists($params->{'what'}) || ! defined($params->{'what'}) ){
		# nothing was provided in the input, we use ALL our providers loaded during construction
		my $m = $self->providers();
		if( ! defined $m ){ warn "error, data providers must be inserted prior to using this, e.g. providers('World::JHU')."; return undef }
		@providerstrs = keys %$m;
	} else {
		# something was given at input
		$inp = $params->{'what'};
		if( ref($inp) eq 'HASH' ){
			# this is a hash of {providerID => [list-of-basenames]}
			my %ret;
			for my $aproviderstr (sort keys %$inp){
				my $da = $self->read_data_from_file({
					'basename' => $inp->{$aproviderstr}
				});
				if( ! defined $da ){ warn "error, call to read_data_from_file() has failed for provider '$aproviderstr'."; return undef }
				$ret{$aproviderstr} = $da;
			}
			return \%ret
		} elsif( ref($inp) eq 'ARRAY' ){
			# this is an array of provider strings,
			# all files from the data dir of this provider will be loaded
			@providerstrs = @$inp;
		} elsif( ref($inp) eq '' ){
			# this is just a lone provider string
			@providerstrs = ($inp);
		}
	}
	# Here we have a list of providerstrs only
	# So, we will let read_data_from_file() find data files in our datafilesdir()
	my %ret;
	foreach my $aproviderstr (@providerstrs){
		my $da = $self->read_data_from_file({
			'provider' => $aproviderstr
		});
		if( ! defined($da) ){ warn "error, call to read_data_from_file() has failed for the provider '$aproviderstr'."; return undef }
		$ret{$aproviderstr} = $da;
	}
	return \%ret
}
# read the Version table from DB which holds the db-version which is useful
# for migrating to newer db-versions when upgrades happen.
# ideally each upgrade should have a migration script for migrating from
# old version to newer.
# read db-version from DB and cache the result (and also return it)
# if $force==1 then it discards the cached version and re-connects to DB
# returns the version as a string or undef on failure
sub	version {
	my $self = $_[0];
	my $force = defined $_[1] ? $_[1] : 0;
	if( $force==0 && defined($self->{'db-version'}) ){ return $self->{'db-version'} }

	my $vio = $self->_create_Version_IO();
	if( ! defined $vio ){ warn "error, call to _create_Version_IO() has failed."; return undef }
	if( ! defined $vio->db_connect() ){ warn "error, failed to connect to DB, call to ".'db_connect()'." has failed."; return undef }
	my $versionobj = $vio->db_select();
	if( defined($versionobj) && (scalar(@$versionobj)==1) ){
		$self->{'db-version'} = $versionobj->[0]->version(); return $self->{'db-version'}
	}
	if( scalar @$versionobj >1 ){ warn "error, why there are more than 1 rows for table Version? (got ".@$versionobj." rows)."; return undef }

	# no version row, create one
	$versionobj = Statistics::Covid::Version->new();
	if( ! defined $versionobj ){ warn "error, call to ".'Statistics::Covid::Version->new()'." has failed."; return undef }
	$self->{'db-version'} = $versionobj->version();
	# and save the version to db;
	if( 1 != $vio->db_insert($versionobj) ){ warn "error, db_insert() failed for version."; return undef }
	return $versionobj->version();
}
# returns the number of rows in the Datum table in the database
# with optional conditions (WHERE clauses) in the $params
# conditions follow the convention of L<DBIx::Class::ResultSet>
# here is an example:
# e.g. $params = {'conditions' => { 'name' => 'Hackney' } }
# it returns -1 on failure
# it returns the count (can be zero or positive) on success
sub	db_count_datums {
	my $self = $_[0];
	my $params = defined($_[1]) ? $_[1] : undef;
	my $count = $self->{'p'}->{'datum-io'}->db_count($params);
	if( $count < 0 ){ warn "error, call to db_count() has failed for the above parameters."; return -1 }
	return $count
}
sub	db_merge {
	my $self = $_[0];
	my $another_db = $_[1];

	die "not yet implemented"
}

# returns 0 on failure,
#        -1 on nothing to do
#         1 on success
sub	migrate {
	my $self = $_[0];

	my $dbversion = $self->version();
	if( $self->version() eq $VERSION ){ warn "migrate(): nothing to do"; return -1 }

	my $migrator = Statistics::Covid::Migrator->new({
		'config-hash' => $self->config(),
		'version-from' => $dbversion,
		'version-to' => $VERSION,
	});
	if( ! defined $migrator ){ warn "error, call to ".'Statistics::Covid::Migrator->new()'." has failed."; return 0 }
	return $migrator->migrate()
}
sub	db_backup {
	my $self = $_[0];
	# optional output file, or default
	my $outfile = $_[1]; # if undef then a timestamped filename will be created in current dir (not in db dir)
	return $self->{'p'}->{'datum-io'}->db_create_backup_file($outfile)
}
# getter/setter subs
sub     debug {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'debug'} = $m; return $m }
	return $self->{'debug'}
}
sub     dbparams { return $_[0]->config()->{'dbparams'} }
# returns the hashref of providers (id=>obj) if no input
# provider string id is provided
# else checks to see if a provider can be matched from our list
# and if it does, it returns the provider obj
# if not found returns undef (so undef can happen only
# if a provider id is specified at input)
sub	providers {
	my $self = $_[0];
	my $m = $_[1];

	if( ! defined $m ){ return $self->{'p'}->{'provider-objs'} }

	if( ref($m) eq '' ){
		# we were given a string to search for that provider and return its data
		# return the exact provider if the pstr matches an id from our providers
		return($self->{'p'}->{'provider-objs'}->{$m})
			if exists($self->{'p'}->{'provider-objs'}->{$m});
		return undef # id given is not in our list
	} elsif( ref($m) eq 'ARRAY' ){
		my $debug = $self->debug();
		# we were given an arrayref, presumably a list of providers
		# we need to find the package of each provider and load it,
		# that's why the contents of this array plus the package string below
		# must much exactly our installed provider packages
		my %providers = ();
		for my $aprovider (@$m){
			my $pn = 'Statistics::Covid::DataProvider::'.$aprovider;
			my $pnf = File::Spec->catdir(split(/\:\:/, $pn)).'.pm';
			my $loadedOK = eval {
				require $pnf;
				$pn->import;
				1;
			};
			if( ! $loadedOK ){ warn "error, failed to load module '$pn' (file '$pnf'), most likely provider does not exist '$pn'."; return undef }
			my $providerObj = $pn->new({
				'config-hash' => Storable::dclone($self->config()),
				'debug' => $debug
			});
			if( ! defined $providerObj ){ warn "error, call to $pn->new() has failed."; return undef }
			# the key to the providers can be the full package or just this bit
			# we prefer this bit (e.g. World::JHU)
			#$providers{$pn} = $providerObj;
			$providers{$aprovider} = $providerObj;
			if( $debug > 0 ){ warn "provider added '$pn':\n".$providerObj->toString() }
		}
		$self->{'p'}->{'provider-objs'} = \%providers;
	}
	return $self->{'p'}->{'provider-objs'} # that's the hash with the providers
}
sub     config {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'p'}->{'config-hash'} = $m; return $m }
	return $self->{'p'}->{'config-hash'}
}
sub     save_to_file {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'save-to-file'} = $m; return $m }
	return $self->{'save-to-file'}
}
sub     save_to_db {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'save-to-db'} = $m; return $m }
	return $self->{'save-to-db'}
}
# private subs
sub	_create_Datum_IO {
	my $self = $_[0];
	my $params = defined($_[1]) ? $_[1] : {}; # optional params
	my $io = Statistics::Covid::Datum::IO->new({
		'config-hash' => $self->config(),
		'debug' => $self->debug(),
		%$params
	});
	if( ! defined $io ){ warn "error, call to ".'Statistics::Covid::Datum::IO->new()'." has failed."; return undef }
	if( ! defined $io->db_connect() ){ warn "error, failed to connect to DB, call to ".'db_connect()'." has failed."; return undef }
	if( ! $io->db_is_connected() ){ warn "error, not connected to DB when it should be"; return undef }
	return $io;
}
sub	_create_Version_IO {
	my $self = $_[0];
	my $params = defined($_[1]) ? $_[1] : {}; # optional params
	my $io = Statistics::Covid::Version::IO->new({
		'config-hash' => $self->config(),
		'debug' => $self->debug(),
		%$params
	});
	if( ! defined $io ){ warn "error, call to ".'Statistics::Covid::Datum::IO->new()'." has failed."; return undef }
	if( ! defined $io->db_connect() ){ warn "error, failed to connect to DB, call to ".'db_connect()'." has failed."; return undef }
	if( ! $io->db_is_connected() ){ warn "error, not connected to DB when it should be"; return undef }
	return $io;
}
sub	_db_insert_bulk_toString {
	# $inhash is a hashref of what was inserted in db, what was replaced, what was omitted because identical
	my ($inhash, $rows_before, $rows_after) = @_; 
	my $ret =
  "attempted a DB insert for ".$inhash->{'num-total-records'}." records in total, on ".DateTime->now(time_zone=>'UTC')->iso8601()." UTC:\n"
. "new records inserted                           : ".$inhash->{'num-virgin'}."\n"
. "  records outdated replaced                    : ".$inhash->{'num-replaced'}."\n"
. "  records not replaced because better exists   : ".$inhash->{'num-not-replaced-because-better-exists'}."\n"
. "  records not replaced because of no overwrite : ".$inhash->{'num-not-replaced-because-ignore-was-set'}."\n"
. "  records in DB before                         : ".$rows_before."\n"
. "  records in DB after                          : ".$rows_after."\n"
	;
	if( $inhash->{'num-failed'} > 0 ){ $ret .= "  records FAILED            : ".$inhash->{'num-failed'}."\n" }
	return $ret
}
1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8

=head1 NAME

Statistics::Covid - Fetch, store in DB, retrieve and analyse Covid-19 statistics from data providers

=head1 VERSION

Version 0.23

=head1 DESCRIPTION

This module fetches, stores in a database, retrieves from a database and analyses
Covid-19 statistics from online or offline data providers, such as
from L<the John Hopkins University|https://www.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6>
which I hope I am not obstructing (please send an email to the author if that is the case).

After specifying one or more data providers (as a url and a header for data and
optionally for metadata), this module will attempt to fetch the latest data
and store it in a database (SQLite and MySQL, only SQLite was tested so far).
Each batch of data should ideally contain information about one or more locations
and at a given point in time. All items in this batch are extracted and stored
in DB each with its location name and time (it was published, not fetched) as primary keys.
Each such data item (Datum) is described in L<Statistics::Covid::Datum::Table>
and the relevant class is L<Statistics::Covid::Datum>. It contains
fields such as: C<population>, C<confirmed>, C<unconfirmed>, C<terminal>, C<recovered>.

Focus was on creating very high-level which distances as much as possible
the user from the nitty-gritty details of fetching data using L<LWP::UserAgent>
and dealing with the database using L<DBI> and L<DBIx::Class>.

This is an early release until the functionality and the table schemata
solidify.

=head1 SYNOPSIS

	use Statistics::Covid;
	use Statistics::Covid::Datum;
	
	$covid = Statistics::Covid->new({   
		'config-file' => 't/config-for-t.json',
		'providers' => ['UK::BBC', 'UK::GOVUK', 'World::JHU'],
		'save-to-file' => 1,
		'save-to-db' => 1,
		'debug' => 2,
	}) or die "Statistics::Covid->new() failed";
	# fetch all the data available (posibly json), process it,
	# create Datum objects, store it in DB and return an array 
	# of the Datum objects just fetched  (and not what is already in DB).
	my $newobjs = $covid->fetch_and_store();
	
	print $_->toString() for (@$newobjs);
	
	print "Confirmed cases for ".$_->name()
		." on ".$_->date()
		." are: ".$_->confirmed()
		."\n"
	for (@$newobjs);
	
	my $someObjs = $covid->select_datums_from_db({
		'conditions' => {
			belongsto=>'UK',
			name=>'Hackney'
		}
	});
	
	print "Confirmed cases for ".$_->name()
		." on ".$_->date()
		." are: ".$_->confirmed()
		."\n"
	for (@$someObjs);
	
	# or for a single place (this sub sorts results wrt publication time)
	my $timelineObjs = $covid->select_datums_from_db_for_specific_location_time_ascending('Hackney');
	# or for a wildcard match
	# $covid->select_datums_from_db_for_specific_location_time_ascending({'like'=>'Hack%'});
	# and maybe specifying max rows
	# $covid->select_datums_from_db_for_specific_location_time_ascending({'like'=>'Hack%'}, {'rows'=>10});
	for my $anobj (@$timelineObjs){
		print $anobj->toString()."\n";
	}

	print "datum rows in DB: ".$covid->db_count_datums()."\n"

	use Statistics::Covid;
	use Statistics::Covid::Datum;
	use Statistics::Covid::Utils;
	use Statistics::Covid::Analysis::Plot::Simple;

	# now read some data from DB and do things with it
	$covid = Statistics::Covid->new({   
		'config-file' => 't/config-for-t.json',
		'debug' => 2,
	}) or die "Statistics::Covid->new() failed";
	# retrieve data from DB for selected locations (in the UK)
	# data will come out as an array of Datum objects sorted wrt time
	# (the 'datetimeUnixEpoch' field)
	$objs = $covid->select_datums_from_db_for_specific_location_time_ascending(
		#{'like' => 'Ha%'}, # the location (wildcard)
		['Halton', 'Havering'],
		#{'like' => 'Halton'}, # the location (wildcard)
		#{'like' => 'Havering'}, # the location (wildcard)
		'UK', # the belongsto (could have been wildcarded)
	);
	# create a dataframe
	$df = Statistics::Covid::Utils::datums2dataframe({
		'datum-objs' => $objs,
		# collect data from all those with same 'name' and same 'belongsto'
		# and maybe plot this data as a single curve (or fit or whatever)
		'groupby' => ['name','belongsto'],
		# put only these values of the datum object into the dataframe
		# one of them will be X, another will be Y
		# if you want to plot multiple Y, then add here more dependent columns
		# like ('unconfirmed').
		'content' => ['confirmed', 'unconfirmed', 'datetimeUnixEpoch'],
	});

	# plot confirmed vs time
	$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
		'dataframe' => $df,
		# saves to this file:
		'outfile' => 'confirmed-over-time.png',
		# plot this column against X
		# (which is not present and default is time ('datetimeUnixEpoch')
		'Y' => 'confirmed',
	});

	# plot confirmed vs unconfirmed
	# if you see a vertical line it means that your data has no 'unconfirmed'
	$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
		'dataframe' => $df,
		# saves to this file:
		'outfile' => 'confirmed-vs-unconfirmed.png',
		'X' => 'unconfirmed',
		# plot this column against X
		'Y' => 'confirmed',
	});

	# plot using an array of datum objects as they came
	# out of the DB. A dataframe is created internally to the plot()
	# but this is not recommended if you are going to make several
	# plots because equally many dataframes must be created and destroyed
	# internally instead of recycling them like we do here...
	$ret = Statistics::Covid::Analysis::Plot::Simple::plot({
		'datum-objs' => $objs,
		# saves to this file:
		'outfile' => 'confirmed-over-time.png',
		# plot this column as Y
		'Y' => 'confirmed', 
		# X is not present so default is time ('datetimeUnixEpoch')
		# and make several plots, each group must have 'name' common
		'GroupBy' => ['name', 'belongsto'],
		'date-format-x' => {
			# see Chart::Clicker::Axis::DateTime for all the options:
			format => '%m', ##<<< specify timeformat for X axis, only months
			position => 'bottom',
			orientation => 'horizontal'
		},
	});

	use Statistics::Covid;
	use Statistics::Covid::Datum;
	use Statistics::Covid::Utils;
	use Statistics::Covid::Analysis::Model::Simple;

	# create a dataframe
	my $df = Statistics::Covid::Utils::datums2dataframe({
		'datum-objs' => $objs,
		'groupby' => ['name'],
		'content' => ['confirmed', 'datetimeUnixEpoch'],
	});
	# convert all 'datetimeUnixEpoch' data to hours, the oldest will be hour 0
	for(sort keys %$df){
		Statistics::Covid::Utils::discretise_increasing_sequence_of_seconds(
			$df->{$_}->{'datetimeUnixEpoch'}, # in-place modification
			3600 # seconds->hours
		)
	}

	# do an exponential fit
	my $ret = Statistics::Covid::Analysis::Model::Simple::fit({
		'dataframe' => $df,
		'X' => 'datetimeUnixEpoch', # our X is this field from the dataframe
		'Y' => 'confirmed', # our Y is this field
		'initial-guess' => {'c1'=>1, 'c2'=>1}, # initial values guess
		'exponential-fit' => 1,
		'fit-params' => {
			'maximum_iterations' => 100000
		}
	});

	# fit to a polynomial of degree 10 (max power of x is 10)
	my $ret = Statistics::Covid::Analysis::Model::Simple::fit({
		'dataframe' => $df,
		'X' => 'datetimeUnixEpoch', # our X is this field from the dataframe
		'Y' => 'confirmed', # our Y is this field
		# initial values guess (here ONLY for some coefficients)
		'initial-guess' => {'c1'=>1, 'c2'=>1},
		'polynomial-fit' => 10, # max power of x is 10
		'fit-params' => {
			'maximum_iterations' => 100000
		}
	});

	# fit to an ad-hoc formula in 'x'
	# (see L<Math::Symbolic::Operator> for supported operators)
	my $ret = Statistics::Covid::Analysis::Model::Simple::fit({
		'dataframe' => $df,
		'X' => 'datetimeUnixEpoch', # our X is this field from the dataframe
		'Y' => 'confirmed', # our Y is this field
		# initial values guess (here ONLY for some coefficients)
		'initial-guess' => {'c1'=>1, 'c2'=>1},
		'formula' => 'c1*sin(x) + c2*cos(x)',
		'fit-params' => {
			'maximum_iterations' => 100000
		}
	});

	# this is what fit() returns

	# $ret is a hashref where key=group-name, and
	# value=[ 3.4,  # <<<< mean squared error of the fit
	#  [
	#     ['c1', 0.123, 0.0005], # <<< coefficient c1=0.123, accuracy 0.00005 (ignore that)
	#     ['c2', 1.444, 0.0005]  # <<< coefficient c1=1.444
	#  ]
	# and group-name in our example refers to each of the locations selected from DB
	# in this case data from 'Halton' in 'UK' was fitted on 0.123*1.444^time with an m.s.e=3.4

	# This is what the dataframe looks like:
	#  {
	#  Halton   => {
	#		confirmed => [0, 0, 3, 4, 4, 5, 7, 7, 7, 8, 8, 8],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  Havering => {
	#		confirmed => [5, 5, 7, 7, 14, 19, 30, 35, 39, 44, 47, 70],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  }

	# and after converting the datetimeUnixEpoch values to hours and setting the oldest to t=0
	#  {
	#  Halton   => {
	#                confirmed => [0, 0, 3, 4, 4, 5, 7, 7, 7, 8, 8, 8],
	#                datetimeUnixEpoch => [0, 24, 48, 72, 104, 120, 144, 168, 192, 216, 240, 264],
	#              },
	#  Havering => {
	#                confirmed => [5, 5, 7, 7, 14, 19, 30, 35, 39, 44, 47, 70],
	#                datetimeUnixEpoch => [0, 24, 48, 72, 104, 120, 144, 168, 192, 216, 240, 264],
	#              },
	#  }



	use Statistics::Covid::Analysis::Plot::Simple;

	# plot something
	my $objs = $io->db_select({
		conditions => {belongsto=>'UK', name=>{'like' => 'Ha%'}}
	});
	my $outfile = 'chartclicker.png';
	my $ret = Statistics::Covid::Analysis::Plot::Simple::plot({
        	'datum-objs' => $objs,
		# saves to this file:
	        'outfile' => $outfile,
		# plot this column (x-axis is time always)
        	'Y' => 'confirmed', 
		# and make several plots, each group must have 'name' common
	        'GroupBy' => ['name']
	});
	

=head1 EXAMPLE SCRIPT

C<script/statistics-covid-fetch-data-and-store.pl> is
a script which accompanies this distribution. It can be
used to fetch any data from specified providers using a
specified configuration file.

For a quick start:

    cp t/config-for-t.json config.json
    # optionally modify config.json to change the destination data dirs
    # now fetch data from some default data providers:
    script/statistics-covid-fetch-data-and-store.pl --config-file config.json

The above will fetch the latest data and insert it into an SQLite
database in C<data/db/covid19.sqlite> directory.
When this script is called again, it will fetch the data again
and will be saved into a file timestamped with publication date.
So, if data was already fetched it will be simply overwritten by
this same data. 

As far as updating the database is concerned, only newer, up-to-date data
will be inserted. So, calling this script, say once or twice will
make sure you have the latest data without accummulating it
redundantly.

B<But please call this script AT MAXIMUM one or two times per day so as not to
obstruct public resources. Please, Please.>

When the database is up-to-date, analysis of data is the next step.

In the synopis, it is shown how to select records from the database,
as an array of L<Statistics::Covid::Datum> objects. Feel free to
share any modules you create on analysing this data, either
under this namespace (for example Statistics::Covid::Analysis::XYZ)
or any other you see appropriate.

=head1 CONFIGURATION FILE

Below is an example configuration file which is essentially JSON with comments.
It can be found in C<t/config-for-t.json> relative to the root directory 
of this distribution.

	# comments are allowed, otherwise it is json
	# this file does not get eval'ed, it is parsed
	# only double quotes! and no excess commas
	{
		# fileparams options
		"fileparams" : {
			# dir to store datafiles, each DataProvider class
			# then has its own path to append
			"datafiles-dir" : "datazz/files"
		},
		# database IO options
		"dbparams" : {
			# which DB to use: SQLite, MySQL (case sensitive)
			"dbtype" : "SQLite",
			# the name of DB
			# in the case of SQLite, this is a filepath
			# all non-existing dirs will be created (by module, not by DBI)
			"dbdir" : "datazz/db",
			"dbname" : "covid19.sqlite",
			# how to handle duplicates in DB? (duplicate=have same PrimaryKey)
			# only-better : replace records in DB if outdated (meaning number of markers is less, e.g. terminal or confirmed)
			# replace     : force replace irrespective of markers
			# ignore      : if there is a duplicate in DB DONT REPLACE/DONT INSERT
			# (see also Statistics::Covid::Datum for up-to-date info)
			"replace-existing-db-record" : "only-better",
			# username and password if needed
			# unfortunately this is in plain text
			# BE WARNED: do not store your main DB password here!!!!
			# perhaps create a new user or use SQLite
			# there is no need for these when using SQLite
			"hostname" : "", # must be a string (MySQL-related)
			"port"     : "", # must be a string (MySQL-related)
			"username" : "", # must be a string
			"password" : "", # must be a string
			# options to pass to DBI::connect
			# see https://metacpan.org/pod/DBI for all options
			"dbi-connect-params" : {
				"RaiseError" : 1, # die on error
				"PrintError" : 0  # do not print errors or warnings
			}
		}
	}

=head1 DATABASE SUPPORT

SQLite and MySQL database types are supported through the
abstraction offered by L<DBI> and L<DBIx::Class>.

B<However>, only the SQLite support has been tested.

B<Support for MySQL is totally untested>.

=head1 AUTHOR
	
Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>, C<< <andreashad2 at gmail.com> >>

=head1 BENCHMARKS

There are some benchmark tests to time database insertion and retrieval
performance. These are
optional and will not be run unless explicitly stated via
C<make bench>

These tests do not hit the online data providers at all. And they
should not, see ADDITIONAL TESTING for more information on this.
They only time the creation of objects and insertion
to the database.

=head1 ADDITIONAL TESTING

Testing the DataProviders is not done because it requires
network access and hits on the providers which is not fair.
However, there are targets in the Makefile for initiating
the "network" tests by doing C<make network> .

=head1 CAVEATS

This module has been put together very quickly and under pressure.
There are must exist quite a few bugs. In addition, the database
schema, the class functionality and attributes are bound to change.
A migration database script may accompany new versions in order
to use the data previously collected and stored.

B<Support for MySQL is totally untested>. Please use SQLite for now
or test the MySQL interface.

B<Support for Postgres has been somehow missed but is underway!>.

=head1 BUGS

This module has been put together very quickly and under pressure.
There are must exist quite a few bugs.

Please report any bugs or feature requests to C<bug-statistics-Covid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Covid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Covid


You can also look for information at:

=over 4

=item * github L<repository|https://github.com/hadjiprocopis/statistics-covid>  which will host data and alpha releases

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Covid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Covid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Covid>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Covid/>

=item * Information about the basis module DBIx::Class

L<http://search.cpan.org/dist/DBIx-Class/>

=back


=head1 DEDICATIONS

Almaz

=head1 ACKNOWLEDGEMENTS

=over 2

=item L<Perlmonks|https://www.perlmonks.org> for supporting the world with answers and programming enlightment

=item L<DBIx::Class>

=item the data providers:

=over 2

=item L<John Hopkins University|https://www.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6>,

=item L<UK government|https://www.gov.uk/government/publications/covid-19-track-coronavirus-cases>,

=item L<https://www.bbc.co.uk> (for disseminating official results)

=back

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut
