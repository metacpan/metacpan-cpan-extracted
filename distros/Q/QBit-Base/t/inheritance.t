#!/usr/bin/perl -w

use Test::More;
use Test::Deep;

use qbit;

use FindBin qw($Bin);

use lib "$Bin/../lib";
use lib "$Bin/lib";

use TestApplication;

my $app = TestApplication->new();

$app->pre_run();

is(ref($app->model_one), 'TestApplication::Model::TestModelOne', 'model one name');
is(ref($app->model_two), 'TestApplication::Model::TestModelTwo', 'model two name');

is($app->model_one->{'__MODEL_ONE__'}, 'MODEL ONE', 'model one init');
is($app->model_two->{'__MODEL_ONE__'}, 'MODEL ONE', 'model two SUPER::init');
is($app->model_two->{'__MODEL_TWO__'}, 'MODEL TWO', 'model two init');

is($app->model_one->check, 'MODEL ONE', 'model one method');
is($app->model_two->check, 'MODEL TWO', 'model two method');

is(ref($app->model_one->db),  'QBit::Application::Model::DB',        'accessor "db" one name');
is(ref($app->model_two->db),  'QBit::Application::Model::DB',        'accessor "db" two name');
is(ref($app->model_two->db2), 'QBit::Application::Model::DB::mysql', 'accessor "db2" two name');

cmp_deeply(
    package_stash(ref($app->model_one)),
    {
        '__RIGHT_ACTIONS__'        => {'right_action' => 'do_model_right_action'},
        '__DB_FILTER_DBACCESSOR__' => 'db',
        '__DB_FILTER__'            => {
            'model_field'     => {'type' => 'text'},
            'id'              => {'type' => 'number'},
            'model_one_field' => {'type' => 'text'}
        },
        '__MODEL_ACCESSORS__' => {},
        '__BITS__' =>
          [['status_one', 'model_multistate_name_one', {}], ['status_two', 'model_multistate_name_two', {}]],
        '__BITS_HS__' => {
            'status_one' => {
                'bit'         => 0,
                'description' => 'model_multistate_name_one',
                'opts'        => {},
            },
            'status_two' => {
                'bit'         => 1,
                'description' => 'model_multistate_name_two',
                'opts'        => {},
            }
        },
        '__MODEL_FIELDS_SORT_ORDERS__' => {
            'id'                           => 0,
            'model_one_field'              => 0,
            'model_one_field_with_depends' => 1,
            'model_field'                  => 0
        },
        '__ACTIONS__' => {
            'action'       => 'model_action_name',
            'right_action' => 'model_right_action_name'
        },
        '__MODEL_FIELDS_INITIALIZED__' => {
            'id' => {
                'pk'      => 1,
                'default' => 1,
                'db'      => 1
            },
            'model_field' => {
                'db'      => 1,
                'default' => 1
            },
            'model_one_field' => {
                'db'      => 1,
                'default' => 1
            },
            'model_one_field_with_depends' => {
                'depends_on' => [qw(id)],
                'get'        => ignore()
            },
        },
        '__EMPTY_NAME__'   => 'model_multistate_empty_name',
        '__MODEL_FIELDS__' => {
            'model_one_field' => {
                'db'      => 1,
                'default' => 1
            },
            'model_one_field_with_depends' => {
                'depends_on' => [qw(id)],
                'get'        => ignore()
            },
            'id' => {
                'pk'      => 1,
                'default' => 1,
                'db'      => 1
            },
            'model_field' => {
                'default' => 1,
                'db'      => 1
            }
        },
        '__RIGHT_GROUPS__' => {
            'model_right_name'     => 'model_right_description',
            'model_one_right_name' => 'model_one_right_description'
        },
        '__RIGHTS__' => {
            'model_right_2' => {
                'group' => 'model_right_name',
                'name'  => 'model_right_2'
            },
            'model_one_right_2' => {
                'group' => 'model_one_right_name',
                'name'  => 'model_one_right_2'
            },
            'model_right_1' => {
                'name'  => 'model_right_1',
                'group' => 'model_right_name'
            },
            'model_one_right_1' => {
                'name'  => 'model_one_right_1',
                'group' => 'model_one_right_name'
            }
        },
        '__MULTISTATES__' => {
            '2' => {},
            '0' => {'action' => 1},
            '1' => {'right_action' => 2},
        }
    },
    'model one stash'
);

