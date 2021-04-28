use Test2::V0;

use Sub::Meta;
use Sub::Meta::Test qw(test_is_same_interface);

my $p1 = Sub::Meta::Parameters->new(args => ['Str']);
my $p2 = Sub::Meta::Parameters->new(args => ['Int']);

my $r1 = Sub::Meta::Returns->new('Str');
my $r2 = Sub::Meta::Returns->new('Int');

my $obj = bless {} => 'Some';

subtest "no args: {  }" => sub {
    my $meta = Sub::Meta->new({ });
    my @tests = (
        relax_pass => 'invalid subname'    => { subname => 'foo' },
        pass       => 'valid'              => {  },
    );
    test_is_same_interface($meta, @tests);
};

subtest "{ subname => 'foo' }" => sub {
    my $meta = Sub::Meta->new({ subname => 'foo' });
    my @tests = (
        fail       => 'other is undef'         => undef,
        fail       => 'other is not Sub::Meta' => $obj,
        fail       => 'invalid subname'        => { subname => 'bar' },
        fail       => 'undef subname'          => { subname => undef },
        relax_pass => 'invalid parameters'     => { subname => 'foo', parameters => $p1 },
        relax_pass => 'invalid returns'        => { subname => 'foo', returns => $r1 }, ,
        pass       => 'valid'                  => { subname => 'foo' },
        pass       => 'valid w/ stashname'     => { fullname => 'path::foo' },
    );
    test_is_same_interface($meta, @tests);
};

subtest "one args: { parameters => \$p1 }" => sub {
    my $meta = Sub::Meta->new({ parameters => $p1 });
    my @tests = (
        fail       => 'invalid subname'    => { subname => 'foo' },
        fail       => 'invalid parameters' => { parameters => $p2 },
        fail       => 'no parameters'      => {  },
        relax_pass => 'invalid subname'    => { parameters => $p1, subname => 'foo' }, 
        relax_pass => 'invalid returns'    => { parameters => $p1, returns => $r1 }, 
        pass       => 'valid'              => { parameters => $p1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "returns: { returns => \$r1 }" => sub {
    my $meta = Sub::Meta->new({ returns => $r1 });
    my @tests = (
        fail       => 'invalid returns'    => { returns => $r2 },
        fail       => 'no returns'         => {  },
        relax_pass => 'invalid subname'    => { returns => $r1, subname => 'foo' }, 
        relax_pass => 'invalid parameters' => { returns => $r1, parameters => $p1 },
        pass       => 'valid'              => { returns => $r1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "mixed case: { subname => 'foo', parameters => \$p1, returns => \$r1 }" => sub {
    my $meta = Sub::Meta->new({ subname => 'foo', parameters => $p1, returns => $r1 });
    my @tests = (
        fail => 'invalid subname'    => { subname => 'bar', parameters => $p1, returns => $r1 }, 
        fail => 'invalid parameters' => { subname => 'foo', parameters => $p2, returns => $r1 }, 
        fail => 'invalid returns'    => { subname => 'foo', parameters => $p1, returns => $r2 }, 
        pass => 'valid'              => { subname => 'foo', parameters => $p1, returns => $r1 }, 
        pass => 'valid w/ stashname' => { subname => 'foo', parameters => $p1, returns => $r1, stashname => 'main' },
        pass => 'valid w/ attribute' => { subname => 'foo', parameters => $p1, returns => $r1, attribute => ['method'] },
        pass => 'valid w/ prototype' => { subname => 'foo', parameters => $p1, returns => $r1, prototype => '$' },
    );
    test_is_same_interface($meta, @tests);
};

subtest "is_method: { subname => 'foo', is_method => !!1 }" => sub {
    my $meta = Sub::Meta->new({ subname => 'foo', is_method => !!1 });
    my @tests = (
        fail => 'invalid method'        => { subname => 'foo', is_method => !!0 },
        fail => 'default is not method' => { subname => 'foo' }, 
        pass => 'valid method'          => { subname => 'foo', is_method => !!1 }, 
    );
    test_is_same_interface($meta, @tests);
};

subtest "not method: { subname => 'foo', is_method => !!0 }" => sub {
    my $meta = Sub::Meta->new({ subname => 'foo', is_method => !!0 });
    my @tests = (
        fail => 'invalid method'                => { subname => 'foo', is_method => !!1 },
        pass => 'valid method'                  => { subname => 'foo', is_method => !!0 },
        pass => 'valid method / default case'   => { subname => 'foo' },
    );
    test_is_same_interface($meta, @tests);
};

subtest "method: { subname => 'foo', is_method => !!1, parameters => \$p1 }" => sub {
    my $meta = Sub::Meta->new({ subname => 'foo', is_method => !!1, parameters => $p1 });
    my @tests = (
        fail => 'invalid method'      => { subname => 'foo', is_method => !!0, parameters => $p1 },
        fail => 'invalid method'      => { subname => 'foo',                   parameters => $p1 },
        fail => 'invalid parameters'  => { subname => 'foo', is_method => !!1, parameters => $p2 },
        pass => 'valid method'        => { subname => 'foo', is_method => !!1, parameters => $p1 },
    );
    test_is_same_interface($meta, @tests);
};

done_testing;
