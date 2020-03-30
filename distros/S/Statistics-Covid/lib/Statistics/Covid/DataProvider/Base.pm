package Statistics::Covid::DataProvider::Base;

# parent class of all DataProvider classes

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

use Statistics::Covid::Utils;

use HTTP::CookieJar::LWP;
use LWP::UserAgent;
use DateTime;
use File::Spec;
use File::Path;
use Data::Dump;
use JSON::Parse;
use File::Basename;

# this will take all the pv (the perl-vars-from-json fetched)
# and create a data id to be used for labelling and saving to files
# this must be unique of each time point.
# the data generally should be for all locations
# it is specific to each data provider so abstract
sub	create_data_id { die "abstract method, you need to implement it." }

# given some fetched data converted to perlvar
# this sub should create Datum objects from this perlvar
# the 1st parameter is an arrayref (see save_fetched_data_to_localfile() for what this data is)
# returns an arrayref of Datum objects on success or undef on failure
sub create_Datums_from_fetched_data {
	my $self = $_[0];
	my $datas = $_[1];
	die "abstract method you need to implement it"
	# return \@datum_objs # return an array of Datum objects created
}

# saves the input datas (a perl arrayref) to a local file (2nd parameter)
# returns 0 on failure, 1 on success
# '$datas' is an arrayref of
# [ [url, data_received_string, data_as_perlvar] ... ] (where ... denotes optionally more of that first array)
# some data providers send data and metadata, in which cases $datas will contain 2
# such sub-arrays (metadata, followed by data)
# others send only data, so they have 1 such array.
# Some future providers may send more data items...
# About [url, data_received_string, data_as_perlvar] :
# url is where data was fetched
# data_received_string is the json string fetched (or whatever the provider sent)
# data_as_perlvar is the data received as a perlvar (if it's json we received, then JSON::json_decode()
# will give the perlvar.
sub save_fetched_data_to_localfile {
	my $self = $_[0];
	my $datas = $_[1]; # an array 
	my $outfiles = $_[2];
	die "abstract method you need to implement it"
	# return 0 or 1
}
sub load_fetched_data_from_localfile {
	my $self = $_[0];
	# this is the basename for the particular batch downloaded
	# depending on provider, some data is stored in just one file
	# as a perl variable (Data::Dump) with extension .pl
	# and also as a json file (verbatim from the data provider)
	# with extension .json.
	# Ideally you need only the .pl file
	# For other data providers, there are 2 files for each batch of data
	# 1 is the data, the other is metadata (for example the dates!)
	# so our input parameter is a basename which you either append a '.pm' and eval its contents
	# or do some more work to read the metadata also.
	my $inbasename = $_[1];
	die "abstract method you need to implement it"
}

##### methods below are implemented and do not generally need to be overwritten

