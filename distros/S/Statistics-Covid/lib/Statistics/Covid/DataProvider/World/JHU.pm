package Statistics::Covid::DataProvider::World::JHU;

# John Hopkins University

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

use parent 'Statistics::Covid::DataProvider::Base';

use DateTime;
use File::Spec;
use File::Path;
use Data::Dump qw/pp/;

use Statistics::Covid::Utils;

# new method inherited but here we will create one
# to be used as a factory
sub new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;
	$params->{'urls'} = [
	    [ # start a url
		# check the resultRecordCount=10000 and where=TotalCases%20%3E%3D%200
		# modified for where=TotalCases%20%3D%3E%200 (that is >=0) and resultRecordCount=10000
		'https://services9.arcgis.com/N9p5hsImWXAccRNI/arcgis/rest/services/Z7biAeD8PAkqgmWhxG2A/FeatureServer/1/query?f=json&where=Confirmed%20%3E%3D%200&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=Confirmed%20desc%2CCountry_Region%20asc%2CProvince_State%20asc&resultOffset=0&resultRecordCount=250&cacheHint=true',
		#'https://services9.arcgis.com/N9p5hsImWXAccRNI/arcgis/rest/services/Z7biAeD8PAkqgmWhxG2A/FeatureServer/1/query?cacheHint=true&f=json&orderByFields=Confirmed+desc%2CCountry_Region+asc%2CProvince_State+asc&outFields=*&resultOffset=0&resultRecordCount=250&returnGeometry=false&spatialRel=esriSpatialRelIntersects&where=Confirmed+%3E+0',
		# the headers associated with that url
		[
		'Cache-Control'     => 'max-age=0',
		'Connection'        => 'keep-alive',
		'Accept'	    => '*/*',
		'Accept-Encoding'   => 'gzip, x-gzip, deflate, x-bzip2, bzip2',
		'Accept-Language'   => 'en-US,en;q=0.5',
		'Host'		    => 'services9.arcgis.com:443',
		# likes this: 'Mon, 16 Mar 2020 21:14:13 GMT',
		'If-Modified-Since' => DateTime->now(time_zone=>'GMT')->add(minutes=>-1)->strftime('%a, %d %b %Y %H:%M:%S %Z'),
		'If-None-Match'     => 'sd8_-224912290',
		'Referer'           => 'https://services9.arcgis.com/N9p5hsImWXAccRNI/arcgis/rest/services/Z7biAeD8PAkqgmWhxG2A/FeatureServer/1/query?f=json&where=Confirmed%20%3E%200&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=Confirmed%20desc%2CCountry_Region%20asc%2CProvince_State%20asc&resultOffset=0&resultRecordCount=250&cacheHint=true',
		'TE'                => 'Trailers',
		# we have our own default
		#'User-Agent'        => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.20; rv:61.0) Gecko/20100101 Firefox/73.0',
		'DNT'               => '1',
		'Origin'            => 'https://www.arcgis.com',
		] # end headers
	    ] # end a url
	]; # end 'urls'

	# initialise our parent class
	my $self = $class->SUPER::new($params);
	if( ! defined $self ){ warn "error, call to $class->new() has failed."; return undef }

	# and do set parameters specific to this particular data provider
	$self->name('JHU'); # <<<< Make sure this is unique over all providers
	$self->datafilesdir(File::Spec->catfile(
		$self->datafilesdir(), # use this as prefix it was set in config
		'World', $self->name() # and append a dir hierarchy relevant to this provider
	));

	# initialise this particular data provider
	if( ! $self->init() ){ warn "error, call to init() has failed."; return undef }

	# this will now be JHU obj (not generic)
	return $self
}
# overwriting this from parent
# returns undef on failure or a data id unique on timepoint
# which can be used for saving data to a file or labelling this data
sub create_data_id {
	my $self = $_[0];
	my $datas = $_[1]; # this is an arrayref of [url, data_received_string, data_as_perlvar]

	# get the date from the first pv

	# this json is idiotic because it's just arrays,
	# 0: location id
	# 1: location name
	# 2: cases
	# 3: population
	# unless [0] is 'UpdatedOn', in which case [1] is 09:00 GMT, 15 March
	# thankfully this update info is last
	my $date = undef;
	my $aurl = $datas->[0]->[0];
	my $apv = $datas->[0]->[2];
	# note this is in milliseconds epoch, but parser will take care
	# also note that this is about countries and each country has its own last-update
	# some countries (only china?) have province data too
	# so, for the time being find the maximum epoch which is the latest data at least one country was updated
	# epoch and index in the array
	my $latest = [$apv->{'features'}->[0]->{'attributes'}->{'Last_Update'}, 0];
	my $epoch_date_str;
	for(my $i=scalar(@{$apv->{'features'}});$i-->1;){
		# note that this is millis epoch
		$epoch_date_str = $apv->{'features'}->[$i]->{'attributes'}->{'Last_Update'} + 0;
		if( $epoch_date_str > $latest->[0] ){ $latest = [$epoch_date_str, $i] }
	}
	$epoch_date_str = $apv->{'features'}->[$latest->[1]]->{'attributes'}->{'Last_Update'};
	if( ! defined($date=Statistics::Covid::Utils::epoch_milliseconds_to_DateTime($epoch_date_str)) ){
		warn "error, failed to parse date '$epoch_date_str' from input json data just transfered from url '$aurl'.";
		return undef;
	}
	my $dataid = $date->strftime('2020-%m-%dT%H.%M.%S')
		     . '_'
		     . $date->epoch()
	;
	print "create_data_id() : using last updated time of '".$apv->{'features'}->[$latest->[1]]->{'attributes'}->{'Country_Region'}."', last updated on: ".$date->iso8601()."\n";
	return $dataid
}
# returns the data read if successful or undef if failed
sub load_fetched_data_from_localfile {
	my $self = $_[0];
	my $inbasename = $_[1];

	my $infile = $inbasename . '.data.json';
	my $infh;
	if( ! open($infh, '<:encoding(UTF-8)', $infile) ){ warn "error, failed to open file '$infile' for reading, $!"; return undef }
	my $json_contents; {local $/=undef; $json_contents = <$infh> } close $infh;
	my $pv = Statistics::Covid::Utils::json2perl($json_contents);
	if( ! defined $pv ){ warn "error, call to ".'Statistics::Covid::Utils::json2perl()'." has failed (for data, file '$infile')."; return undef }
	return [['file://'.$infile, $json_contents, $pv]];
}
sub create_Datums_from_fetched_data {
	my $self = $_[0];
	my $datas = $_[1]; # the fetched data as an arrayref with 1 element which is an array of [url, data_received_string, data_as_perlvar]

	my $data = $datas->[0]->[2]->{'features'}; # getting to the array of locations
# data is an array of
#          {
#   	 attributes => {
#   	   Active => 6285,
#   	   Admin2 => undef,
#   	   Combined_Key => 'fix',
#   	   Confirmed => 67800,
#   	   Country_Region => "China",
#   	   Deaths => 3133,
#   	   FIPS => 'fix',
#   	   Last_Update => 1584690182000,
#   	   Lat => 30.9756403482891,
#   	   Long_ => 112.270692167452,
#   	   OBJECTID => 106,
#   	   Province_State => "Hubei",
#   	   Recovered => 58382,
#   	 },

# and for countries only data
#	{
#	  attributes => {
#	    Active => 91,
#	    Admin2 => 'fix',
#	    Combined_Key => 'fix',
#	    Confirmed => 95,
#	    Country_Region => "Cyprus",
#	    Deaths => 1,
#	    FIPS => 'fix',
#	    Last_Update => 1584895387000,
#	    Lat => 35.1264,
#	    Long_ => 33.4299,
#	    OBJECTID => 7,
#	    Province_State => 'fix',
#	    Recovered => 3,
#	  },

	my $ds = $self->name();
	my ($name, $belongsto, $datetimeobj);
	my @ret = ();
	for my $aWorldLocation (@$data){
		$aWorldLocation = $aWorldLocation->{'attributes'};
		if( ! exists $aWorldLocation->{'Province_State'}
		 or ! defined $aWorldLocation->{'Province_State'}
		 or $aWorldLocation->{'Province_State'} eq 'fix'
		){
			$name = $aWorldLocation->{'Country_Region'};
			$belongsto = 'World'; # default for countries!
		} else {
			$name = $aWorldLocation->{'Province_State'};
			$belongsto = $aWorldLocation->{'Country_Region'};
		}
		$datetimeobj = Statistics::Covid::Utils::epoch_milliseconds_to_DateTime($aWorldLocation->{'Last_Update'});
		if( ! defined $datetimeobj ){ warn pp($aWorldLocation)."\n\nerror, call to ".'Statistics::Covid::Utils::epoch_milliseconds_to_DateTime()'." has failed for date field of 'Last_Update' in the above parameters (it must be milliseconds since unix epoch. A filename (or a url) may be associated with it at\n  ".$datas->[0]->[0]."\n"; return undef }
		my $datumobj = Statistics::Covid::Datum->new({
			'id' => join('/',
				$aWorldLocation->{'Country_Region'}, $aWorldLocation->{'Lat'}, $aWorldLocation->{'Long_'}),
			'name' => $name,
			'belongsto' => $belongsto,
			'confirmed' => $aWorldLocation->{'Confirmed'},
			'recovered' => $aWorldLocation->{'Recovered'},
			'terminal' => $aWorldLocation->{'Deaths'},
			# what is 'Active'?
			'date' => $datetimeobj,
			'type' => 'Country or Region',
			'datasource' => $ds,
		});
		if( ! defined $datumobj ){ warn "error, call to ".'Statistics::Covid::Datum->new()'." has failed for this data: ".join(",", @$aWorldLocation); return undef }
		push @ret, $datumobj
	}
	return \@ret
}
# saves data received as JSON and PL (perl variables)
# into files specified by an optional basename (input param: $outbase)
# OR if no outbase is specified, it creates one
# as a timestamped id and the dir will be the datafielesdir()
# as it was specified in its config during construction
# '$datas' is an arrayref of
# [ [url, data_received_string, data_as_perlvar] ]
# this provider does not have any metadata, all data is received in 1 chunk
# returns undef on failure or the basename if successful
sub save_fetched_data_to_localfile {
	my $self = $_[0];
	my $datas = $_[1]; # this is an arrayref of [url, data_received_string, data_as_perlvar]
	my $outbase = $_[2]; # optional outbase

	if( ! defined $outbase ){
		my $dataid = $self->create_data_id($datas);
		if( ! defined $dataid ){
			warn "error, call to ".'create_data_id()'." has failed.";
			return undef;
		}
		$outbase = File::Spec->catfile($self->datafilesdir(), $dataid);
	}
	my $index = 0;
	my $outfile = $outbase . '.data.json';
	my $aurl = $datas->[$index]->[0];
	if( ! Statistics::Covid::Utils::save_text_to_localfile($datas->[$index]->[1], $outfile) ){ warn "error, call to ".'save_text_to_localfile()'." has failed for url '$aurl'."; return undef }
	$outfile = $outbase . '.data.pl';
	if( ! Statistics::Covid::Utils::save_perl_var_to_localfile($datas->[$index]->[2], $outfile) ){ warn "error, call to ".'save_perl_var_to_localfile()'." has failed for url '$aurl'."; return undef }
	print "save_fetched_data_to_localfile() : saved data to base '$outbase'.\n";
	return $outbase;
}
1;
__END__
# end program, below is the POD
