#!perl -T

use strict;
use warnings;
use Test::More 'no_plan';

use Template::Replace;
use FindBin;

use Data::Dumper;

#
# Prepare data directory ...
#
my $data_dir = "$FindBin::Bin/data";                       # construct path
$data_dir = $1 if $data_dir =~ m#^((?:/(?!\.\./)[^/]+)+)#; # un-taint
mkdir $data_dir unless -e $data_dir;                       # create if missing

#
# Cleanup beforehand ... no need for it so far!
#


#
# Let's have some prerequisites ...
#
my $tmpl;
my $arg_ref;


#
# Validate error conditions when instantiating ...
#

eval { $tmpl = Template::Replace->new({}, 'test'); };
like( $@, qr/Only one optional argument!/, 'new() more than one arg error' );

eval { $tmpl = Template::Replace->new('myPath'); };
like( $@, qr/Argument has to be a hash reference!/, 'new() arg no hash ref' );

eval { $tmpl = Template::Replace->new({ path => {} }); };
like(
    $@, qr/Path is no string or array_ref!/,
    'new() path is no string or array_ref'
);

eval { $tmpl = Template::Replace->new({ path => 'invalidPath'} ); };
like( $@, qr/Path .*? does not exist!/, 'new() path does not exist error' );

eval { $tmpl = Template::Replace->new({ path => ['invalidPath'] }); };
like( 
	$@, qr/Path array contains invalid path!/,
	'new() path array contains invalid path error'
);

eval { $tmpl = Template::Replace->new({ path => [$data_dir, 'invalidPath'] }); };
like( 
	$@,
	qr/Path array contains invalid path!/,
	'new() path array contains invalid path error'
);

eval { $tmpl = Template::Replace->new({ delimiter => [] }); };
like(
    $@, qr/Argument for delimiters is no hash ref!/,
    'new() delimiters no hash ref'
);

eval { $tmpl = Template::Replace->new({ delimiter => {include => []} }); };
like(
	$@, qr/ARRAY reference of two delimiter strings expected for include!/,
	'new() empty array for include delimiter'
);

$arg_ref->{delimiter} = {  };
eval {
    $tmpl = Template::Replace->new({ delimiter => { include => ['<!--+'] } });
};
like(
	$@, qr/ARRAY reference of two delimiter strings expected for include!/,
	'new() only one string in array for include delimiter'
);

eval { $tmpl = Template::Replace->new({ filter => [] }); };
like(
    $@, qr/Argument for filters is no hash ref!/,
    'new() filters no hash ref'
);

eval { $tmpl = Template::Replace->new({ filter => { default => [] } }); };
like(
	$@, qr/Filter has to be a pre-defined filter name or a CODE reference!/,
	'new() filter no name or code ref'
);

$arg_ref->{filter} = { default => 'noPreDefinedFilter' };
eval { $tmpl = Template::Replace->new($arg_ref); };
like(
	$@, qr/Unknown pre-defined filter 'noPreDefinedFilter'!/,
	'new() unknown pre-defined filter'
);

eval { $tmpl = Template::Replace->new({ filename => {} }); };
like( $@, qr/Filename has to be a string!/, 'new() filename no string' );

eval { $tmpl = Template::Replace->new({ filename => 'test.tmpl' }); };
like(
    $@, qr/No paths defined to load files from!/,
    'new() with filename but no paths given'
);


#
# Now we should get an object ...
#
$tmpl = undef;
$tmpl = Template::Replace->new();
ok    ( defined $tmpl, 'new()' );
isa_ok( $tmpl, 'Template::Replace', '$tmpl is a Template::Replace object' );

$tmpl = undef;
$tmpl = Template::Replace->new({ path => $data_dir });
ok    ( defined $tmpl, 'new({ path => $data_dir })' );

$tmpl = undef;
$tmpl = Template::Replace->new({ path => [$data_dir] });
ok    ( defined $tmpl, 'new({ path => [$data_dir] })' );

$arg_ref = {
	path => $data_dir,
	filename => '',
	delimiter => {},
	filter => {},
};
$tmpl = undef;
$tmpl = Template::Replace->new($arg_ref);
ok    ( defined $tmpl, 'new($arg_ref) with empty delimiter hash_ref' );



#
# Cleanup ... no need for it so far!
#

