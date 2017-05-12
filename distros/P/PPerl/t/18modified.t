#!perl -w
use strict;
use Test;
plan tests => 4;

# yes, all this echo futz is fairly nonportable - bite me.

my $pperl = './pperl -Iblib/lib -Iblib/arch';
my $file = 'modified.plx';
`echo "print 'foo'">$file`;

ok( `$^X $file`,    'foo' );
ok( `$pperl $file`, 'foo' );

`echo "print 'bar'">$file`;
ok( `$^X $file`,    'bar' );
ok( `$pperl $file`, 'bar' );

`$pperl -k $file`;
unlink $file;
