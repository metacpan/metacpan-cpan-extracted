package Stepford::Grapher::CommandLine;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.01';

# This globally changes the underlying Getopt::Long behavior to allow passing
# through of unprocessed dash arguments without error, which allows us to have
# multiple classes to have an attempt to read the file. Ideally this wouldn't
# be a global setting, but the conclusion of #moose is that this is good
# enough
use Getopt::Long qw(:config pass_through);
use Module::Runtime qw(require_module);
use Stepford::Grapher;

use Moose;

has renderer => (
    is            => 'ro',
    isa           => 'Str',
    default       => 'graphviz',
    documentation => 'The name of the renderer to use',
);

with 'MooseX::Getopt::Dashes';

sub run {
    my $class = shift;
    my $self  = $class->new_with_options;

    my $renderer_classname
        = 'Stepford::Grapher::Renderer::' . ucfirst lc $self->renderer;
    require_module($renderer_classname);

    # Any command line options that we didn't consume are passed onto the
    # renderer so it gets a chance to process them.
    my $renderer = $renderer_classname->new_with_options(
        argv => $self->extra_argv,
    );

    # We pass our main object any command line options that aren't consumed by
    # the renderer and this class
    my $grapher = Stepford::Grapher->new_with_options(
        renderer => $renderer,
        argv     => $renderer->extra_argv,
    );

    $grapher->run;

    return;
}

# We can't just override this since the method created for us was installed
# directly in this class. Instead wrap it with around and
around print_usage_text => sub {
    ## no critic (InputOutput::RequireCheckedSyscalls)
    print <<'TEXT';
Many more command line options are available depending on they type of
renderer you are using. Please refer to the documentation for the individual
renderers or use "perldoc graph-stepford.pl" for an overview.
TEXT
};

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Module supporting command line interface for Stepford::Grapher

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::Grapher::CommandLine - Module supporting command line interface for Stepford::Grapher

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    use Stepford::Grapher::CommandLine;
    exit Stepford::Grapher::CommandLine->run;

=head1 DESCRIPTION

=head1 ATTRIBUTE

=head2 renderer

The short form of the classname of the renderer to instantiate.  For example
C<graphviz> for L<Stepford::Grapher::Renderer::Graphviz>.

Required.

=head1 METHOD

=head2 $cl->run

Create a new Stepford::Grapher from the command line options (including creating
a renderer) and then having it render the graph.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford-Grapher/issues>.

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
