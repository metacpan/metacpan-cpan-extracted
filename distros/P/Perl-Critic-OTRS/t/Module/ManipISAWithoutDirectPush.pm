package t::Module::ManipISAWithoutDirectPush;

use Data::Dumper;

our @ISA;
# ABSTRACT: This module is a test module

sub Test {
    my $Self = shift;

    @ISA = qw(Data::Dumper);
    @ISA = ('Data::Dumper');

    my $caller = caller(0);
    push @{"$caller\::ISA"}, 'Data::Dumper';
    push( @{"$caller\::ISA"}, 'Data::Dumper' );
}

1;
