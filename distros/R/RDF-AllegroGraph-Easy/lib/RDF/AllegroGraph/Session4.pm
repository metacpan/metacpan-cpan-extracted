package RDF::AllegroGraph::Session4;

use strict;
use warnings;

use base qw(RDF::AllegroGraph::Repository4);

use Data::Dumper;
use feature "switch";

use JSON;
use URI::Escape qw/uri_escape_utf8/;

use HTTP::Request::Common;

=pod

=head1 NAME

RDF::AllegroGraph::Session4 - AllegroGraph session handle for AGv4

=head1 INTERFACE

=cut

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

=pod

=head2 Methods (additional to L<RDF::AllegroGraph::Repository4>)

=over

=item B<ping>

I<$pong> = I<$session>->ping

This method will keep the "connection" with the HTTP server alive (it probably resets the
timeout). In the regular case it should return C<pong>, in the error case it will time out.

=cut

sub ping {
    my $self = shift;
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/session/ping');
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success; 
    my $result = $resp->content;
    $result =~ s/^\"//; $result =~ s/\"$//;
    return $result;
}

=pod

=item B<rules>

I<$session>->rules (" .... prolog rules encoded in LISP, brr ...")

This method parks additional I<ontological knowledge> as rules onto the server. If they can be
parsed correctly, they will be used with the onboard PROLOG reasoner.  See the Franz Prolog tutorial
(./doc/prolog-tutorial.html) for details.

=cut

sub rules {
    my $self = shift;
    my $lisp = shift;
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->post ($self->{path} . '/functor',
						       'Content-Type' => 'text/plain', 'Content' => $lisp);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success; 
}

=pod

=item B<generator>

This method creates one I<generator>, in the AGv4 sense. As parameter you have to
pass in 

=over

=item the name of the generator:

A symbol, just a simple string, probably better without any fancy characters.

=item how to reach other nodes in the RDF model:

Here you name various predicates (full URIs, no namespaces seem to work) and also whether
these edges should be followed

=over

=item in the C<forward> direction, or

=item in the C<reverse> direction (I<inverseOf> in the OWL sense), or

=item in both directions: C<bidirectional>

=back

=back

Example:

   $session->generator ('associates', 
          { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional',
            '<http://www.franz.com/lesmis#knows>'      => 'bidirectional' }
   );

=cut

sub generator {
    my $self   = shift;
    my $symbol = shift;
    my $spec   = shift;

    my @bidirectional;
    my @forward;
    my @reverse;
    foreach my $pred (keys %$spec) {
	given ($spec->{$pred}) {
	    when ('bidirectional') {
		push @bidirectional, $pred;
	    }
	    when ('forward') {
		push @forward, $pred;
	    }
	    when ('reverse') {
		push @reverse, $pred;
	    }
	}
    }
#    warn Dumper \@undirected;

    my $url = new URI ($self->{path} . '/snaGenerators/' . $symbol);
    $url->query_form (
		      (@bidirectional    ? (undirected => \@bidirectional) : ()),
		      (@forward          ? (objectOf   => \@forward)       : ()),
		      (@reverse          ? (subjectOf  => \@reverse)       : ()),
		      );

    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (PUT $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success; 
}

=pod

=back

=head2 SNA Convenience Methods

While all of the following can be (and actually are) emulated via C<generator> and C<prolog>
invocations, you might find the following handy:

=over

=item B<SNA_members>

I<@members> = I<$session>->SNA_members (I<$start_node>, { I<generator specification> })

This method returns the member nodes which can be reached when starting at a particular node and
when particular edges are followed. That edge specification is the same as for the method
C<generator>.

B<NOTE>: Internally an SNA generator is created and - using this method - it will be always
overwritten. So, if you need to query this heavily, it is better to fall back to the low-level
generator method and use that instead of a full specification:

   $session->generator ('intimates', 
          { '<http://www.franz.com/lesmis#knows_well>' => 'bidirectional' });

   @ms = $session->SNA_members ('<where-to-start>', 'intimates');

=cut

our $adhoc = 'zwumpelfax'; # you may change it, but under what circumstances, really?

sub _linkage {
    my $self = shift;
    my $spec = shift;

    if (ref ($spec) eq 'HASH') {
	my $linkage = $adhoc;
	$self->generator ($linkage, $spec);
	return $linkage;
    } else {
	return $spec; # it is already a string
    }
}

sub SNA_members {
    my $self  = shift;
    my $start = shift;
    my $spec  = shift;

    my $linkage = _linkage ($self, $spec);
    my @ss = $self->prolog (qq{
   (select (?member)
        (ego-group-member !$start 1 $linkage ?member)
    )
    });
#    warn Dumper \@ss;
    return map {$_->[0] } @ss;
}

sub SNA_ego_group {
    my $self = shift;
    my $start = shift;
    my $spec = shift;
    my $depth = shift;

    return ();
}

sub SNA_path {
    my $self = shift;
    my $start = shift;
    my $stop = shift;
    my $spec = shift;
    my $depth = shift;

    my $linkage = _linkage ($self, $spec);
    my @ss = $self->prolog (qq{
   (select (?path)
      (breadth-first-search-path !$start !$stop $linkage $depth ?path))
    });
    warn "ss ". Dumper \@ss;
    return map { $_->[0] } @ss;
}

# strategy : breadth_first, depth_first, bidirectional

sub SNA_nodal_degree {
    my $self = shift;
    my $node = shift;
    my $spec = shift;

}

sub SNA_nodal_neighbors {
    my $self = shift;
    my $node = shift;
    my $spec = shift;
}

=pod

=item B<SNA_cliques>

I<@cliques> = I<$session>->SNA_cliques (I<$node>, I<$generator>)

This method returns a list of list references to the cliques the node is part of. The generator can
again be one predefined (see C<generator>), or an adhoc one (see C<SNA_members>).

=cut

sub SNA_cliques {
    my $self = shift;
    my $node = shift;
    my $spec = shift;

    my $linkage = _linkage ($self, $spec);
    my @ss = $self->prolog (qq{
   (select (?clique)
      (clique !$node $linkage ?clique))
    });
#    warn Dumper \@ss;
    return map { $_->[0] } @ss;
}

sub SNA_actor_degree_centrality {
}

sub SNA_actor_closeness_centrality {
}

sub SNA_actor_betweeness_centrality {
}

sub SNA_group_degree_centrality {
}

sub SNA_group_closeness_centrality {
}

sub SNA_group_betweeness_centrality {
}



=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

our $VERSION  = '0.03';

1;

__END__
