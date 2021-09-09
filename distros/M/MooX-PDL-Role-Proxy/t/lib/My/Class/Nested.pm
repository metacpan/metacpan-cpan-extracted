package My::Class::Nested;

use Module::Load 'load';

use Moo::Role;
use PDL::Lite ();

has "+c1" => (
    is      => 'rwp',
    default => sub {
        my $class = shift;
        load $class->test_class;
        $class->test_class->new;
    },
);

has "+c2" => (
    is      => 'rwp',
    default => sub {
        my $class = shift;
        load $class->test_class;
        $class->test_class->new;
    },
);


1;
