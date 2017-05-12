package Pegex::Forth::Runtime;
use Pegex::Base;
use POSIX;

has stack => [];
has return_stack => [];

sub call {
    my $self = shift;
    for my $word (@_) {
        my $function = $self->dict->{lc $word}
            or $self->error("Undefined word: '$word'");
        $function->($self);
    }
}

sub size {
    scalar(@{$_[0]->{stack}});
}

sub push {
    my ($self, @items) = @_;
    push @{$self->stack}, @items;
}

sub pop {
    my ($self, $count) = (@_);
    my $stack = $self->{stack};
    $self->underflow unless $count <= @$stack;
    return splice(@$stack, 0 - $count, $count);
}

sub peek {
    my $self = shift;
    my $stack = $self->{stack};
    map {
        my $i = $_ + 1;
        $self->underflow unless $i <= @$stack;
        my $a = $stack->[0 - $i];
        return $a unless wantarray;
    } @_;
}

sub underflow {
    $_[0]->error("Stack underflow");
}

sub error {
    die "$_[1]\n";
}

has dict => {

'.' => sub {
    my $num = $_[0]->pop(1);
    print "$num\n";
},

'.s' => sub {
    my $stack = $_[0]->stack;
    my $size = @$stack;
    print "<$size>" . join('', map " $_", @$stack) . "\n";
},

'+' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a + $b);
},

'-' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a - $b);
},

'*' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a * $b);
},

'/' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->error("Division by zero") if $b == 0;
    $_[0]->push(floor($a / $b));
},

'/2' => sub {
    my ($a) = $_[0]->pop(1);
    $_[0]->push(floor($a / 2));
},

'mod' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->error("Division by zero") if $b == 0;
    $_[0]->push($a % $b);
},

'/mod' => sub {
    $_[0]->call(qw(2dup mod -rot /));
},

'clearstack' => sub {
    $_[0]->{stack} = [];
},

'0sp' => sub {
    $_[0]->call('clearstack');
},

'dup' => sub {
    my ($a) = $_[0]->pop(1);
    $_[0]->push($a, $a);
},

'swap' => sub {
    $_[0]->push(reverse $_[0]->pop(2));
},

'over' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a, $b, $a);
},

'drop' => sub {
    $_[0]->pop(1);
},

'rot' => sub {
    my ($a, $b, $c) = $_[0]->pop(3);
    $_[0]->push($b, $c, $a);
},

'pick' => sub {
    $_[0]->push(scalar $_[0]->peek($_[0]->pop(1)));
},

'?dup' => sub {
    $_[0]->call('dup') if ($_[0]->peek(0) != 0);
},

'-rot' => sub {
    my ($a, $b, $c) = $_[0]->pop(3);
    $_[0]->push($c, $a, $b);
},

'2swap' => sub {
    my ($a, $b, $c, $d) = $_[0]->pop(4);
    $_[0]->push($c, $d, $a, $b);
},

'2over' => sub {
    my ($a, $b, $c, $d) = $_[0]->pop(4);
    $_[0]->push($a, $b, $c, $d, $a, $b);
},

'2dup' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a, $b, $a, $b);
},

'nip' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($b);
},

'tuck' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($b, $a, $b);
},

'abs' => sub {
    $_[0]->push(abs $_[0]->pop(1));
},

'negate' => sub {
    $_[0]->push(0 - $_[0]->pop(1));
},

'lshift' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a << $b);
},

'rshift' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a >> $b);
},

'arshift' => sub {
    use integer;
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a >> $b);
},

'min' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a < $b ? $a : $b);
},

'max' => sub {
    my ($a, $b) = $_[0]->pop(2);
    $_[0]->push($a > $b ? $a : $b);
},

'emit' => sub {
    print chr $_[0]->pop(1);
},

words => sub {
    print join(' ', sort keys %{$_[0]{dict}}) . "\n";
},

};

1
