use warnings;
use strict;

use FindBin;
use lib $FindBin::Bin . '/lib';

use Test::More tests => 2;
use Test::Output qw(:functions);
use Test::Regression;
use TestApp;

my $app = TestApp->new;

is_deeply(
    [sort($app->command_names)],
    [qw(--help -? -h bashcomplete commands help testcommand)],
    'Command names ok'
);

@ARGV = ('bashcomplete');

ok_regression(sub { stdout_from(sub { TestApp->run }) },
              "$FindBin::Bin/output.txt");
