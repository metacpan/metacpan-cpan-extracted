package TestApplication;

use qbit;

use base qw(QBit::Application);

use TestApplication::Model::TestModel accessor => 'test_model';
use TestApplication::Model::RBAC accessor      => 'rbac';

__PACKAGE__->use_config('TestApplication.cfg');

TRUE;
