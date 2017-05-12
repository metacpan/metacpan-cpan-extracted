
use Test::More tests => 16;

use_ok( 'Sort::Half::Maker', qw(make_halfsort) );

{

    my $sub = make_halfsort( start => [qw(x y z)] );
    ok( defined $sub, "defined return" );
    isa_ok( $sub, 'CODE' );

    my @list = sort $sub qw(a y c x z b);
    is_deeply( \@list, [qw(x y z a b c)] );
}

{
    my $sub = make_halfsort(
        start => [qw(x y z)],
        end   => [qw(a b c)],
    );
    ok( defined $sub, "defined return" );
    isa_ok( $sub, 'CODE' );

    my @list = sort $sub qw(a y f h w z b t x);
    is_deeply( \@list, [qw(x y z f h t w a b)] );
}

{
    my $sub = make_halfsort(
        start    => [qw(x y z)],
        fallback => sub ($$) { uc $_[0] cmp uc $_[1] },
    );
    ok( defined $sub, "defined return" );
    isa_ok( $sub, 'CODE' );

    my @list = sort $sub qw(b a c A z x y b);
  SKIP: {
        skip '5.6 sort is not stable', 1 if $] < 5.008;
        is_deeply( \@list, [qw(x y z a A b b c)] );
    }

}

{
    # BUG fixed: in 0.02, using start = qw(a b a) sorted like qw(b a)
    #           instead of qw(a b)

    my $sub = make_halfsort( start => [qw(a b a)], );
    ok( defined $sub, "defined return" );
    isa_ok( $sub, 'CODE' );

    my @list = sort $sub qw(a b);
    is_deeply( \@list, [qw(a b)],
        'start => [ qw(a b a) ] sorts like [ qw(a b) ]' );

}

{
    # BUG fixed: in 0.02, the same bug above with 'end' argument

    my $sub = make_halfsort( end => [qw(x y z x)], );
    ok( defined $sub, "defined return" );
    isa_ok( $sub, 'CODE' );

    my @list = sort $sub qw(y z x);
    is_deeply( \@list, [qw(x y z)],
        'end => [ qw(x y z x) ] sorts like [ qw(x y z) ]' );

}
