use inc::Module::Install;
use Getopt::Long;


name     'Net-Google-Code';
all_from 'lib/Net/Google/Code.pm';
author   'sunnavy <sunnavy@bestpractical.com>';
license  'perl';

test_requires 'Test::More';
test_requires 'Test::MockModule';
test_requires 'File::Slurp';
test_requires 'Test::Mock::LWP';

requires 'Any::Moose';
# requires 'WWW::Mechanize' doesn't work with Test::Mock::LWP
requires 'WWW::Mechanize::Link';

requires 'HTML::TreeBuilder';
requires 'XML::FeedPP';
requires 'URI::Escape';
requires 'Params::Validate';
requires 'DateTime';
requires 'MIME::Types';
requires 'File::MMagic';
requires 'JSON';

my $live;
GetOptions( 'live' => \$live );
if ($live) {
    tests('t/*.t t/*/*.t');
}
else {
    tests('t/*.t t/google_api/*.t');
}

recursive_author_tests('xt/');

auto_install;

WriteAll;

