package RDF::AllegroGraph::Repository4;

use strict;
use warnings;

use base qw(RDF::AllegroGraph::Repository);

use Data::Dumper;
use feature "switch";

use JSON;
use URI::Escape qw/uri_escape_utf8/;

use HTTP::Request::Common;

=pod

=head1 NAME

RDF::AllegroGraph::Repository4 - AllegroGraph repository handle for AGv4

=head1 INTERFACE

Same as L<RDF::AllegroGraph::Repository> from which we inherit.

=cut

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    $self->{path} = $self->{CATALOG}->{SERVER}->{ADDRESS} . ($self->{CATALOG}->{NAME} eq '/'
                                                             ? ''
                                                             : '/catalogs' . $self->{CATALOG}->{NAME} ) . '/repositories/' . $self->{id};
    return $self;
}

=pod

=over

=item B<id>

This read-only accessor method returns the id of the repository.

=cut

sub id {
    my $self = shift;
    return $self->{CATALOG}->{NAME} eq '/'
           ? '/' . $self->{id}
           : $self->{CATALOG}->{NAME} . '/' . $self->{id};
}

=pod

=item B<disband>

I<$repo>->disband

This method removes the repository from the server. The object cannot be used after that, obviously.

=cut

sub disband {
    my $self = shift;
    my $requ = HTTP::Request->new (DELETE => $self->{path});
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
}

=pod

=item B<size>

I<$nr_triples> = I<$repo>->size

Returns the size of the repository in terms of the number of triples.

B<NOTE>: As of time of writing, AllegroGraph counts duplicate triples!

=cut

sub size {
    my $self = shift; 
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/size');
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success; 
    return $resp->content;
}

=pod

=back

=head2 Methods (over those we inherit)

=over

=item B<session> (since v0.06)

I<$session> = I<$repo>->session

This method forks a session out of the current repository session. Unlike a transaction, all changes
are autocommitted into the mother repository. But AG4 needs a separate connection thread for some
specific features (SNA, loading Prolog knowledge, etc.)

=cut

sub session {
    my $self = shift;
    my %opts = @_;
    $opts{autoCommit} ||= 'true';                                        # this is - by default - a session, so whatever we do, it will shine through
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->post ($self->{path} . '/session', %opts);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success; 
    my $url = $resp->content;
    $url =~ s/^\"//; $url =~ s/\"$//;                                    # for some very odd reason we get this URI in the content
    {                                                                    # try to find authentication information inside the repo URL
	if ($self->{path} =~ m{http://(.+?@)}) {
	    my $auth = $1;
	    $url =~ s{http://}{http://$auth};
	}
    }
    if ($opts{autoCommit} eq 'true') {                                              # we do like 'true' strings ...
	use RDF::AllegroGraph::Session4;
	return new RDF::AllegroGraph::Session4     (path    => $url,                # the newly returned URL will be its home
						    CATALOG => $self->{CATALOG});   # and the catalog will be the same
    } else {
	use RDF::AllegroGraph::Transaction4;
	return new RDF::AllegroGraph::Transaction4 (path    => $url,                # the newly returned URL will be its home
						    CATALOG => $self->{CATALOG});   # and the catalog will be the same
    }
}

=pod

=item B<transaction> (since v0.06)

I<$tx> = I<$repo>->transaction

This method forks a transaction out of the current repository session. That transaction is itself a
repository session (and a session, for that matter). Whatever you do in the transaction, will stay
in the transaction. With calling the C<rollback> method (see L<RDF::AllegroGraph::Transaction4>),
you will simply empty the transaction. That is also the default behaviour, if the transaction object
goes out of scope.

To manifest any changes you will have to invoke C<commit> on the transaction object.

=cut

sub transaction {
    my $self = shift;
    return $self->session (autoCommit => 'false');
}

=pod

=item B<blanks> (since v0.06)

I<@blanks> = I<$repo>->blanks (I<int_amount>)

This method asks the server to create a number of blank nodes in the repository. The ids of these
nodes will be returned. By default, one node will be created, but you can ask for more.

=cut

sub blanks {
    my $self = shift;
    my $amount = shift || 1;

    my $resp  = $self->{CATALOG}->{SERVER}->{ua}->post ($self->{path} . '/blankNodes', 
							'Content-Type' => 'application/x-www-form-urlencoded',
							'Accept' => 'application/json',
							'Content' => { 'amount' => $amount });
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
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
    _put_post_stmts ('POST', @_);
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
		    my $requ = HTTP::Request->new (DELETE => _to_uri ($self->{path} . '/statements', $w, {}) );
		    my $resp = $ua->request ($requ);
		    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
		}
	    }
	    default { die "You should never end here: Unhandled '$method'"; }
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
    my $path    = shift;
    my $w       = shift;
    my $options = shift;

    my $url = new URI ($path);
    $url->query_form ((defined $w->[0]
                             ? ('subj' => $w->[0])
                             : () ),
                          (defined $w->[1]
                             ? ('pred' => $w->[1])
                             : () ),
                          (ref ($w->[2]) eq 'ARRAY'
                             ? ('obj'    => $w->[2]->[0],
				'objEnd' => $w->[2]->[1]
				)
                             : (defined $w->[2]
                                ? ('obj'    => $w->[2])
                                : ()
				)),
			  (defined $options->{limit}
			   ? (limit => $options->{limit})
			   : ())
			  );
    return $url;
}

