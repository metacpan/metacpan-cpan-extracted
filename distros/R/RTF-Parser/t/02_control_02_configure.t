#!/usr/bin/perl

# RTF::Parser's first unit-test! Yay :-)
#
# We're checking that our replacement _configure statment will work
#   in the same way that the original did.

use strict;
use warnings;

use RTF::Control;
use Test::More tests => 6;

{

    package RTF::TESTSET::ConfigureTests;
    use strict;
    use vars qw( $top_output );

    @RTF::TESTSET::ConfigureTests::ISA = ( 'Exporter', 'RTF::Control' );
    @RTF::TESTSET::ConfigureTests::EXPORT = qw( $top_output );

    $top_output = '123';

    # Redefine the set_top_output_to function that would
    #   normally be called.
    sub set_top_output_to {

        my $self = shift;
        $top_output = shift;
    }

}

my $object = RTF::TESTSET::ConfigureTests->new();

# Check that $top_output is accessible and our default value
is( $RTF::TESTSET::ConfigureTests::top_output,
    '123', 'We can check $top_output' );

# Try the different config styles...
$object->_configure( -output => 'answer1' );
is( $RTF::TESTSET::ConfigureTests::top_output, 'answer1', '-output worked' );

$object->_configure( -Output => 'answer2' );
is( $RTF::TESTSET::ConfigureTests::top_output, 'answer2', '-Output worked' );

$object->_configure( output => 'answer3' );
is( $RTF::TESTSET::ConfigureTests::top_output, 'answer3', 'output worked' );

$object->_configure( Output => 'answer4' );
is( $RTF::TESTSET::ConfigureTests::top_output, 'answer4', 'Output worked' );

# Just checking...
$object->_configure( -atput => 'answer5' );
is( $RTF::TESTSET::ConfigureTests::top_output,
    'answer4', "-atput didn't work (correct behaviour)" );
