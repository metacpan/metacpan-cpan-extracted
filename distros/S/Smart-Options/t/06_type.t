use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Smart::Options;

subtest 'type check Int' => sub {
    my $opt = Smart::Options->new();
    $opt->type( foo => 'Int' );

    is $opt->parse(qw/--foo=3/)->{foo}, 3;
    throws_ok { $opt->parse(qw/--foo=3.14/) }
        qr/Value '3\.14' invalid for option foo\(Int\)/;
};

subtest 'type check Num' => sub {
    my $opt = Smart::Options->new();
    $opt->type( foo => 'Num' );

    is $opt->parse(qw/--foo=3.14/)->{foo}, 3.14;
    throws_ok { $opt->parse(qw/--foo=xxx/) }
        qr/Value 'xxx' invalid for option foo\(Num\)/;
};

subtest 'type check ArrayRef' => sub {
    my $opt = Smart::Options->new();
    $opt->type( foo => 'ArrayRef' );

    is_deeply $opt->parse(qw/--foo=a --foo=b/)->{foo}, [qw/a b/];
    is_deeply $opt->parse(qw/--foo=c/)->{foo}, [qw/c/];
    throws_ok { $opt->parse(qw/--foo.d=e/) }
        qr/Value 'HASH\(.+\)' invalid for option foo\(ArrayRef\)/;
};

subtest 'type check HashRef' => sub {
    my $opt = Smart::Options->new();
    $opt->type( foo => 'HashRef' );

    is_deeply $opt->parse(qw/--foo.a=10 --foo.b=5/)->{foo}, { a => 10, b => 5 };
    throws_ok { $opt->parse(qw/--foo=c/) }
        qr/Value 'c' invalid for option foo\(HashRef\)/;
};

done_testing;