=pod

=item B<replace>

This method behaves exactly like C<add>, except that any existing content in the repository is wiped
before adding anything.

=cut

sub replace {
    _put_post_stmts ('PUT', @_);
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
    _put_post_stmts ('DELETE', @_);
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
    my $self = shift;
    my $options = ref($_[0]) eq 'HASH' ? shift : {};

    my @stmts;
    my $ua = $self->{CATALOG}->{SERVER}->{ua};
    foreach my $w (@_) {
	my $resp  = $ua->get (_to_uri ($self->{path} . '/statements', $w, $options));
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	push @stmts, @{ from_json ($resp->content) };
    }
    return @stmts;
}

sub _query {
    my $self  = shift;
    my $query = shift;
    my $lang  = shift || 'sparql';
    my %options = @_;

    $options{RETURN} ||= 'TUPLE_LIST';        # a good default
    my $NAMED = 0;
    ($NAMED, $options{RETURN}) = (1, 'TUPLE_LIST') if $options{RETURN} eq 'NAMED_TUPLE_LIST';        # store the info that we should return the names as well

    my @params;
    push @params, "queryLn=$lang";
    push @params, 'query='.uri_escape_utf8 ($query);
    push @params, 'infer='.uri_escape_utf8 ($options{INFERENCING}) if defined $options{INFERENCING};
    
    my $resp  = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '?' . join ('&', @params) );
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

    my $json = from_json ($resp->content);
    given ($options{RETURN}) {
	when ('TUPLE_LIST') {
	    return $NAMED ? ($json) : @{ $json->{values} };
	}
	default { die };
    }
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

In the case of C<TUPLE_LIST> the result will be a sequence of (references to) arrays. All naming of
the individual columns is hereby lost. C<TUPLE_LIST> really only returns the data (and not the names
within SELECT clause).

(since v0.08)
C<NAMED_TUPLE_LIST> also returns a hash with the names (list reference) and the result sequence
(list reference, too).

=item C<INFERENCING> (default: undef)

[Since v0.08] With this option you can control the degree of inferencing used with this query.
By default, no inferencing is used, but if you pass in C<rdfs++>, then the semantics of those
properties mentioned in C<.../doc/agraph-introduction.html#reasoning> are honored.

=back

=cut

sub sparql {
    my $self = shift;
    my $query = shift;

    return _query ($self, $query, 'sparql', @_);
}

=pod

=item B<prolog> (since v0.06)

See C<sparql>, but this is only supported for AGv4 servers.

=cut

