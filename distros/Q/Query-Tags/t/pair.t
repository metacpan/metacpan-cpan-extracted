use v5.16;
use Test::More;
use Scalar::Util qw(blessed);
use Pegex;
use Query::Tags::Grammar;
use Query::Tags::To::AST;

sub p {
    state $parser = Pegex::Parser->new(
        grammar  => Query::Tags::Grammar->new,
        receiver => Query::Tags::To::AST->new,
    );
    my ($q, $arg) = @_;
    $parser->parse($q, 'pair')->test($arg)
}

# Matching key-value pairs
ok  p(q[:abc'def']    => { abc => 'def' });
ok  p(q[:abc/[def]/]  => { abc => 'xfx' });
ok  p(q[:abc|<d e f>] => { abc => 'e'   });

# Testing existence of keys
my $h = { xuz => 0 };
ok  p(q[:xuz] => $h);
ok !p(q[:xuf] => $h);

package Tester {
    sub xuf { undef }
};

# Blessed objects
my $obj = bless $h, 'Tester';
ok  p(q[:xuz] => $obj);
ok  p(q[:xuf] => $obj);

done_testing;
