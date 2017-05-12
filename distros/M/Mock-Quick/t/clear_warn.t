use strict;
use warnings;

use Test::More;

BEGIN {
    unless(eval { require Path::Class; 1 }) {
        Test::More->import(skip_all => 'Path::Class is needed for this test');
        exit 0;
    }
}

use Mock::Quick;
use Path::Class;

my $x = qobj(foo => qmeth { print "# My file is $_[1]\n" });

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    $x->foo( file(".") );
}
ok(!@warnings, "No warnings") || print STDERR @warnings;

done_testing;