sub prolog {
    my $self = shift;
    my $query = shift;

    return _query ($self, $query, 'prolog', @_);
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

B<NOTE>: My current understanding is that AG does NOT support namespaces when you load data with
C<add()> or C<replace()>, or try to match it with C<match()>. In that case, all URIs must be fully
expanded. Namespaces seem to work with SPARQL queries, though.

=cut

sub namespaces {
    my $self = shift;
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/namespaces');
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return
	map { $_->{prefix} => $_->{namespace} }
	@{ from_json ($resp->content) };
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
    my $self = shift;
    my $prefix = shift;

    my $uri = $self->{path} . '/namespaces/' . $prefix;
    if (scalar @_) {   # there was a second argument!
        if (my $nsuri = shift) {
	    my $requ = HTTP::Request->new ('PUT' => $uri, [ 'Content-Type' => 'text/plain' ], $nsuri);
	    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	    return $nsuri;
	} else {
	    my $requ = HTTP::Request->new ('DELETE' => $uri);
	    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	}
    } else {
	my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($uri);
	return undef if $resp->code == 404;
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	return $resp->content =~ m/^"?(.*?)"?$/ && $1;
    }
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
    my $self = shift;
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/geo/types');
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return  @{ from_json ($resp->content) };
}

=pod

=item B<spherical>

I<$coord> = I<$repo>->spherical (C<undef>, '5.2 degree');

This method registers a spherical coordinate system on the server.

B<NOTE>: With this version, no region can be specified (so this is always a complete sphere) and
only degrees are supported.

=cut

sub spherical {
    my $self = shift;
    my $region = shift;
    my $scale  = shift;

    use Regexp::Common;
    die "scale information must be of the form 5 mile, or 10 km, or similar"
	unless ($scale =~ /($RE{num}{real})(\s+(degree|mile|km|radian))?/);

    my $stripW = $1;
    my $unit   = $3 if $2; # leave it undef otherwise

    my $url = new URI ($self->{path} . '/geo/types/spherical');
    $url->query_form (stripWidth => $stripW,
		      ($unit
		          ? (unit => $unit) # be explicit
		          : ()
		       )
		      );

    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (POST $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return $resp->content =~ m/^"?(.*?)"?$/ && $1;
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
    my $self = shift;

    my $url = new URI ($self->{path} . '/geo/types/cartesian');

    use Regexp::Common;
    if ($_[0] =~ /($RE{num}{real})x($RE{num}{real})(\+($RE{num}{real})\+($RE{num}{real}))?/) {
	shift;
	my ($W, $H, $X, $Y) = ($1, $2, $4||0, $5||0);
	my $stripW = shift;
	$url->query_form (stripWidth => $stripW, xmin => $X, xmax => $X+$W, ymin => $Y, ymax => $Y+$H);
    } else {
	my ($X1, $Y1, $X2, $Y2, $stripW) = @_;
	$url->query_form (stripWidth => $stripW, xmin => $X1, xmax => $X2, ymin => $Y1, ymax => $Y2);
    }

    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (POST $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return $resp->content =~ m/^"?(.*?)"?$/ && $1;
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
    my $self    = shift;
    my $geotype = shift;
    my $pred    = shift;
    my ($xmin, $ymin, $xmax, $ymax) = @_;
    my $options = $_[4] || {};

    my $url = new URI ($self->{path} . '/geo/box');
    $url->query_form (type => $geotype,
		      predicate => $pred,
		      xmin => $xmin,
		      ymin => $ymin,
		      xmax => $xmax,
		      ymax => $ymax,
		      (defined $options->{limit}
		        ? (limit => $options->{limit})
			   : ())
		      );
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (GET $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
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
    my $self    = shift;
    my $geotype = shift;
    my $pred    = shift;
    my ($x, $y, $radius) = @_;
    my $options = $_[3] || {};

    my $url = new URI ($self->{path} . '/geo/circle');
    $url->query_form (type      => $geotype,
		      predicate => $pred,
		      x         => $x,
		      y         => $y,
		      radius    => $radius,
		      (defined $options->{limit}
		        ? (limit => $options->{limit})
			   : ())
		      );
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (GET $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
}

=pod

=item I<inPolygon> (since v0.06)

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
    my $self    = shift;
    my $geotype = shift;
    my $pred    = shift;
    my @points;
    while (ref($_[0]) eq 'ARRAY') { 
	use RDF::AllegroGraph::Utils qw(coord2literal);
	push @points, coord2literal ($geotype, @{ shift @_ });
    }
    my $options = shift || {};

    my ($blank) = $self->blanks;                                           # get one blank node

    my $url  = new URI ($self->{path} . '/geo/polygon');                   # build request to park polygon temporarily
    $url->query_form (resource => $blank,                                  # under the blank node
		      point    => \@points                                 # with these points expanded
		      );
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (PUT $url);       # AGv4 does seem to require to have that URL encoded (with PUT??)
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

    $url  = new URI ($self->{path} . '/geo/polygon');                      # build request to park polygon temporarily
    $url->query_form (polygon   => $blank,                                 # under the blank node
		      type      => $geotype,                               # for this geotype
		      predicate => $pred,                                  # and for this predicate
		      (defined $options->{limit}
		        ? (limit => $options->{limit})
			: ())
		      );
    $resp = $self->{CATALOG}->{SERVER}->{ua}->request (GET $url);          # now we make the real query
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
}


=pod

=item B<valid_indices>

This method will return a list of indices which the repository on the server understands. The list
contains strings of the form C<spogi> which identify the bias of the index. See
L<http://www.franz.com/agraph/support/documentation/v4/python-tutorial/python-tutorial-40.html#Creating a Repository>
for some introduction.

B<NOTE>: These are NOT the indices which are active for that repository. See C<indices> for that.

=cut

sub valid_indices {
    my $self = shift;
    my $url  = new URI ($self->{path} . '/indices?listValid=true');
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (GET $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
}

=pod

=item B<indices>

I<@idxs> = I<$rep>->indices ([ I<change list> ])

This method always returns the current list of applied indices for that repository.

Optionally you can pass in a list of changes you want in terms of indices, I<changes> in terms of
indices you want to add, or to remove. To add, say, a C<spogi> index you would prefix it with a '+':

   $rep->indices ('+spogi')

You can provide any number of such additions. In the same way you would a prefixed '-' to indicate
that you want an index to be deleted.

=cut

sub indices {
    my $self = shift;
    foreach my $sidx (@_) {                                                       # in the case we want changes to be made
	if ($sidx =~ m{\-(.+)}) {                                                 # removal of indices
	    my $url  = new URI ($self->{path} . '/indices/' . $1);
	    my $requ = HTTP::Request->new (DELETE => $url);
	    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

	} elsif ($sidx =~ m{\+(.+)}) {                                            # adding of indices
	    my $url  = new URI ($self->{path} . '/indices/' . $1);
	    my $requ = HTTP::Request->new (PUT => $url);
	    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

	} else {                                                                  # not sure what this is => ignorance is bliss
	    warn "not sure what to do with '$sidx', ignoring ...";
	}
    }
    # now collect the state of affairs from the server
    my $url  = new URI ($self->{path} . '/indices');
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (GET $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
}


=pod

=item B<bulk_loading_mode>

I<$bool> = I<$repo>->bulk_loading_mode (C<1|0>)

This method switches on and off the bulk loading capability of the repository. To enable it, pass in
C<1>, to turn it off pass in C<0>. In any case the current state is returned where C<undef> is
returned instead of C<0>.

=cut

sub _mode {
    my $ua = shift;
    my $path = shift;
    my $val  = shift;

    if (defined $val) {
	if ($val) {
	    my $resp = $ua->request (PUT $path, 'Content' => $val);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	} else {
	    my $requ = HTTP::Request->new (DELETE => $path);
	    my $resp = $ua->request ($requ);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	}
    }
    my $resp = $ua->get ($path);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return $resp->content eq 'true';
}

sub bulk_loading_mode {
    my $self = shift;
    my $val  = shift;

    return _mode ($self->{CATALOG}->{SERVER}->{ua}, $self->{path} . '/bulkMode', $val);

}

=pod

=item B<commit_mode>

I<$bool> = I<$repo>->commit_mode (C<1|0>)

Method to control the commit mode of a repository. Parameters and return values are like those for C<bulk_loading_mode>.

=cut

sub commit_mode {
    my $self = shift;
    my $val  = shift;

    return ! _mode ($self->{CATALOG}->{SERVER}->{ua}, $self->{path} . '/noCommit', defined $val ? abs($val-1) : undef);
}

=pod

=item B<duplicate_suppression_mode>

I<$bool> = I<$repo>->duplicate_suppression_mode (C<1|0>)

Method to control the duplicate suppression behavior of a repository. Parameters and return values
are like those for C<bulk_loading_mode>.

=cut

sub duplicate_suppression_mode {
    my $self = shift;
    my $val  = shift;

    return _mode ($self->{CATALOG}->{SERVER}->{ua}, $self->{path} . '/deleteDuplicates', $val);
}

=pod

=back

=cut

our $VERSION  = '0.07';

1;

__END__
