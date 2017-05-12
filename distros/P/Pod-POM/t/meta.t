#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM qw( meta );
use Pod::POM::Nodes;
use Pod::POM::Test;

#$Pod::POM::Node::DEBUG = 1;
my $DEBUG = 1;


ntests(6);

my $parser = Pod::POM->new( warn => 1 );
my $pom = $parser->parse_file(\*DATA);
assert( $pom );

my @w = $parser->warnings();
if (@w) {
    print STDERR scalar @w, " warnings\n";
    foreach my $w (@w) {
	print STDERR "warning: $w\n";
    }
}
else {
    ok(1);
    # print "Syntax OK, no warnings\n";
}


match( $pom->meta('module'), 'Foo::Bar::Baz' );
match( $pom->meta('author'), 'Andy Wardley' );

my $meta = $pom->meta();
match( $meta->{ module }, 'Foo::Bar::Baz' );
match( $meta->{ author }, 'Andy Wardley' );


__DATA__
=meta module Foo::Bar::Baz

=meta author Andy Wardley

=head1 NAME

A test Pod document.

Another paragraph with a B<bold> tag.
