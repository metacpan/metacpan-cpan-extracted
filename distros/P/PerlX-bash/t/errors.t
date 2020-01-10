use Test::Most 		0.25;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;
use TestUtilFuncs qw< perl_error_is >;


my $uninit_msg = q|Use of uninitialized argument to bash|;

throws_ok { bash } qr/Not enough arguments/, 'bash with no args dies';
throws_ok { bash echo => undef } qr/$uninit_msg/, 'bash with an undefined arg dies';
throws_ok { bash \lines => } qr/Not enough arguments/, 'bash with only capture args dies';
throws_ok { bash -c => } qr/Not enough arguments/, 'bash with only switch args dies';
throws_ok { bash \lines => -c => } qr/Not enough arguments/, 'bash with only capture _and_ switch args dies';

# You would think you could wrap a `warning_is` inside a `dies_ok` here.
# You would be wrong.
perl_error_is( "bash with first arg undefined doesn't throw bogus warning", $uninit_msg, <<'END');
    use PerlX::bash;
    bash undef;
END


done_testing;
