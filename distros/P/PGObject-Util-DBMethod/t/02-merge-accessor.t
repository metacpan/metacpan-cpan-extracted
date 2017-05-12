package FakeMoo;
use PGObject::Util::DBMethod;

sub new {
    return bless { myobjtype => 'FakeMoo' };
}

sub has {
    return 1;
}

sub extends {
    return 1;
}

sub id {
    my ($self, $id) = @_;
    $self->{id} = $id;
}

sub foo {
    my ($self, $foo) = @_;
    $self->{foo} = $foo;
}

my $funcreturns = {
    foo => { id => 1, foo => 2 },
    bar => { id => 2, foo => 'foo123'},
    baz => { id => 4 },
 foobar => { id => 3, foo => undef },
};

sub call_dbmethod {
    my $self = shift;
    my %args = @_;
    return $funcreturns->{$args{funcname}};
}

dbmethod fooz => (merge_back => 1, funcname => 'foo');
dbmethod bar => (merge_back => 1, funcname => 'bar');
dbmethod baz => (merge_back => 1, funcname => 'baz');
dbmethod foobar => (merge_back => 1, funcname => 'foobar');

package main;
use Test::More tests => 16;

ok $obj = FakeMoo->new, 'Fake Moo-like object created for accessor testing';
is $obj->{myobjtype}, 'FakeMoo', 'Object is expected type';
is $obj->{id}, undef, 'ID not yet set';
is $obj->{foo}, undef, 'foo not yet set';

ok $obj->fooz, 'Successfully ran fooz method';
is $obj->{id}, 1, 'ID now 1';
is $obj->{foo}, 2, 'foo now 2';

ok $obj->bar, 'Successfully ran bar method';
is $obj->{id}, 2, 'ID now 2';
is $obj->{foo}, 'foo123', 'foo now 123';

ok $obj->baz, 'Successfully ran baz method';
is $obj->{id}, 4, 'ID now 4';
is $obj->{foo}, 'foo123', 'foo unchanged';

ok $obj->foobar, 'Successfully ran foobar method';
is $obj->{id}, 3, 'ID now 3';
is $obj->{foo}, undef, 'foo now undef again';
