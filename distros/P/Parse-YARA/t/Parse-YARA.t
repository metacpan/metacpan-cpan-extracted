# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parse-YARA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 51;
BEGIN { use_ok('Parse::YARA') };

#########################
use Parse::YARA;
use Tie::IxHash;
$SIG{'__WARN__'} = sub { warn $_[0] unless (caller eq "Parse::YARA"); };

# Test new();
my $empty_ruleset = Parse::YARA->new();
isa_ok($empty_ruleset, 'Parse::YARA');

# Generate the rule hash we would expect to return for most of our tests
my $rule_hash;
my $rule_hash_knot = tie(%{$rule_hash}, 'Tie::IxHash');
$rule_hash = {
                 'include' => 1,
                 'rules' => {
                              'test_rule' => {
                                               'modifier' => 'global',
                                               'meta' => {
                                                           'meta_name2' => 'meta_val2',
                                                           'meta_name1' => 'meta_val1'
                                                         },
                                               'strings' => {
                                                              '$str_name2' => [
                                                                                {
                                                                                  value => 'str_val2',
                                                                                  type => 'text',
                                                                                  modifier => []
                                                                                }
                                                                              ],
                                                              '$str_name1' => [
                                                                                {
                                                                                  value => 'str_val1',
                                                                                  type => 'text',
                                                                                  modifier => []
                                                                                }
                                                                              ]
                                                            },
                                               'condition' => 'true',
                                               'tags' => [
                                                           'tag1',
                                                           'tag2'
                                                         ]
                                             }
                            }
               };
bless($rule_hash, 'Parse::YARA');

# Generate the default rule string we would expect to return for most of our tests
my $rule_string = "global rule test_rule : tag1 tag2
{
\tmeta:
\t\tmeta_name2 = \"meta_val2\"
\t\tmeta_name1 = \"meta_val1\"

\tstrings:
\t\t\$str_name2 = \"str_val2\"
\t\t\$str_name1 = \"str_val1\"

\tcondition:
\t\ttrue
}\n";

# Test new(rule => $rule_string)
my $string_ruleset = Parse::YARA->new(rule => $rule_string);
isa_ok($string_ruleset, 'Parse::YARA');
ok($string_ruleset->as_string eq $rule_string);

# Test calling parse($rule_string) on an empty object
my $parse_string_ruleset = Parse::YARA->new();
$parse_string_ruleset->parse($rule_string);
ok($parse_string_ruleset->as_string eq $rule_string);

# Create a var containing a string of what we expect out of 
# parsing t/FromYARADocumentation.txt
my $comparison_file_as_string = '';
open(COMPARISON_FILE, '<', 't/OutputComparison.txt');
while(<COMPARISON_FILE>) {
    if(!/^\/\/.*/) {
        $comparison_file_as_string .= $_; 
    }
}
close(COMPARISON_FILE);

# Test files
my $file_ruleset = Parse::YARA->new(file => 't/FromYARADocumentation.txt');
isa_ok($file_ruleset, 'Parse::YARA');

my $no_includes_ruleset = Parse::YARA->new(file => 't/FromYARADocumentation.txt', disable_includes => 1);
isa_ok($no_includes_ruleset, 'Parse::YARA');
    
my $file_as_string = $file_ruleset->as_string();
my $no_includes_as_string = $no_includes_ruleset->as_string();
ok($file_as_string ne $no_includes_as_string);
ok($no_includes_as_string eq $comparison_file_as_string);

my $read_file_ruleset = Parse::YARA->new();
$read_file_ruleset->read_file('t/FromYARADocumentation.txt');
my $read_file_as_string = $read_file_ruleset->as_string();

my $read_file_no_includes = Parse::YARA->new(disable_includes => 1);
$read_file_no_includes->read_file('t/FromYARADocumentation.txt');
my $read_file_no_includes_as_string = $read_file_no_includes->as_string();
ok($read_file_as_string ne $read_file_no_includes_as_string);
ok($file_as_string eq $read_file_as_string);
ok($no_includes_as_string eq $read_file_no_includes_as_string);

# Test get_referenced_rule($rule_id)
my @referenced_rules = $file_ruleset->get_referenced_rule('Rule2');
ok(scalar(@referenced_rules) == 1);
ok($referenced_rules[0] eq "Rule1");

