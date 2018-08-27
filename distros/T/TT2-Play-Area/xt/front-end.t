use Test2::V0;
use Test2::Require::EnvVar 'SITE_URL';
use Test2::Require::Module 'WebDriver::Tiny' => '0.101';

use WebDriver::Tiny;

# basic idea with this test is to sanity check
# that clicking the button will trigger the request
# and we'll succesfully get the results.
#
# Basic check of,
#
# * javascript
# * csrf protection
# * processing the template

my $drv = WebDriver::Tiny->new(
    capabilities => {

        # run chrome headless?
        chromeOptions        => { binary => '/usr/bin/google-chrome' },
        'moz:firefoxOptions' => { args   => ['-headless'] }
    },
    ( host => $ENV{WEBDRIVER_HOST} ) x !!$ENV{WEBDRIVER_HOST},
    ( port => $ENV{WEBDRIVER_PORT} ) x !!$ENV{WEBDRIVER_PORT},
);
$drv->get( $ENV{SITE_URL} );
$drv->('a.tt2')->click();

# give it a moment to bring back the result.
select( undef, undef, undef, .25 );

my $elements = $drv->('div#results');
like $elements->text, qr'&quot;test&quot;';
like $elements->text, qr'TT2';

done_testing;
