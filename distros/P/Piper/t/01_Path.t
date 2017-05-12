#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Path module
#####################################################################

use v5.10;
use strict;
use warnings;

use Test::Most;

my $APP = "Piper::Path";

use Piper::Path;

#####################################################################

# Test 
{
    subtest "$APP - new" => sub {
        my $EXP = [qw(grandparent parent child)];

        my $path = Piper::Path->new(qw(grandparent parent child));
        is_deeply(
            $path->path,
            $EXP,
            'from array'
        );

        $path = Piper::Path->new(qw(grandparent/parent child));
        is_deeply(
            $path->path,
            $EXP,
            'from array with slash'
        );

        $path = Piper::Path->new(Piper::Path->new(qw(grandparent)), qw(parent/child));
        is_deeply(
            $path->path,
            $EXP,
            'from Piper::Path object and string'
        );
    };
}

# Test child
{
    subtest "$APP - child" => sub {
        my $path = Piper::Path->new('grandparent');
        my $exp = Piper::Path->new(qw(grandparent parent));

        is_deeply(
            $path->child('parent'),
            $exp,
            'one level'
        );

        $exp = Piper::Path->new(qw(grandparent parent child));

        is_deeply(
            $path->child(qw(parent child)),
            $exp,
            'two levels by array'
        );

        is_deeply(
            $path->child('parent/child'),
            $exp,
            'two levels by slashed string'
        );

        is_deeply(
            $path->child(Piper::Path->new(qw(parent child))),
            $exp,
            'two levels by Piper::Path object'
        );
    };
}

my $PATH = Piper::Path->new(qw(grandparent parent child));

# Test name
{
    subtest "$APP - name" => sub {
        is($PATH->name, 'child', "ok");
    };
}

# Test split
{
    subtest "$APP - split" => sub {
        is_deeply(
            [ $PATH->split ],
            [ qw(grandparent parent child) ],
            "ok"
        );
    };
}

# Test stringify
{
    subtest "$APP - stringify" => sub {
        is($PATH->stringify, 'grandparent/parent/child', 'by method');
        is("$PATH", 'grandparent/parent/child', 'by overload');
    };
}

#####################################################################

done_testing();
