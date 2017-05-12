package MyApp::Config::_common;
use strict;
use vars qw(%C);
*Config = \%C;
use Class::Inspector;
use Cwd;
my $filename = Cwd::abs_path(Class::Inspector->resolved_filename(__PACKAGE__));

$C{TMPL_PATH} = './t/view';

$C{COOKIE_NAME}   = '_sid';
$C{COOKIE_PATH}   = '/';
$C{COOKIE_DOMAIN} = 'localhost';

1;

