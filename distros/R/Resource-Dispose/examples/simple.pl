#!/usr/bin/perl

use lib 'lib', '../lib';

package My::Class;
use Moose;

has 'ref' => (is => 'rw', clearer => 'clear_ref');

sub DISPOSE {
    warn "$_[0]\->DISPOSE called";
    $_[0]->clear_ref
}

sub DESTROY {
    warn "memory leak of @_" if ${^GLOBAL_PHASE} and ${^GLOBAL_PHASE} eq 'DESTRUCT';
}


package main;
use Resource::Dispose;

resource my ($obj1, $obj2);
$obj1 = My::Class->new();
$obj2 = My::Class->new();
$obj1->ref($obj2);
$obj2->ref($obj1);
