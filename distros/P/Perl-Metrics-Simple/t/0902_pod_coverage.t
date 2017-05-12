use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

eval {
	use Test::Pod::Coverage 1.04;
};

if ( $EVAL_ERROR ) {
    plan skip_all => 'Test::Pod::Coverage required to test POD';
}
else {
    plan tests => 3;
}

pod_coverage_ok( 'Perl::Metrics::Simple' );
pod_coverage_ok( 'Perl::Metrics::Simple::Analysis' );
pod_coverage_ok( 'Perl::Metrics::Simple::Analysis::File' );
