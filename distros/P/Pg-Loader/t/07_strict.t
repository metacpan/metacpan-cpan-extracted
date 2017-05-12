use Test::More  'no_plan';


push @_ , <../blib*>, <blib*> ;

my $strict  = eval ' use Test::Strict;    1'   ;
my $version = eval 'use Test::HasVersion; 1'   ;



SKIP: {
	skip 'Test::Strict not installed', 1    unless $strict;
	all_perl_files_ok( @_ );
	skip 'Test::Strict not installed', 1    unless $version;
	@_ =  all_pm_files ( @_ );
	warnings_ok( $_ , "use warnings \t$_" )  for @_ ;
}

