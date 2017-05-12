package TestApplication;

use qbit;

use base qw(QBit::Application);

use QBit::Application::Model::Authorization accessor => 'session';
use TestApplication::Model::DB accessor              => 'db';
use TestApplication::Model::Request accessor         => 'request';
use TestApplication::Model::Response accessor        => 'response';

__PACKAGE__->use_config('TestApplication.cfg');

TRUE;
