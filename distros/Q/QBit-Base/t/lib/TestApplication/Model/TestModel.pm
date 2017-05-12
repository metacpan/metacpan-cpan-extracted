package TestApplication::Model::TestModel;

use qbit;

use base qw(QBit::Application::Model::DBManager QBit::Application::Model::Multistate::DB);

__PACKAGE__->model_accessors(db => 'QBit::Application::Model::DB');

__PACKAGE__->register_rights(
    [
        {
            name        => 'model_right_name',
            description => 'model_right_description',
            rights      => {
                model_right_1 => 'model_right_1',
                model_right_2 => 'model_right_2',
            }
        }
    ]
);

__PACKAGE__->model_fields(
    id          => {db => TRUE, pk      => TRUE, default => TRUE},
    model_field => {db => TRUE, default => TRUE},
);

__PACKAGE__->model_filter(
    db_accessor => 'db',
    fields      => {
        id          => {type => 'number',},
        model_field => {type => 'text',},
    },
);

__PACKAGE__->multistates_graph(
    empty_name  => 'model_multistate_empty_name',
    multistates => [[status_one => 'model_multistate_name_one'], [status_two => 'model_multistate_name_two']],
    actions            => {action          => 'model_action_name',},
    right_group        => ['model_actions' => 'model_actions_description'],
    right_name_prefix  => 'model_',
    right_actions      => {right_action    => 'model_right_action_name'},
    multistate_actions => [
        {
            action    => 'action',
            from      => '__EMPTY__',
            set_flags => ['status_one'],
        },
        {
            action      => 'right_action',
            from        => 'status_one and not status_two',
            reset_flags => ['status_one'],
            set_flags   => ['status_two'],
        },
    ]
);

sub check {'MODEL'}

sub init {$_[0]->{'__MODEL__'} = 'MODEL'}

TRUE;
