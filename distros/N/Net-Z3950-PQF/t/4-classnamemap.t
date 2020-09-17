use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Net::Z3950::PQF') };

my $parser = new Net::Z3950::PQF({
    'Net::Z3950::PQF::AndNode' => 'Net::Z3950::RPN::And',
    'Net::Z3950::PQF::OrNode' => 'Net::Z3950::RPN::Or',
    'Net::Z3950::PQF::NotNode' => 'Net::Z3950::RPN::AndNot',
    'Net::Z3950::PQF::TermNode' => 'Net::Z3950::RPN::Term',
    'Net::Z3950::PQF::RsetNode' => 'Net::Z3950::RPN::RSID',
});
ok(defined $parser, "created parser");

my $query = '@and @attr 1=21 history @or @attr 1=4 churchill @set r42';
my $node = $parser->parse($query);
ok(defined $node, "parsed: $query");

is2(ref $node, 'Net::Z3950::RPN::And');

my $sub1 = $node->{sub}->[0];
is2(ref $sub1, 'Net::Z3950::RPN::Term');
is2($sub1->{value}, 'history');

my $sub2 = $node->{sub}->[1];
is2(ref $sub2, 'Net::Z3950::RPN::Or');

my $subA1 = $sub2->{sub}->[0];
is2(ref $subA1, 'Net::Z3950::RPN::Term');
is2($subA1->{value}, 'churchill');

my $subA2 = $sub2->{sub}->[1];
is2(ref $subA2, 'Net::Z3950::RPN::RSID');
is2($subA2->{value}, 'r42');


sub is2 {
    my($got, $expected) = @_;
    return is($got, $expected, $expected);
}
