#
# $Id: ui.pm,v 1.1.1.1 2004/11/22 19:16:02 owensc Exp $

package Myco::UI::Foo;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

1;

