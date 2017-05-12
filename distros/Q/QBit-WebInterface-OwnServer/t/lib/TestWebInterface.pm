package TestWebInterface;

use qbit;

use base qw(QBit::WebInterface::OwnServer QBit::Application);

use TestWebInterface::Controller::Test path => 'test';

sub default_cmd {test => 'test'}

TRUE;
