package t::Module::NoCamelCase;

use Data::Dumper;

# ABSTRACT: This module is a test module

# this is an exception of the rule
# as "new" is used for constructors
sub new {
}

sub test {
    my $self = shift;

    my $long_variable_name = 1;
    my $four = 4;
    my $testVar = 5;
}

1;
