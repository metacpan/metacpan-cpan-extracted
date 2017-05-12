#!/usr/bin/perl 
require SVN::Notify::Mirror;
use Test::More tests => 12;

sub shortest {
    my ( $dirs, $expected ) = @_;

    is(SVN::Notify::Mirror::_shortest_path(@$dirs), $expected);
    is(SVN::Notify::Mirror::_shortest_path(reverse(@$dirs)), $expected);
}

shortest(['/foo/bar', '/foo/baz', '/foo/blargh'], '/foo');
shortest(['/foo/bar', '/foo/bar'], '/foo');
shortest(['/foo/bar'], '/foo');
shortest(['/foo/bar/a', '/foo/bar/b', '/blar/blagh'], '');
shortest(['/'], '');
shortest(['', '/foo/bar', '', '/foo/baz'], '/foo');
