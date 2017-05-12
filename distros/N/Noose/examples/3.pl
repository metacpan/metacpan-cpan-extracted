use v5.14.0;
use strict;
use warnings;
use Data::Printer;
use Data::Dumper;

package Thing {
    use Noose;
    sub exclaim {
        my $self = shift;
        die 'BLARGH' unless $self->a == 1;
        say 'yepyepyep';
    }
}

my $thing = Thing->new( a => 0 );
my $new = $thing->new( a => 2 ); # override a
my $clone = $new->new();         # clone

p $thing;
p $new;
p $clone;
print Dumper { thing => $thing, new => $new, clone => $clone }; # no $VAR1->{...}