# Test position_rule($rule_id, $position_reference, $position)
$file_ruleset->position_rule('ExternalVariableExample4', 'before', 'ExternalVariableExample1');
ok($file_ruleset->{rules_knot}->Indices('ExternalVariableExample4') < $file_ruleset->{rules_knot}->Indices('ExternalVariableExample1'));
$file_ruleset->position_rule('ExternalVariableExample2', 'after', 'ExternalVariableExample3');
ok($file_ruleset->{rules_knot}->Indices('ExternalVariableExample2') > $file_ruleset->{rules_knot}->Indices('ExternalVariableExample3'));

# Generate a hashref to use as testing
my $rule_element_hashref;
my $rule_element_hashref_knot = tie(%{$rule_element_hashref}, 'Tie::IxHash');
my $meta_hashref;
my $meta_hashref_knot = tie(%{$meta_hashref}, 'Tie::IxHash');
my $strings_hashref;
my $strings_hashref_knot = tie(%{$strings_hashref}, 'Tie::IxHash');
$meta_hashref->{meta_name2} = 'meta_val2';
$meta_hashref->{meta_name1} = 'meta_val1';
$strings_hashref->{'$str_name2'} = { value => 'str_val2', type => 'text' };
$strings_hashref->{'$str_name1'} = { value => 'str_val1', type => 'text' };
$rule_element_hashref = {
                         modifier => 'global',
                         rule_id => 'test_rule',
                         tag => [
                                 'tag1',
                                 'tag2'
                                ],
                         meta => $meta_hashref,
                         strings => $strings_hashref,
                         condition => 'true'
                        };

# Test creating a rule calling new(rulehash => $rule_element_hashref) on the above hash ref
my $hash_ruleset = Parse::YARA->new(rulehash => $rule_element_hashref);
isa_ok($hash_ruleset, 'Parse::YARA');
ok($hash_ruleset->as_string eq $rule_string);

# Copy hash for testing
my $test_ruleset = $hash_ruleset;

# Test set_rule_modifier($rule_id, $modifier)
$test_ruleset->set_rule_modifier('test_rule', 'private');
ok($test_ruleset->{rules}->{test_rule}->{modifier} eq 'private');
$test_ruleset->set_rule_modifier('test_rule', 'global');
ok($test_ruleset->{rules}->{test_rule}->{modifier} eq 'global');
$test_ruleset->set_rule_modifier('test_rule', undef);
ok(!$test_ruleset->{rules}->{test_rule}->{modifier});
$test_ruleset->set_rule_modifier('test_rule', 'invalid');
ok(!$test_ruleset->{rules}->{test_rule}->{modifier});

# Test set_condition($rule_id, $condition)
$test_ruleset->set_condition('test_rule', 'false');
ok($test_ruleset->{rules}->{test_rule}->{condition} eq 'false');
$test_ruleset->set_condition('test_rule', 'condition');
ok($test_ruleset->{rules}->{test_rule}->{condition} eq 'false');

# Test add_tag($rule_id, $tag)
$test_ruleset->add_tag('test_rule', 'newTag');
$test_ruleset->add_tag('test_rule', 'entrypoint');
my %tags = map { $_ => 1 } @{$test_ruleset->{rules}->{test_rule}->{tags}};
ok(exists($tags{newTag}));
ok(!exists($tags{entrypoint}));

# Test remove_tag($rule_id, $tag)
$test_ruleset->remove_tag('test_rule', 'newTag');
%tags = map { $_ => 1 } @{$test_ruleset->{rules}->{test_rule}->{tags}};
ok(!exists($tags{newTag}));

# Test add_meta($rule_id, $meta_name, $meta_val)
$test_ruleset->add_meta('test_rule', 'metaTest', 'metaTestVal');
ok($test_ruleset->{rules}->{test_rule}->{meta}->{metaTest} eq 'metaTestVal');
$test_ruleset->add_meta('test_rule', 'condition', 'metaTestVal2');
ok(!exists($test_ruleset->{rules}->{test_rule}->{meta}->{condition}));

# Test modify_meta($rule_id, $meta_name, $meta_val)
$test_ruleset->modify_meta('test_rule', 'metaTest', 'modifiedMetaTestVal');
ok($test_ruleset->{rules}->{test_rule}->{meta}->{metaTest} eq 'modifiedMetaTestVal');

