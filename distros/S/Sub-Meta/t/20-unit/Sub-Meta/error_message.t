use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(test_error_message);

my $p1 = Sub::Meta::Parameters->new(args => ['Str']);
my $p2 = Sub::Meta::Parameters->new(args => ['Int']);
my $r1 = Sub::Meta::Returns->new('Str');
my $r2 = Sub::Meta::Returns->new('Int');

subtest "{ subname => 'foo' }" => sub {
    my $meta = Sub::Meta->new({ subname => 'foo' });
    my @tests = (
        fail       => undef,                                   qr/^other must be Sub::Meta. got: Undef/,
        fail       => (bless {} => 'Some'),                    qr/^other must be Sub::Meta. got: Some/,
        fail       => { subname => 'bar' },                    qr/^invalid subname. got: bar, expected: foo/,
        fail       => { subname => undef },                    qr/^invalid subname. got: , expected: foo/,
        fail       => { subname => 'foo', is_method => 1 },    qr/^invalid method/,
        relax_pass => { subname => 'foo', parameters => $p1 }, qr/^invalid parameters:/,
        relax_pass => { subname => 'foo', returns => $r1 },    qr/^invalid returns:/,
        pass       => { subname => 'foo' },                    qr//, # valid
        pass       => { fullname => 'path::foo' },             qr//, # valid
    );
    test_error_message($meta, @tests);
};

subtest "no args: {}" => sub {
    my $meta = Sub::Meta->new();
    my @tests = (
        relax_pass => { subname => 'foo' }, qr/^should not have subname. got: foo/,
        pass       => { },                  qr//, # valid
    );
    test_error_message($meta, @tests);
};

subtest "method: { is_method => 1 }" => sub {
    my $meta = Sub::Meta->new({ is_method => 1 });
    my @tests = (
        fail => { is_method => 0 }, qr/^invalid method/,
        pass => { is_method => 1 }, qr//, # valid
    );
    test_error_message($meta, @tests);
};

subtest "p1: { parameters => \$p1 }" => sub {
    my $meta = Sub::Meta->new({ parameters => $p1 });
    my @tests = (
        fail => { parameters => $p2 }, qr/^invalid parameters/,
        fail => {  },                  qr/^invalid parameters/,
        pass => { parameters => $p1 }, qr//, #valid
    );
    test_error_message($meta, @tests);
};

subtest "{ returns => \$r1 }" => sub {
    my $meta = Sub::Meta->new({ returns => $r1 });
    my @tests = (
        fail => { returns => $r2 }, qr/^invalid returns/,
        fail => {  },               qr/^invalid returns/,
        pass => { returns => $r1 }, qr//, #valid
    );
    test_error_message($meta, @tests);
};

done_testing;
