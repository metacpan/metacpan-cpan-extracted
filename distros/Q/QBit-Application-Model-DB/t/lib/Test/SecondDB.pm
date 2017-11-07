package Test::SecondDB;

use qbit;

use base qw(QBit::Application::Model::DB);

use DBD::Mock;

use Test::DB::Table;

__PACKAGE__->meta(
    tables => {
        table1 => {
            fields => [
                {
                    name => 'field1',
                    type => 'TYPE',
                },
                {name => 'field2', type => 'TYPE'},
            ],
            primary_key => ['field1'],
            indexes     => [{fields => ['field2']}]
        },
    }
);

sub _get_table_class {
    my ($self, %opts) = @_;

    return 'Test::DB::Table';
}

TRUE;
