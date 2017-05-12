package TestModuleB;
use threads;
use threads::shared;

{
    my $instance;
    sub get_instance : locked {
        my ($class, $name) = @_;
        return $instance if defined $instance;
        $instance = &share({});
        $instance->{name} = $name;
        return bless $instance, $class;
    }
}

sub get_name : locked method {
    my ($self) = @_;
    return $self->{name};
}

sub get_age : locked method {
    my ($self) = @_;
    return $self->{age}++;
}

1;
