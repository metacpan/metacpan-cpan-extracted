package t::Module::NoFetchrowHashref;

use Data::Dumper;

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;
    print $Self->{DBObject}->FetchrowArray();
}

1;
