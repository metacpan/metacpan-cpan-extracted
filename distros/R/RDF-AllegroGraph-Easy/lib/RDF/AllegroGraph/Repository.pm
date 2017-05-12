package RDF::AllegroGraph::Repository;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

use feature 'switch';

=pod

=head1 NAME

RDF::AllegroGraph::Repository - AllegroGraph repository handle

=head1 DESCRIPTION

An AllegroGraph repository corresponds to an RDF model. Into such a model you can park RDF
information, either as individual statements or via file bulk loading. Then you can navigate through
it on a statement level, or query that model.

=head1 INTERFACE

=head2 Constructor

The constructor expects the following fields:

=over

=item C<CATALOG> (mandatory)

This is the handle to the catalog the repository belongs to.

=item C<id> (mandatory)

This identifier is always of the form C</whatever>.

=back

Example:

  my $repo = new RDF::AllegroGraph::Repository (CATALOG => $cat, id => '/whereever');

=head2 Methods

=over

=item B<id>

This read-only accessor method returns the id of the repository.

=cut

sub id {
    die;
}

=pod

=item B<disband>

I<$repo>->disband

This method removes the repository from the server. The object cannot be used after that, obviously.

=cut

sub disband {
    die;
}

=pod

=item B<size>

I<$nr_triples> = I<$repo>->size

Returns the size of the repository in terms of the number of triples.

B<NOTE>: As of time of writing, AllegroGraph counts duplicate triples!

=cut

sub size {
    die;
}

=pod

=item B<add>

I<$repo>->add ('file://....', ...)

I<$repo>->add ('http://....', ...)

I<$repo>->add (' triples in N3 ', ...)

I<$repo>->add ([ I<$subj_uri>, I<$pred_uri>, I<$obj_uri> ], ...)

This method adds triples to the repository. The information can be provided in any of the following
ways (also mixed):

=over

=item file, HTTP, FTP URL

If a string looks like an URL, it will be dereferenced, the contents of the resource consulted and
that shipped to the repository on the server. If the resource cannot be read, an exception C<Could
not open> will be raised. Any number of these URLs can be provided as parameter.

B<NOTE>: Only N3 files are supported, and also only when the URL ends with the extension C<nt> or
C<n3>.

=item N3 triple string

If the string looks like N3 notated triples, that content is shipped to the server.

=item ARRAY reference

The reference is interpreted as one triple (statement), containing 3 URIs. These will be shipped
as-is to the server.

=back

If the server chokes on any of the above, an exception C<protocol error> is raised.

B<NOTE>: There are no precautions for over-large content. Yet.

B<NOTE>: Named graphs (aka I<contexts>) are not handled. Yet.


=cut

sub add {
    die;
}

