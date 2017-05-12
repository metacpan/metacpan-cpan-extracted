use strict;
use warnings;
package RDF::Dumper;
{
  $RDF::Dumper::VERSION = '0.3';
}
# ABSTRACT: Dump RDF data objects

use RDF::Trine::Serializer;
use Scalar::Util 'blessed';
use Carp 'croak';

our $GLOBAL_SERIALIZER;

use Sub::Exporter -setup => {
    exports => [
        rdfdump => \&_build,
        Dumper  => \&_build,
    ],
    groups => {
        default => [ qw(rdfdump) ],
        dd      => [ qw(Dumper) ],
        # "all" is created automatically
    },
};

sub _build {
    my ($class, $name, $arg) = @_;

    my $fallback = delete($arg->{fallback_sub});
    if ($name eq 'Dumper') {
        $fallback ||= sub {
            require Data::Dumper;
            local $Data::Dumper::Terse = 1;
            Data::Dumper::Dumper(@_);
        }
    }

    my $format = delete($arg->{format}) || 'Turtle';
    my $default_serializer = RDF::Trine::Serializer->new($format, %$arg);

    return sub {
        my $serializer = (blessed $_[0] and $_[0]->isa('RDF::Trine::Serializer'))
            ? shift
            : ($GLOBAL_SERIALIZER || $default_serializer);
        my @serialized = map { _rdfdump($serializer, $_, $fallback) } @_;
        return join "\n", grep { defined $_ } @serialized;
    };
}

# In case people want to call fully-qualified RDF::Dumper::rdfdump($thing)
*rdfdump = __PACKAGE__->_build(rdfdump => {});
*Dumper  = __PACKAGE__->_build(Dumper  => {});

sub _rdfdump {
    my ($ser, $rdf, $fallback) = @_;

    if ( blessed $rdf ) {
        # RDF::Trine::Serializer should have a more general serialize_ method
        if ( $rdf->isa('RDF::Trine::Model') ) {
            return $ser->serialize_model_to_string( $rdf );
        } elsif ( $rdf->isa('RDF::Trine::Iterator') ) {
            return $ser->serialize_iterator_to_string( $rdf );
        } elsif ( $rdf->isa('RDF::Trine::Statement') ) {
            my $model = RDF::Trine::Model->temporary_model;
            $model->add_statement( $rdf );
            return $ser->serialize_model_to_string( $model );
        } elsif ( $rdf->isa('RDF::Trine::Store') or
                  $rdf->isa('RDF::Trine::Graph') ) {
            $rdf = $rdf->get_statements;
            return $ser->serialize_iterator_to_string( $rdf );
        }
        # TODO: serialize patterns (in Notation3) and single nodes?
    }

    if ( $fallback ) {
        return $fallback->($rdf);
    }

    # Sorry, this was no RDF object...
    if ( ref $rdf ) {
        $rdf = "$rdf";
    } elsif ( not defined $rdf ) {
        $rdf = 'undef';
    }

    croak "expected Model/Iterator/Store/Statement/Graph but got $rdf";

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Dumper - Dump RDF data objects

=head1 VERSION

version 0.3

=head1 SYNOPSIS

  use RDF::Dumper;
  print rdfdump( $rdf_object );

  # Data::Dumper-compatible version
  use RDF::Dumper qw(Dumper);   # just like rdfdump, but falls back
  print Dumper($object);        # to Data::Dumper for non-RDF things

  # Custom serializer
  use RDF::Dumper rdfdump => { format => 'rdfxml', namespaces => \%ns };
  print rdfdump( $rdf );              # use serializer created on import
  print rdfdump( $serializer, $rdf ); # use another serializer

  # Multiple imports
  use RDF::Dumper
    rdfdump => { -as => 'dump_nt',  format => 'ntriples' },
    rdfdump => { -as => 'dump_xml', format => 'rdfxml', namespaces => \%ns };
  print dump_nt( $rdf );
  print dump_xml( $rdf );

=head1 DESCRIPTION

Exports function 'rdfdump' to serialize RDF data objects given as instances of
L<RDF::Trine::Model>, L<RDF::Trine::Iterator>, L<RDF::Trine::Statement>,
L<RDF::Trine::Store>, or L<RDF::Trine::Graph>. See L<RDF::Trine::Serializer>
for details on RDF serializers. By default RDF is serialized as RDF/Turtle.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
