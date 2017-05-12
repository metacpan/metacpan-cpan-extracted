package Pinwheel::View::String;

use overload
    '""' => \&to_string,
    '.' => \&concat;


sub new
{
    my ($class, $raw, $escape) = @_;
    my ($d);

    $raw = ref($raw) ? $raw : [[$raw]];
    foreach (@$raw) {
        if (ref($_) eq 'Pinwheel::View::String') {
            push @$d, @{$_->_export()};
        } else {
            push @$d, $_;
        }
    }

    return bless({d => $d, escape => $escape}, $class);
}

sub clone
{
    my ($self, $d) = @_;
    return bless({d => $d, escape => $self->{escape}}, ref($self));
}

sub concat
{
    my ($self, $b, $order) = @_;
    my $a = $self->{d};

    $b = ref($b) ? $b->_export() : [$b];
    if (!defined($order)) {
        # $a .= $b
        push @$a, $_ foreach (@$b);
    } elsif (!$order) {
        # $a . $b
        $self = $self->clone([@$a, @$b]);
    } else {
        # $b . $a
        $self = $self->clone([@$b, @$a]);
    }

    return $self;
}

sub concat_raw
{
    push @{$_[0]->{d}}, [$_[1]];
    return $_[0];
}

sub add
{
    my ($self, $b) = @_;
    $b = ref($b) ? $b->_export() : [$b];
    return $self->clone([@{$self->{d}}, @$b]);
}

sub radd
{
    my ($self, $b) = @_;
    $b = ref($b) ? $b->_export() : [$b];
    return $self->clone([@$b, @{$self->{d}}]);
}

sub to_string
{
    my ($self) = @_;
    my ($escape, $s);

    $escape = $self->{escape} || sub { $_[0] };
    $s = '';
    $s .= ref($_) ? $_->[0] : $escape->($_) foreach (@{$self->{d}});
    $self->{d} = [[$s]];

    return $s;
}

sub _export
{
    my ($self) = @_;

    return $self->{d} unless $self->{escape};
    return [map { ref($_) ? $_ : [$self->{escape}($_)] } @{$self->{d}}];
}


1;
