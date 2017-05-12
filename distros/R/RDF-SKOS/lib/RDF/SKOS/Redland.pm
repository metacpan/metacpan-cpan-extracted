package RDF::SKOS::Redland;

use strict;
use warnings;
use Data::Dumper;

use RDF::SKOS::Scheme;
use RDF::SKOS::Concept;

use base 'RDF::SKOS';
    
our $SKOS_NS = "http://www.w3.org/2004/02/skos/core#";

use RDF::Redland::Query;

=head1 NAME

RDF::SKOS::Redland - SKOS - RDF::Redland based implementation

=head1 SYNOPSIS

   my $model = ... # get an redland model

   use RDF::SKOS::Redland;
   my $skos = new RDF::SKOS::Redland ($model);

   # API like RDF::SKOS

=head1 DESCRIPTION

One way to experience an SKOS object is to I<extract> it from an underlying RDF graph. As the SKOS
vocabulary is defined on the basis of RDF, this is well-defined.

This package makes this translation, assuming an L<RDF::Redland> model underneath.  How you get that
model is your problem.

At the moment, this is all read-only. That is, you cannot modify the SKOS object and expect that
this is reflected in the underlying RDF graph.

=head2 Concept Identification

Of course, being in the RDF world, concepts are identified via their URI (IRI, whatever).

=head2 Annoyances

=over

=item

You will get a STDERR warning:

  C<Redland warning: Variable a was selected but is unused in the query.>

That is harmless, but cause of the incomplete implementation of SPARQL on
top of Redland. Maybe I find a trick of working around, or maybe drop SPARQL
alltogether.

=item

With some versions of Redland you may get

  C<1/0Name "swig_runtime_data::type_pointer3 ....>

Not sure what this is caused by.

=back

=head1 INTERFACE

=head2 Constructor

The constructor expects exactly one parameter: the RDF model from which the SKOS is derived.  An
exception is raised if this is not so.

=cut

sub new {
    my $class = shift;
    my $model = shift;
    die "no model" unless $model->isa ('RDF::Redland::Model');
    my $self = bless { model => $model }, $class;
    $self->{conceptClasses} = [ map { "<$_>" } _subclassesT ($model, $SKOS_NS.'Concept') ];
    return $self;
}

=pod

=head2 Methods

See L<RDF::SKOS>.

=over

=item B<concept>

Given a concept IRI, this returns an L<RDF::SKOS::Concept>. This is read-only.

=cut

sub concept {
    my $self = shift;
    my $ID   = shift;
    return new RDF::SKOS::Concept ($self, $ID) if _is_instance ($self->{model}, $ID, @{ $self->{conceptClasses} });
}

sub concepts {
    my $self = shift;
    return 
	map { new RDF::SKOS::Concept ($self, $_) } 
        _uniq (
               map { _instances ($self->{model}, $_) }
               @{ $self->{conceptClasses} }
               );
}

sub schemes {
    my $self = shift;
    return
	map { new RDF::SKOS::Scheme ($self, $_) }
        _instances ($self->{model}, 'skos:ConceptScheme' );
}

sub scheme {
    my $self = shift;
    my $ID   = shift;
    return new RDF::SKOS::Scheme ($self, $ID) if _is_instance ($self->{model}, $ID, 'skos:ConceptScheme');
}

sub topConcepts {
    my $self = shift;
    my $id   = shift;
    return 
	map { new RDF::SKOS::Concept ($self, $_) }
        _navigate ($self->{model}, $id, 'skos:hasTopConcept');
}

sub prefLabels {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:prefLabel');
}

sub altLabels {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:altLabel');
}

sub hiddenLabels {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:hiddenLabel');
}

sub notes {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:note');
}

sub scopeNotes {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:scopeNote');
}

sub examples {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:example');
}

sub historyNotes {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:historyNote');
}

sub editorialNotes {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:editorialNote');
}

sub changeNotes {
    my $self = shift;
    my $id   = shift;
    return 
        _literal ($self->{model}, $id, 'skos:changeNote');
}


sub narrower {
    my $self = shift;
    my $id   = shift;
    return 
	map { bless { id => $_, skos => $self }, 'RDF::SKOS::Concept' }
            _uniq
            ( _navigate ($self->{model}, $id, 'skos:narrower'),
	      _navigate ($self->{model}, $id, 'skos:broader', -1) )
		;
}

sub narrowerTransitive {
    my $self = shift;
    my $id   = shift;
    return
	map { bless { id => $_, skos => $self }, 'RDF::SKOS::Concept' }
            _uniq
		( _narrowTrec ($self, $id, {}) );

    sub _narrowTrec {
	my $self  = shift;
	my $id    = shift;
	my $seen  = shift;
	return () if $seen->{$id}++;
	my @T  = ( _navigate ($self->{model}, $id, 'skos:narrower'),
		   _navigate ($self->{model}, $id, 'skos:broader', -1) );
	my @TT = map { _narrowTrec ($self, $_, $seen) }
	         @T;
	return ($id, @T, @TT);
    }
}


