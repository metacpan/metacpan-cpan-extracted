package Test04Base;

use Moose;

has 'test1' => (
    is              => 'rw',
    isa             => 'Str',
);

has 'test2' => (
    is              => 'rw',
    isa             => 'Bool',
);

has 'test3' => (
    is              => 'rw',
    isa             => 'Str',
);

sub run {
    print "RAN";
}

1;