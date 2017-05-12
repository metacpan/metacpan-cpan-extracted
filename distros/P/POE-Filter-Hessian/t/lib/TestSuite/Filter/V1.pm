package  TestSuite::Filter::V1;

use strict;
use warnings;
use base 'TestSuite::Filter';

use YAML;
use Test::More;
use Test::Deep;

use POE::Filter::Hessian;

sub prep001_set_version : Test(startup) {    #{{{
    my $self = shift;
    $self->{version} = 1;
}    #}}}

sub t007_hessian_simple_buffer_read : Test(5) {    #{{{
    my $self             = shift;
    my $hessian_elements = [
        "Vt\x00\x04[intl\x00\x00\x00\x02\x90\x91z",
        "\x4dt\x00\x08SomeType\x05color\x0aaquamarine"
          . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00z",
        "Mt\x00\x0aLinkedListS\x00"
          . "\x04headI\x00\x00\x00\x01S\x00\x04tailR\x00\x00\x00\x02z",
    ];
    my $filter = $self->{filter};
    $filter->get_one_start($hessian_elements);
    my $some_chunk = $filter->get_one()->[0];
    cmp_deeply( $some_chunk, [ 0, 1 ], "Array [ 0, 1] taken out of filter." );
    my $second_chunk = $filter->get_one()->[0];
    isa_ok( $second_chunk, 'SomeType',
        'Data structure returned by deserializer' );
    is( $second_chunk->{model}, 'Beetle',
        'Model attribute has correct value.' );
    like( $second_chunk->{mileage},
        qr/\d+/, 'Mileage attribute is an integer.' );

    my $third_chunk = $filter->get_one()->[0];
    isa_ok( $third_chunk, 'LinkedList', "Object parsed by deserializer" );
    $self->{dataset1} = [ $some_chunk, $second_chunk, $third_chunk ];
    $self->{hessian_sets} = $hessian_elements;

}    #}}}

sub t009_hessian_filter_get : Test(3) {    #{{{
    my $self = shift;
    my $map =
        "MI\x00\x00\x00\x01"
      . "S\x00\x03fee"
      . "I\x00\x00\x00\x10"
      . "S\x00\x03fie"
      . "I\x00\x00\x01\x00"
      . "S\x00\x03foe" . "z";
      my $object_definition = "";
    my $hessian_elements = [
        $map,
        "Vt\x00\x04[intl\x00\x00\x00\x02\x90\x91z",
        "\x4dt\x00\x08SomeType\x05color\x0aaquamarine"
          . "\x05model\x06Beetle\x07mileageI\x00\x01\x00\x00z",
        "Mt\x00\x0aLinkedListS\x00"
          . "\x04headI\x00\x00\x00\x01S\x00\x04tailR\x00\x00\x00\x04z",
    ];

    my $processed_chunks = $self->{filter}->get($hessian_elements);
    cmp_deeply(
        $processed_chunks->[0],
        { 1 => 'fee', 16 => 'fie', 256 => 'foe' },
        "Received expected datastructure."
    );

    my $object = $processed_chunks->[2];
    print "Got object: " . Dump($object) . "\n";
    is( $object->{color}, 'aquamarine', 'Correctly accessed object color' );
    is( $object->{model}, 'Beetle', 'Correclty accessed object model' );
}    #}}}

sub t011_put_hessian_data : Test(2) {    #{{{
    my $self             = shift;
    my $filter           = POE::Filter::Hessian->new( version => 1 );
    my $dataset          = $self->{dataset1};
    my $hessian_elements = $self->{hessian_sets};
    my $processed_hessian = $filter->put($dataset);
    local $TODO= 'Problem with hessian serialization';
    isa_ok( $processed_hessian, 'ARRAY', "Received expected datastructure." );
    my $reverse_processed = $filter->get($processed_hessian);
    cmp_deeply( $dataset, $reverse_processed,
        "Received same datastructure we put in.." );
}    #}}}

"one, but we're not the same";

__END__


=head1 NAME

TestSuite::Filter - Base class for testing POE::Filter::Hessian

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

/bin/bash: format: command not found
