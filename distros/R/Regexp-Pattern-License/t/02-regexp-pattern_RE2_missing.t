use Test2::V0;

use Test::Without::Module qw( re::engine::RE2 );

use Regexp::Pattern;

use Test::Regexp::Pattern;

plan 1;

my $OPTS = { engine => 'RE2' };

my $e = dies { re( "License::fsful", $OPTS ) };
like $e,
	qr/cannot use regexp engine "RE2": Module "re::engine::RE2" is not installed/,
	"call with engine RE2 -> dies";

done_testing;
