package MyRDGC;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw/ Static::Simple::ByClass /;

our $VERSION = '0.01';

__PACKAGE__->config( 
    name => 'MyRDGC',
    default_view => 'RDGC',
    'Plugin::Static::Simple::ByClass' =>
        { classes => [qw( CatalystX::CRUD::YUI::TT )], }
);
__PACKAGE__->setup;

#warn Data::Dump::dump( MyRDGC->config );

# required by CatalystX::CRUD::YUI
use MRO::Compat;
use mro 'c3';
Class::C3::reinitialize();

#warn Data::Dump::dump( MyRDGC->config );

1;
