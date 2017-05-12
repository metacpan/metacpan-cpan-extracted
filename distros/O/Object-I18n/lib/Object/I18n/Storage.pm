
package Object::I18n::Storage;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ($data) = @_;# from $obj->setter($data);

    my $obj = $class->init;
    $obj->store($data);
    return $obj;
}

sub init {
    my $class = shift;
    # This is where you set up special requirements like user, state, etc.
    # Does language go here too?
    bless {};
}

sub store {
    my $self = shift;
    $self->{data} = shift;
}

sub fetch {
    my $self = shift;
    $self->{data};
}

1;
