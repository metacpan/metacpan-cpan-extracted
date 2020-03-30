package Statistics::Covid::Version::Table;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

our $SCHEMA = {
  # specify your table and schema
  'tablename' => 'Version',
  'column-names-for-primary-key' => [qw/version/],
  'schema' => {
	# key is the internal name and also name in DB
	# then 'sql' is the sql spec for creating this DB column (SQLite and MySQL)
	# 'default-value' is the default value
	# the id of the location, e.g. 123AXY or CHINA12 - this is not a primary key (pk is formed as a combination see above)
	'version' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>$Statistics::Covid::Version::Table::VERSION},
	'package' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>'Statistics::Covid'},
	'authorname' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>'Andreas Hadjiprocopis'},
	'authoremail' => {data_type => 'varchar', is_nullable=>0, size=>100, default_value=>'andreashad2@gmail.com'},
  }, # end schema
};
### nothing to change below:
$SCHEMA->{'column-names'} = [ sort {$a cmp $b } keys %{$SCHEMA->{'schema'}} ];
$SCHEMA->{'num-columns'} = scalar @{$SCHEMA->{'column-names'}};

1;
__END__
# end program, below is the POD
