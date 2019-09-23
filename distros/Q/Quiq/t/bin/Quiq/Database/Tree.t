#!/usr/bin/env perl

package Quiq::Database::Tree::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Perl;
use Quiq::Database::Tree;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Database::Tree');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(35) {
    my $self = shift;

    Quiq::Perl->createClass('Person','Quiq::Database::Row::Object');
    my $tab = Person->makeTable(
        [qw/id parent_id name/],
        1,'','A',
        2,1,'B',
        3,2,'C',
        4,1,'D',
    );
    my $tree = Quiq::Database::Tree->new($tab,'id','parent_id');
    my $h = $tree->pkIndex;

    # parent

    my $row = $tree->parent(1);
    $self->is($row,undef);

    $row = $tree->parent(2);
    $self->is($row->id,1);

    $row = $tree->parent(3);
    $self->is($row->id,2);

    $row = $tree->parent(4);
    $self->is($row->id,1);

    # childs()

    my @rows = $tree->childs(1);
    $self->isDeeply(\@rows,[$h->get(2),$h->get(4)]);

    @rows = $tree->descendants(2);
    $self->isDeeply(\@rows,[$h->get(3)]);

    @rows = $tree->descendants(3);
    $self->isDeeply(\@rows,[]);

    @rows = $tree->descendants(4);
    $self->isDeeply(\@rows,[]);

    # descendants()

    @rows = $tree->descendants(1);
    $self->is(scalar @rows,3);
    $self->isDeeply(\@rows,[$h->get(2),$h->get(3),$h->get(4)]);

    @rows = $tree->descendants($h->get(1)); # $row als Argument
    $self->is(scalar @rows,3);
    $self->isDeeply(\@rows,[$h->get(2),$h->get(3),$h->get(4)]);

    @rows = $tree->descendants(2);
    $self->is(scalar @rows,1);
    $self->isDeeply(\@rows,[$h->get(3)]);

    @rows = $tree->descendants(3);
    $self->is(scalar @rows,0);

    @rows = $tree->descendants(4);
    $self->is(scalar @rows,0);

    # @rows = path(...)

    @rows = $tree->path(1);
    $self->isDeeply(\@rows,[$h->get(1)]);

    @rows = $tree->path(2);
    $self->isDeeply(\@rows,[$h->get(1),$h->get(2)]);

    @rows = $tree->path(3);
    $self->isDeeply(\@rows,[$h->get(1),$h->get(2),$h->get(3)]);

    @rows = $tree->path(4);
    $self->isDeeply(\@rows,[$h->get(1),$h->get(4)]);

    # @values = path(...)

    @rows = $tree->path(1,'id');
    $self->isDeeply(\@rows,[1]);

    @rows = $tree->path(2,'id');
    $self->isDeeply(\@rows,[1,2]);

    @rows = $tree->path(3,'id');
    $self->isDeeply(\@rows,[1,2,3]);

    @rows = $tree->path(4,'id');
    $self->isDeeply(\@rows,[1,4]);

    # $path = path(...)

    my $path = $tree->path(1,'name','/');
    $self->is($path,'A');

    $path = $tree->path(2,'name','/');
    $self->is($path,'A/B');

    $path = $tree->path(3,'name','/');
    $self->is($path,'A/B/C');

    $path = $tree->path($h->get(3),'name','/'); # $row als Argument
    $self->is($path,'A/B/C');

    $path = $tree->path(4,'name','/');
    $self->is($path,'A/D');

    # siblings()
    
    @rows = $tree->siblings(1);
    $self->is(scalar @rows,0);

    @rows = $tree->siblings(2);
    $self->is(scalar @rows,1);
    $self->isDeeply(\@rows,[$h->get(4)]);

    @rows = $tree->siblings(3);
    $self->is(scalar @rows,0);

    @rows = $tree->siblings(4);
    $self->is(scalar @rows,1);
    $self->isDeeply(\@rows,[$h->get(2)]);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Database::Tree::Test->runTests;

# eof
