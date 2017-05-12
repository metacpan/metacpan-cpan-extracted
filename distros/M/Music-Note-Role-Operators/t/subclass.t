#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
package Music::MyNote;
use parent 'Music::Note';
use Role::Tiny::With;
with 'Music::Note::Role::Operators';

package main;
my $note = Music::MyNote->new('C');
my $other = $note->clone;
ok $note->eq($other), "check class inherited ok";
ok $note == $other, "check same with overloading";

my $isanote = Music::Note->new('D');
TODO: {
    local $TODO = "comparing a Music::Note to a subclass with role applied maybe should work but currently doesn't";
     ok (Music::Note->new('D') > $note, "comparing a music::note to a subclass");
};

done_testing;
