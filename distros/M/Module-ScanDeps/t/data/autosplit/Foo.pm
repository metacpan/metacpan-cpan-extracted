package Foo;

use strict;
use warnings;

use AutoLoader 'AUTOLOAD';

sub blab
{
    my @blab = @_;
    print "begin blab\n";
    print "$_\n" foreach @blab;
    print "end blab\n";
}

1;

__END__

sub fred { print "fred!\n" };
sub barnie { print "barnie!\n" };
