package TM::Tau::Filter::Analyze;

# register
$TM::Tau::filters{'http://psi.tm.bond.edu.au/queries/1.0/analyze'} = scalar __PACKAGE__;

use TM;

use TM::Tau::Filter;
use base qw(TM::Tau::Filter);

use Data::Dumper;

=pod

=head1 NAME

TM::Tau::Filter::Analyze - Topic Maps, Analysis Filter

=head1 SYNOPSIS

   # get a map
   my $tm = ... some map (or another filter)
   # build a filter expression
   my $an = new TM::Tau::Filter::Analyze (left => $tm);

   # this will calculate a map which carries the analysis result
   $an->sync_in; 

   # print all metrics, the values are occurrences
   warn $an->instances ($an->mids ('metric));

=head1 DESCRIPTION

This package implements an analysis filter. See L<TM::Tau::Filter> how
to use filters.

=head2 Ontology

The underlying ontology will develop. You can bootstrap yourself by
looking for C<metric> in the map. All instances have occurrences with
(integer) values.

B<NOTE>: This may change.

=cut

sub transform {
    my $self    = shift;
    my $map     = shift;
    my $baseuri = shift;

    use TM::Analysis;
    my $analysis = TM::Analysis::statistics ($map);
#warn Dumper $analysis;
    my $tm = new TM (baseuri => $baseuri);
    $tm->assert (
		 map { Assertion->new (type => 'isa',        roles => [ 'class', 'instance' ], players => [ 'metric', $_ ]),
		       Assertion->new (type => 'occurrence', roles => [ 'value', 'thing' ],    players => [ new TM::Literal ($analysis->{$_}) , $_ ]) }
                 keys %$analysis                                      # create topics for all of this
		 );
    return $tm;
}

=pod

=head1 SEE ALSO

L<TM::Tau::Filter>

=head1 AUTHOR INFORMATION

Copyright 200[5-6], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.2;
our $REVISION = '$Id: Analyze.pm,v 1.4 2006/11/26 22:01:32 rho Exp $';

1;


__END__

metric

nr_....

docs

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub sync_in {
    my $self = shift;

    die __PACKAGE__ . ": operand for filter is missing" unless $self->{operand};
#warn __PACKAGE__ . ": triggering operand syncin";
    $self->{operand}->sync_in;

    # applying the operator on the store
    #
    $self->{result} = { 
	measure => {
	    nr_topics => 23,
	    nr_assertions => 42 
	    }
    };
}

sub store {
    my $self = shift;

#warn "ANALYZE store";
    my $ms = new TM::Store (psis => $TM::PSI::topicmaps); # BaseURI?
    # create topics for all of this
    foreach my $k (keys %{$self->{result}}) {
	foreach my $v (keys %{$self->{result}->{$k}}) {
	    $ms->assert ([undef, undef, 'isa',                 TM::Store->ASSOC,    [ 'class', 'instance' ],            [ $k, $v ] ]);
	    $ms->assert ([undef, undef, 'has-basename',        TM::Store->BASENAME, [ 'basename', 'thing' ],            [ \ 'AAA', $v ] ]);
	    $ms->assert ([undef, undef, 'has-data-occurrence', TM::Store->OCCDATA,  [ 'has-data-occurrence', 'thing' ], [ \ "$self->{result}->{$k}->{$v}" , $v ] ]);
	}
    }
#warn "ANALYZE store ". Dumper $ms;
    return $ms;
}

sub sync_out {
    my $self = shift;

#warn __PACKAGE__ . ": syncing out analyze";
    if ($self->{url} eq 'io:stdout') {
	use Data::Dumper;
	use TM::Utils;
	TM::Utils::put_content ($self->{url}, Dumper $self->{result});
    } elsif ($self->{url} eq 'io:stdin') {
	# nothing
    } elsif ($self->{url} eq 'null:') {
	# nothing
    } else {
	use TM::Utils;
	TM::Utils::put_content ($self->{url}, TM::Utils::xmlify_hash ($self->{result}));
    }
}

sub DESTROY {
    my $self = shift;
#warn __PACKAGE__ . ": DESTROY";
    $self->sync_out;
}


__END__

__DATA__

# Ontology

nr_toplets (measure)
bn: Nr of toplets
in: <some value>

nr_maplets (measure)
bn: Nr of maplets

nr_types (measure)

nr_assoc_types (measure)

nr_basename_types (measure)

nr_occdata_types (measure)

nr_occref_types (measure)

nr_scopes (measure)

map_size (measure)
in: <some value> in bytes
