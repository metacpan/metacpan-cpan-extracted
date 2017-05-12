#!/usr/bin/perl -w

use strict;

my $pre;
my $post;

use Test::More tests => 3;

use lib 't/lib'; use Prototyped;
use Sub::WrapPackages (
    packages => [qw(Prototyped)],
    pre => sub { $pre = \@_; },
    post => sub { $post = \@_; }
);

my @foo = (1,2,3);
my $r = [Prototyped::prototyped(@foo, 'cow')];
is_deeply($r, [ [1, 2, 3], 'cow'], "prototyped subs work right");
is_deeply($pre, [
    'Prototyped::prototyped',
    [1, 2, 3], 'cow'
], "pre gets the right prototype-ish data");
is_deeply($post, [
    'Prototyped::prototyped',
    [1, 2, 3], 'cow'
], "post gets the right data");
