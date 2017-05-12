package Perlipse::SourceParser::Utils;

use strict;

sub lastLocation
{
    my $class = shift;
    my ($element) = @_;
    
    my $last = $element->last_element;

    return (defined $last) ? $class->location($last) : 0;
}

sub location
{
    my $class = shift;
    my ($element) = @_;
    
    return $element->location->[3];
}

1;