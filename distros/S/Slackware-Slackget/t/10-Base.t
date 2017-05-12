use Test::More tests => 3;

use Slackware::Slackget::Base;
use Slackware::Slackget::Config;

my $config = Slackware::Slackget::Config->new('t/config.xml');
ok($config);

# diag("\n\nThe test of the Slackware::Slackget::Base class can success only if the followings class are running well : Slackware::Slackget::PackageList, Slackware::Slackget::Package, Slackware::Slackget::File, Slackware::Slackget::Media, Slackware::Slackget::MediaList, Slackware::Slackget::Date\n\n");

my $sgb = new Slackware::Slackget::Base($config);
ok($sgb);
diag("\n\nWe are now compiling the /var/log/packages/ directory.\nIt will takes some time (from 1 secondes to 10 minutes depending of your system configuration and if you actually run a Slackware based GNU/Linux)\n\n");
ok($sgb->compil_packages_directory('/var/log/packages/'));