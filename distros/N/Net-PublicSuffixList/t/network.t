use v5.26;
use Test::More 1;
use File::Path            qw(remove_tree);
use File::Spec::Functions qw(catfile);
use Mojo::Util            qw(dumper);

my $class = 'Net::PublicSuffixList';


subtest sanity => sub {
	use_ok( $class ) or BAILOUT( "$class did not compile" );
	can_ok( $class, 'new' );
	};

diag( "You'll see a warnings about 'no way to fetch' for this test. That's fine." );
subtest url => sub {
	my $url = 'http://www.example.com/list.dat';

	my $default_obj = $class->new(
		no_local => 1,
		no_net   => 1,
		);
	can_ok( $default_obj, 'url' );
	delete $default_obj->{list_url};
	ok( ! exists $default_obj->{list_url}, 'list_url is not set' );
	is( $default_obj->url, $default_obj->default_url, 'No configured URL uses the default' );

	my $url_obj = $class->new(
		no_local => 1,
		no_net   => 1,
		list_url => $url,
		);
	can_ok( $url_obj, 'url' );
	is( $url_obj->url, $url, 'Configured URL uses the configured URL'  );
	};
diag( "You shouldn't see any more 'no way to fetch' warnings." );

SKIP: {
	skip 'Enable network testing with NET_PUBLICSUFFIXLIST_NETWORK=1', 2
		unless $ENV{NET_PUBLICSUFFIXLIST_NETWORK};

	subtest no_cache => sub {
		my $obj = $class->new( no_local => 1, cache_dir => undef );
		isa_ok( $obj, $class );
		is( $obj->{source}, 'net', 'source parameter is "net"' );

		my $host = 'amazon.co.uk';
		is( $obj->longest_suffix_in( $host ), 'co.uk' );
		};

	subtest cache => sub {
		my $cache_dir = catfile( qw( t cache ) );
		remove_tree( $cache_dir );
		my $obj = $class->new(
			no_local  => 1,
			cache_dir => $cache_dir,
			);
		isa_ok( $obj, $class );
		is( $obj->{source}, 'net', 'source parameter is "net"' );
		ok( -d $cache_dir, "Cache dir <$cache_dir> exists" );

		my $cache_path = catfile( $cache_dir, $obj->default_local_file );
		ok( -e $cache_path, "Cache path <$cache_path> is there" );

		my $host = 'amazon.co.uk';
		is( $obj->longest_suffix_in( $host ), 'co.uk' );

		subtest net_cache => sub {
			ok( -d $cache_dir, "Cache dir <$cache_dir> exists" );
			ok( -e $cache_path, "Cache path <$cache_path> is there" );

			my $obj = $class->new(
				no_local  => 1,
				cache_dir => $cache_dir,
				);
			isa_ok( $obj, $class );
			is( $obj->{source}, 'net_cached', 'source parameter is "net_cache"' );
			};

		subtest local_file => sub {
			ok( -e $cache_path, "Local file <$cache_path> exists" );
			my $local_obj = $class->new(
				no_net     => 1,
				local_path => $cache_path,
				);
			isa_ok( $local_obj, $class );
			is( $local_obj->{source}, 'local_file', 'source parameter is "local_file"' );

			my $host = 'amazon.co.uk';
			is( $local_obj->longest_suffix_in( $host ), 'co.uk' );
			};

		# This one should fall through to fetching from the net
		# and that should be cached already
		subtest local_file_missing => sub {
			my $missing_file = 'not_there.dat';
			ok( ! -e $missing_file, "Missing file <$missing_file> is missing (good)" );
			my $local_obj = $class->new(
				local_path => $missing_file,
				);
			isa_ok( $local_obj, $class );
			is( $local_obj->{source}, 'net_cached', 'source parameter is "net_cached" for missing local file' );

			my $host = 'amazon.co.uk';
			is( $local_obj->longest_suffix_in( $host ), 'co.uk' );
			};

		# remove_tree( $cache_dir );
		};

	};

done_testing();
