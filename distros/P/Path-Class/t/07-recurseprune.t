#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use Test::More;
use File::Temp qw(tempdir);

plan tests => 8;

use_ok 'Path::Class';

my $cwd = getcwd;
my $tmp = dir(tempdir(CLEANUP => 1));

# Test recursive iteration through the following structure:
#     a
#    / \
#   b   c
#  / \   \
# d   e   f
#    / \   \
#   g   h   i
(my $abe = $tmp->subdir(qw(a b e)))->mkpath;
(my $acf = $tmp->subdir(qw(a c f)))->mkpath;
$acf->file('i')->touch;
$abe->file('h')->touch;
$abe->file('g')->touch;
$tmp->file(qw(a b d))->touch;

my $a = $tmp->subdir('a');

# Warmup without pruning
{
    my %visited;
    $a->recurse( 
        callback => sub{
            my $item = shift;
            my $rel_item = $item->relative($tmp);
            my $tag = join '|', $rel_item->components;
            $visited{$tag} = 1;
        });

    is_deeply(\%visited, {
        "a" => 1, "a|b" => 1, "a|c" => 1,
        "a|b|d" => 1, "a|b|e" => 1, "a|b|e|g" => 1, "a|b|e|h" => 1,
        "a|c|f" => 1, "a|c|f|i" => 1, });
}

# Prune constant
ok( $a->PRUNE );

# Prune no 1
{
    my %visited;
    $a->recurse( 
        callback => sub{
            my $item = shift;
            my $rel_item = $item->relative($tmp);
            my $tag = join '|', $rel_item->components;
            $visited{$tag} = 1;
            return $item->PRUNE if $tag eq 'a|b';
        });

    is_deeply(\%visited, {
        "a" => 1, "a|b" => 1, "a|c" => 1,
        "a|c|f" => 1, "a|c|f|i" => 1, });
}

# Prune constant alternative way
use_ok("Path::Class::Entity");
ok( Path::Class::Entity::PRUNE() );
is( $a->PRUNE, Path::Class::Entity::PRUNE() );

# Prune no 2
{
    my %visited;
    $a->recurse( 
        callback => sub{
            my $item = shift;
            my $rel_item = $item->relative($tmp);
            my $tag = join '|', $rel_item->components;
            $visited{$tag} = 1;
            return Path::Class::Entity::PRUNE() if $tag eq 'a|c';
        });

    is_deeply(\%visited, {
        "a" => 1, "a|b" => 1, "a|c" => 1,
        "a|b|d" => 1, "a|b|e" => 1, "a|b|e|g" => 1, "a|b|e|h" => 1,
    });
}

#diag("PRUNE constant value: " . $a->PRUNE);
