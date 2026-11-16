use v5.26;
use Test::More 1;
use File::Spec::Functions qw(catfile);
use Mojo::Util            qw(dumper);

my $class = 'Net::PublicSuffixList';

my $warnings;
local $SIG{'__WARN__'} = sub { $warnings .= $_[0] };

subtest sanity => sub {
	use_ok( $class ) or BAIL_OUT( "$class did not compile" );
	can_ok( $class, 'new' );
	};

subtest bare => sub {
	$warnings = undef;

	my $obj = $class->new( no_local => 1, no_net => 1 );
	isa_ok( $obj, $class );
	ok( $obj->{no_local}, "no_local is true" );
	ok( $obj->{no_net}, "no_net is true" );
	like $warnings, qr/No way to fetch/, 'got fetch warning';

	ok( ! defined $obj->fetch_list_from_local, 'fetch_list_from_local returns undef for no_local = 1' );
	ok( ! defined $obj->fetch_list_from_net, 'fetch_list_from_net returns undef for no_net = 1' );
	};

subtest add_suffix => sub {
	$warnings = undef;

	my $obj = $class->new( no_net => 1, no_local => 1 );
	my $suffix = 'co.uk';
	isa_ok( $obj, $class );
	can_ok( $obj, 'suffix_exists', 'add_suffix' );
	like $warnings, qr/No way to fetch/, 'got fetch warning';

	ok( ! $obj->suffix_exists( $suffix ), "Suffix <$suffix> does not exist yet" );

	my $result = $obj->add_suffix( $suffix );
	isa_ok( $result, $class, 'add_suffix returns the object' );

	ok( $obj->suffix_exists( $suffix ), "Suffix <$suffix> now exists" );
	};

subtest add_suffix_strip => sub {
	$warnings = undef;

	my $obj = $class->new( no_net => 1, no_local => 1 );
	my $suffix = 'co.uk';
	isa_ok( $obj, $class );
	can_ok( $obj, 'suffix_exists', 'add_suffix' );
	like $warnings, qr/No way to fetch/, 'got fetch warning';

	my @suffixes = (
		[ qw( *.com    com   ) ],
		[ qw( *net     net   ) ],
		[ qw( *.co.uk  co.uk ) ],
		);
	foreach my $pair ( @suffixes ) {
		foreach my $suffix ( $pair->@* ) {
			ok( ! $obj->suffix_exists( $suffix ), "Suffix <$suffix> does not exist yet" );
			}
		}

	foreach my $pair ( @suffixes ) {
		my $result = $obj->add_suffix( $pair->[0] );
		isa_ok( $result, $class, 'add_suffix returns the object'  );
		ok(   $obj->suffix_exists( $pair->[1] ), "Suffix <$pair->[1]> now exists for <$pair->[0]>" );
		ok( ! $obj->suffix_exists( $pair->[0] ), "Suffix <$pair->[0]> does not exist" );
		}

	my $result = $obj->add_suffix( $suffix );
	isa_ok( $result, $class, 'add_suffix returns the object' );

	ok( $obj->suffix_exists( $suffix ), "Suffix <$suffix> now exists" );
	};

subtest remove_suffix => sub {
	$warnings = undef;

	my $obj = $class->new( no_net => 1, no_local => 1 );
	my $suffix = 'au';
	isa_ok( $obj, $class );
	can_ok( $obj, 'suffix_exists', 'add_suffix', 'remove_suffix' );
	like $warnings, qr/No way to fetch/, 'got fetch warning';

	ok( ! $obj->suffix_exists( $suffix ), "Suffix <$suffix> does not exist yet" );

	my $result = $obj->add_suffix( $suffix );
	isa_ok( $result, $class, 'add_suffix returns the object' );

	ok( $obj->suffix_exists( $suffix ), "Suffix <$suffix> now exists" );

	$result = $obj->remove_suffix( $suffix );
	isa_ok( $result, $class, 'remove_suffix returns the object' );
	ok( ! $obj->suffix_exists( $suffix ), "Suffix <$suffix> no longer exists" );

	};

