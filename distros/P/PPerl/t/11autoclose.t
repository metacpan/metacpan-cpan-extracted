#!perl -w
use Test;
BEGIN { plan tests => 4 }

`./pperl --prefork=1 t/autoclose.plx`;

my $file = "foo.$$";
my $foo;

`$^X t/autoclose.plx $file foo`;
ok(`$^X t/cat.plx $file`, "foo\n");
`$^X t/autoclose.plx $file bar`;
ok(`$^X t/cat.plx $file`, "foo\nbar\n");

unlink $file;

`./pperl t/autoclose.plx $file foo`;
ok(`$^X t/cat.plx $file`, "foo\n");
`./pperl t/autoclose.plx $file bar`;
ok(`$^X t/cat.plx $file`, "foo\nbar\n");

`./pperl -k t/autoclose.plx`;
`./pperl -k t/cat.plx`;

unlink $file;
