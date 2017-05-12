use Test::More;
use Pegex::Crontab;
use YAML::XS;
use IO::All;
# use XXX;

my $xt = -e 'xt' ? 'xt' : 'test/devel';
my $got = YAML::XS::Dump(Pegex::Crontab->new->parse(io("$xt/crontab")->all));
my $expect = <<'...';
---
- cmd: tar -zcf /var/backups/home.tgz /home/
  dom: '*'
  dow: '1'
  hour: '5'
  min: '0'
  mon: '*'
...

is $got, $expect, 'crontab parses';

done_testing;
