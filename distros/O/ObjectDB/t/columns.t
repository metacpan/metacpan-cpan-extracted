use strict;
use warnings;
use lib 't/lib';

use Test::More;

use Table;

subtest 'should set columns via constructor' => sub {
    my $row = _build(foo => 'bar');

    is($row->get_column('foo'), 'bar');
};

subtest 'should set columns overwrite early set columns' => sub {
    my $row = _build(foo => 'bar');

    $row->set_columns(foo => 'baz');

    is($row->get_column('foo'), 'baz');
};

subtest 'should set column overwrites undef value' => sub {
    my $row = _build();

    $row->set_column(foo => undef);
    $row->set_column(foo => 'bar');

    is($row->get_column('foo'), 'bar');
};

subtest 'should not null columns return empty strings' => sub {
    my $row = _build(foo => undef);

    is($row->get_column('foo'), '');
};

subtest 'should null columns return undef' => sub {
    my $row = _build();

    is($row->get_column('nullable'), undef);
};

subtest 'should default columns return default values' => sub {
    my $row = _build();

    is($row->get_column('with_default'), '123');
};

subtest 'should virtual columns are not set via constructor' => sub {
    my $row = _build(unknown => 'bar');

    is($row->get_column('unknown'), undef);
};

subtest 'should virtual columns are set via methods' => sub {
    my $row = _build();

    $row->set_column(unknown => 'bar');

    is($row->get_column('unknown'), 'bar');
};

done_testing;

sub _build {
    Table->new(@_);
}