cmp_deeply(
    package_stash(ref($app->model_two)),
    {
        '__EMPTY_NAME__'  => 'model_multistate_empty_name',
        '__MULTISTATES__' => {
            '2' => {},
            '0' => {'action' => 1},
            '1' => {'right_action' => 2}
        },
        '__MODEL_FIELDS_SORT_ORDERS__' => {
            'model_one_field'              => 0,
            'id'                           => 0,
            'model_field'                  => 0,
            'model_two_field'              => 0,
            'model_one_field_with_depends' => 1
        },
        '__ACTIONS__' => {
            'right_action' => 'model_right_action_name',
            'action'       => 'model_action_name'
        },
        '__DB_FILTER_DBACCESSOR__' => 'db2',
        '__RIGHT_ACTIONS__'        => {'right_action' => 'do_model_right_action'},
        '__MODEL_FIELDS__'         => {
            'id' => {
                'default' => 1,
                'pk'      => 1,
                'db'      => 1
            },
            'model_field' => {
                'db'      => 1,
                'default' => 1
            },
            'model_two_field' => {
                'default' => 1,
                'db'      => 1
            },
            'model_one_field' => {
                'db'           => 1,
                'check_rights' => 'view__model_one_field',
                'default'      => 1
            },
            'model_one_field_with_depends' => {
                'depends_on' => [qw(id)],
                'get'        => ignore()
            }
        },
        '__BITS__' =>
          [['status_one', 'model_multistate_name_one', {}], ['status_two', 'model_multistate_name_two', {}]],
        '__BITS_HS__' => {
            'status_one' => {
                'bit'         => 0,
                'opts'        => {},
                'description' => 'model_multistate_name_one'
            },
            'status_two' => {
                'bit'         => 1,
                'description' => 'model_multistate_name_two',
                'opts'        => {}
            }
        },
        '__MODEL_ACCESSORS__' => {},
        '__DB_FILTER__'       => {
            'id'              => {'type' => 'number'},
            'model_field'     => {'type' => 'text'},
            'model_two_field' => {'type' => 'text'},
            'model_one_field' => {'type' => 'date'}
        },
        '__RIGHT_GROUPS__' => {
            'model_right_name'     => 'model_right_description',
            'model_one_right_name' => 'model_one_right_description',
            'model_two_right_name' => 'model_two_right_description'
        },
        '__MODEL_FIELDS_INITIALIZED__' => {
            'model_one_field' => {
                'db'           => 1,
                'default'      => 1,
                'check_rights' => ['view__model_one_field']
            },
            'model_one_field_with_depends' => {
                'depends_on' => [qw(id)],
                'get'        => ignore()
            },
            'model_field' => {
                'default' => 1,
                'db'      => 1
            },
            'id' => {
                'db'      => 1,
                'default' => 1,
                'pk'      => 1
            },
            'model_two_field' => {
                'default' => 1,
                'db'      => 1
            }
        },
        '__RIGHTS__' => {
            'model_one_right_2' => {
                'group' => 'model_one_right_name',
                'name'  => 'model_one_right_2'
            },
            'model_two_right_1' => {
                'name'  => 'model_two_right_1',
                'group' => 'model_two_right_name'
            },
            'model_right_2' => {
                'name'  => 'model_right_2',
                'group' => 'model_right_name'
            },
            'model_one_right_1' => {
                'name'  => 'model_one_right_1',
                'group' => 'model_one_right_name'
            },
            'model_right_1' => {
                'name'  => 'model_right_1',
                'group' => 'model_right_name'
            },
            'model_two_right_2' => {
                'group' => 'model_two_right_name',
                'name'  => 'model_two_right_2'
            }
        }
    },
    'model two stash'
);

cmp_deeply(
    $app->get_registered_rights(),
    {
        'model_right_1' => {
            'group' => 'model_right_name',
            'name'  => 'model_right_1'
        },
        'model_one_right_2' => {
            'group' => 'model_one_right_name',
            'name'  => 'model_one_right_2'
        },
        'do_model_right_action' => {
            'group' => 'model_actions',
            'name'  => ignore(),
        },
        'model_one_right_1' => {
            'group' => 'model_one_right_name',
            'name'  => 'model_one_right_1'
        },
        'model_two_right_2' => {
            'group' => 'model_two_right_name',
            'name'  => 'model_two_right_2'
        },
        'model_two_right_1' => {
            'name'  => 'model_two_right_1',
            'group' => 'model_two_right_name'
        },
        'model_right_2' => {
            'name'  => 'model_right_2',
            'group' => 'model_right_name'
        }
    },
    'registered rights'
);

$app->post_run();

done_testing();
