package TWebInterface;

use qbit;

use base qw(QBit::WebInterface QBit::Application);

use QBit::WebInterface::Routing;

use TWebInterface::Controller::TestController path => 'test_controller';

__PACKAGE__->config_opts(timelog_class => 'TestTimeLog',);

TRUE;
