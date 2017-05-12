package My::Test::Class;
use strict;
use warnings;
use parent qw(Test::Class Class::Data::Inheritable);
use Test::More;

BEGIN {
    __PACKAGE__->mk_classdata('class');
}

sub _startup : Tests(startup => 1) {
    my $test = shift;
    (my $class = ref $test) =~ s/::Test$//;
    use_ok $class or die;
    $test->class($class);
}

1;

