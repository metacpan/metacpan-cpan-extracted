package TestApp;

use Moo;

with 'Plasp::App';

my ( $app_root ) = __FILE__ =~ m/(.*)\.pm$/;

__PACKAGE__->config(
    ApplicationRoot => $app_root,
    DocumentRoot    => 'root',
    Global          => 'root',
    GlobalPackage   => 'TestApp::ASP',
    IncludesDir     => 'root',
    XMLSubsMatch    => '(?:TestApp::ASP::\w+)::\w+',
);

1;
