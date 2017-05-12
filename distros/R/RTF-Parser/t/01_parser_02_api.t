#!/usr/bin/perl

# Tests for the RTF::Parser API...

use strict;
use warnings;

use RTF::Parser;
use Test::More tests => 22;

# Create a testing subclass...

{

    package RTFTest;

    # We'll be doing lots of printing without newlines, so don't buffer output

    $|++;

    # Subclassing magic...

    @RTFTest::ISA = ('RTF::Parser');

    # Redefine the API in a test-friendly way

    sub parse_start {
        my $self = shift;
        push( @{ $self->{_TEST_BUFFER} }, 'parse_start' );
    }

    sub group_start {
        my $self = shift;
        push( @{ $self->{_TEST_BUFFER} }, 'group_start' );
    }

    sub group_end {
        my $self = shift;
        push( @{ $self->{_TEST_BUFFER} }, 'group_end' );
    }
    sub text { my $self = shift; push( @{ $self->{_TEST_BUFFER} }, "text" ); }
    sub char { my $self = shift; push( @{ $self->{_TEST_BUFFER} }, 'char' ); }

    sub symbol {
        my $self = shift;
        push( @{ $self->{_TEST_BUFFER} }, 'symbol' );
    }

    sub parse_end {
        my $self = shift;
        push( @{ $self->{_TEST_BUFFER} }, 'parse_end' );
    }

}

my %do_on_control = (

    # What to do when we see any control we don't have
    #   a specific action for...

    '__DEFAULT__' => sub {

    },

    # Special bold handler

    'b' => sub {
        my $self = shift;
        my $type = shift;
        my $arg  = shift;
        push( @{ $self->{_TEST_BUFFER} }, "[$type][$arg]" );
    },

);

# Grab DATA...

my $data = join '', (<DATA>);

# Create an instance of the class we created above

my $parser = RTFTest->new();
$parser->{_TEST_BUFFER} = [];

# Prime the object with our control handlers...

$parser->control_definition( \%do_on_control );

# Don't skip undefined destinations...

$parser->dont_skip_destinations(1);

# Start the parsing!

$parser->parse_string($data);

# Check our test buffer

my @actions = @{ content() };

foreach my $buffer ( @{ $parser->{_TEST_BUFFER} } ) {

    my $control = shift(@actions);

    is( $buffer, $control, "$buffer found" );

}

sub content {

    return [

        'parse_start',
        'group_start',
        'group_start',
        'group_start',
        'text',
        'group_end',
        'group_end',
        'group_start',
        'text',
        'char',
        'text',
        'text',
        'char',
        'text',
        'text',
        'group_end',
        'symbol',
        '[b][1]',
        'text',
        '[b][0]',
        'group_end',
        'parse_end',

    ];

}

__END__
{\rtf1\ansi\deff0{\fonttbl{\f0 Times New Roman;}}
{\pard\sb300\li900
  Toc toc Il a ferm\'e9 la porte\line
  Les lys du jardin sont fl\'e9tris\line
  Quel est donc ce mort qu'on emporte
  \par}\_\b1 Tell me it's so :-)\b0}
