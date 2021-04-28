use Test2::V0;

use Sub::Meta::Parameters;
use Sub::Meta::Test qw(test_error_message);

my $Slurpy = Sub::Meta::Param->new("Slurpy");
my $Str = Sub::Meta::Param->new("Str");
my $Int = Sub::Meta::Param->new("Int");

subtest "{ args => [] }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [] });
    my @tests = (
        fail        => undef,                                        qr/^must be Sub::Meta::Parameters. got: /,
        fail        => (bless {} => 'Some'),                         qr/^must be Sub::Meta::Parameters\. got: Some/,
        relax_pass  => { args => [$Str] },                           qr/^invalid args length. got: 1, expected: 0/, 
        relax_pass  => { args => [], slurpy => $Slurpy },            qr/^should not have slurpy/, 
        fail        => { args => [], nshift => 1 },                  qr/^nshift is not equal. got: 1, expected: 0/, 
        pass        => { args => [] },                               qr//, # valid
        pass        => { args => [], slurpy => undef },              qr//, # valid
        pass        => { args => [], nshift => 0 },                  qr//, # valid
        pass        => { args => [], slurpy => undef, nshift => 0 }, qr//, # valid
    );
    test_error_message($meta, @tests);
};
 
subtest "one args: { args => [\$Str] }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [$Str] });
    my @tests = (
        fail => { args => [] },     qr/^invalid args length. got: 0, expected: 1/,
        fail => { args => [$Int] }, qr/^args\[0\] is invalid. got: Int, expected: Str/,
        pass => { args => [$Str] }, qr//, # valid
    );
    test_error_message($meta, @tests);
};
 
subtest "two args: { args => [\$Str, \$Int] }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [$Str, $Int] });
    my @tests = (
        fail => { args => [$Int, $Str] }, qr/^args\[0\] is invalid. got: Int, expected: Str/,
        fail => { args => [$Str, $Str] }, qr/^args\[1\] is invalid. got: Str, expected: Int/,
        pass => { args => [$Str, $Int] }, qr//, # valid
    );
    test_error_message($meta, @tests);
};
 
subtest "slurpy: { args => [], slurpy => \$Str }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [], slurpy => $Str });
    my @tests = (
        fail => { args => [] },                 qr/^invalid slurpy. got: , expected: Str/,
        fail => { args => [], slurpy => $Int }, qr/^invalid slurpy. got: Int, expected: Str/,
        pass => { args => [], slurpy => $Str }, qr//, # 'valid',
    );
    test_error_message($meta, @tests);
};
 
subtest "nshift: { args => [], nshift => 1 }" => sub {
    my $meta = Sub::Meta::Parameters->new({ args => [], nshift => 1 });
    my @tests = (
        fail => { args => [] },              qr/^nshift is not equal. got: 0, expected: 1/,
        fail => { args => [], nshift => 0},  qr/^nshift is not equal. got: 0, expected: 1/,
        pass => { args => [], nshift => 1 }, qr//, # 'valid',
    );
    test_error_message($meta, @tests);
};
 
done_testing;
