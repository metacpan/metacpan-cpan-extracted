#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;
use Punk::Challenge::Solver ();

# verify is not checked by csrf: the plugin puts its own prefix on the
# exempt list at compile, whichever side of the plugin line `csrf` sat on.
# A control route proves csrf is really on in each application.

{
    package CsrfAfter;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8 };
    session secret => 's' x 32;
    csrf;
    challenge for => '/gated', always => 1;
    get  '/gated' => sub { $_[0]->text('in') };
    post '/plain' => sub { $_[0]->text('posted') };
}

{
    package CsrfBefore;
    use Punk;
    use Punk::Plugin::Challenge;
    session secret => 's' x 32;
    csrf;
    plugin 'Challenge' => { secret => 'k', bits => 8, prefix => '/pow' };
    challenge for => '/gated', always => 1;
    get  '/gated' => sub { $_[0]->text('in') };
    post '/plain' => sub { $_[0]->text('posted') };
}

my $A = { REMOTE_ADDR => '192.0.2.7' };

for my $case ([ CsrfAfter => '/challenge/verify' ], [ CsrfBefore => '/pow/verify' ]) {
    my ($class, $verify) = @$case;
    my $t = Punk::Test->new($class);

    $t->post_ok('/plain', env => $A, form => { a => 1 })
      ->status_is(403, "$class: csrf is on - a plain POST without a token is refused")
      ->content_like(qr/invalid csrf token/, '  by csrf');

    $t->get_ok('/gated', env => $A)->status_is(403);
    my $sol = Punk::Challenge::Solver::solve($t->header('X-Challenge'));
    $t->post_ok($verify, env => $A, json => { solution => $sol })
      ->status_is(200, "$class: verify without a token is not refused")
      ->json_like('/clearance', qr/^v1\./, '  and answers with the clearance');
    $t->get_ok('/gated', env => $A)->status_is(200)->content_is('in', '  which clears the rule');
}

done_testing;
