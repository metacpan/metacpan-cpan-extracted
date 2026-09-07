#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;

# Test applications in package blocks, one per distinct configuration, since
# to_app compiles once. Every request goes through Punk::Test in process.

{
    package HelpersOn;
    use Punk;
    use Punk::Plugin::Challenge;

    plugin 'Challenge' => { secret => 'k', bits => 12 };

    get '/have' => sub {
        my ($c) = @_;
        $c->text(join ',', map { $c->can($_) ? 1 : 0 }
                 qw(challenge_cleared challenge_issue challenge_clear));
    };

    # The options are read before the gate is reached, so a bad option is
    # reported as itself.
    get '/issue-bad-bits' => sub {
        my ($c) = @_;
        local $@;
        eval { $c->challenge_issue(bits => 99) };
        $c->text($@);
    };
    get '/issue-bad-opt' => sub {
        my ($c) = @_;
        local $@;
        eval { $c->challenge_issue(bitz => 8) };
        $c->text($@);
    };
    get '/cleared-odd' => sub {
        my ($c) = @_;
        local $@;
        eval { $c->challenge_cleared('bits') };
        $c->text($@);
    };
    get '/clear-hash' => sub {
        my ($c) = @_;
        local $@;
        eval { $c->challenge_clear({ bits => 'x' }) };
        $c->text($@);
    };
}

{
    package HelpersOff;
    use Punk;
    use Punk::Plugin::Challenge;    # the use alone: keywords, no helpers

    get '/have' => sub {
        my ($c) = @_;
        $c->text(join ',', map { $c->can($_) ? 1 : 0 }
                 qw(challenge_cleared challenge_issue challenge_clear));
    };
}

my $on = Punk::Test->new('HelpersOn');
$on->get_ok('/have')->status_is(200)->content_is('1,1,1');

$on->get_ok('/issue-bad-bits')->status_is(200)
   ->content_like(qr/`bits` must be between 1 and 22/);
$on->get_ok('/issue-bad-opt')->status_is(200)
   ->content_like(qr/unknown option 'bitz' \(known: bits\)/);
$on->get_ok('/cleared-odd')->status_is(200)
   ->content_like(qr/takes key => value pairs or a hash reference/);
$on->get_ok('/clear-hash')->status_is(200)
   ->content_like(qr/`bits` must be a number/);

my $off = Punk::Test->new('HelpersOff');
$off->get_ok('/have')->status_is(200)->content_is('0,0,0');

done_testing;
