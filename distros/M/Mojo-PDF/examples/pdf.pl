#!perl

use strict;
use warnings;
use lib 'lib';
use Mojo::PDF;

Mojo::PDF->new('myawesome.pdf')
    ->mixin('_template.pdf')
    ->font('Times-Bold')->size(24)->color(0, 0, .7)
        ->text('Mojo loves PDFs', 612/2, 500, 'center')
    ->font('TI')->size(12)->color
        ->text('Lorem ipsum dolor sit amet, ', 20 )
        ->text('consectetur adipiscing elit!')
    ->end;
