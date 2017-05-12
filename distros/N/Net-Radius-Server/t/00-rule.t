use Test::More tests => 84;
use Net::Radius::Server::Base qw/:all/;

# Simple constant tests
is(NRS_MATCH_FAIL,	0, 'Constant NRS_MATCH_FAIL');
is(NRS_MATCH_OK,	1, 'Constant NRS_MATCH_OK');

is(NRS_SET_CONTINUE,	0, 'Constant NRS_SET_CONTINUE');
is(NRS_SET_SKIP,	1, 'Constant NRS_SET_SKIP');
is(NRS_SET_RESPOND,	2, 'Constant NRS_SET_RESPOND');
is(NRS_SET_DISCARD,	4, 'Constant NRS_SET_DISCARD');

use_ok('Net::Radius::Server::Rule');

my $rule = new Net::Radius::Server::Rule;
isa_ok($rule, 'Exporter');
isa_ok($rule, 'Class::Accessor');
isa_ok($rule, 'Net::Radius::Server');
isa_ok($rule, 'Net::Radius::Server::Rule');

can_ok($rule, 'eval');
can_ok($rule, 'new');
can_ok($rule, 'log_level');
can_ok($rule, 'log');
can_ok($rule, 'match_methods');
can_ok($rule, 'set_methods');

# Test the ->description facility
can_ok($rule, 'description');
like($rule->description, qr/Net::Radius::Server::Rule/, 
     "Description contains the class");
like($rule->description, qr/\([^:]+:/, "Description contains the filename");
like($rule->description, qr/:\d+\)$/, "Description contains the line");

# Build work match and set classes
package My::Match;
use base 'Net::Radius::Server::Match';
__PACKAGE__->mk_accessors(qw/result tag/);
sub match_result { $_[1]->{$_[0]->tag}++; $_[0]->result }

package My::Set;
use base 'Net::Radius::Server::Set';
__PACKAGE__->mk_accessors(qw/result tag/);
sub set_result { $_[1]->{$_[0]->tag}++; $_[0]->result }

package main;

# Now create various objects
my $match_ok	= My::Match->mk({result => NRS_MATCH_OK, 
				 tag => 'match_ok', log_level => -1 });
my $match_fail	= My::Match->mk({result => NRS_MATCH_FAIL, 
				 tag => 'match_fail', log_level => -1 });

my $set_skip	= My::Set->mk({result => NRS_SET_SKIP, 
			       tag => 'set_skip', log_level => -1 });
my $set_disc	= My::Set->mk({result => NRS_SET_DISCARD, 
			       tag => 'set_disc', log_level => -1 });
my $set_cont	= My::Set->mk({result => NRS_SET_CONTINUE, 
			       tag => 'set_cont', log_level => -1 });
my $set_cont_r	= My::Set->mk({result => NRS_SET_CONTINUE | NRS_SET_RESPOND, 
			       tag => 'set_cont_r', log_level => -1 });

# Sc 1: Rule with no match - It should evaluate
$rule->match_methods	([]);
$rule->set_methods	([$set_cont]);
my $val = { set_cont => -1 };
my $r = $rule->eval($val);
eval_scenario("No match, base set", NRS_SET_CONTINUE, $val);

# Sc 2: match, set - Must evaluate the set
$rule->match_methods	([$match_ok]);
$rule->set_methods	([$set_cont]);
$val = { match_ok => -1, set_cont => -1 };
$r = $rule->eval($val);
eval_scenario("Match, base set", NRS_SET_CONTINUE, $val);

# Sc 3: match, no match, set - Must not evaluate the set
$rule->match_methods	([$match_ok, $match_fail]);
$rule->set_methods	([$set_cont]);
$val = { match_ok => -1, match_fail => -1 };
$r = $rule->eval($val);
eval_scenario("Match, no match, no set", 'undef', $val);

# Sc 4: Matches in short circuit
$rule->match_methods	([$match_ok, $match_fail, $match_ok]);
$rule->set_methods	([$set_cont]);
$val = { match_ok => -1, match_fail => -1 };
$r = $rule->eval($val);
eval_scenario("Matches in short circuit", 'undef', $val);

# Sc 5: match, match, set - Must evaluate the set
$rule->match_methods	([$match_ok, $match_ok]);
$rule->set_methods	([$set_cont]);
$val = { match_ok => -2, set_cont => -1 };
$r = $rule->eval($val);
eval_scenario("Match, match, set", NRS_SET_CONTINUE, $val);

# Sc. 6: Default rule return
$rule->match_methods	([$match_ok, $match_ok]);
$rule->set_methods	([]);
$val = { match_ok => -2 };
$r = $rule->eval($val);
eval_scenario("Match, match, no set", NRS_SET_DISCARD, $val);

# Sc. 7: No match, no set
$rule->match_methods	([]);
$rule->set_methods	([]);
$val = {};
$r = $rule->eval($val);
eval_scenario("No match, no set", NRS_SET_DISCARD, $val);

# Sc. 8: Set with skip
$rule->match_methods	([]);
$rule->set_methods	([ $set_skip, $set_cont_r ]);
$val = { set_skip => -1 };
$r = $rule->eval($val);
eval_scenario("Skipping set", NRS_SET_SKIP, $val);

# Sc. 8: Set with discard
$rule->match_methods	([]);
$rule->set_methods	([ $set_disc, $set_cont ]);
$val = { set_disc => -1, set_cont => -1 };
$r = $rule->eval($val);
eval_scenario("Discard and another set", NRS_SET_CONTINUE, $val);

sub eval_scenario
{
    is(defined($r) ? $r : 'undef', $_[1], "$_[0]: Rule result");
    is($_[2]->{$_} || 0, 0, "$_[0]: $_ invocations") 
    for qw/match_ok match_fail set_skip 
    set_disc set_skip_r set_cont/;
}
