use Test::Most 0.25;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;


# simple test
lives_ok  { bash -c => "echo foo | perl -e 'print <>' 2>/dev/null" }              'bash -c passes straight through';

# stuff that should fail in expected ways
# (this could also be done in t/errors.t, I suppose ...)
throws_ok { bash -c => echo => 'foo' } qr/Too many arguments for bash -c/, 'bash -c takes only a single arg';
throws_ok { bash -c => undef } qr/Missing argument for bash -c/, 'bash -c requires defined arg';
throws_ok { bash -c => '' } qr/Missing argument for bash -c/, 'bash -c requires non-empty arg';
# contrariwise, this one should actually work (sort of)
lives_ok  { bash -c => '0' } 'bash -c accepts "0" as an arg';

# with capture
#lives_ok  { bash -e => \string => "$^X -e 'exit 0'" }
#				'bash -e and capture with clean exit lives';


done_testing;
