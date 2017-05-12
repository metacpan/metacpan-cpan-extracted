#!/usr/bin/env perl

use strict;
use warnings;
use Railsish::Database;
use Railsish::Record;

{
    no strict;
    no warnings;
    *Railsish::Database::_build_config = sub {
        return {
            dsn => "hash",
            user => "",
            password => ""
        };
    }
}

package Advertisement;
use Moose;
use MooseX::Types::DateTimeX qw(DateTime);
# use Any::Moose;
# use Any::Moose qw(X::Types::DateTimeX) => ['DateTime']; 

extends 'Railsish::Record';

has type  => ( isa => "Str", is => "ro", required => 1);
has url   => ( isa => "Str", is => "rw", required => 1);
has title => ( isa => "Str", is => "rw", required => 1);

has start_date => ( isa => DateTime, is => "rw", required => 1, coerce => 1 );
has end_date   => ( isa => DateTime, is => "rw", required => 1, coerce => 1 );

__PACKAGE__->meta->make_immutable;

package main;
use Test::More tests => 1;

my $obj = Advertisement->new(
    type => "normal",
    url => "http://example.com",
    title => "Example",
    start_date => "2009/05/08",
    end_date => "2009/10/08"
);


my @titles = ();
$obj->save;

pass; exit;

my $stream = Advertisement->find_all;
while (my $block = $stream->next) {
    for my $obj (@$block) {
        push @titles, $obj->title;
    }
}

is_deeply(\@titles, ["Example"]);