# creates an obj. There are no input params
sub     new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $self = {
		# urls is a hash keyed on url, value is optional headers as arrayref
		'urls' => undef,
		'name' => undef, # this is the name for each provider, e.g. JHU or BBC
		'fileparams' => {
			# where downloaded data files go
			'datafiles-dir' => undef,
		},
		'debug' => 0,
	};
	bless $self => $class;
	for my $k (keys %$params){
		$self->{$k} = $params->{$k} if exists $self->{$k}
	}

	# we accept config-file or config-hash, see t/example-config.json for an example
	if( exists $params->{'config-file'} ){ if( ! $self->config_file($params->{'config-file'}) ){ warn "error, call to config_file() has failed."; return undef } }
	elsif( exists $params->{'config-hash'} ){ if( ! $self->config_hash($params->{'config-hash'}) ){ warn "error, call to config_hash() has failed."; return undef } }

	# you need to call init() from subclasses after new() and set
	# params
	return $self
}
sub	init {
	my $self = $_[0];

	my $debug = $self->debug();

	# leave the die someone is doing something wrong...
	die "'urls' has not been defined, set it via the parameters." unless defined $self->{'urls'};
	die "'datafiles-dir' has not been defined, set it via the parameters or specify a configuration file via 'config-file'." unless defined $self->datafilesdir();

	# make the output datadir
	if( ! Statistics::Covid::Utils::make_path($self->datafilesdir()) ){ warn "error, failed to create data dir '".$self->datafilesdir()."'."; return 0 }
	if( $debug > 0 ){ warn "check and/or made dir for datafiles '".$self->datafilesdir()."'." }
	return 1 # success
}
# returns undef on failure
# or an arrayref of [$aurl, $pv] on success
sub	fetch {
	my $self = $_[0];

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $DEBUG = $self->debug();
	my $jar = HTTP::CookieJar::LWP->new;
	my $ua = LWP::UserAgent->new(
		cookie_jar => $jar,
		timeout => 50, # seconds
	);
	# the return array will be [url, perlvar] for each url
	my @retJsonPerlVars = ();
	my ($response, $aurl, $headers);
	for my $anentry (@{$self->{'urls'}}){
		$aurl = $anentry->[0];
		$headers = $anentry->[1];
		# add a default useragent string before headers if any which can overwrite it
		if( $DEBUG > 0 ){ print STDOUT "$whoami : fetching url '$aurl' ...\n" }
		$ua->agent('Mozilla/5.0 (Windows NT 6.1; WOW64; rv:64.0) Gecko/20100101 Firefox/64.0');
		if( defined $headers ){
			$response = $ua->get($aurl, @$headers);
		} else {
			$response = $ua->get($aurl);
		}
		if( ! $response->is_success ){
			warn "failed to get url '".$aurl."': ".$response->status_line;
			return undef;
		}
		my $json_str = $response->decoded_content;
		if( ! defined $json_str or $json_str eq '' ){
			warn "failed to get url '".$aurl."': content is empty";
			return undef;
		}
		my $pv = Statistics::Covid::Utils::json2perl($json_str);
		if( ! defined $pv ){
			warn $json_str."\n\nfailed to parse above json data from URL '".$aurl."', is it valid?";
			return undef;
		}
		push @retJsonPerlVars, [$aurl, $json_str, $pv];
	}
	return \@retJsonPerlVars;
}
sub	debug {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'debug'} = $m; return $m }
	return $self->{'debug'}
}
sub     fileparams {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'fileparams'} unless defined $m;
	$self->{'fileparams'} = $m;
	if( ! exists $m->{'datafiles-dir'} or ! defined $m->{'datafiles-dir'} ){ $m->{'datafiles-dir'} = '.' }
	else {
		# now make sure target dir is created already or create it
		# make the output datadir
		if( ! Statistics::Covid::Utils::make_path($m->{'datafiles-dir'}) ){ warn "error, failed to create data dir '".$m->{'datafiles-dir'}."'."; return 0 }
		if( $self->debug() > 0 ){ warn "checked and/or made dir for data files '".$m->{'datafiles-dir'}."'." }
	}
	return $m;
}
sub	datafilesdir {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'fileparams'}->{'datafiles-dir'} = $m; return $m }
	return $self->{'fileparams'}->{'datafiles-dir'}
}
sub	name {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'name'} = $m; return $m }
	return $self->{'name'}
}
sub	urls {
	my $self = $_[0];
	my $m = $_[1];
	if( defined $m ){ $self->{'urls'} = $m; return $m }
	return $self->{'urls'}
}

# reads json data from file which represents the configuration settings
# for this module. It contains a 'fileparams' and a 'dbparams' section
# each with their own sub-sections and options (like dbtype, dbname, password, username, hostname, port)
# any of these can also be inserted in $self->dbparams()->{'password'} for example
# returns 0 on failure, 1 on success
# NOTE: it does not eval, it slurps the file and then converts json content to perl hash
# NOTE2: the configuration file DOES accept COMMENTS (unlike json) which are discarded
# if you have config hash then just use config($hash)
sub	config_file {
	my ($self, $infile) = @_;
	my $inhash = Statistics::Covid::Utils::configfile2perl($infile);
	if( ! defined $inhash ){ warn "error, call to ".'Statistics::Covid::Utils::configfile2perl()'." has failed for file '$infile'."; return 0 }
	return $self->config_hash($inhash)
}
sub	config_hash {
	my ($self, $inhash) = @_;
	if( exists $inhash->{'fileparams'} ){ if( ! $self->fileparams($inhash->{'fileparams'}) ){ warn "error, call to fileparams() has failed."; return undef } }
	return 1 # success
}
sub	toString {
	my $self = $_[0];
	return "DataProvider: ".$self->name().':'
		."\nurls:\n   ".join("\n  ", map { $_->[0] } @{$self->urls()})
		."\ndata files dir: ".$self->datafilesdir()
}
1;
__END__
# end program, below is the POD
