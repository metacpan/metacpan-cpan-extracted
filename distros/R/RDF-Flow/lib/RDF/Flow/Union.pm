use strict;
use warnings;
package RDF::Flow::Union;
{
  $RDF::Flow::Union::VERSION = '0.178';
}
#ABSTRACT: Returns the union of multiple sources

use Log::Contextual::WarnLogger;
use Log::Contextual qw(:log), -default_logger
    => Log::Contextual::WarnLogger->new({ env_prefix => __PACKAGE__ });

use RDF::Flow::Source qw(sourcelist_args iterator_to_model);
use parent 'RDF::Flow::Source';

sub new {
    my $class = shift;
    my ($inputs, $args) = RDF::Flow::Source::sourcelist_args( @_ );

    my $self = bless {
        inputs => $inputs,
        name   => ($args->{name} || 'anonymous union'),
    }, $class;

    $self->match( $args->{match} );

    return $self;
}

sub about {
    my $self = shift;
    $self->name($self) . ' with ' . $self->size . ' inputs';
}

sub retrieve_rdf { # TODO: try/catch errors?
    my ($self, $env) = @_;
    my $result;

    if ( $self->size == 1 ) {
        $result = $self->[0]->retrieve( $env );
    } elsif( $self->size > 1 ) {
        $result = RDF::Trine::Model->new;
        foreach my $src ( $self->inputs ) { # TODO: parallel processing?
            my $rdf = $src->retrieve( $env );
            next unless defined $rdf;
            $rdf = $rdf->as_stream unless $rdf->isa('RDF::Trine::Iterator');
            iterator_to_model( $rdf, $result );
        }
    }

    return $result;
}

# experimental
sub _graphviz_edgeattr {
    my ($self,$n) = @_;
    return ();
}

1;


__END__
=pod

=head1 NAME

RDF::Flow::Union - Returns the union of multiple sources

=head1 VERSION

version 0.178

=head1 SYNOPSIS

    use RDF::Flow qw(union);
    $src = union( @sources );                 # shortcut

    use RDF::Flow::Union;
    $src = RDF::Flow::Union->new( @sources ); # explicit

    $rdf = $src->retrieve( $env );

=head1 DESCRIPTION

This L<RDF::Flow> returns the union of responses of a set of input sources.

=head1 SEE ALSO

L<RDF::Flow::Cascade>, L<RDF::Flow::Pipeline>,
L<RDF::Trine::Model::Union>

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

