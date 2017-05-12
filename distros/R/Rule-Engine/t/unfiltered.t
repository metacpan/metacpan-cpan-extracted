use strict;
use Test::More;

use lib 't/lib';

use Rule::Engine::Filter;
use Rule::Engine::Rule;
use Rule::Engine::RuleSet;
use Rule::Engine::Session;

use Account;

my $sess = Rule::Engine::Session->new;

my $rs = Rule::Engine::RuleSet->new(
    name => 'set-credit-limit',
);

$rs->add_rule(
	Rule::Engine::Rule->new(
	    name => 'low-score',
	    condition => sub {
	        my ($self, $env, $obj) = @_;
	        return $obj->credit_score <= 300;
	    },
	    action => sub {
	        my ($self, $env, $obj) = @_;
			$obj->credit_limit(1000);
	    }
	)
);
$rs->add_rule(
	Rule::Engine::Rule->new(
	    name => 'med-score',
	    condition => sub {
	        my ($self, $env, $obj) = @_;
	        return $obj->credit_score >= 500;
	    },
	    action => sub {
	        my ($self, $env, $obj) = @_;
			$obj->credit_limit(5000);
	    }
	)
);
$rs->add_rule(
	Rule::Engine::Rule->new(
	    name => 'high-score',
	    condition => sub {
	        my ($self, $env, $obj) = @_;
	        return $obj->credit_score >= 700;
	    },
	    action => sub {
	        my ($self, $env, $obj) = @_;
			$obj->credit_limit(10000);
	    }
	)
);


$sess->add_ruleset($rs->name, $rs);

is($sess->ruleset_count, 1, 'ruleset_count');

is($sess->get_ruleset('set-credit-limit')->rule_count, 3, 'rule_count');

my $acct_low = Account->new(credit_score => 120);
my $acct_med = Account->new(credit_score => 506);
my $acct_high = Account->new(credit_score => 723);
my $foo = $sess->execute('set-credit-limit', [ $acct_low, $acct_med, $acct_high ]);

is($acct_low->credit_limit, 1000, 'limit for low score');
is($acct_med->credit_limit, 5000, 'limit for medium score');
is($acct_high->credit_limit, 10000, 'limie for high score');

done_testing;