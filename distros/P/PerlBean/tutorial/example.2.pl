#!/usr/bin/perl

use strict;

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

# Make a PerlBean calles MyTwistedMemory
use PerlBean;
my $perl_bean = PerlBean->new ( {
    package => 'MyTwistedMemory',
    short_description => 'my twisted memory',
    abstract => 'my twisted memory',
    autoloaded => 0,
} );
$coll->add_perl_bean( $perl_bean );

# PerlBean::Attribute::Single
my $attr = $fact->create_attribute( {
    method_factory_name => 'mood',
    short_description => 'the mood I\'m in today',
    allow_value => [ qw( good excelent ) ],
} );
$perl_bean->add_method_factory( $attr );

# PerlBean::Attribute::Boolean
$attr = $fact->create_attribute( {
    type => 'BOOLEAN',
    method_factory_name => 'late',
    short_description => 'it is late',
    default_value => 1,
} );
$perl_bean->add_method_factory( $attr );

# PerlBean::Attribute::Multi::Ordered
$attr = $fact->create_attribute( {
    type => 'MULTI',
    ordered => 1,
    method_factory_name => 'seq_random_nr_i_rem',
    short_description => 'a funny sequence of random numbers I can remember',
    allow_value => [ qw( 1 2 3 4 5 6 7 8 9 0 ) ],
    default_value => [ qw( 0 0 7 ) ],
} );
$perl_bean->add_method_factory( $attr );

# PerlBean::Attribute::Multi::Unique
$attr = $fact->create_attribute( {
    type => 'MULTI',
    unique => 1,
    method_factory_name => 'all_ssn_i_know_by_hart',
    short_description => 'the list of all SSN I know by hart',
} );
$perl_bean->add_method_factory( $attr );

# PerlBean::Attribute::Multi::Unique::Ordered
$attr = $fact->create_attribute( {
    type => 'MULTI',
    unique => 1,
    ordered => 1,
    method_factory_name => 'traveling_salesman_itinerary',
    short_description => 'the list of paces the traveling salesman visits',
} );
$perl_bean->add_method_factory( $attr );

# PerlBean::Attribute::Multi::Unique::Associative
$attr = $fact->create_attribute( {
    type => 'MULTI',
    unique => 1,
    associative => 1,
    method_factory_name => 'fileno_to_io_handle',
    short_description => 'list of file numbers and their IO::Handle',
    allow_isa => [ qw(IO::Handle) ],
} );
$perl_bean->add_method_factory( $attr );

# PerlBean::Attribute::Multi::Unique::Associative::MethodKey
$attr = $fact->create_attribute( {
    type => 'MULTI',
    unique => 1,
    associative => 1,
    method_key => 'fileno',
    method_factory_name => 'io_handle_by_fileno',
    short_description => 'list of IO::Handle by fileno',
    allow_isa => [ qw(IO::Handle) ],
} );
$perl_bean->add_method_factory( $attr );

# The directory name
my $dir = 'example.2';

# Remove the old directory
system ("rm -rf $dir");

# Make the directory
mkdir($dir);

# Write the collection
$coll->write($dir);
