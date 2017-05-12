# $Id: 99_pod_coverage.t yblusseau $
# vim: filetype=perl

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

# These are the default Pod::Coverage options.
my $default_opts = {
  also_private => [
    qr/^[A-Z0-9_]+$/,      # Constant subroutines.
  ],
};

# Get the list of modules
my @modules = all_modules();
plan tests => scalar @modules;

foreach my $module ( @modules ) {
	my $opts = $default_opts;

  # Modules that inherit documentation from their parents.
  if ( $module =~ /^POE::Filter::/ ) {
	  $opts = {
			   %$default_opts,
			   coverage_class => 'Pod::Coverage::CountParents',
			  };
  }
  SKIP: {

		# Skip modules that can't load for some reason.
		eval "require $module";
		skip "Not checking $module ...", 1 if $@;

		# Finally!
		pod_coverage_ok( $module, $opts );
	}
}
