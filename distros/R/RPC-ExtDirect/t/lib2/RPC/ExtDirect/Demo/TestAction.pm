package RPC::ExtDirect::Demo::TestAction;

use strict;
use warnings;
no  warnings 'uninitialized';

use Carp;

use RPC::ExtDirect Action => 'TestAction';

sub doEcho : ExtDirect(1) {
    my ($class, $data) = @_;

    return $data;
}

sub multiply : ExtDirect(1) {
    my ($class, $num) = @_;

    croak "Call to multiply with a value that is not a number"
        unless $num =~ / \A \d+ \z /xms;

    return $num * 8;
}

sub getTree : ExtDirect(1) {
    my ($class, $id) = @_;

    return if length $id == 3;

    return [ map { { id => "n$_", text => "Node $_", leaf => \0 } } 1..5 ]
        if $id eq 'root';

    my ($parent) = $id =~ /n(\d)/;

    return [
        map { { id => "$id$_", text => "Node $parent.$_", leaf => \1 } } 1..5
    ];
}

sub getGrid : ExtDirect( params => [ 'sort' ] ) {
    my ($class, %params) = @_;

    my $field     = $params{sort}->[0]->{property};
    my $direction = $params{sort}->[0]->{direction};

    my $sort_sub = sub {
        my ($foo, $bar)         = $direction eq 'ASC' ? ($a, $b)
                                :                       ($b, $a)
                                ;
        return $field eq 'name' ? $foo->{name}     cmp $bar->{name} 
                                : $foo->{turnover} <=> $bar->{turnover}
                                ;
    };

    my @data = sort $sort_sub (
        { name => 'ABC Accounting',         turnover => 50000   },
        { name => 'Ezy Video Rental',       turnover => 106300  },
        { name => 'Greens Fruit Grocery',   turnover => 120000  },
        { name => 'Icecream Express',       turnover => 73000   },
        { name => 'Ripped Gym',             turnover => 88400   },
        { name => 'Smith Auto Mechanic',    turnover => 222980  },
    );

    return [ @data ];
}

sub showDetails : ExtDirect(params => [qw(firstName lastName age)]) {
    my ($class, %params) = @_;

    my $first = $params{firstName};
    my $last  = $params{lastName};
    my $age   = $params{age};

    return "Hi $first $last, you are $age years old.";
}

1;
