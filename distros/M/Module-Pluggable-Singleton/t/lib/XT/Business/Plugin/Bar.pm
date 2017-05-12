package XT::Business::Plugin::Bar;

use Moose;
#
#extends 'XT::Business::Base';
#
#has 'blah' => (
#    is => 'ro',
#);
#
#no Moose;
#
sub foo {
    my($self,$foo) = @_;
    print "input was $foo\n";
}
1;
