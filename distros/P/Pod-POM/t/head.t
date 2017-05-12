#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM::Test;

#$Pod::POM::DEBUG = 1;
#$Pod::POM::Node::DEBUG = 1;
#my $DEBUG = 1;

ntests(13);

package My::View;
use parent qw( Pod::POM::View );

sub view_seq_entity {
    my ($self, $text) = @_;
    return "ENTITY: [$text]";
}

package main;

my $parser = Pod::POM->new();
my $pom = $parser->parse_file(\*DATA);
assert( $pom );

my $sections = $pom->head1();
match( scalar @$sections, 2 );
match( $sections->[0]->title(), 'NAME' );
match( $sections->[1]->title(), 'DESCRIPTION' );
match( $sections->[0]->type(), 'head1' );

my $items = $pom->head1->[1]->head2->[0]->over->[0]->item;
my $view = My::View->new();
match( $items->[0]->title, 'new() =E<gt> $object' );
match( $view->print($items->[0]->title), 'new() =ENTITY: [gt] $object' );

match( $view->print($sections->[0]->title()), 'NAME' );
match( $view->print($sections->[1]->title()), 'DESCRIPTION' );

my @expect = qw( NAME DESCRIPTION );
foreach my $head1 ($pom->head1()) {
    match( $head1->title(), shift @expect );
}

my $h3 = $pom->head1->[1]->head2->[0]->head3->[0];
match($view->print($h3->title), 'New Heading');

my $h4 = $h3->head4->[0];
match($view->print($h4->title), 'Newer Heading');

__DATA__
=head1 NAME

Document Name

=head1 DESCRIPTION

This is a description.

=head2 METHODS

These are the methods:

=over 4

=item new() =E<gt> $object

This is the constructor method.

=back

=head3 New Heading

Blah blah

=head4 Newer Heading

yah yah

