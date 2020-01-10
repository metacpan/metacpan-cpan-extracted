use Test::Most 0.25;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;


my $gather;

# filter STDOUT
$gather = [];
bash "$^X -le 'print foreach 1..10' |" => sub { push @$gather, $_ if $_ % 2 == 0 };
eq_or_diff $gather, [map { "$_\n" } 2,4,6,8,10], "can filter to Perl sub";

# filter STDERR too
$gather = [];
bash "$^X -le 'print STDERR foreach 1..10' |&" => sub { push @$gather, $_ if $_ % 2 == 0 };
eq_or_diff $gather, [map { "$_\n" } 2,4,6,8,10], "can filter STDERR to Perl sub";

# ensure we're still checking exit codes
$gather = [];
throws_ok { bash -e => "$^X -le 'print foreach 1..10; exit 1' |" => sub { push @$gather, $_ if $_ % 2 == 0 } }
		qr/unexpectedly returned exit value /, 'bash -e still works with filters';


# not allowed to use capture with filter
throws_ok { bash \string => "echo foo |" => sub {} } qr/multiple output redirects/, 'capture with filter throws error';

# filter sub, but no redirect specified
throws_ok { bash "echo foo" => sub {} } qr/cannot filter without redirect/, 'filter without pipe throws error';

# || doesn't count as a redirect
throws_ok { bash "echo foo ||" => sub {} } qr/cannot filter without redirect/, 'can distinguish | from ||';


done_testing;
