#!/usr/bin/perl

use strict;
use lib '../blib/lib';
use PerlBean::Style qw(:codegen);

# Make a PerlBean collection
use PerlBean::Collection;
my $coll = PerlBean::Collection->new( {
    license => <<EOF,
This code is licensed under B<GNU GENERAL PUBLIC LICENSE>.
Details on L<http://gnu.org>.
EOF
} );

# Make a PerlBean attribute factory
use PerlBean::Attribute::Factory;
my $fact = PerlBean::Attribute::Factory->new();

# Make the Shape PerlBean and add it to the PerlBean collection
use PerlBean;
my $shape = PerlBean->new ( {
    package => 'Shape',
    short_description => 'geometrical shape package',
    abstract => 'geometrical shape package',
    autoloaded => 0,
} );
$coll->add_perl_bean( $shape );

# Make the area() interface method add it to the Shape PerlBean
use PerlBean::Method;
my $area = PerlBean::Method->new( {
    method_name => 'area',
    interface => 1,
    description => <<EOF,
Calculates the area of the C<Shape> object.
EOF
} );
$shape->add_method( $area );

# Make the Circle PerlBean and add it to the PerlBean collection
my $circle = PerlBean->new ( {
    package => 'Circle',
    base => [ qw( Shape ) ],
    short_description => 'circle shape',
    description => "circle shape\n",
    abstract => 'circle shape',
    autoloaded => 0,
} );
$coll->add_perl_bean( $circle );

# Make the Circle PerlBean radius attribute and add it to the Circle PerlBean
my $radius = $fact->create_attribute( {
    method_factory_name => 'radius',
    short_description => 'the shape\'s radius',
    allow_rx => [ qw( ^\d*(\.\d+)?$ ) ],
} );
$circle->add_method_factory( $radius );

# Make the Circle area() method add it to the Circle PerlBean
use PerlBean::Method;
my $op = &{$MOF}('get');
my $mb = $radius->get_method_base();
my $area_circle = PerlBean::Method->new( {
    method_name => 'area',
    body => <<EOF,
    my \$self = shift;

    return( 2 * \$PI * \$self->$op$mb() );
EOF
} );
$circle->add_method( $area_circle );

# Make a PI symbol and add it to the Circle PerlBean
my $symbol = PerlBean::Symbol->new( {
    symbol_name => '$PI',
    description => "The PI constant\n",
    assignment => 3.14 . ";\n",
    comment => "# The PI constant\n",
    export_tag => [ qw( geo ) ],
} );
$circle->add_symbol( $symbol );

# Make the geo export tag description and add it to the Circle PerlBean
use PerlBean::Described::ExportTag;
my $geo = PerlBean::Described::ExportTag->new( {
    export_tag_name => 'geo',
    description => "Geometric constants\n",
} );
$circle->add_export_tag_description( $geo );

# Make the Square PerlBean and add it to the PerlBean collection
my $square = PerlBean->new ( {
    package => 'Square',
    base => [ qw( Shape ) ],
    short_description => 'square shape',
    abstract => 'square shape',
    autoloaded => 0,
} );
$coll->add_perl_bean( $square );

# Make the Square PerlBean width attribute and add it to the Square PerlBean
my $width = $fact->create_attribute( {
    method_factory_name => 'width',
    short_description => 'the shape\'s width',
    allow_rx => [ qw( ^\d*(\.\d+)?$ ) ],
} );
$square->add_method_factory( $width );

# Make the Square area() method add it to the Square PerlBean
use PerlBean::Method;
$op = &{$MOF}('get');
$mb = $width->get_method_base();
my $area_square = PerlBean::Method->new( {
    method_name => 'area',
    body => <<EOF,
    my \$self = shift;

    return( \$self->$op$mb() * \$self->$op$mb() );
EOF
} );
$square->add_method( $area_square );

# Make the Rectangle PerlBean and add it to the PerlBean collection
my $rectangle = PerlBean->new ( {
    package => 'Rectangle',
    base => [ qw( Square ) ],
    short_description => 'rectangle shape',
    abstract => 'rectangle shape',
    autoloaded => 0,
} );
$coll->add_perl_bean( $rectangle );

# Make the Rectangle PerlBean height attribute and add it to the the PerlBean
my $height = $fact->create_attribute( {
    method_factory_name => 'height',
    short_description => 'the shape\'s height',
    allow_rx => [ qw( ^\d*(\.\d+)?$ ) ],
} );
$rectangle->add_method_factory( $height );

# Make the Rectangle area() method add it to the Rectangle PerlBean
use PerlBean::Method;
$op = &{$MOF}('get');
$mb = $width->get_method_base();
my $mb_height = $height->get_method_base();
my $area_rectangle = PerlBean::Method->new( {
    method_name => 'area',
    body => <<EOF,
    my \$self = shift;

    return( \$self->$op$mb() * \$self->$op$mb_height() );
EOF
} );
$rectangle->add_method( $area_rectangle );

# The directory name
my $dir = 'example.1';

# Remove the old directory
system ("rm -rf $dir");

# Make the directory
mkdir($dir);

# Write the collection
$coll->write($dir);

1;
