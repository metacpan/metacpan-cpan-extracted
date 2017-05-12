#!perl -T

use strict;
use warnings FATAL => 'all';

use MooseX::PDF;
use Test::Most;

eval "use MooseX::ClassCompositor";
plan skip_all => "MooseX::ClassCompositor required for testing PDF creation" if $@;
eval "use Test::Moose";
plan skip_all => "Test::Moose required for testing PDF creation" if $@;

my @attributes  = qw( inc_path );
my @methods     = qw( create_pdf );
my ( $instance );

my  $class = MooseX::ClassCompositor->new(
    { class_basename => 'Test' })->class_for( 
        'MooseX::PDF',
    );

map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;

lives_ok{ 
    $instance = $class->new( inc_path => './' );
} 'Created a MooseX::PDF instance';

is ($instance->has_inc_path, 1, 'Has an include path');

TODO: {
    local $TODO = 'PDF creation tests incomplete';

    my $raw_pdf;
    lives_ok { $raw_pdf = $instance->create_pdf( 't/data/pdf_template.tt', { msg => 'Hello World!' } ); };
    is($@,'','No creation faults');
    diag('this is the raw pdf: ' . (defined $raw_pdf ? $raw_pdf : '<undef>'));

    #isa_ok($raw_pdf, 'MooseX::PDF');

    # other cool tests, for example;
    # is( 42, $instance->important_method( '?' ), 'The answer') )
}

done_testing();
