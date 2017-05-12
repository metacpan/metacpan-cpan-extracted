package Cat;
use Rubyish;
use base 'Animal';

def sound {
    "meow, meow";
};

def speak {
    print "A cat goes " . $self->sound . "\n";
};

def play($toy) {
    if ($toy) {
        return "$toy is funny, " . $self->sound . "\n";
    }
    return $self->sound . "\n";
}

1;
