#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use lib qw( ./lib ../lib );
use Pod::POM;
use Pod::POM::View;
use Pod::POM::Test;

ntests(2);

#------------------------------------------------------------------------
package My::View;
use parent qw( Pod::POM::View::Text );

sub view_head1 {
    my ($self, $head1) = @_;
    my $title = $head1->title->present($self);

    $self->visit('head1');
    my $output = "<h1>$title</h1>\n\n"
	. $head1->content->present($self);
    $self->leave('head1');

    return $output;
}

sub view_head2 {
    my ($self, $head2) = @_;
    my $title = $head2->title->present($self);

    if ($self->visiting('head1')) {
	return "<h2>$title</h2>\n\n"
	    . $head2->content->present($self);
    }
    else {
	return "<h1>$title</h1>\n\n"
	    . $head2->content->present($self);
    }
}

#------------------------------------------------------------------------
package main;
    
my $text;
{   local $/ = undef;
    $text = <DATA>;
}
my ($test, $expect) = split(/\s*-------+\s*/, $text);

my $parser = Pod::POM->new();

my $pom = $parser->parse_text($test);

assert( $pom );

$Pod::POM::DEFAULT_VIEW = 'My::View';

my $result = "$pom";

for ($result, $expect) {
    s/^\s*//;
    s/\s*$//;
}

match($result, $expect);

__DATA__
=head2 TWO

Outer head2

=head1 FIRST

First head1

=head1 SECOND

Second head1

=head2 INNER

Inner head2

=head1 THIRD

Third head1
------------------------------------------------------------------------
<h1>TWO</h1>

Outer head2

<h1>FIRST</h1>

First head1

<h1>SECOND</h1>

Second head1

<h2>INNER</h2>

Inner head2

<h1>THIRD</h1>

Third head1

