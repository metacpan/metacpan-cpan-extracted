package Statistics::Covid::DataProvider::UK::GOVUK;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

use parent 'Statistics::Covid::DataProvider::Base';

use DateTime;
use File::Spec;
use File::Path;
use Data::Dump qw/pp/;

# new method inherited but here we will create one
# to be used as a factory
sub new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;
	$params->{'urls'} = [
		# here we have 2 urls we need to fetch for one data-batch
		# one is the actual data, the other is metadata containing the very important ... date!
		# so, add 2 entries:
		[
			# start a url (for metadata)
			# returns overall cases and also date
			'https://services1.arcgis.com/0IrmI40n5ZYxTUrV/arcgis/rest/services/DailyIndicators/FeatureServer/0/query?f=json&where=1%3D1&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&resultOffset=0&resultRecordCount=50&cacheHint=true',
			[] # and its headers
		],
		[
			# start a url (for actual data)
			# data for each local authority but without dates
			# check the resultRecordCount=10000 and where=TotalCases%20%3E%3D%200
			#'https://services1.arcgis.com/0IrmI40n5ZYxTUrV/arcgis/rest/services/CountyUAs_cases/FeatureServer/0/query?f=json&where=TotalCases%20%3C%3E%200&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=TotalCases%20desc&resultOffset=0&resultRecordCount=1000&cacheHint=true'
			# modified for where=TotalCases%20%3E%3D%200 (that is >=0) and resultRecordCount=10000
			'https://services1.arcgis.com/0IrmI40n5ZYxTUrV/arcgis/rest/services/CountyUAs_cases/FeatureServer/0/query?f=json&where=TotalCases%20%3E%3D%200&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=TotalCases%20desc&resultOffset=0&resultRecordCount=10000&cacheHint=true',
			[] # and its headers
		],
	];
	# initialise our parent class
	my $self = $class->SUPER::new($params);
	if( ! defined $self ){ warn "error, call to $class->new() has failed."; return undef }

	# and do set parameters specific to this particular data provider 
	$self->name('GOVUK'); # <<<< Make sure this is unique over all providers
	$self->datafilesdir(File::Spec->catfile(
		$self->datafilesdir(), # use this as prefix
		'UK', $self->name() # and append a dir hierarchy relevant to this provider
	));

	# initialise this particular data provider
	if( ! $self->init() ){ warn "error, call to init() has failed."; return undef }

	# this will now be GOVUK obj (not generic)
	return $self
}
# returns the data read if successful or undef if failed
sub load_fetched_data_from_localfile {
	my $self = $_[0];
	my $inbasename = $_[1];

	my @ret = ();
	my $infile = $inbasename . '.meta.json';
	my $infh;
	if( ! open($infh, '<:encoding(UTF-8)', $infile) ){ warn "error, failed to open file '$infile' for reading, $!"; return undef }
	my $json_contents = undef; {local $/=undef; $json_contents = <$infh> } close $infh;
	my $metadata = Statistics::Covid::Utils::json2perl($json_contents);
	if( ! defined $metadata ){ warn "error, call to ".'Statistics::Covid::Utils::json2perl()'." has failed (for metadata, file '$infile')."; return undef }
	push @ret, ['file://'.$infile, $json_contents, $metadata];

	$infile = $inbasename . '.data.json';
	if( ! open($infh, '<:encoding(UTF-8)', $infile) ){ warn "error, failed to open file '$infile' for reading, $!"; return undef }
	$json_contents = undef; {local $/=undef; $json_contents = <$infh> } close $infh;
	my $data = Statistics::Covid::Utils::json2perl($json_contents);
	if( ! defined $data ){ warn "error, call to ".'Statistics::Covid::Utils::json2perl()'." has failed (for data, file '$infile'))."; return undef }
	push @ret, ['file://'.$infile, $json_contents, $data];
	return \@ret
}
sub create_Datums_from_fetched_data {
	my $self = $_[0];
	my $datas = $_[1]; # the fetched data as an arrayref with 1 element which is an array of [url, data_received_string, data_as_perlvar]

	if( ! exists $datas->[0]->[2]->{'features'} ){ warn pp($datas)."\n\nerror, input data is not of the format expected (metadata)."; return undef }
	my $metadata = $datas->[0]->[2]->{'features'};
	if( ! defined $metadata ){ warn "error, metadata does not contain the expected structure"; return undef }
	# unix-epoch seconds (data provides milliseconds but we convert it)
	# (also there we have NewUKCases, EnglandCases, NICases, ScotlandCases, TotalUKCases, TotalUKDeaths, WalesCases)
	my $epochseconds = Statistics::Covid::Utils::epoch_milliseconds_to_DateTime($metadata->[0]->{'attributes'}->{'DateVal'});
	if( ! defined $epochseconds ){ warn "error, did not find any 'DateVal' in metadata"; return undef }
	# this is actual data as an array of 
#      {
#	attributes => {
#	  FID => 132,
#	  GSS_CD => "E10000014",
#	  GSS_NM => "Hampshire",
#	  Shape__Area => 9307104053.23901,
#	  Shape__Length => 753284.882915695,
#	  TotalCases => 87,
#	},
#      },

	my @ret = ();
	if( ! exists $datas->[1]->[2]->{'features'} ){ warn pp($datas)."\n\nerror, input data is not of the format expected (data)."; return undef }
	my $data = $datas->[1]->[2]->{'features'};
	if( ! defined $data ){ warn "error, data does not contain the expected structure"; return undef }
	my $ds = $self->name();
	for my $aUKlocation (@$data){
		if( ! exists $aUKlocation->{'attributes'} ){ warn "json data:".$datas->[1]->[1]."\ndata is:\n".pp($data)."\n\nAND location data is:\n".pp($aUKlocation)."\n\nerror data does not contain an 'attribute' field."; return undef }
		$aUKlocation = $aUKlocation->{'attributes'};
		# make a random test, if that does not exist then something wrong
		if( ! exists $aUKlocation->{'Shape__Area'} ){ warn "json data:".$datas->[1]->[1]."\ndata is:\n".pp($data)."\n\nAND location data is:\n".pp($aUKlocation)."\n\nerror data does not contain a 'Shape__Area' field."; return undef }

		my $datumobj = Statistics::Covid::Datum->new({
			'id' => $aUKlocation->{'GSS_CD'},
			'name' => $aUKlocation->{'GSS_NM'},
			'belongsto' => 'UK',
			'area' => $aUKlocation->{'Shape__Area'},
			'confirmed' => $aUKlocation->{'TotalCases'},
			'date' => $epochseconds,
			'type' => 'UK Higher Local Authority',
			'datasource' => $ds,
		});
		if( ! defined $datumobj ){ warn "error, call to ".'Statistics::Covid::Datum->new()'." has failed for this data: ".pp($aUKlocation); return undef }
		push @ret, $datumobj;
	}
	return \@ret
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
	my $metadata = $datas->[0];
	my $aurl = $metadata->[0];
	my $apv = $metadata->[2];
	# note this is in milliseconds epoch, but parser will take care
	my $epoch_date_str = $apv->{'features'}->[0]->{'attributes'}->{'DateVal'};
	if( ! defined($date=Statistics::Covid::Utils::epoch_milliseconds_to_DateTime($epoch_date_str)) ){
		warn "error, failed to parse date '".$apv->[1]."' from input json data just transfered from url '$aurl'.";
		return undef;
	}
	my $dataid = $date->strftime('2020-%m-%dT%H.%M.%S')
		     . '_'
		     . $date->epoch()
	;
	return $dataid
}
# OR if no outbase is specified, it creates one
# as a timestamped id and the dir will be the datafielesdir()
# as it was specified in its config during construction
# '$datas' is an arrayref of 2 items (metadata and data)
# [ [url, data_received_string, data_as_perlvar], [url, data_received_string, data_as_perlvar] ]
# this provider has BOTH metadata and data
# and so 2 output files will be written, one for each
# returns undef on failure or the basename if successful
sub save_fetched_data_to_localfile {
	my $self = $_[0];
	# this is an arrayref of [url, data_received_string, data_as_perlvar]
	# there are 2 items in there, the first is the metadata, the other is the actual data
	my $datas = $_[1]; # this is an arrayref of [url, data_received_string, data_as_perlvar]
	my $outbase = $_[2]; # optional outbase

	my $debug = $self->debug();

	if( ! defined $outbase ){
		my $dataid = $self->create_data_id($datas);
		if( ! defined $dataid ){
			warn "error, call to ".'create_data_id()'." has failed.";
			return undef;
		}
		$outbase = File::Spec->catfile($self->datafilesdir(), $dataid);
	}
	my $index = 0;
	my $outfile = $outbase . '.meta.json';
	if( ! Statistics::Covid::Utils::save_text_to_localfile($datas->[$index]->[1], $outfile) ){ warn "error, call to ".'save_text_to_localfile()'." has failed."; return undef }
	$outfile = $outbase . '.meta.pl';
	if( ! Statistics::Covid::Utils::save_perl_var_to_localfile($datas->[$index]->[2], $outfile) ){ warn "error, call to ".'save_perl_var_to_localfile()'." has failed."; return undef }
	if( $debug > 0 ){ print STDOUT "save_fetched_data_to_localfile() : saved data to base '$outfile'.\n" }

	$index++;
	$outfile = $outbase . '.data.json';
	if( ! Statistics::Covid::Utils::save_text_to_localfile($datas->[$index]->[1], $outfile) ){ warn "error, call to ".'save_text_to_localfile()'." has failed."; return undef }
	$outfile = $outbase . '.data.pl';
	if( ! Statistics::Covid::Utils::save_perl_var_to_localfile($datas->[$index]->[2], $outfile) ){ warn "error, call to ".'save_perl_var_to_localfile()'." has failed."; return undef }
	if( $debug > 0 ){ print STDOUT "save_fetched_data_to_localfile() : saved data to base '$outfile'.\n" }
	return $outbase
}
1;
__END__
# end program, below is the POD
