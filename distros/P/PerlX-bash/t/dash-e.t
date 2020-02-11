use Test::Most 0.25;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;


# sanity checks
lives_ok  { bash       $^X, -e => 'exit 0' }                                        'bash with clean exit lives';
lives_ok  { bash       $^X, -e => 'exit 1' }                                        'bash with dirty exit lives';

# simple test
lives_ok  { bash -e => $^X, -e => 'exit 0' }                                        'bash -e with clean exit lives';
throws_ok { bash -e => $^X, -e => 'exit 1' } qr/unexpectedly returned exit value /, 'bash -e with dirty exit dies';

# with capture
lives_ok  { bash -e => \string => $^X, -e => 'exit 0' }
				'bash -e and capture with clean exit lives';
throws_ok { bash -e => \string => $^X, -e => 'exit 1' } qr/unexpectedly returned exit value /,
				'bash -e and capture with dirty exit dies';


done_testing;
