package Cat;
use Rubyish;

attr_accessor "name", "color", "master";

def sound { "meow, meow, meow" };

def play {
    for my $stuff(@args) {
        print "I CAN HAS " . uc($stuff) . "\n";
        push @{ $self->{played} ||=[] }, $stuff;
    }
};


1;
