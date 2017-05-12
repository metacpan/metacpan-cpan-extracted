#!perl -T
use strict;
use warnings;
use Sub::Pipe;
use Test::More 'no_plan';    # tests => 1;

my $encode_entities = joint {
    my $str = shift;
    $str =~ s{([&<>"])}{
        '&' . { qw/& amp  < lt > gt " quot/ }->{$1} . ';' ;
    }msgex;
    $str;
};

sub replace {
    my ($regexp, $replace) = @_;
    joint {
        my $str = shift;
        $str =~ s{$regexp}{$replace}g;
        $str;
    }
}

# warn '<a>' | $encode_entities;
is "<a>" | $encode_entities, '&lt;a&gt;';
is "foo" | replace('f','b'), 'boo';
