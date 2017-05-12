#!perl

use Test::Spec;
use Test::Deep;
use Monorail::Change::AddField;
use Monorail::Change::CreateTable;

describe 'An add field change' => sub {
    my $sut;
    my %sut_args;
    before each => sub {
        %sut_args = (
            table          => 'epcot',
            name           => 'description',
            type           => 'TEXT',
            is_nullable    => 1,
            is_primary_key => 0,
            is_unique      => 0,
            default_value  => undef,
        );
        $sut = Monorail::Change::AddField->new(%sut_args);
        $sut->db_type('PostgreSQL');
    };

    it 'produces valid sql' => sub {
        like($sut->as_sql, qr/ALTER TABLE epcot ADD COLUMN description TEXT/i);
    };

    it 'produces valid perl' => sub {
        my $perl = $sut->as_perl;

        my $new = eval $perl;
        cmp_deeply($new, all(
            isa('Monorail::Change::AddField'),
            methods(%sut_args),
        ));
    };

    it 'transforms a schema object' => sub {
        my $schema = SQL::Translator::Schema->new();
        $schema->add_table(name => 'epcot');

        $sut->transform_schema($schema);

        cmp_deeply(
            $schema->get_table('epcot')->get_field('description'),
            methods(
                name      => 'description',
                data_type => 'TEXT',
            )
        );
    };


    it 'can add a field to a schema that came from real DBIx::Class' => sub {
        my $sut = Monorail::Change::AddField->new(
            type           => 'text',
            table          => 'logs',
            is_unique      => 0,
            size           => [ 0 ],
            is_primary_key => 0,
            name           => 'related_object',
            is_nullable    => 1
        );
        my $schema = get_test_table()->schema;
        $sut->transform_schema($schema);
        #use Data::Dumper;
        #diag Dumper($schema);
        ok(1);
    }
};


sub get_test_table {
    my $perl = <<'END_OF_PERL';
    my $VAR1 = bless( {
                     '_fields' => {
                                    'job_id' => bless( {
                                                         'extra' => {},
                                                         'is_primary_key' => 0,
                                                         '_ERROR' => '',
                                                         'table' => {},
                                                         'comments' => [],
                                                         'is_nullable' => 0,
                                                         'order' => 2,
                                                         'name' => 'job_id',
                                                         'size' => [
                                                                     '0'
                                                                   ],
                                                         'data_type' => 'integer'
                                                       }, 'SQL::Translator::Schema::Field' ),
                                    'change_type' => bless( {
                                                              'data_type' => 'text',
                                                              'name' => 'change_type',
                                                              'size' => [
                                                                          '0'
                                                                        ],
                                                              'is_nullable' => 1,
                                                              'comments' => [],
                                                              'order' => 5,
                                                              'extra' => {},
                                                              'is_primary_key' => 0,
                                                              'table' => {},
                                                              '_ERROR' => ''
                                                            }, 'SQL::Translator::Schema::Field' ),
                                    'message' => bless( {
                                                          'data_type' => 'text',
                                                          'size' => [
                                                                      '0'
                                                                    ],
                                                          'name' => 'message',
                                                          'order' => 7,
                                                          'comments' => [],
                                                          'is_nullable' => 1,
                                                          'table' => {},
                                                          '_ERROR' => '',
                                                          'is_primary_key' => 0,
                                                          'extra' => {}
                                                        }, 'SQL::Translator::Schema::Field' ),
                                    'source_id' => bless( {
                                                            'size' => [
                                                                        '0'
                                                                      ],
                                                            'name' => 'source_id',
                                                            'data_type' => 'text',
                                                            '_ERROR' => '',
                                                            'table' => {},
                                                            'extra' => {},
                                                            'is_primary_key' => 0,
                                                            'order' => 3,
                                                            'is_nullable' => 1,
                                                            'comments' => []
                                                          }, 'SQL::Translator::Schema::Field' ),
                                    'id' => bless( {
                                                     'is_primary_key' => 1,
                                                     'extra' => {},
                                                     '_ERROR' => '',
                                                     'table' => {},
                                                     'comments' => [],
                                                     'is_nullable' => 0,
                                                     'order' => 1,
                                                     'name' => 'id',
                                                     'size' => [
                                                                 '0'
                                                               ],
                                                     'data_type' => 'serial'
                                                   }, 'SQL::Translator::Schema::Field' ),
                                    'account_id' => bless( {
                                                             'table' => {},
                                                             '_ERROR' => '',
                                                             'extra' => {},
                                                             'is_primary_key' => 0,
                                                             'order' => 4,
                                                             'is_nullable' => 1,
                                                             'comments' => [],
                                                             'size' => [
                                                                         '0'
                                                                       ],
                                                             'name' => 'account_id',
                                                             'data_type' => 'integer'
                                                           }, 'SQL::Translator::Schema::Field' )
                                  },
                     '_can_link' => {},
                     'extra' => {},
                     '_ERROR' => 'Field "message" does not exist',
                     'schema' => bless( {
                                          'name' => '',
                                          '_views' => {},
                                          '_tables' => {
                                                         'logs' => {}
                                                       },
                                          '_triggers' => {},
                                          '_procedures' => {},
                                          'extra' => {},
                                          'database' => '',
                                          '_ERROR' => '',
                                          '_order' => {
                                                        'table' => 1,
                                                        'trigger' => 0,
                                                        'proc' => 0,
                                                        'view' => 0
                                                      }
                                        }, 'SQL::Translator::Schema' ),
                     'comments' => [],
                     'order' => 1,
                     'name' => 'logs',
                     'options' => [],
                     '_constraints' => [
                                         bless( {
                                                  'options' => [],
                                                  'name' => '',
                                                  'on_update' => '',
                                                  'field_names' => [
                                                                     'id'
                                                                   ],
                                                  'reference_table' => '',
                                                  'table' => {},
                                                  '_ERROR' => '',
                                                  'match_type' => '',
                                                  'deferrable' => 1,
                                                  'type' => 'PRIMARY KEY',
                                                  'on_delete' => '',
                                                  'extra' => {},
                                                  'expression' => ''
                                                }, 'SQL::Translator::Schema::Constraint' )
                                       ]
                   }, 'SQL::Translator::Schema::Table' );
    $VAR1->{'_fields'}{'job_id'}{'table'} = $VAR1;
    $VAR1->{'_fields'}{'change_type'}{'table'} = $VAR1;
    $VAR1->{'_fields'}{'message'}{'table'} = $VAR1;
    $VAR1->{'_fields'}{'source_id'}{'table'} = $VAR1;
    $VAR1->{'_fields'}{'id'}{'table'} = $VAR1;
    $VAR1->{'_fields'}{'account_id'}{'table'} = $VAR1;
    $VAR1->{'schema'}{'_tables'}{'logs'} = $VAR1;
    $VAR1->{'_constraints'}[0]{'table'} = $VAR1;
    $VAR1;
END_OF_PERL
    my $table = eval $perl;
    die $@ if $@;

    return $table;
}
runtests;
