package TestWebInterface;

use qbit;

use base qw(QBit::WebInterface::Test QBit::Application);

use TestWebInterface::Controller::Test path => 'test';

__PACKAGE__->config_opts(
    TemplateIncludePaths => ['${ApplicationPath}../lib/QBit/templates', '${ApplicationPath}lib/templates']
    ,    # Use framework templates
    MinimizeTemplate => TRUE,
    timelog_class    => 'TestTimeLog',
    use_base_routing => TRUE,
);

TRUE;
