use Test::More;
use File::Temp qw/ tempfile /;

my $class = 'Net::MAC::Vendor';

diag( "These tests download big files and may take several minutes" );
diag( "We skip these tests unless you set RUN_CACHE_TESTS" );

unless( defined $ENV{RUN_CACHE_TESTS} ) {
	pass();
	done_testing();
	exit;
	}

subtest setup => sub {
	use_ok( $class );
	ok( defined &{"${class}::load_cache"}, "&load_cache is defined" );
	};

subtest bad_source => sub {
	local *STDERR;
	open STDERR, ">", \my $output;

	my $file = 'not_there.txt';
	ok( ! -f $file, "The file that shouldn't be there isn't there [$file]" );
	my $rc = Net::MAC::Vendor::load_cache( $file );
	is( $rc, undef, "load_cache returns undef for bad source [$file]");
	};

subtest load_cache_default => sub {
	local *STDERR;
	open STDERR, ">", \my $output;
	my $rc = Net::MAC::Vendor::load_cache();
	ok( $rc, "load_cache returns true for default source");
	};

my ($fh, $filename) = tempfile( UNLINK => 1 );

subtest load_cache_default_write => sub {
	local *STDERR;
	open STDERR, ">:utf8", \my $output;
	my $rc = Net::MAC::Vendor::load_cache(undef, $filename);
	ok( $rc, "load_cache returns true for default source with write");

	ok ( -s $filename, "load_cache results in file with size > 0");
	};

subtest created_source => sub {
	local *STDERR;
	open STDERR, ">", \my $output;
	my $rc = Net::MAC::Vendor::load_cache($filename);
	ok( $rc, "load_cache returns true read from created source");
	};

done_testing();
