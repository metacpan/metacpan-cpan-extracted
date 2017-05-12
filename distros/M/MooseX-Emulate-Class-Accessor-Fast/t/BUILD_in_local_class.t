{
    package My::Class;
    use Moose;
    use namespace::clean -except => 'meta';

    with 'MooseX::Emulate::Class::Accessor::Fast';

    sub BUILD {
        my ($self, $args) = @_;
        return $self;
    }

    __PACKAGE__->meta->make_immutable;
}

use Test::More tests => 1;
my $i = My::Class->new(totally_random_not_an_attribute => 1);
is $i->{totally_random_not_an_attribute}, 1, 'Unknown attrs get into hash';

