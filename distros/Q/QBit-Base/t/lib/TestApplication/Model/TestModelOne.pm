package TestApplication::Model::TestModelOne;

use qbit;

use QBit::Base qw(TestApplication::Model::TestModel);

__PACKAGE__->model_accessors();

__PACKAGE__->register_rights(
    [
        {
            name        => 'model_one_right_name',
            description => 'model_one_right_description',
            rights      => {
                model_one_right_1 => 'model_one_right_1',
                model_one_right_2 => 'model_one_right_2',
            }
        }
    ]
);

__PACKAGE__->model_fields(
    model_one_field => {db => TRUE, default => TRUE},
);

__PACKAGE__->model_filter(
    db_accessor => 'db',
    fields      => {
        model_one_field => {type => 'text',},
    },
);

sub check {'MODEL ONE'}

sub init {$_[0]->{'__MODEL_ONE__'} = 'MODEL ONE'}

TRUE;
