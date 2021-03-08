package
    T::Exit; # hide from PAUSE

use v5.10;
use Moo;

use namespace::clean;

has status => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    return @args == 1 && !ref $args[0] ? { status => $args[0] }
         :                               $class->$orig(@args);
};

sub throw {
    my ($class, @args) = @_;
    die $class->new(@args);
}

1;