# Test remove_meta($rule_id, $meta_name)
$test_ruleset->remove_meta('test_rule', 'metaTest');
ok(!exists($test_ruleset->{rules}->{test_rule}->{meta}->{metaTest}));

# Test add_string($rule_id, $str_name, $str_val, $str_type)
$test_ruleset->add_string('test_rule', '$stringTest', 'stringTestVal1', 'text');
$test_ruleset->add_string('test_rule', '$stringTest', 'stringTestVal2', 'text');
ok($test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{value} eq 'stringTestVal1');
$test_ruleset->add_string('test_rule', 'stringTest', 'stringTestVal2', 'text');
ok(!exists($test_ruleset->{rules}->{test_rule}->{strings}->{stringTest}));

# Test add_string_modifier($rule_id, $str_name, $modifier)
$test_ruleset->add_string_modifier('test_rule', '$stringTest', 'wide');
$test_ruleset->add_string_modifier('test_rule', '$stringTest', 'ascii');
$test_ruleset->add_string_modifier('test_rule', '$stringTest', 'nocase');
$test_ruleset->add_string_modifier('test_rule', '$stringTest', 'fullword');
$test_ruleset->add_string_modifier('test_rule', '$stringTest', 'invalid');
ok(my %mods = map { $_ => 1; } @{$test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{modifier}});
ok(exists($mods{wide}));
ok(exists($mods{ascii}));
ok(exists($mods{nocase}));
ok(exists($mods{fullword}));
ok(!exists($mods{invalid}));

# Test remove_string_modifier($rule_id, $str_name, $modifier)
$test_ruleset->remove_string_modifier('test_rule', '$stringTest', 'wide');
ok(!grep(/wide/, @{$test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{modifier}}));
$test_ruleset->remove_string_modifier('test_rule', '$stringTest', 'ascii');
ok(!grep(/wide/, @{$test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{modifier}}));
$test_ruleset->remove_string_modifier('test_rule', '$stringTest', 'nocase');
ok(!grep(/wide/, @{$test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{modifier}}));
$test_ruleset->remove_string_modifier('test_rule', '$stringTest', 'fullword');
ok(!grep(/wide/, @{$test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{modifier}}));

# Test the keyword 'all' for string modifiers
$test_ruleset->add_string_modifier('test_rule', '$stringTest', 'all');
%mods = map { $_ => 1; } @{$test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{modifier}};
ok(exists($mods{wide}) and exists($mods{ascii}) and exists($mods{nocase}) and exists($mods{fullword}));
$test_ruleset->remove_string_modifier('test_rule', '$stringTest', 'all');
%mods = map { $_ => 1; } @{$test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{modifier}};
ok(!exists($mods{wide}) and !exists($mods{ascii}) and !exists($mods{nocase}) and !exists($mods{fullword}));

# Test modify_string($rule_id, $str_name, $str_val)
$test_ruleset->modify_string('test_rule', '$stringTest', 'modifiedStringTestVal');
ok($test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}->{value} eq 'modifiedStringTestVal');

# Test remove_string($rule_id, $str_name)
$test_ruleset->remove_string('test_rule', '$stringTest');
ok(!exists($test_ruleset->{rules}->{test_rule}->{strings}->{'$stringTest'}));

# Test add_anonymous_string($rule_id, $str_val, $str_type)
$test_ruleset->add_anonymous_string('test_rule', 'anonStringTestVal1', 'text');
ok($test_ruleset->{rules}->{test_rule}->{strings}->{'$'}->{value} eq 'anonStringTestVal1');
$test_ruleset->add_anonymous_string('test_rule', 'anonStringTestVal2', 'text');
ok($test_ruleset->{rules}->{test_rule}->{strings}->{'$$'}->{value} eq 'anonStringTestVal2');

# Test remove_anonymous_string($rule_id, $str_val)
$test_ruleset->remove_string('test_rule', '$');
ok(exists($test_ruleset->{rules}->{test_rule}->{strings}->{'$'}) and exists($test_ruleset->{rules}->{test_rule}->{strings}->{'$$'}));
$test_ruleset->remove_anonymous_string('test_rule', 'anonStringTestVal1');
ok(!exists($test_ruleset->{rules}->{test_rule}->{strings}->{'$'}) and exists($test_ruleset->{rules}->{test_rule}->{strings}->{'$$'}));
