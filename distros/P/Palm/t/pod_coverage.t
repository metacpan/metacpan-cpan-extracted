use vars qw(@classes %ignore);

%ignore = (
	Palm::PDB  => [ qw( new_Resource ) ],
	);
	
BEGIN
	{
	@classes = map { "Palm::$_" }
		qw( Address Datebook Mail Memo PDB Raw StdAppInfo ToDo );
	}

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => scalar @classes;

foreach my $class ( @classes )
	{
	pod_coverage_ok(
	   $class,
	   { also_private => [ qr/^Pa(ck|rse)/, @{ $ignore{$class} || [] } ], },
	   "$class pod coverage",
	);
    }
