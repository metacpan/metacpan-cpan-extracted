use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/POE/Component/App/PNGCrush.pm',
    'lib/POE/Component/Bundle/WebDevelopment.pm',
    'lib/POE/Component/CSS/Minifier.pm',
    'lib/POE/Component/JavaScript/Minifier.pm',
    'lib/POE/Component/Syntax/Highlight/CSS.pm',
    'lib/POE/Component/Syntax/Highlight/HTML.pm',
    'lib/POE/Component/WWW/Alexa/TrafficRank.pm',
    'lib/POE/Component/WWW/Cache/Google.pm',
    'lib/POE/Component/WWW/DoctypeGrabber.pm',
    'lib/POE/Component/WWW/GetPageTitle.pm',
    'lib/POE/Component/WWW/HTMLTagAttributeCounter.pm',
    'lib/POE/Component/WWW/Lipsum.pm',
    'lib/POE/Component/WWW/WebDevout/BrowserSupportInfo.pm',
    'lib/POE/Component/WebService/HtmlKitCom/FavIconFromImage.pm',
    'lib/POE/Component/WebService/Validator/CSS/W3C.pm',
    'lib/POE/Component/WebService/Validator/HTML/W3C.pm',
    't/00-compile.t',
    't/App-PNGCrush/00-load.t',
    't/CSS-Minifier/00-load.t',
    't/JavaScript-Minifier/00-load.t',
    't/Syntax-Highlight-CSS/00-load.t',
    't/Syntax-Highlight-HTML/00-load.t',
    't/WWW-Alexa-TrafficRank/00-load.t',
    't/WWW-Cache-Google/00-load.t',
    't/WWW-DoctypeGrabber/00-load.t',
    't/WWW-GetPageTitle/00-load.t',
    't/WWW-HTMLTagAttributeCounter/00-load.t',
    't/WWW-Lipsum/00-load.t',
    't/WWW-WebDevout-BrowserSupportInfo/00-load.t',
    't/WebService-HtmlKitCom-FavIconFromImage/00-load.t',
    't/WebService-Validator-CSS-W3C/00-load.t',
    't/WebService-Validator-CSS-W3C/01-val.t',
    't/WebService-Validator-HTML-W3C/01_initializing.t',
    't/WebService-Validator-HTML-W3C/02_method_same_session.t',
    't/WebService-Validator-HTML-W3C/03_method_other_session.t',
    't/WebService-Validator-HTML-W3C/04_event_same_session.t',
    't/WebService-Validator-HTML-W3C/05_event_other_session.t',
    't/WebService-Validator-HTML-W3C/06_val_errors_and_special_args.t',
    't/WebService-Validator-HTML-W3C/test1.html'
);

notabs_ok($_) foreach @files;
done_testing;
