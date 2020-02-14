package My::Animal;
use parent 'Perinci::Class::Base';

our %SPEC;

$SPEC{speak} = {
    v => 1.1,
    is_meth => 1,
};
sub speak {
    die "Please override me!";
}

sub new {
    my ($package, %args) = @_;
    bless \%args, $package;
}

1;
