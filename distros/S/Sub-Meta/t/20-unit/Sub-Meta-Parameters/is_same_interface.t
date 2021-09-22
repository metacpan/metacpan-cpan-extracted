use Test2::V0;

use Sub::Meta::Parameters;
use Sub::Meta::Test qw(test_is_same_interface);

my $p1             = Sub::Meta::Param->new("Str");
my $p2             = Sub::Meta::Param->new("Int");
my $invocant       = Sub::Meta::Param->new(invocant => 1);
my $invocant_self  = Sub::Meta::Param->new(invocant => 1, name => '$self');
my $invocant_class = Sub::Meta::Param->new(invocant => 1, name => '$class');
my $slurpy         = Sub::Meta::Param->new("Slurpy");

subtest "{ args => [] }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [] });
    my @tests = (
        fail       => 'invalid other'   => undef,
        fail       => 'invalid obj'     => (bless {} => 'Some'),
        relax_pass => 'invalid args'    => { args => [$p1], slurpy => undef, nshift => 0 },
        relax_pass => 'not need slurpy' => { args => [], slurpy => $slurpy, nshift => 0 },
        fail       => 'invalid nshift'  => { args => [], slurpy => undef, nshift => 1 },
        pass       => 'valid'           => { args => [], slurpy => undef, nshift => 0 },
        pass       => 'valid'           => { args => [], nshift => 0 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "one args: { args => [\$p1], nshift => 0 }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [$p1], nshift => 0 });
    my @tests = (
        fail       => 'invalid args'  => { args => [$p2], slurpy => undef, nshift => 0 },
        relax_pass => 'too many args' => { args => [$p1, $p2], slurpy => undef, nshift => 0 },
        fail       => 'too few args'  => { args => [], slurpy => undef, nshift => 0 },
        pass       => 'valid'         => { args => [$p1], nshift => 0 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "two args: { args => [$p1, $p2], nshift => 0 }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [$p1, $p2], nshift => 0 });
    my @tests = (
        fail       => 'invalid args'  => { args => [$p2, $p1], slurpy => undef, nshift => 0 },
        relax_pass => 'too many args' => { args => [$p1, $p2, $p1], slurpy => undef, nshift => 0 },
        fail       => 'too few args'  => { args => [$p1], slurpy => undef, nshift => 0 },
        pass       => 'valid'         => { args => [$p1, $p2], nshift => 0 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "slurpy: { args => [], slurpy => $slurpy, nshift => 0 }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [], slurpy => $slurpy, nshift => 0 });
    my @tests = (
        fail => 'invalid args'   => { args => [$p1], slurpy => undef, nshift => 0 },
        fail => 'invalid slurpy' => { args => [], slurpy => undef, nshift => 0 },
        fail => 'invalid nshift' => { args => [], slurpy => $slurpy, nshift => 1 },
        pass => 'valid'          => { args => [], slurpy => $slurpy, nshift => 0 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "empty slurpy: { args => [], nshift => 0 }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [], nshift => 0 });
    my @tests = (
        fail       => 'invalid'         => { args => [], nshift => 1 },
        relax_pass => 'not need args'   => { args => [$p1], nshift => 0 },
        relax_pass => 'not need slurpy' => { args => [], slurpy => 'Str', nshift => 0 },
        pass       => 'valid'           => { args => [], nshift => 0 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "nshift: { args => [\$p1], nshift => 1 }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [$p1], nshift => 1 });
    my @tests = (
        fail       => 'invalid args'    => { args => [$p2], slurpy => undef, nshift => 1 },
        relax_pass => 'not need slurpy' => { args => [$p1], slurpy => $slurpy, nshift => 1 },
        relax_pass => 'too many args'   => { args => [$p1, $p2], slurpy => undef, nshift => 1 },
        pass       => 'valid'           => { args => [$p1], nshift => 1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "slurpy & nshift: { args => [\$p1], slurpy => \$slurpy, nshift => 1 }" => sub {

    my $meta = Sub::Meta::Parameters->new({ args => [$p1], slurpy => $slurpy, nshift => 1 });
    my @tests = (
        fail       => 'invalid args'          => { args => [$p2], slurpy => $slurpy, nshift => 1 },
        fail       => 'invalid slurpy'        => { args => [$p1], slurpy => undef, nshift => 1 },
        fail       => 'invalid nshift'        => { args => [$p1], slurpy => $slurpy, nshift => 0 },
        relax_pass => 'too many args'         => { args => [$p1, $p2], slurpy => $slurpy, nshift => 1 },
        relax_pass => 'invalid invocant name' => { args => [$p1], slurpy => $slurpy, invocant => $invocant_self },
        pass       => 'valid'                 => { args => [$p1], slurpy => $slurpy, nshift => 1 },
        pass       => 'valid'                 => { args => [$p1], slurpy => $slurpy, invocant => $invocant },
    );
    test_is_same_interface($meta, @tests);
};

subtest "default invocant: { args => [], invocant => \$invocant }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [], invocant => $invocant });
    my @tests = (
        relax_pass => 'invalid invocant name' => { args => [], invocant => $invocant_class },
        pass       => 'valid'                 => { args => [], invocant => $invocant },
        pass       => 'valid nshift'          => { args => [], nshift => 1 },
    );
    test_is_same_interface($meta, @tests);
};

subtest "invocant: { args => [], invocant => \$invocant_self }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [], invocant => $invocant_self });
    my @tests = (
        fail => 'invalid nshift'    => { args => [], nshift => 0 },
        fail => 'invalid nshift'    => { args => [], nshift => 1 },
        fail => 'invalid invocant'  => { args => [], invocant => $invocant_class },
        fail => 'invalid invocant'  => { args => [$invocant_self] },
        pass => 'valid'             => { args => [], invocant => $invocant_self },
    );
    test_is_same_interface($meta, @tests);
};

done_testing;
