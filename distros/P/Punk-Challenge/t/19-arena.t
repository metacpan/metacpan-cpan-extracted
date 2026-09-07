#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The other inert case: Hyperman is installed and loadable, so the compile
# check finds its table and says nothing - but this process is not a
# Hyperman server and has no arena. The counter fails open exactly as it
# does with no Hyperman at all, so the plugin probes the arena at the first
# request under an `after` rule and says so, once.
#
# Under a real Hyperman worker the same probe finds the arena and nothing
# is said. That half is not testable here: the arena is mapped inside
# Hyperman's run(), which a test does not enter.

BEGIN {
    plan skip_all => 'Hyperman is not installed; t/12-after.t covers that case'
        unless eval { require Hyperman; Hyperman->can('ratelimit_hit') };
    delete $ENV{PUNK_NO_HM_ABI};
}

use Punk::Test;

my @warned;
{
    package Arena;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8 };
    challenge for => '/api', after => { limit => 1, window => 60 };
    get '/api/x' => sub { $_[0]->text('x') };
    get '/open'  => sub { $_[0]->text('open') };
}

my $A = { REMOTE_ADDR => '192.0.2.7' };
local $SIG{__WARN__} = sub { push @warned, $_[0] };

my $t = Punk::Test->new('Arena');
is(scalar @warned, 0, 'with Hyperman loadable, compile says nothing: it cannot see an arena from there');

$t->get_ok('/open', env => $A)->status_is(200);
is(scalar @warned, 0, 'a request under no rule probes nothing');

$t->get_ok('/api/x', env => $A)->status_is(200, 'the first request under the after rule is through');
is(scalar @warned, 1, '  and the arena was probed and found missing: one warning');
like($warned[0], qr/the `after` rule for '\/api' is inert/, '  naming the rule');
like($warned[0], qr/this server is not Hyperman, or its arena is not mapped/, '  and the reason');
like($warned[0], qr/plackup -s Hyperman/, '  and how to serve it so that it fires');

$t->get_ok('/api/x', env => $A)->status_is(200, 'the second is through too: the rule is inert');
$t->get_ok('/api/x', env => $A)->status_is(200);
is(scalar @warned, 1, '  and it was said once');

done_testing;
