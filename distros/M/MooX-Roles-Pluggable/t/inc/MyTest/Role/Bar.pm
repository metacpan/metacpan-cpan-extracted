package #
    MyTest::Role::Bar;

use Moo::Role;

around info => sub {
    my $next = shift;
    my $self = shift;
    my $info = $self->$next(@_);
    $info->{Bar} = 1;
    push @{$info->{pkgs}}, __PACKAGE__,
    return $info;
};

1;
