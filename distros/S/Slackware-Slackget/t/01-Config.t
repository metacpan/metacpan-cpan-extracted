use Test::More tests => 1;

use Slackware::Slackget::Config;

my $config = Slackware::Slackget::Config->new('t/config.xml');
ok($config);
diag("slack-get's configuration loaded - version is $config->{common}->{'conf-version'}");