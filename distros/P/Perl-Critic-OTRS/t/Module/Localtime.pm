package t::Module::Localtime;

use Data::Dumper;

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;

    my $date  = localtime;
    my $date2 = localtime();
    my $date3 = localtime(3);
}

1;