sub _put_post_stmts {
    my $method = shift;
    my $self   = shift;

    my @stmts;                                                                  # collect triples there
    my $n3;                                                                     # collect N3 stuff there
    my @files;                                                                  # collect file names here
    use Regexp::Common qw/URI/;

    foreach my $item (@_) {                                                     # walk through what we got
	if (ref($item) eq 'ARRAY') {                                            # a triple statement
	    push @stmts, $item;
	} elsif (ref ($item)) {
	    die "don't know what to do with it";
	} elsif ($item =~ /^$RE{URI}{HTTP}/) {
	    push @files, $item;
	} elsif ($item =~ /^$RE{URI}{FTP}/) {
	    push @files, $item;
	} elsif ($item =~ /^$RE{URI}{file}/) {
	    push @files, $item;
	} else {                                                                # scalar => N3
	    $n3 .= $item;
	}
    }

    my $ua = $self->{CATALOG}->{SERVER}->{ua};                                  # local handle

    if (@stmts) {                                                               # if we have something to say to the server
	given ($method) {
	    when ('POST') {
		my $resp  = $ua->post ($self->{path} . '/statements',
				       'Content-Type' => 'application/json', 'Content' => encode_json (\@stmts) );
		die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	    }
	    when ('PUT') {
		my $requ = HTTP::Request->new (PUT => $self->{path} . '/statements',
					       [ 'Content-Type' => 'application/json' ], encode_json (\@stmts));
		my $resp = $ua->request ($requ);
		die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	    }
	    when ('DELETE') {                                                     # DELETE
		# first bulk delete facts, i.e. where there are no wildcards
		my @facts      = grep { defined $_->[0]   &&   defined $_->[1] &&   defined $_->[2] } @stmts;
		my $requ = HTTP::Request->new (POST => $self->{path} . '/statements/delete',
					       [ 'Content-Type' => 'application/json' ], encode_json (\@facts));
		my $resp = $ua->request ($requ);
		die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

		# the delete one by one those with wildcards
		my @wildcarded = grep { ! defined $_->[0] || ! defined $_->[1] || ! defined $_->[2] } @stmts;
		foreach my $w (@wildcarded) {
		    my $requ = HTTP::Request->new (DELETE => $self->{path} . '/statements' . '?' . _to_uri ($w) );
		    my $resp = $ua->request ($requ);
		    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
		}
	    }
	    default { die $method; }
	}
    }
    if ($n3) {                                                                  # if we have something to say to the server
	my $requ = HTTP::Request->new ($method => $self->{path} . '/statements', [ 'Content-Type' => 'text/plain' ], $n3);
	my $resp = $ua->request ($requ);
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    }
    for my $file (@files) {                                                     # if we have something to say to the server
	use LWP::Simple;
	my $content = get ($file) or die "Could not open URL '$file'";
	my $mime;                                                               # lets guess the mime type
	given ($file) {                                                         # magic does not normally cope well with RDF/N3, so do it by extension
	    when (/\.n3$/)  { $mime = 'text/plain'; }                           # well, not really, since its text/n3
	    when (/\.nt$/)  { $mime = 'text/plain'; }
	    when (/\.xml$/) { $mime = 'application/rdf+xml'; }
	    when (/\.rdf$/) { $mime = 'application/rdf+xml'; }
	    default { die; }
	}

	my $requ = HTTP::Request->new ($method => $self->{path} . '/statements', [ 'Content-Type' => $mime ], $content);
	my $resp = $ua->request ($requ);
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

	$method = 'POST';                                                        # whatever the first was, the others must add to it!
    }


}

sub _to_uri {
    my $w = shift;
    my @params;
    push @params, 'subj='.$w->[0] if $w->[0];
    push @params, 'pred='.$w->[1] if $w->[1];
    push @params, 'obj=' .$w->[2] if $w->[2];
    return join ('&', @params);   # TODO URI escape?
}

=pod

=item B<replace>

This method behaves exactly like C<add>, except that any existing content in the repository is wiped
before adding anything.

=cut

sub replace {
    die;
}

=pod

=item B<delete>

I<$repo>->delete ([ I<$subj_uri>, I<$pred_uri>, I<$obj_uri> ], ...)

This method removes the passed in triples from the repository. In that process, any combination of
the subject URI, the predicate or the object URI can be left C<undef>. That is interpreted as
wildcard which matches anything.

Example: This deletes anything where the Stephansdom is the subject:

  $air->delete ([ '<urn:x-air:stephansdom>', undef, undef ])

=cut

sub delete {
    die;
}

=pod

=item B<match>

I<@stmts> = I<$repo>->match ([ I<$subj_uri>, I<$pred_uri>, I<$obj_uri> ], ...)

This method returns a list of all statements which match one of the triples provided
as parameter. Any C<undef> as URI within such a triple is interpreted as wildcard, matching
any other URI.

(Since v0.06): The object part can now be a range of values. You simply provide an array reference
with the lower and the upper bound as values in the array, such as for example

    $repo->match ([ undef, undef, [ '"1"^^my:type', '"10"^^my:type' ] ]);

B<NOTE>: Subject range queries and predicate range queries are not supported as RDF would not allow
literals at these places anyway.

(Since v0.06): For AGv4 there is now a way to configure some options when fetching matching triples:
Simply provide as first parameter an options hash:

    $repo->match ({ limit => 10 }, [ undef, .....]);

These options will apply to all passed in match patterns SEPARATELY, so that with several patterns
you might well get more than your limit.

=cut

sub match {
    die;    
}

=pod

=item B<sparql>

I<@tuples> = I<$repo>->sparql ('SELECT ...')

I<@tuples> = I<$repo>->sparql ('SELECT ...' [, I<$option> => I<$value> ])

This method takes a SPARQL query string and returns a list of tuples which the query produced from
the repository.

B<NOTE>: At the moment only SELECT queries are supported.

As additional options are accepted:

=over

=item C<RETURN> (default: C<TUPLE_LIST>)

The result will be a sequence of (references to) arrays. All naming of the individual columns is
currently lost.

=back

=cut

sub sparql {
    die;
}

