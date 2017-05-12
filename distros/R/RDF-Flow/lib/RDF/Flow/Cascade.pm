use strict;
use warnings;
package RDF::Flow::Cascade;
{
  $RDF::Flow::Cascade::VERSION = '0.178';
}
#ABSTRACT: Returns the first non-empty response of a sequence of sources

use Log::Contextual::WarnLogger;
use Log::Contextual qw(:log), -default_logger
    => Log::Contextual::WarnLogger->new({ env_prefix => __PACKAGE__ });

use parent 'RDF::Flow::Source';
use RDF::Flow::Source qw(:util);

use Carp 'croak';
use Scalar::Util 'blessed';

sub new {
    my $class = shift;
    my ($inputs, $args) = sourcelist_args( @_ );

    my $self = bless {
        inputs => $inputs,
        name   => ($args->{name} || 'anonymous cascade'),
    }, $class;

    $self->match( $args->{match} );

    return $self;
}

sub about {
    my $self = shift;
    $self->name($self) . ' with ' . $self->size . ' inputs';
}

sub retrieve { # TODO: try/catch errors?
    my ($self, $env) = @_;

    log_trace { 'retrieve from ' . $self->about; }

    my $i = 1;
    my $rdf;
    foreach my $src ( $self->inputs ) {
        $rdf = $src->retrieve( $env );

        next unless defined $rdf;
        if ( blessed $rdf and $rdf->isa('RDF::Trine::Model') ) {
            last if $rdf->size > 0;
        } elsif ( blessed $rdf and $rdf->isa('RDF::Trine::Iterator') ) {
            last if $rdf->peek;
        } else {
            croak 'unexpected response in ' . $self->name . ': ' . $rdf;
        }

        $i++;
    }

    $self->timestamp( $env );
    $self->trigger_retrieved( $rdf, "%s returned $i. with %s" );
}

sub _graphviz_edgeattr {
	my ($self,$n) = @_;
	my %attr = (label => sprintf("%d.",$n));
	$attr{style} = 'dotted' if $n > 1;
	return %attr;
}

1;


__END__
=pod

=head1 NAME

RDF::Flow::Cascade - Returns the first non-empty response of a sequence of sources

=head1 VERSION

version 0.178

=head1 SYNOPSIS

    use RDF::Flow qw(cascade);
    $src = cascade( @sources );                  # shortcut
    $src = cascade( @sources, name => 'foo' );   # with name

    use RDF::Flow::Cascade;
    $src = RDF::Flow::Cascade->new( @sources );  # explicit

    $rdf = $src->retrieve( $env );

=head1 DESCRIPTION

This L<RDF::Flow::Source> returns the first non-empty response of a given
sequence of sources.

=head1 SEE ALSO

L<RDF::Flow::Union>, L<RDF::Flow::Pipeline>

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

