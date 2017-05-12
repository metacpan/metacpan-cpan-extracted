package Stepford::Grapher::Renderer::Json;

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use JSON::PP qw( encode_json );

use Moose;

our $VERSION = '1.01';

with(
    'Stepford::Grapher::Role::Renderer',
);

has output => (
    is  => 'ro',
    isa => 'Str',
);

sub render {
    my $self = shift;
    my $data = shift;

    my $fh = \*STDOUT;
    if ( defined $self->output ) {

        # open as raw because encode_json produces bytes not chars
        open $fh, '>:raw', $self->output;
    }

    print $fh encode_json($data)
        or die "Problem printing JSON: $!";
    return;
}

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Render to a JSON data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::Grapher::Renderer::Json - Render to a JSON data structure

=head1 VERSION

version 1.01

=head1 SYNOPSIS

   my $grapher = Stepford::Grapher->new(
       step  => 'My::Step::ExampleStep',
       step_namespaces => ['My::Steps'],
       renderer => Stepford::Grapher::Renderer::Json->new(
           output => 'diagram.json',
       ),
   );
   $grapher->run;

=head1 DESCRIPTION

Renders the graph as a simple JSON data structure.

    {
        "Step::ExampleStep":{
            "the_air_that_i_breathe":"Step::Atmosphere",
            "to_love_you":"Step::Love",
        },
        "Step::Love":{
            "person":"Step::Partner",
            "oxytocin":"Step::Hug"
        },
        "Step::Partner":{
            "sugar":"Step::Supermarket",
            "spice":"Step::Supermarket",
            "all_things_nice":"Step::CotedAzur"
        },
        "Step::CotedAzur":{},
        "Step::Supermarket":{},
        "Step::Hug":{},
        "Step::Atmosphere":{
            "rainforest":"Step::Brazil",
            "sunlight":"Step::Sol"
        },
        "Step::Brazil":{},
        "Step::Sol":{}
    }

The data structure is a simple hash of hashes, where the top level keys
represent the step class names and the value hashes contain mappings from
dependency names to the other steps that fulfill that dependency.

=head1 ATTRIBUTE

=head2 output

A string containing the filename that the rendered JSON should be written to.
By default this is undef, rendering the output to C<STDOUT>.

=head1 METHOD

=head2 $renderer->render()

Renders the output.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford-Grapher/issues>.

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
