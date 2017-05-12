package MyEnum;
use strict;

sub new {
    my ($class, @x) = @_;
    return bless [ @x ], $class;
}

sub each {
    my ($self, $cb) = @_;

    my $i = 0;
    for my $x (@$self) {
        local $_ = $x;
        $cb->($i++);
    }
}

1;
