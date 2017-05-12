package TAEB::Message;
use TAEB::OO;

sub name {
    my $self = shift;
    my $class = blessed($self) || $self;

    $class =~ s/.*:://;
    return lc $class;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

