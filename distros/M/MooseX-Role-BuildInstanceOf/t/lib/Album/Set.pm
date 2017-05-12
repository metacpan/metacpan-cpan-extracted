package Album::Set; {

    use Moose;
    use MooseX::Iterator;
    use List::Util qw(shuffle);

    has resource_types => (
        is => 'ro',
        isa => 'Object',
        required => 1,
    );

    has collection => (
        is => 'ro',
        isa => 'ArrayRef[HashRef]',
        required => 1,
    );

    has iterator => (
        is => 'ro',
        isa => 'MooseX::Iterator::Array',
        lazy_build => 1,
        handles => [qw/has_next reset/],
    );

    sub _build_iterator {
        my $self = shift @_;
        MooseX::Iterator::Array->new(
            collection => $self->collection,
        );
    }

    sub inflate {
        my ($self, $item) = @_;
        $self->resource_types->process($item);
    }

    sub peek {
        my $self = shift @_;
        my $peek = $self->iterator->peek;
        my $inflated = $self->inflate($peek);
        return $inflated;
    }

    sub next {
        my $self = shift @_;
        my $next = $self->iterator->next;
        my $inflated = $self->inflate($next);
        return $inflated;
    }

    sub all {
        my $self = shift @_;
        map {
            $self->inflate($_);
        } @{$self->collection};
    }

    sub find {
        my ($self, $title) = @_;
        my($match, @others) = grep {
            $_->{title} eq $title;
        } @{$self->collection};
        warn "find matches too many titles for $title"
          if @others;
        return $match ? $self->inflate($match) : undef;
    }

    sub slice {
        my ($self, $offset, $length) = @_;
        my @collection = splice(@{$self->collection}, $offset, $length);
        __PACKAGE__->new(
            collection => \@collection,
            resource_types => $self->resource_types,
        );
    }

    sub randomize {
        my $self = shift @_;
        my @collection = shuffle @{$self->collection};
        __PACKAGE__->new(
            collection => \@collection,
            resource_types => $self->resource_types,
        );
    }
}

1;
