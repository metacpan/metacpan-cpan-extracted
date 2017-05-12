use warnings;
use strict;
use CGI::Application::Server;
use lib 'lib';
use <tmpl_var main_module>;

my $app = <tmpl_var main_module>->new(
    TMPL_PATH => './share/templates',
    PARAMS    => {

    },
);

my $server = CGI::Application::Server->new();
$server->document_root('./t/www');
$server->entry_points({
    '/index.cgi' => $app,
});
$server->run;
