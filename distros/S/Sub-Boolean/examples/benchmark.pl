use strict;
use warnings;
no warnings 'once';
use Benchmark qw( cmpthese );
use Sub::Boolean qw( make_true );

*naive = sub { !!1 };
make_true "main::with_xs";

cmpthese( -1, {
	impl_naive   => q{ my @r = grep !::naive($_),   1 .. 1_000_000 },
	impl_with_xs => q{ my @r = grep !::with_xs($_), 1 .. 1_000_000 },
} );

__END__
               Rate   impl_naive impl_with_xs
impl_naive   6.60/s           --         -60%
impl_with_xs 16.7/s         152%           --