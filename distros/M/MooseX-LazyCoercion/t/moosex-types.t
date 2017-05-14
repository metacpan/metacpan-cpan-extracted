use Test::More;
BEGIN {
    eval { require MooseX::Types::DateTime };
    if ($@) {
        die $@;
        plan skip_all => "MooseX::Types::DateTime not installed";
    } else {
        plan tests => 4;
    }
}
{
    package My::Foo;
    use Moose;
    use MooseX::Types::DateTime qw(DateTime);
    use MooseX::LazyCoercion;

    has_lazily_coerced x => (
        is => 'ro',
        isa => DateTime,
    );
}

use Data::Dumper;
my $time = time();
# my $time = \ "FOO";
my $f = My::Foo->new(
    x => $time,
);
is $f->__x, $time;
ok ! $f->{x};
ok $f->x;
is $f->x->epoch, $time;
