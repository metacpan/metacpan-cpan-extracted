use Test2::V0;
use Devel::Refcount qw(refcount);

use Sub::Meta;
use Sub::Meta::Library;

sub hello {}

my $orig_count = refcount(\&hello);

note "COUNT: $orig_count";

{
    my $meta = Sub::Meta->new(
        sub => \&hello,
    );

    is refcount($meta->sub), $orig_count, 'sub is weaken';

    Sub::Meta::Library->register($meta->sub, $meta);

    is refcount($meta->sub), $orig_count;
}

is refcount(\&hello), $orig_count;

done_testing;
