use Test::More tests => 4;
{
    package My::Foo;
    use Moose;
    use DateTime;
    use Moose::Util::TypeConstraints;
    use MooseX::LazyCoercion;

    subtype 'My::DateTime' => as 'DateTime';
    coerce 'My::DateTime' => from 'Int', via { DateTime->from_epoch( epoch => $_ ) };


    has_lazily_coerced x => (
        is => 'ro',
        isa => 'My::DateTime',
#        coerce_from => 'DateTime|Int',
    );
}

use Data::Dumper;

my $time = time();
#my $time = "FOO";
my $f = My::Foo->new(
    x => $time,
);


is $f->__x, $time;
ok ! $f->{x};
ok $f->x;
is $f->x->epoch, $time;
