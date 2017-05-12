package TestApplication;

use qbit;

use base qw(QBit::Application);

use TestApplication::Model::TestModel accessor    => 'model';
use TestApplication::Model::TestModelOne accessor => 'model_one';
use TestApplication::Model::TestModelTwo accessor => 'model_two';
use QBit::Application::Model::DB accessor         => 'db';
use QBit::Application::Model::DB::mysql accessor  => 'db2';

__PACKAGE__->config_opts(
    timelog_class => 'TestTimeLog',
    locales       => {en => {name => 'English', code => 'en_GB', default => 1},},
);

TRUE;