subtest parse_list => sub {
	$warnings = undef;

	my $obj = $class->new( no_net => 1, no_local => 1 );
	can_ok( $obj, 'parse_list' );
	like $warnings, qr/No way to fetch/, 'got fetch warning';

	my @suffixes = qw( co.uk foo.bar com );
	foreach my $suffix ( @suffixes ) {
		ok( ! $obj->suffix_exists( $suffix ), "Suffix <$suffix> does not exist yet" );
		}

	my $body = join "\n", @suffixes;

	my $result = $obj->parse_list( \$body );
	isa_ok( $result, $class );

	foreach my $suffix ( @suffixes ) {
		ok( $obj->suffix_exists( $suffix ), "Suffix <$suffix> now exists" );
		}
	};

subtest parse_list_strip => sub {
	$warnings = undef;

	my $obj = $class->new( no_net => 1, no_local => 1 );
	can_ok( $obj, 'parse_list' );
	like $warnings, qr/No way to fetch/, 'got fetch warning';

	my @suffixes = (
		[ qw( *.com    com   ) ],
		[ qw( *net     net   ) ],
		[ qw( *.co.uk  co.uk ) ],
		);
	foreach my $pair ( @suffixes ) {
		foreach my $suffix ( $pair->@* ) {
			ok( ! $obj->suffix_exists( $suffix ), "Suffix <$suffix> does not exist yet" );
			}
		}

	my $body = join "\n", map { $_->[0] } @suffixes;

	my $result = $obj->parse_list( \$body );
	isa_ok( $result, $class );

	foreach my $pair ( @suffixes ) {
		ok(   $obj->suffix_exists( $pair->[1] ), "Suffix <$pair->[1]> now exists for <$pair->[0]>" );
		ok( ! $obj->suffix_exists( $pair->[0] ), "Suffix <$pair->[0]> does not exist" );
		}
	};

subtest local_path => sub {
	my $local_file = 'test.dat';
	my $local_path = catfile( 'corpus', $local_file );
	ok( -e $local_path, "Local file <$local_path> exists" );

	my $obj = $class->new( no_net => 1, local_path => $local_path );
	isa_ok( $obj, $class );
	can_ok( $obj, 'local_path' );

	is( $obj->local_file, $local_file );
	is( $obj->local_path, $local_path );
	is( $obj->{source}, 'local_file' );

	my @suffixes = qw( com net co.uk email badger koala.au );
	foreach my $suffix ( @suffixes ) {
		ok( $obj->suffix_exists( $suffix ), "Suffix <$suffix> exists" );
		}
	};

subtest suffixes => sub {
	my $local_file = 'test.dat';
	my $local_path = catfile( 'corpus', $local_file );
	ok( -e $local_path, "Local file <$local_path> exists" );

	my $obj = $class->new( no_net => 1, local_path => $local_path );
	isa_ok( $obj, $class );
	can_ok( $obj, 'suffixes_in' );

	my $host = 'wildfire.koala.au';

	subtest suffixes_in => sub {
		can_ok( $obj, 'suffixes_in' );
		my $suffixes = $obj->suffixes_in( $host );
		ok( $suffixes->@* == 2, "There are two suffixes in $host" );

		is( $suffixes->@[0], 'au',        'First suffix is right' );
		is( $suffixes->@[1], 'koala.au',  'Second suffix is right' );
		};

	subtest longest_suffix_in => sub {
		can_ok( $obj, 'longest_suffix_in' );
		is( $obj->longest_suffix_in( $host ), 'koala.au' );
		};

	subtest split_host => sub {
		can_ok( $obj, 'split_host' );
		my $result = $obj->split_host( $host );
		isa_ok( $result, ref {}, "split_host returns a hash ref" );
		is( $result->{suffix}, 'koala.au' );
		is( $result->{short}, 'wildfire' );
		is( $result->{host}, $host );
		}
	};

done_testing();
