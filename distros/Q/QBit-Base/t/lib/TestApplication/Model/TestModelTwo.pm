package TestApplication::Model::TestModelTwo;

use qbit;

use QBit::Base qw(TestApplication::Model::TestModelOne);

__PACKAGE__->model_accessors(db2 => 'QBit::Application::Model::DB::mysql');

__PACKAGE__->register_rights(
    [
        {
            name        => 'model_two_right_name',
            description => 'model_two_right_description',
            rights      => {
                model_two_right_1 => 'model_two_right_1',
                model_two_right_2 => 'model_two_right_2',
            }
        }
    ]
);

__PACKAGE__->model_fields(
    model_one_field => {db => TRUE, default => TRUE, check_rights => 'view__model_one_field'},
    model_two_field => {db => TRUE, default => TRUE},
);

__PACKAGE__->model_filter(
    db_accessor => 'db2',
    fields      => {
        model_one_field => {type => 'date',},
        model_two_field => {type => 'text',},
    },
);

sub check {'MODEL TWO'}

sub init {$_[0]->{'__MODEL_TWO__'} = 'MODEL TWO'; $_[0]->SUPER::init();}

TRUE;
