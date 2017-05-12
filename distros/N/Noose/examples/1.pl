use v5.14.0;
use strict;
use warnings;

package Thing {
    use Noose;

=head1 Name

Thing - an object

=head1 METHODS

=head2 new

The constructor must be called with C<< a => 1 >>, or nothing
will work.

=head2 exclaim

Utters an exclamation if the object was constructed correctly;
dies otherwise.

=cut

    sub exclaim {
        my $self = shift;
        die 'BLARGH' unless $self->a == 1;
        say 'yepyepyepyepyep'; # http://youtu.be/KTc3PsW5ghQ
    }
}

my $thing = Thing->new();
eval { $thing->exclaim };
print "$@" if $@; # nope

$thing = Thing->new(a => 0);
eval { $thing->exclaim };
print "$@" if $@; # BLARGH

$thing = Thing->new(a => 1);
eval { $thing->exclaim }; # The Martians are A-OK!
print "$@" if $@;

say 'DONE';
