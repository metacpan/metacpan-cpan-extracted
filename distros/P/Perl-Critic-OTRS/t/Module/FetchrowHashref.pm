package t::Module::FetchrowHashref;

use Data::Dumper;

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;
    print $Self->{DBObject}->FetchrowHashref();
}

1;
