use Test::More tests => 32;

use lib 't/lib';
use PathTest;

use utf8;

my $builder = Test::More->builder;
binmode $builder->output,         ':utf8';
binmode $builder->failure_output, ':utf8';
binmode $builder->todo_output,    ':utf8';

my $opts = {
   style => 'File::Unix',
   auto_normalize => 1,
   auto_cleanup   => 1,
};

test_pathing($opts,
   [qw(
      /
      ..
      .
      /etc/foobar.conf
      ../..///.././aaa/.///bbb/ccc/../ddd
      /home/bbyrd///foo/bar.txt
      foo/////bar
      ////root
      var/log/turnip.log
   ),
      '/root/FILENäME NIGHTMäRE…/…/ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ.conf',
   ],
   [qw(
      /
      ..
      .
      /etc/foobar.conf
      ../../../aaa/bbb/ddd
      /home/bbyrd/foo/bar.txt
      foo/bar
      /root
      var/log/turnip.log
   ),
      '/root/FILENäME NIGHTMäRE…/…/ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ.conf',
   ],
   'Basic',
);

test_pathing_failures($opts,
   [
      "/home/asd\0"."asd/",
      '/../home',
   ],
   [
      qr/^Found unshiftable step/,
      qr/^During path cleanup, an absolute path dropped into a negative depth/,
   ],
   'Fails',
);
