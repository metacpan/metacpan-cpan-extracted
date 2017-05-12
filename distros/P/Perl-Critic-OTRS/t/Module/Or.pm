package t::Module::Or;

use Data::Dumper;

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;

    my $op1 = 1;
    my $op2 = 3;

    if ( $op1 or $op2 ) {
        print "yes";
    }

    if ( $op1 || $op2 ) {
        print "yes";
    }
}

1;
