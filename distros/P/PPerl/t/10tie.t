#!perl -w
use strict;
use Test;
BEGIN { plan tests => 10 }

my $db = "foo.$$";
use DB_File;
my %foo;
tie(%foo, 'DB_File', $db, O_RDWR|O_CREAT, 0600)
  or die "couldn't create tie!";

%foo = ( foo => "foo",
         bar => "baz" );
untie(%foo);

my $shouldbe = `$^X t/tie.plx $db 2>&1`;
for(1..10) {
    ok(`./pperl t/tie.plx $db 2>&1`, $shouldbe);
}

unlink $db;

`./pperl -k t/tie.plx`;
