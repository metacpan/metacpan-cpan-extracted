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

eval "use Test::Pod::Coverage 1.04; use Pod::Coverage::TrustPod;";
plan( skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" ) if( $@ );
my $params = 
{
    coverage_class => 'Pod::Coverage::TrustPod',
    trustme =>  => [qr/^(new|init|AUTH_REQUIRED|DECLINED|DONE|FORBIDDEN|NOT_FOUND|OK|REDIRECT|SERVER_ERROR|HTTP_[A-Z_]+|checkonly|cookies_v1|cookie_new_ok_but_hang_on)$/] };
all_pod_coverage_ok( $params );

done_testing();

__END__

