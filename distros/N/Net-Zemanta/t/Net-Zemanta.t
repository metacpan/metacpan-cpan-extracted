use Test::More tests => 7;
BEGIN { 
	use_ok('Net::Zemanta::Suggest');
	use_ok('Net::Zemanta::Preferences');
}

my $s = Net::Zemanta::Suggest->new();
ok( ! $s );

$s = Net::Zemanta::Suggest->new(APIKEY => "dummy");
ok( $s );

$s = Net::Zemanta::Suggest->new(APIKEY => "dummy",
				MARKUP_ONLY => 1);
ok( $s );

$s = Net::Zemanta::Preferences->new();
ok( ! $s );

$s = Net::Zemanta::Preferences->new(APIKEY => "dummy");
ok( $s );

# If you have a valid API key, you can also run these tests:

# $s = Net::Zemanta::Suggest->new(APIKEY => 'net-zemanta-dummy-key');
# 
# ok( $s );
# 
# my $result = $s->suggest("Cozy lummox gives smart squid who asks for job pen.",
# 			 freebase => 0);
# 
# ok( $result );
# ok( $result->{rid} );
# ok( $result->{articles} );
# ok( $result->{keywords} );
# ok( $result->{images} );
# ok( $result->{markup} );
# ok( $result->{signature} );
