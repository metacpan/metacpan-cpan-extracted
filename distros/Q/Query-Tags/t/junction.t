use v5.16;
use Test::More;
use Scalar::Util qw(blessed);
use Pegex;
use Query::Tags::Grammar;
use Query::Tags::To::AST;

sub j {
    state $parser = Pegex::Parser->new(
        grammar  => Query::Tags::Grammar->new,
        receiver => Query::Tags::To::AST->new,
    );
    my ($q, $arg) = @_;
    $parser->parse($q, 'junction')->test($arg)
}

# All junction
ok j(q[&</a/ /b/ /c/>]      => "abc");
ok j(q[~&</a/ /b/ /c/>]     => "ab");
ok j(q[&</a/ /b/ /c?/>]     => "ab");
ok j(q[&</[a-z]/>]          => "x");
ok j(q[~&</[a-z]/ /[0-9]/>] => "x");

# Any junction
ok j(q[|<a b c>]        => "a");
ok j(q[~|<a b c>]       => "ab");
ok j(q[|</a/ /b/ /c/>]  => "ab");
ok j(q[~|</a/ /b/ /c/>] => "x");
ok j(q[|</\w/ /\d/>]    => "x");
ok j(q[|</\w/ /\d/>]    => "0");

# None junction
ok j(q[~!</a/ /b/ /c/>] => "abc");
ok j(q[!<a b c>]        => "abc");
ok j(q[!<a b c>]        => "0");

done_testing;
