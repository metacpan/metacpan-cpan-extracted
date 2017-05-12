use Test::Spec;

use lib 't/lib';

use Table;

describe 'columns' => sub {
    it 'should set columns via constructor' => sub {
        my $row = _build_object(foo => 'bar');
        is($row->get_column('foo'), 'bar');
    };

    it 'should set columns overwrite early set columns' => sub {
        my $row = _build_object(foo => 'bar');
        $row->set_columns(foo => 'baz');
        is($row->get_column('foo'), 'baz');
    };

    it 'should set column overwrites undef value' => sub {
        my $row = _build_object();
        $row->set_column(foo => undef);
        $row->set_column(foo => 'bar');
        is($row->get_column('foo'), 'bar');
    };

    it 'should not null columns return empty strings' => sub {
        my $row = _build_object(foo => undef);
        is($row->get_column('foo'), '');
    };

    it 'should null columns return undef' => sub {
        my $row = _build_object();
        is($row->get_column('nullable'), undef);
    };

    it 'should default columns return default values' => sub {
        my $row = _build_object();
        is($row->get_column('with_default'), '123');
    };

    it 'should virtual columns are not set via constructor' => sub {
        my $row = _build_object(unknown => 'bar');
        is($row->get_column('unknown'), undef);
    };

    it 'should virtual columns are set via methods' => sub {
        my $row = _build_object();
        $row->set_column(unknown => 'bar');
        is($row->get_column('unknown'), 'bar');
    };
};

sub _build_object {
    Table->new(@_);
}

runtests unless caller;
