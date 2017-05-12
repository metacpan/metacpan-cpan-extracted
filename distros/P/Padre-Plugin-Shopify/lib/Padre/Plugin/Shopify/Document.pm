#!/usr/bin/perl

use strict;
use warnings;

package Padre::Document::Liquid;
use parent 'Padre::Document';

sub colorize {
    my ($self) = @_;
 
    $self->remove_color;
 
    my $editor = $self->editor;
    my $text   = $self->text_get;
    
    print STDERR "K\n";
}
    

1;