package Animal;
use Rubyish::Attribute qw(:all);

BEGIN {

  attr_accessor qw(name);
  attr_reader qw(color);
  attr_writer qw(type);

}

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    for (keys %$args) {
        $self->{$_} = $args->{$_};
    }
    $self;
}

sub instant_name {
  my ($self, $new_name) = @_;
  __name__ = $new_name;
  __name__;
}

sub instant_color {
  my ($self) = @_;
  __color__;
}

sub instant_type {
  my ($self) = @_;
  __type__;
}


1;

