#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM::Test;

my $DEBUG = 1;

ntests(7);

my $parser = Pod::POM->new();
my $pom = $parser->parse_file(\*DATA);
assert( $pom );

my $text = $pom->head1->[0]->text;
assert( $text );
match( scalar @$text, 2 );
match( $text->[0], 
       "A test Pod document.\n\n" );
match( $text->[1], 
       "Another paragraph with a B<bold> tag.\n\n" );
match( $text, 
       "A test Pod document.\n\n"
     . "Another paragraph with a B<bold> tag.\n\n" );
match( $pom->head1->[0],
       "=head1 NAME\n\n"
     . "A test Pod document.\n\n"
     . "Another paragraph with a B<bold> tag.\n\n" );

__DATA__
=head1 NAME

A test Pod document.

Another paragraph with a B<bold> tag.
