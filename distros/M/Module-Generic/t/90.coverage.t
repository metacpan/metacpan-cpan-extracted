#!perl
BEGIN
{
    use lib './lib';
    use Test::More;
	unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
	{
		plan(skip_all => 'These tests are for author or release candidate testing');
	}
};

eval "use Test::Pod::Coverage 1.04";
plan( skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" ) if( $@ );
my $trustme = { trustme => [qr/^(new|init|added|compute|FREEZE|STORABLE_freeze|STORABLE_thaw|THAW|TO_JSON|TIEHASH|CLEAR|DELETE|EXISTS|FETCH|FIRSTKEY|NEXTKEY|SCALAR|STORE|enable|_exclude|op|op_minus_plus)$/] };
all_pod_coverage_ok( $trustme );
