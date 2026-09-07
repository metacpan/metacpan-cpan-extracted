#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# `after`: the counter is stubbed, because rate_hit reads Hyperman's arena
# and this test has not got one. The stub goes onto the context class at
# RUNTIME, after the application has compiled, because a stub compiled first
# is redefined away by a later require.
#
# The inert case: with the real rate_hit and no arena, an `after` rule lets
# everything through, and the boot warning was emitted exactly once.

BEGIN { $ENV{PUNK_NO_HM_ABI} = 1 }

use Punk::Test;
use Punk::Challenge::Token ();

my @warned;
{
    package After;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8 };
    challenge for => '/api', after => { limit => 2, window => 60 }, tag => 'api';
    challenge for => '/other', after => { limit => 5, window => 10 };
    get '/api/x' => sub { $_[0]->text('x') };
    get '/other' => sub { $_[0]->text('o') };
}

my $A = { REMOTE_ADDR => '192.0.2.7' };
my $T = Punk::Challenge::Token::;

# ---- inert, and warned once -----------------------------------------------------------

my $t;
{
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    $t = Punk::Test->new('After');   # to_app: the boot check runs here
}
is(scalar @warned, 1, 'the boot warning was emitted exactly once');
like($warned[0], qr/Punk::Plugin::Challenge: the `after` rule for '\/api', '\/other' is inert/,
    '  naming every after rule');
like($warned[0], qr/no shared arena to count in \(Hyperman is not loadable here\)/, '  and saying why');
like($warned[0], qr/an `always` rule works on any PSGI server/, '  and what works instead');

$t->get_ok('/api/x', env => $A)->status_is(200)->content_is('x', 'with no arena, the first request is through');
$t->get_ok('/api/x', env => $A)->status_is(200);
$t->get_ok('/api/x', env => $A)->status_is(200)->content_is('x', '  and so is the third: the rule is inert');

# ---- a scripted counter -----------------------------------------------------------------

my @script = (1, 1, 0);       # within, within, past
my @keys;
{
    no warnings 'redefine';
    *Punk::Context::rate_hit = sub {
        my ($c, $key, $limit, $window) = @_;
        push @keys, [ $key, $limit, $window ];
        my $ok = @script ? shift @script : 0;
        return ($ok, $ok ? 1 : 0, time + 60);
    };
}

my $s = Punk::Test->new('After');
$s->get_ok('/api/x', env => $A)->status_is(200)->content_is('x', 'within: through');
$s->get_ok('/api/x', env => $A)->status_is(200)->content_is('x', 'within: through');
$s->get_ok('/api/x', env => $A)->status_is(403, 'past: the challenge')
  ->json_is('/error', 'challenge')
  ->json_is('/challenge/bits', 8, '  at the default bits');
is_deeply($keys[0], [ 'challenge:api:192.0.2.0/24', 2, 60 ],
    'the counter key is challenge:<tag>:<subject>, with the rule\'s limit and window');
is(scalar @keys, 3, 'three requests, three counts');

{
    my $subject = $T->subject('192.0.2.7');
    my $v = $T->clear({ secret => 'k', bits => 8 }, $subject);
    $s->get_ok('/api/x', env => $A, headers => { 'X-Clearance' => $v })
      ->status_is(200)->content_is('x', 'with a clearance after that, through');
    is(scalar @keys, 3, '  and a cleared request is not counted');
}

{
    @script = (0);
    $s->get_ok('/other', env => { REMOTE_ADDR => '2001:db8:1:2::9' })
      ->status_is(403, 'the second rule counts under its own tag');
    is_deeply($keys[-1], [ 'challenge:/other:2001:db8:1:2::/64', 5, 10 ],
        '  which defaults to the prefix, with the IPv6 /64 as subject');
}

done_testing;
