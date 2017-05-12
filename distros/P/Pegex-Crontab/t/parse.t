use strict; use warnings;
use Test::More;

use Pegex::Crontab;

my $crontab = <<'...';
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user    command
17 *  * * *   root    cd / && run-parts --report /etc/cron.hourly
25 0-23/6  * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6,12,18  * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6  1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
#
...

my $data = Pegex::Crontab->parse($crontab);

ok $data, 'Parse passed';
is scalar(@$data), 6, 'Found 6 parts';
is $data->[0]{var}, 'SHELL', 'Got SHELL var';
is $data->[0]{val}, '/bin/sh', 'Got SHELL == /bin/sh';
is $data->[1]{var}, 'PATH', 'Got PATH var';

is $data->[2]{min}, 17, 'Parsed min == 17 on first entry';
is $data->[2]{hour}, '*', 'Parsed hour == * on first entry';
is $data->[2]{cmd}, 'root    cd / && run-parts --report /etc/cron.hourly',
  'Parsed cmd on first entry';
is $data->[3]{hour}, '0-23/6', 'Parsed hour == 0-23/6 on second entry';
is $data->[4]{hour}, '6,12,18', 'Parsed hour == 6,12,18 on third entry';

done_testing;
