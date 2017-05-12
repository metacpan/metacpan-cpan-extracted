package TestApplication;

use qbit;

use base qw(QBit::Application);

use TestApplication::Model::TestModel accessor => 'test_model';

__PACKAGE__->config_opts(
    timelog_class => 'TestTimeLog',
    locales       => {
        ru => {name => 'Русский', code => 'ru_RU', default => 1},
        en => {name => 'English', code => 'en_GB'},
    },
);

TRUE;
