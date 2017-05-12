package Config::Pinwheel;

use Pinwheel::Controller;
use File::Basename 'dirname';
use Cwd 'realpath';

#
# Application specific settings for Pinwheel
#

our $Root = realpath(dirname(__FILE__).'/../..');
unshift @INC, "$Root/lib";

require $_ foreach (glob("$Root/lib/Config/*.pm"));
require $_ foreach (glob("$Root/lib/Models/*.pm"));
require $_ foreach (glob("$Root/lib/Helpers/*.pm"));
require $_ foreach (glob("$Root/lib/Controllers/*.pm"));

Pinwheel::Controller::set_static_root("$Root/htdocs");
Pinwheel::Controller::set_templates_root("$Root/tmpl");
Pinwheel::Controller::initialise();


1;
