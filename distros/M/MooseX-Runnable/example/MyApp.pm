package MyApp;
use Moose;
use 5.010;

with 'MooseX::Runnable', 'MooseX::Getopt';

has 'name' => ( is => 'ro', isa => 'Str', default => 'world', documentation =>
                  'Your name, defaults to "world"' );

sub run {
    my ($self, $name) = @_;
    say 'Hello, '. $self->name. '.';
    return 0;
}

1;

__END__

cd to this dir, and then run "mx-run MyApp --help"
