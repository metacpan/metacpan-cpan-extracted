#!/usr/bin/env perl

use strict;
use warnings;
use Mojolicious::Lite;
use Test::Mojo;
use Test::More tests => 15;
use FindBin '$Bin';
use lib "$Bin/../lib";

plugin 'RelativeUrlFor';

my %follow = (
    'a/b/c' => 'a/b/d',
    'a/b/d' => 'a/c/d',
    'a/c/d' => 'b/c/d',
    'b/c/d' => 'b/c',
);

get '/*p' => sub {
    my $self = shift;
    my $new  = $follow{$self->param('p')};
    my $url  = $self->rel_url_for('foo', p => $new);
    $self->render(text => $url);
} => 'foo';

# create tester
my $t = Test::Mojo->new;

$t->get_ok('/a/b/c')->status_is(200)->content_is('d', 'right url');
$t->get_ok('/a/b/d')->status_is(200)->content_is('../c/d', 'right url');
$t->get_ok('/a/c/d')->status_is(200)->content_is('../../b/c/d', 'right url');
$t->get_ok('/b/c/d')->status_is(200)->content_is('./', 'right url');
$t->get_ok('/1/2/3')->status_is(200)->content_is('../..', 'right url');

__END__
