use strict;
use warnings;
use utf8;
use Test::More;
use Perl6::PVIP;

{
    my $node = Perl6::PVIP->new->parse_string('say(1)');
    isa_ok($node, 'Perl6::PVIP::Node');
    is($node->type, PVIP_NODE_STATEMENTS);
    note $node->as_sexp;
    is($node->name, 'statements');
    isa_ok($node->value, 'ARRAY');
}

{
    my $n = Perl6::PVIP->new->parse_string(q!''!);
    is($n->value->[0]->value, '');
}

{
    my $n = Perl6::PVIP->new->parse_string(q!'hoge'!);
    is_deeply($n->perl, +{
        type => PVIP_NODE_STATEMENTS,
        line_number => 1,
        value => [
            +{
                type => PVIP_NODE_STRING,
                line_number => 0,
                value => 'hoge',
            }
        ],
    });
}

done_testing;