=pod

=back

=head2 Namespace Support

=over

=item B<namespaces>

I<%ns> = I<$repo>->namespaces

This read-only function returns a hash containing the namespaces: keys
are the prefixes, values are the namespace URIs.

B<NOTE>: No AllegroGraph I<environment> is honored at the moment.

=cut

sub namespaces {
    die;
}

=pod

=item B<namespace>

$uri = $repo->namespace ($prefix)

$uri = $repo->namespace ($prefix => $uri)

$repo->namespace        ($prefix => undef)

This method fetches, sets and deletes prefix/uri namespaces. If only the prefix is given,
it will look up the namespace URI. If the URI is provided as second parameter, it will set/overwrite
that prefix. If the second parameter is C<undef>, it will delete the namespace associated with it.

B<NOTE>: No I<environment> is honored at the moment.

=cut

sub namespace {
    die;
}

=pod

=back

=head2 GeoSpatial Support

=over

=item B<geotypes>

I<@geotypes> = I<$repo>->geotypes

This method returns a list of existing geotypes (in form of specially
crafted URIs). You need these URIs when you want to create locations
for them, or when you want to retrieve tuples within a specific area
(based on the geotype).

=cut

sub geotypes {
    die;
}

=pod

=item B<cartesian>

I<$uri> = I<$repo>->cartesian ("100x100",       I<$stripWidth>);

I<$uri> = I<$repo>->cartesian ("100x100+10+10", I<$stripWidth>);

I<$uri> = I<$repo>->cartesian (I<$minx>, I<$miny>, I<$maxx>, I<$maxy>, I<$stripWidth>);

This method registers one new coordinate system at the server. The returned URI is later used as
reference to that system. The extensions of the system is provided either

=over

=item in the form C<WxH+X+Y>

All numbers being floats. The X,Y offset part can be omitted.

=item or, alternatively, as minx, miny, maxx, maxy quadruple

Again all numbers being floats.

=back

The last parameter defines the resolution of the stripes, and gives the server optimization hints.
(See the general AG description for a deep explanation.)

=cut

sub cartesian {
    die;
}

=pod

=item B<inBox>

I<@ss> = I<$repo>->inBox (I<$geotype>, I<$predicate>, 35, 35, 65, 65, { limit => 10 });

This method tries to find all triples which lie within a certain bounding box.

The geotype is the one you create with C<cartesian> or C<spherical>. The bounding box is given by the
bottom/left and the top/right corner coordinates. The optional C<limit> restricts the number of
triples you request.

For cartesian coordinates you provide the bottom/left corner, and then the top/right one.

For spherical coordinates you provide the longitude/latitude of the bottom/left corner, then 
the longitude/latitude of the top/right one.

=cut

sub inBox {
    die;
}

=pod

=item B<inCircle>

I<@ss> = I<$repo>->inCircle (I<$geotype>, I<$predicate>, 35, 35, 10, { limit => 10 });

This method tries to find all triples which lie within a certain bounding circle.

The geotype is the one you create with C<cartesian> or C<spheric>. The bounding circle is given by
the center and the radius. The optional C<limit> restricts the number of triples you request.

For cartesian coordinates you simply provide the X/Y coordinates of the circle center, and the
radius (in the unit as provided with the geotype.

For spherical coordinates the center is specified with a longitude/latitude pair. The radius is also
interpreted along the provided geotype.

B<NOTE>: As it seems, the circle MUST be totally within the range you specified for your
geotype. Otherwise AG will return 0 tuples.

=cut

sub inCircle {
    die;
}

=pod

=item I<inPolygon> (since v0.06, only for AG4)

I<@ss> = I<$repo>->inPolygon (I<$coordtype>, I<$preduri>, I<@points>, { I<%options> })

This method tries to identify all statements where the object is within a polygon defined by the
C<points> array. Each point is simply an array reference with 2 entries (x,y, of course).

The predicate URI defines which predicates should be considered. Do not leave it C<undef>. The
coordinate type is the one you will have generated before with C<cartesian>.

The optional options can only contain C<limit> to restrict the number of tuples to be returned.

For spherical coordinates make sure that you (a) provide longitude/latitude pairs and then that the
polygon is built clockwise.

B<NOTE>: This is a somewhat expensive operation in terms of communication round-trips.

=cut

sub inPolygon {
    die;
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 20(09|1[01]) Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

our $VERSION  = '0.03';

1;

__END__
