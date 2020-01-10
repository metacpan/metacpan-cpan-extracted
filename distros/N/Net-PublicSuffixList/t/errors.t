use v5.26;
use Test::More 1;
use File::Spec::Functions qw(catfile);
use Mojo::Util            qw(dumper);

my $class = 'Net::PublicSuffixList';

subtest sanity => sub {
	use_ok( $class ) or BAILOUT( "$class did not compile" );
	can_ok( $class, 'new' );
	};

diag( "You'll see a warnings about 'no way to fetch' for this test. That's fine." );

subtest bad_arg_parse_list => sub {
	my $obj = $class->new( no_local => 1, no_net => 1 );
	isa_ok( $obj, $class );
	can_ok( $obj, 'parse_list' );

	subtest no_argument => sub {
		my $rc = eval { $obj->parse_list() };
		my $at = $@;
		ok( ! defined $rc, 'eval fails' );
		like( $at, qr/Too few arguments/, 'Perl complains' );
		};

	subtest non_ref_arg => sub {
		my $string;
		local $SIG{__WARN__} = sub { $string = join '', @_ };
		my $rc = $obj->parse_list( 'Hello' );
		ok( ! defined $rc );
		like( $string, qr/not a scalar reference/ );
		};

	subtest array_ref_arg => sub {
		my $string;
		local $SIG{__WARN__} = sub { $string = join '', @_ };
		my $rc = $obj->parse_list( [] );
		ok( ! defined $rc );
		like( $string, qr/not a scalar reference/ );
		};

	};

diag( "You shouldn't see any more 'no way to fetch' warnings." );

done_testing();
