
use strict;
use warnings;
use Test::More;

BEGIN {
   package AAA;
   our $VERSION = 2;
   use Sub::Exporter::Progressive -setup => {
      exports => ['aaa'],
   };
   sub aaa { 'aaa' };
   $INC{'AAA.pm'} = __FILE__;
};

ok(eval('use AAA 1; 1'), 'perl built-in module version check');

{
   local $@;
   ok(!eval('use AAA 3; 1'), 'perl built-in module version check');
   like(
      $@,
      qr/^AAA version 3 required/,
      'perl built-in module version check error message',
   );
}

{
   local $@;
   ok(
      !eval('use AAA aaa => 1; 1'),
      'Exporter.pm-style version check',
   );
   like(
      $@,
      qr{^cannot export symbols with a leading digit: '1'},
      'Sub::Exporter::Progressive error message',
   );
}

done_testing;

