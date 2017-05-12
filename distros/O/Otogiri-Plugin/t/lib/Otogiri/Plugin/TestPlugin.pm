package Otogiri::Plugin::TestPlugin;
use strict;
use warnings;
our @EXPORT = qw(test_method very_useful_method_but_has_so_long_name);

sub test_method {
    my ($self, @args) = @_;
    return 'this is test_method ' . join(':', @args);
}

sub very_useful_method_but_has_so_long_name {
    my ($self, @args) = @_;
    return 'long method name desune';
}

1;
