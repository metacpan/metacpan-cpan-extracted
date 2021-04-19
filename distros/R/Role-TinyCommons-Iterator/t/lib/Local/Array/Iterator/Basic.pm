package # hide from PAUSE
    Local::Array::Iterator::Basic;

use Role::Tiny::With;

with 'Role::TinyCommons::Iterator::Basic';

sub new {
    my ($class, @items) = @_;
    bless {
        array => \@items,
        pos => 0,
    }, $class;
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @{ $self->{array} };
}

sub get_next_item {
    my $self = shift;
    $self->{pos} < @{ $self->{array} } or die "StopIterator";
    $self->{array}[ $self->{pos}++ ];
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

1;
