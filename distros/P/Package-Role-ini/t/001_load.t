# --perl--
use strict;
use warnings;
use Test::More tests => 20;
BEGIN { use_ok('Package::New') };
BEGIN { use_ok('Package::Role::ini') };

{
package #hide from index
My::Test;
use strict;
use warnings;
use base qw{Package::New Package::Role::ini};
}

{
package #hide from index
My::Test::Sub;
use strict;
use warnings;
use base qw{My::Test};
}

{
  my $obj = My::Test->new;
  isa_ok($obj, 'Package::New');
  isa_ok($obj, 'Package::Role::ini');

  SKIP: {
    my $etc = '/etc';
    skip "skip", 4 if ($^O eq 'MSWin32' and not (-d $etc and -r $etc));
    is($obj->ini_file_default_extension, 'ini'       , 'ini_file_default_extension');
    is($obj->ini_file_default,           'my-test.ini', 'ini_file_default');
    is($obj->ini_path, $etc              , sprintf("ini_path: %s", $obj->ini_path));
    is($obj->ini_file, "$etc/my-test.ini", sprintf("ini_file: %s", $obj->ini_file));
  }
}

{
  my $obj = My::Test::Sub->new(ini_file_default_extension=>'test');
  isa_ok($obj, 'Package::New');
  isa_ok($obj, 'Package::Role::ini');

  SKIP: {
    my $etc = '/etc';
    skip "skip", 4 if ($^O eq 'MSWin32' and not (-d $etc and -r $etc));
    is($obj->ini_file_default_extension, 'test'           , 'ini_file_default_extension');
    is($obj->ini_file_default,           'my-test-sub.test', 'ini_file_default');
    is($obj->ini_path, $etc                   , sprintf("ini_path: %s", $obj->ini_path));
    is($obj->ini_file, "$etc/my-test-sub.test", sprintf("ini_file: %s", $obj->ini_file));
  }
}

{
  my $obj = My::Test::Sub->new(ini_file_default_extension=>undef);
  isa_ok($obj, 'Package::New');
  isa_ok($obj, 'Package::Role::ini');

  SKIP: {
    my $etc = '/etc';
    skip "skip", 4 if ($^O eq 'MSWin32' and not (-d $etc and -r $etc));
    is($obj->ini_file_default_extension, undef           , 'ini_file_default_extension');
    is($obj->ini_file_default,           'my-test-sub', 'ini_file_default');
    is($obj->ini_path, $etc              , sprintf("ini_path: %s", $obj->ini_path));
    is($obj->ini_file, "$etc/my-test-sub", sprintf("ini_file: %s", $obj->ini_file));
  }
}
