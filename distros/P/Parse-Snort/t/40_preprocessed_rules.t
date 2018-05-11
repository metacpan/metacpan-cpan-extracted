use strict;
use warnings;

use Test::More;
use Parse::Snort;

my $text_rule
    = 'alert ( msg: "DNP3_RESERVED_FUNCTION"; sid:6; gid:145; rev: 1; metadata: rule-type preproc; classtype:protocol-command-decode; )';

my $rule_data = {
    preprocessed => 1,
    action       => 'alert',
    state        => 1,
    opts         => [
        ['msg',       '"DNP3_RESERVED_FUNCTION"'],
        ['sid',       '6'],
        ['gid',       '145'],
        ['rev',       '1'],
        ['metadata',  'rule-type preproc'],
        ['classtype', 'protocol-command-decode'],
    ],
};

my $rule = Parse::Snort->new();
$rule->parse($text_rule);
is_deeply($rule, $rule_data, "parse text rule");

done_testing();
