# config.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 4 };

use PurpleWiki::Config;
my $configfile = 't';

my $config = new PurpleWiki::Config($configfile);

ok(ref $config eq 'PurpleWiki::Config');

ok($config->UseSubpage == 1);
ok($config->RCName eq 'RecentChanges');
ok($config->FS1 eq "\xb31");

