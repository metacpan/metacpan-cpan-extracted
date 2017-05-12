use strict;
use Test::More;

use lib 't/lib';

use Rule::Engine::Filter;
use Rule::Engine::Rule;
use Rule::Engine::RuleSet;
use Rule::Engine::Session;

use Tribble;

my $sess = Rule::Engine::Session->new;
$sess->set_environment('temperature', 65);

my $rs = Rule::Engine::RuleSet->new(
    name => 'find-happy-tribbles',
    filter => Rule::Engine::Filter->new(
        condition => sub {
            my ($self, $session, $obj) = @_;
            $obj->happy ? 1 : 0
        }
    )
);

my $rule = Rule::Engine::Rule->new(
    name => 'temperature',
    action => sub {
        my ($Self, $env, $obj) = @_;
        $obj->happy(1);
    },
    condition => sub {
        my ($self, $env, $obj) = @_;
        return $obj->favorite_temp == $env->get_environment('temperature');
    }
);

$rs->add_rule($rule);

$sess->add_ruleset($rs->name, $rs);

cmp_ok($sess->ruleset_count, '==', 1, 'ruleset_count');

my $tribble1 = Tribble->new(favorite_temp => 65);
my $tribble2 = Tribble->new(favorite_temp => 70);
my $foo = $sess->execute('find-happy-tribbles', [ $tribble1, $tribble2 ]);

is(@{ $foo }, 1, 'got 1 happy tribble');

done_testing;