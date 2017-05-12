use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/POE/Component/IRC/Plugin/AntiSpamMailTo.pm',
    'lib/POE/Component/IRC/Plugin/BrowserSupport.pm',
    'lib/POE/Component/IRC/Plugin/CSS/Minifier.pm',
    'lib/POE/Component/IRC/Plugin/CSS/PropertyInfo.pm',
    'lib/POE/Component/IRC/Plugin/CSS/PropertyInfo/Data.pm',
    'lib/POE/Component/IRC/Plugin/CSS/SelectorTools.pm',
    'lib/POE/Component/IRC/Plugin/ColorNamer.pm',
    'lib/POE/Component/IRC/Plugin/Google/PageRank.pm',
    'lib/POE/Component/IRC/Plugin/HTML/AttributeInfo.pm',
    'lib/POE/Component/IRC/Plugin/HTML/AttributeInfo/Data.pm',
    'lib/POE/Component/IRC/Plugin/HTML/HTML/ElementInfo.pm',
    'lib/POE/Component/IRC/Plugin/JavaScript/Minifier.pm',
    'lib/POE/Component/IRC/Plugin/Syntax/Highlight/CSS.pm',
    'lib/POE/Component/IRC/Plugin/Syntax/Highlight/HTML.pm',
    'lib/POE/Component/IRC/Plugin/Validator/CSS.pm',
    'lib/POE/Component/IRC/Plugin/Validator/HTML.pm',
    'lib/POE/Component/IRC/Plugin/WWW/Alexa/TrafficRank.pm',
    'lib/POE/Component/IRC/Plugin/WWW/Cache/Google.pm',
    'lib/POE/Component/IRC/Plugin/WWW/DoctypeGrabber.pm',
    'lib/POE/Component/IRC/Plugin/WWW/GetPageTitle.pm',
    'lib/POE/Component/IRC/Plugin/WWW/HTMLTagAttributeCounter.pm',
    'lib/POE/Component/IRC/Plugin/WWW/Lipsum.pm',
    'lib/POE/Component/IRC/PluginBundle/WebDevelopment.pm'
);

notabs_ok($_) foreach @files;
done_testing;
