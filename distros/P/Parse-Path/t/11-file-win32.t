use Test::More tests => 50;

use lib 't/lib';
use PathTest;

use utf8;

my $builder = Test::More->builder;
binmode $builder->output,         ':utf8';
binmode $builder->failure_output, ':utf8';
binmode $builder->todo_output,    ':utf8';

my $opts = {
   style => 'File::Win32',
   auto_normalize => 1,
   auto_cleanup   => 1,
};

test_pathing($opts,
   [qw(
      C:
      c:
      C:\
      \
      ..
      .
      \etc\foobar.conf
      ..\..\\\\\\..\.\aaa\.\\\\\\bbb\ccc\..\ddd
      C:\Users\bbyrd\\\\\\foo\bar.txt
      C:foo\bar.txt
      foo\\\\\\\\bar
      \\\\\\\\Windows
      var\log\turnip.log
   ),
      '\Windows\FILENäME NIGHTMäRE…\…\ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ.exe',
   ],
   [qw(
      C:
      C:
      C:\
      \
      ..
      .
      \etc\foobar.conf
      ..\..\..\aaa\bbb\ddd
      C:\Users\bbyrd\foo\bar.txt
      C:foo\bar.txt
      foo\bar
      \Windows
      var\log\turnip.log
   ),
      '\Windows\FILENäME NIGHTMäRE…\…\ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ.exe',
   ],
   'Basic',
);

test_pathing_failures($opts,
   [qw(
      -:
      CAT:
      CAT:\
      /
      C:\WINDOWS\*.???
      \WINDOWS\C:\WINDOWS
      C:\..\Users
   ),
      'C:\"Space is the place"\TEMP',
   ],
   [
      qr/^Found unshiftable step/,
      qr/^Found unshiftable step/,
      qr/^Found unshiftable step/,
      qr/^Found unshiftable step/,
      qr/^Found unshiftable step/,
      qr/^Found unshiftable step/,
      qr/^During path cleanup, an absolute path dropped into a negative depth/,
      qr/^Found unshiftable step/,
   ],
   'Fails',
);
