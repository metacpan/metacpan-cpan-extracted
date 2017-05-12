package MojoX::Session::Store::File::Driver::Storable;

use base 'MojoX::Session::Store::File::Driver';

use Storable qw(store retrieve);

sub new {
    my $class = shift;

    bless $class->SUPER::new(@_), $class;
}

sub freeze {
    my $self = shift;

    my($file, $ref) = @_;
    $ref = \$ref unless ref $ref;

    store $ref, $file;
}

sub thaw {
    my $self = shift;

    my $file = shift;

    retrieve $file;
}

1;
