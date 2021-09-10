
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/playwright_server',
    'bin/reap_playwright_servers',
    'lib/Playwright.pm',
    'lib/Playwright/Accessibility.pm',
    'lib/Playwright/Android.pm',
    'lib/Playwright/AndroidDevice.pm',
    'lib/Playwright/AndroidInput.pm',
    'lib/Playwright/AndroidSocket.pm',
    'lib/Playwright/AndroidWebView.pm',
    'lib/Playwright/Base.pm',
    'lib/Playwright/Browser.pm',
    'lib/Playwright/BrowserContext.pm',
    'lib/Playwright/BrowserServer.pm',
    'lib/Playwright/BrowserType.pm',
    'lib/Playwright/CDPSession.pm',
    'lib/Playwright/ConsoleMessage.pm',
    'lib/Playwright/Coverage.pm',
    'lib/Playwright/Dialog.pm',
    'lib/Playwright/Download.pm',
    'lib/Playwright/Electron.pm',
    'lib/Playwright/ElectronApplication.pm',
    'lib/Playwright/ElementHandle.pm',
    'lib/Playwright/Error.pm',
    'lib/Playwright/FileChooser.pm',
    'lib/Playwright/Frame.pm',
    'lib/Playwright/JSHandle.pm',
    'lib/Playwright/Keyboard.pm',
    'lib/Playwright/Locator.pm',
    'lib/Playwright/Logger.pm',
    'lib/Playwright/ModuleList.pm',
    'lib/Playwright/Mouse.pm',
    'lib/Playwright/Page.pm',
    'lib/Playwright/PlaywrightException.pm',
    'lib/Playwright/Request.pm',
    'lib/Playwright/Response.pm',
    'lib/Playwright/Route.pm',
    'lib/Playwright/Selectors.pm',
    'lib/Playwright/TimeoutError.pm',
    'lib/Playwright/Touchscreen.pm',
    'lib/Playwright/Tracing.pm',
    'lib/Playwright/Util.pm',
    'lib/Playwright/Video.pm',
    'lib/Playwright/WebSocket.pm',
    'lib/Playwright/WebSocketFrame.pm',
    'lib/Playwright/Worker.pm',
    't/Playwright-Base.t',
    't/Playwright-Util.t',
    't/Playwright.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-test-version.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
