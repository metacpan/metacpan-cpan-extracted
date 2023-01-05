use Test2::V0 -no_srand => 1;
use Regexp::Melody -all;

subtest 'basic' => sub {
	my $melody = '1 to 5 of "A";';
	my $re = Regexp::Melody->new( $melody );
	like( 'A', $re );
	unlike( 'B', $re );
	is( $re->to_melody, $melody );
	ok( $re->isa( 'Regexp::Melody' ) );
};

subtest 'compiler' => sub {
	my $melody = '1 to 5 of "A";';
	my $re = compiler( $melody );
	is( $re, 'A{1,5}' );
};

done_testing;
