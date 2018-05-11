use strict;
use warnings;
use Test::More;

use Parse::Snort;

my $rule
    = q{action proto src sport -> dst dport (msg:"the message";sid:42;gid:666;content:foo;rev:1;content:bar;metadata:my metadata;classtype:some class;priority:high;)};

my $object = Parse::Snort->new($rule);

my %expect = (
    msg       => '"the message"',
    sid       => 42,
    gid       => 666,
    rev       => 1,
    metadata  => 'my metadata',
    classtype => 'some class',
    priority  => 'high',

    proto     => 'proto',
    action    => 'action',
    src       => 'src',
    src_port  => 'sport',
    dst       => 'dst',
    dst_port  => 'dport',
    direction => '->',
);

foreach (sort keys %expect) {
    my $val;
    if ($object->can($_)) {
        $val = $object->$_;
    }
    else {
        $val = $object->get($_);
    }
    is($val, $expect{$_}, "$_ matches");
}

is($object->state, 1, "active rule");

done_testing;
