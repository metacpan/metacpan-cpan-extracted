package NotTrans;

sub new
{
    my ($self) = @_;
    my $class = ref($self) || $self;
    return bless {}, $class;
}

1;
