package t::Module::PushToISA;

use Data::Dumper;

our @ISA;
# ABSTRACT: This module is a test module

sub Test {
    my $Self = shift;

    push @ISA, 'Data::Dumper';
    push( @ISA, 'Data::Dumper' );
    CORE::push @ISA, 'Data::Dumper';
    CORE::push( @ISA, 'Data::Dumper' );
}

1;
