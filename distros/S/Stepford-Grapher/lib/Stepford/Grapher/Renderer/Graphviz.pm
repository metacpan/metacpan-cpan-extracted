package Stepford::Grapher::Renderer::Graphviz;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw(:all);

use Moose;

use File::Temp qw( tempfile );
use GraphViz2;
use Stepford::Grapher::Types qw( HashRef Str );

our $VERSION = '1.01';

has output => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_output',
);

has format => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_format',
);

sub _build_format {
    my $self = shift;

    # attempt to use the file extension as the format, if there is a usable
    # extension that is...
    my $ext;
    unless ( $self->has_output
        && ( ($ext) = $self->output =~ /[.]([^.]+)\z/ ) ) {
        return 'src';
    }

    return $ext;
}

# TODO: Make this configurable from the command line, either by accepting some
# sort of JSON-as-command-line-argument-flag setting, or by having multiple
# attributes that *are* individually settable and are lazily built into this
# formatting hashref if nothing is passed.
has node_formatting => (
    is      => 'ro',
    isa     => HashRef,
    builder => '_build_node_formatting',
);

sub _build_node_formatting {
    return {
        fontname => 'Helvetica',
        fontsize => 9,
        shape    => 'rect',
    };
}

has edge_formatting => (
    is      => 'ro',
    isa     => HashRef,
    builder => '_build_edge_formatting',
);

sub _build_edge_formatting {
    return {
        fontname => 'Helvetica',
        fontsize => 7,
    };
}

with 'Stepford::Grapher::Role::Renderer';

sub _create_blank_graph {
    return GraphViz2->new;
}

sub _populate_graph {
    my $self  = shift;
    my $graph = shift;
    my $data  = shift;

    $graph->add_node(
        name => $_,
        %{ $self->node_formatting }
    ) for keys %{$data};

    for my $from ( keys %{$data} ) {
        for my $label ( keys %{ $data->{$from} } ) {
            $graph->add_edge(
                from  => $from,
                to    => $data->{$from}{$label},
                label => $label,
                %{ $self->edge_formatting }
            );
        }
    }

    return;
}

sub _output_graph {
    my $self  = shift;
    my $graph = shift;

    # are we rendering to a named file or a temp file?
    my $output = (
        $self->has_output ? $self->output : do {
            my ( undef, $filename ) = tempfile();
            $filename;
            }
    );

    $graph->run(
        format => ( $self->format eq 'src' ? 'dot' : $self->format ),
        output_file => $output,
    );

    # If we were rendering to STDOUT, send to STDOUT
    unless ( $self->has_output ) {
        open my $fh, '<:raw', $output;
        while (<$fh>) {
            print or die "Can't print: $!";
        }
        close $fh;
        unlink $output;
    }

    return;
}

sub render {
    my $self = shift;
    my $data = shift;

    my $graph = $self->_create_blank_graph;
    $self->_populate_graph( $graph, $data );
    $self->_output_graph($graph);
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Stepford::Grapher::Renderer::Graphviz - Render to a graph using GraphViz

=head1 VERSION

version 1.01

=head1 SYNOPSIS

   my $grapher = Stepford::Grapher->new(
       step  => 'My::Step::ExampleStep',
       step_namespaces => ['My::Steps'],
       renderer => Stepford::Grapher::Renderer::Graphiz->new(
           output => 'diagram.png',
       ),
   );
   $grapher->run;

=head1 DESCRIPTION

Renders the graph using GraphViz.

=head1 ATTRIBUTES

=head2 output

A string containing the filename that the rendered graph should be written to.
By default this is undef, rendering the output to C<STDOUT>.

=head2 format

The format the graph should be written in (C<jpg>, C<png>, C<pdf>, etc.)  You
may use the special format C<src> or C<dot> to indicate that you want simple dot
source code (for manually feeding into Graphviz) output rather than having the
rendering done for you.

By default the format is determined from the output file extension if there
is one.  If one cannot be determined (either because the C<output> attribute
is undefined or the filename does not have an extension) then format will
default to C<src>.

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

__END__

# ABSTRACT: Render to a graph using GraphViz

