use Test2::V0;
use Test::LeakTrace;

plan skip_all => 'Devel::Cover' if $INC{'Devel/Cover.pm'};

use Sub::Meta;
use Sub::Meta::Library;
use Types::Standard -types;

no_leaks_ok {
    my $meta = Sub::Meta->new;
    undef($meta);
} 'Sub::Meta->new';

no_leaks_ok {
    my $meta = Sub::Meta->new(
        args    => [Int, Int],
        returns => Int,
    );
    undef($meta);
} 'Sub::Meta->new(...)';

no_leaks_ok {
    my $meta = Sub::Meta::Parameters->new;
    undef($meta);
} 'Sub::Meta::Parameters->new';

no_leaks_ok {
    my $meta = Sub::Meta::Parameters->new(args => [Int]);
    undef($meta);
} 'Sub::Meta::Parameters->new(...)';

no_leaks_ok {
    my $meta = Sub::Meta::Param->new;
    undef($meta);
} 'Sub::Meta::Param->new';

no_leaks_ok {
    my $meta = Sub::Meta::Param->new(Int);
    undef($meta);
} 'Sub::Meta::Param->new(...)';

no_leaks_ok {
    my $meta = Sub::Meta::Returns->new;
    undef($meta);
} 'Sub::Meta::Returns->new';

no_leaks_ok {
    my $meta = Sub::Meta::Returns->new(Int);
    undef($meta);
} 'Sub::Meta::Returns->new(...)';

subtest 'use Library' => sub {

    leaks_cmp_ok {
        my $sub = sub {};
        my $meta = Sub::Meta->new(sub => $sub);
        Sub::Meta::Library->register($sub, $meta);
        undef($meta);
    } '<=', 1, 'Sub::Meta->new & use Library';


    sub hello {}
    leaks_cmp_ok {
        my $meta = Sub::Meta->new(sub => \&hello);
        Sub::Meta::Library->register(\&hello, $meta);
        undef($meta);
    } '<=', 1, 'Sub::Meta->new & use Library';

    leaks_cmp_ok {
        my $sub = sub {};
        my $meta = Sub::Meta->new(sub => $sub, args => [Int]);
        Sub::Meta::Library->register($sub, $meta);
        undef($meta);
    } '<=', 1, 'Sub::Meta->new(...) & use Library';
};

done_testing;
