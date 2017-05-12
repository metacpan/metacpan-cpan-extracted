#
#
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

my @pod = all_pod_files();
plan tests => 2 * scalar @pod;

foreach my $pod ( @pod ) {
	pod_file_ok( $pod );

	my $tabs = 0;
	open my $f, '<', $pod or die;
	while ( <$f> ) {
		if ( /^=/ .. /^=cut/ ) {
			$tabs++ if /\t/;
		}
	}
	ok( !$tabs, "POD in $pod has no tabs" );
}
