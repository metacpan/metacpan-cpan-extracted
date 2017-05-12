{
    package My::Class;
    use Moo;

    with 'MooX::Emulate::Class::Accessor::Fast';

    sub BUILD {
        my ($self, $args) = @_;
        return $self;
    }
}

use Test::More tests => 1;
my $i = My::Class->new(totally_random_not_an_attribute => 1);
is $i->{totally_random_not_an_attribute}, 1, 'Unknown attrs get into hash';