sub broader {
    my $self = shift;
    my $id   = shift;
    return 
	map { bless { id => $_, skos => $self }, 'RDF::SKOS::Concept' }
            _uniq
            ( _navigate ($self->{model}, $id, 'skos:narrower', -1),
	      _navigate ($self->{model}, $id, 'skos:broader') )
		;
}

sub broaderTransitive {
    my $self = shift;
    my $id   = shift;
    return
	map { bless { id => $_, skos => $self }, 'RDF::SKOS::Concept' }
            _uniq
		( _broadTrec ($self, $id, {}) );
    sub _broadTrec {
	my $self  = shift;
	my $id    = shift;
	my $seen  = shift;
	return () if $seen->{$id}++;
	my @T  = ( _navigate ($self->{model}, $id, 'skos:narrower', -1),
		   _navigate ($self->{model}, $id, 'skos:broader') );
	my @TT = map { _broadTrec ($self, $_, $seen) }
	         @T;
	return ($id, @T, @TT);
    }
}

sub related {
    my $self = shift;
    my $id   = shift;
    return
	map { bless { id => $_, skos => $self }, 'RDF::SKOS::Concept' }
            _uniq
            ( _navigate ($self->{model}, $id, 'skos:related', -1),
	      _navigate ($self->{model}, $id, 'skos:related') )
		;
}

sub relatedTransitive {
    my $self = shift;
    my $id   = shift;
    return
	map { bless { id => $_, skos => $self }, 'RDF::SKOS::Concept' }
            _uniq
		( _relateTrec ($self, $id, {}) );
    sub _relateTrec {
	my $self  = shift;
	my $id    = shift;
	my $seen  = shift;
	return () if $seen->{$id}++;
	my @T  = ( _navigate ($self->{model}, $id, 'skos:related', -1),
		   _navigate ($self->{model}, $id, 'skos:related') );
	my @TT = map { _relateTrec ($self, $_, $seen) }
	         grep { !$seen->{$_}++ }
	         @T;
	return ($id, @T, @TT);
    }
}


sub _navigate {
    my $model = shift;
    my $ID    = shift;
    my $PATH  = shift;
    my $inv   = shift;

    my $q = new RDF::Redland::Query
	("SELECT ?a    WHERE ".($inv ? "(?a $PATH <$ID>)" : "(<$ID> $PATH ?a)"). " 
           USING skos FOR <$SKOS_NS>");
    my $res = $q->execute ($model);
    my @ss;
    while(!$res->finished) {
	my %bs = $res->bindings;
#	warn Dumper \%bs;
#	warn $bs{a}->as_string;
	push @ss, $bs{a}->as_string;
	$res->next_result;
    }
    $res = undef;
    return map { /\[(.*)\]/ ? $1 : $_ } @ss;
}

sub _literal {
    my $model = shift;
    my $ID    = shift;
    my $PATH  = shift;

    my $q = new RDF::Redland::Query
	("PREFIX skos: <$SKOS_NS>
          SELECT ?l    WHERE { <$ID> $PATH ?l }", 
          undef, undef, 'sparql');
    my $res = $q->execute ($model);
    my @ss;
    while(!$res->finished) {
	my %bs = $res->bindings;
#	warn Dumper \%bs;
#	warn $bs{l}->literal_value;
	push @ss, [ $bs{l}->literal_value, $bs{l}->literal_value_language ];
	$res->next_result;
    }
    $res = undef;
    return @ss;
}

sub _is_instance {
    my $model = shift;
    my $ID    = shift;

    foreach my $CLASS (@_) {
	my $q = new RDF::Redland::Query
	("PREFIX skos: <$SKOS_NS>
          SELECT ?a WHERE
                 { <$ID> a $CLASS . }
          ", undef, undef, 'sparql');
	my $res = $q->execute ($model);
	return 1 if $res->count > 0;
    }
    return 0;
}

sub _instances {
    my $model = shift;
    my $TYPE  = shift;

    my $q = new RDF::Redland::Query
	("PREFIX skos: <$SKOS_NS>
          SELECT ?a WHERE
                 { ?a a $TYPE . }
         ", undef, undef, 'sparql');
    my $res = $q->execute ($model);
    my @ss;
    while(!$res->finished) {
	my %bs = $res->bindings;
#	warn Dumper \%bs;
	push @ss, $bs{a}->as_string;
	$res->next_result;
    }
    $res = undef;
    return map { /\[(.*)\]/ && $1 } @ss;
}

sub _subclassesT {
    my $model = shift;
    my $top   = shift;

    my $q = new RDF::Redland::Query
        ("PREFIX skos: <$SKOS_NS>
          PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
          SELECT ?c WHERE 
                 { ?c rdfs:subClassOf <$top> . } 
          ", undef, undef, 'sparql');
    my $res = $q->execute ($model);
    my @ss;
    while(!$res->finished) {
        my %bs = $res->bindings;
#        warn Dumper \%bs;
        push @ss, $bs{c}->as_string;
        $res->next_result;
    }
    $res = undef;
    return _uniq ($top, map  { _subclassesT ($model, $_) }
		  map  { /\[(.*)\]/ && $1 } 
		  @ss) ;
}

sub _uniq {
    my %X;
    $X{$_}++ foreach @_;
    return keys %X;
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-skos at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-SKOS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = '0.01';

"against all odds";

__END__
