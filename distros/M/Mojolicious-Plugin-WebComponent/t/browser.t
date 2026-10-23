use Mojo::Base -strict;
use Test::More;
use Mojo::File qw(curfile);

# Real-browser checks (Chromium via Playwright, app under prefork) need podman
# and a few minutes; they run only when asked for.
plan skip_all => 'set WEBCOMPONENT_BROWSER_TEST=1 to run the browser checks'
    unless $ENV{WEBCOMPONENT_BROWSER_TEST};
plan skip_all => 'podman is not installed' unless system('podman --version >/dev/null 2>&1') == 0;

is system(curfile->sibling('browser', 'run.sh')->to_string), 0, 'browser checks pass';

done_testing;
