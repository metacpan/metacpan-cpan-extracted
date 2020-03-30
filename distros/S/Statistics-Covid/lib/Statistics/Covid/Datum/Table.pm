package Statistics::Covid::Datum::Table;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

our $SCHEMA = {
  'tablename' => 'Datum',
  'column-names-for-primary-key' => [qw/id name datetimeISO8601/],
  'schema' => {
	# key is the internal name and also name in DB
	# then 'sql' is the sql spec for creating this DB column (SQLite and MySQL)
	# 'default-value' is the default value
	# the id of the location, e.g. 123AXY or CHINA12 - this is not a primary key (pk is formed as a combination see above)
	'id' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>'<NA>'},
	# the name of the location e.g. Hubei, Rome or Italy
	'name' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>'<NA>'},
	# the wider area it belongs to, e.g. for london it will be UK
	'belongsto' => {data_type => 'varchar', is_nullable=>0, size=>100, 'default-value'=>''},
	# the type of the location e.g. local authority, some geographical location, city, province, country
	# it's just for information
	'type' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>'<NA>'},
	# the population in this geographic location
	'population' => {data_type => 'integer', is_nullable=>0, default_value=>0},
	# the area in square kilometers
	'area' => {data_type => 'real', is_nullable=>0, default_value=>0},
	# the number of confirmed cases
	'confirmed' => {data_type => 'integer', is_nullable=>0, default_value=>0},
	# the number of unconfirmed cases
	'unconfirmed' => {data_type => 'integer', is_nullable=>0, default_value=>0},
	# the number of terminal cases (deaths)
	'terminal' => {data_type => 'integer', is_nullable=>0, default_value=>0},
	# the number of those confirmed cases which later recovered
	'recovered' => {data_type => 'integer', is_nullable=>0, default_value=>0},
	# where this data came from e.g. JHU (john hopkins university) or BBC or GOV.UK
	'datasource' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>'<NA>'},
	# datetime both as an ISO string (datetime) or unix epoch seconds
	# a 2020-03-20T12:23:35 assuming UTC tz if not tz specified
	'datetimeISO8601' => {data_type => 'varchar', is_nullable=>0, size=>21, default_value=>'<NA>'},
	'datetimeUnixEpoch' => {data_type => 'integer', is_nullable=>0, default_value=>0},
  }, # end schema
};
$SCHEMA->{'column-names'} = [ sort {$a cmp $b } keys %{$SCHEMA->{'schema'}} ];
$SCHEMA->{'num-columns'} = scalar @{$SCHEMA->{'column-names'}};

1;
__END__
# end program, below is the POD
