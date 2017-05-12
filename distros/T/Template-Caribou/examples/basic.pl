#!/usr/bin/perl 

use 5.10.0;


use strict;
use warnings;

use HelloWorld;

my $template = HelloWorld->new(
    user_name => 'Yanick'
);

print $template->render( 'page' );

