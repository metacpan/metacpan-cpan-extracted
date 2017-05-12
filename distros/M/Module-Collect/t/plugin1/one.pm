package One;
use strict;
use warnings;

sub new {
    my($class, $args) = @_;
    $args ||= {};
    bless { %{ $args } }, $class;
}

sub one { shift->{one} }
1;
