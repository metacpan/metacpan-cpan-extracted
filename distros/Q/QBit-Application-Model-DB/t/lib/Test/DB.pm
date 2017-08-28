package Test::DB;

use qbit;

use base qw(QBit::Application::Model::DB);

use DBD::Mock;

use QBit::Application::Model::DB::Filter;
use Test::DB::Table;
use QBit::Application::Model::DB::Query;
use QBit::Application::Model::DB::Field;

__PACKAGE__->meta(
    tables => {
        table1 => {
            fields => [
                {
                    name => 'field1',
                    type => 'TYPE',
                },
                {name => 'field2', type => 'TYPE'},
                {
                    name => 'field3',
                    type => 'TYPE',
                },
                {name => 'field4', type => 'TYPE'},
                {name => 'field5', type => 'TYPE'},
                {name => 'field6', type => 'TYPE'},
                {
                    name => 'field7',
                    type => 'TYPE',
                },
                {name => 'field8', type => 'TYPE'},
                {
                    name => 'field9',
                    type => 'TEXT',
                },
                {name => 'field10', type => 'TEXT'},
            ],
            primary_key => ['field1'],
            indexes     => [{fields => ['field2']}]
        },

        table2 => {
            fields => [
                {name => 'field1', type => 'TYPE'},
                {name => 'field2', type => 'TYPE',},
                {name => 't1_f2'},
                {name => 'ml_field', type => 'TYPE', i18n => 1}
            ],
            primary_key  => [qw(field1 field2)],
            foreign_keys => [[['t1_f2'] => table1 => ['field2']]]
        },

        qtable1 => {
            fields => [
                {name => 'id',       type => 'TYPE'},
                {name => 'field',    type => 'TYPE'},
                {name => 'value',    type => 'TYPE'},
                {name => 'ml_field', type => 'TYPE', i18n => 1}
            ],
            primary_key => [qw(id)],
        },

        qtable2 => {
            fields       => [{name          => 'parent_id'}, {name => 'field', type => 'TYPE'}],
            foreign_keys => [[['parent_id'] => qtable1       => ['id']]]
        }
    }
);

sub filter {
    my ($self, $filter, %opts) = @_;

    return QBit::Application::Model::DB::Filter->new($filter, %opts, db => $self);
}

sub _get_table_class {
    my ($self, %opts) = @_;

    return 'Test::DB::Table';
}

sub query {
    my ($self) = @_;

    return QBit::Application::Model::DB::Query->new(db => $self);
}

sub _connect {
    my ($self) = @_;

    unless ($self->dbh) {
        my $dbh = DBI->connect('DBI:Mock:', '', '') || throw DBI::errstr();

        $self->set_dbh($dbh);
    }
}

TRUE;
