#!perl -w

use strict;
use Benchmark qw(:all);

use Digest::MD5 qw(md5_hex);

print "Benchmark for native traits (Array)\n";

{
    package MouseList;
    use Mouse;

    has list => (
        traits => ['Array'],

        is  => 'rw',

        handles => {
            sort      => 'sort',
            sort_by   => 'sort_by',
        },
        default => sub{ [] },
    );

    __PACKAGE__->meta->make_immutable();
}

sub f{
    return md5_hex($_[0]);
}

print "sort_by vs. sort (10 items)\n";
cmpthese -1 => {
    sort_by => sub{
        my $o = MouseList->new(list => [0 .. 10]);
        my @a = $o->sort_by(sub{ f($_) }, sub{ $_[0] cmp $_[1] });
    },
    sort => sub{
        my $o = MouseList->new(list => [0 .. 10]);
        my @a = $o->sort(sub{ f($_[0]) cmp f($_[1]) });
    },
};

print "sort_by vs. sort (100 items)\n";
cmpthese timethese -1 => {
    sort_by => sub{
        my $o = MouseList->new(list => [0 .. 100]);
        my @a = $o->sort_by(sub{ f($_) }, sub{ $_[0] cmp $_[1] });
    },
    sort => sub{
        my $o = MouseList->new(list => [0 .. 100]);
        my @a = $o->sort(sub{ f($_[0]) cmp f($_[1]) });
    },
};
