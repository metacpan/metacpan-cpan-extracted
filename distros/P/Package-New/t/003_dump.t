# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 17;

BEGIN { use_ok( 'Package::New::Dump' ); }

my $object = Bar->new(one=>{two=>{three=>{four=>{}}}});
isa_ok($object, 'Bar');
isa_ok($object, 'Foo');
isa_ok($object, 'Package::New::Dump');
isa_ok($object, 'Package::New');

can_ok($object, qw{new initialize dump});
can_ok($object, qw{bar});
can_ok($object, qw{baz});
is($object->bar, "baz", "object method");
is(Bar->bar,     "baz", "class method");
is($object->baz, "buz", "object method");
is(Bar->baz,     "buz", "class method");

{
  my $dump = $object->dump(1);
  diag($dump);
  $dump =~ s/\s+//g; #white space compress
  $dump =~ s/0x[0-9a-f]+/XXX/;
  is($dump, q{$VAR1=bless({'one'=>'HASH(XXX)'},'Bar');});
}

{
  my $dump = $object->dump();
  diag($dump);
  $dump =~ s/\s+//g; #white space compress
  $dump =~ s/0x[0-9a-f]+/XXX/;
  is($dump, q{$VAR1=bless({'one'=>{'two'=>'HASH(XXX)'}},'Bar');});
}

{
  my $dump = $object->dump(undef);
  diag($dump);
  $dump =~ s/\s+//g; #white space compress
  $dump =~ s/0x[0-9a-f]+/XXX/;
  is($dump, q{$VAR1=bless({'one'=>{'two'=>'HASH(XXX)'}},'Bar');});
}

{
  my $dump = $object->dump(2);
  diag($dump);
  $dump =~ s/\s+//g; #white space compress
  $dump =~ s/0x[0-9a-f]+/XXX/;
  is($dump, q{$VAR1=bless({'one'=>{'two'=>'HASH(XXX)'}},'Bar');});
}

{
  my $dump = $object->dump(0);
  diag($dump);
  $dump =~ s/\s+//g; #white space compress
  is($dump, q{$VAR1=bless({'one'=>{'two'=>{'three'=>{'four'=>{}}}}},'Bar');});
}

{
  package #hide
  Foo;
  use base qw{Package::New::Dump};
  sub bar {"baz"};
  1;
}

{
  package #hide
  Bar;
  use base qw{Foo};
  sub baz {"buz"};
  1;
}
