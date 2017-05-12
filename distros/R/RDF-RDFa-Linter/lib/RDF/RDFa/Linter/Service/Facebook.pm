package RDF::RDFa::Linter::Service::Facebook;

use 5.008;
use base 'RDF::RDFa::Linter::Service';
use strict;
use constant OGP_NS => 'http://ogp.me/ns#';
use constant ARTICLE_NS => 'http://ogp.me/ns/article#';
use constant BOOK_NS => 'http://ogp.me/ns/book#';
use constant MUSIC_NS => 'http://ogp.me/ns/music#';
use constant PROFILE_NS => 'http://ogp.me/ns/profile#';
use constant VIDEO_NS => 'http://ogp.me/ns/video#';
use constant WEBSITE_NS => 'http://ogp.me/ns/website#';
use constant OLD_NS => 'http://opengraphprotocol.org/schema/';
use constant FB_NS  => 'http://developers.facebook.com/schema/';
use RDF::TrineX::Functions -shortcuts, statement => { -as => 'rdf_statement' };

our $VERSION = '0.053';

#our @ogp_terms = qw(title type image url description site_name
#	latitude longitude street-address locality region postal-code country-name
#	email phone_number fax_number upc isbn);

our $Terms = {
	OGP_NS() =>
		[qw[audio audio:album audio:artist audio:secure_url audio:title audio:type
		    country-name description determiner email fax_number image image:height
		    image:secure_url image:type image:width isbn latitude locale locality
		    longitude phone_number postal-code region site_name street-address title
		    type upc url video video:height video:secure_url video:type video:width
		    locale:alternate image:url audio:url video:url]],
	FB_NS() =>
		[qw[admins app_id]],
	OLD_NS() =>
		[qw[title type image url description site_name upc isbn
		    street-address locality region postal-code country-name
		    latitude longitude email phone_number fax_number]],
	ARTICLE_NS() =>
		[qw[published_time modified_time expiration_time author section tag]],
	BOOK_NS() =>
		[qw[author isbn release_date tag]],
	MUSIC_NS() =>
		[qw[durarion album album:disc album:track musician release_date creator
		    song song:disc song:track]],
	PROFILE_NS() =>
		[qw[first_name last_name username gender]],
	VIDEO_NS() =>
		[qw[actor actor:role director writer duration release_date tag series]],
	WEBSITE_NS() =>
		[qw()],
	};

our $Required =
	[qw[title type image url]];

our $Deprecated =
	[qw[audio:title audio:artist audio:album latitude longitude
	    street-address locality region postal-code country-name
	    email phone_number fax_number isbn upc]];

our $ns_re;
BEGIN {
	my $nsa = FB_NS;
	my $nsb = OGP_NS;
	my $nsc = OLD_NS;
	my $nsd = MUSIC_NS;
	my $nse = VIDEO_NS;
	my $nsf = ARTICLE_NS;
	my $nsg = BOOK_NS;
	my $nsh = PROFILE_NS;
	my $nsi = WEBSITE_NS;
	$ns_re = qr/^(\Q$nsa\E|\Q$nsb\E|\Q$nsc\E|\Q$nsd\E|\Q$nse\E|\Q$nsf\E|\Q$nsg\E|\Q$nsh\E|\Q$nsi\E)(.*)$/;
}

sub sgrep_filter
{
	return 1 if $_[0]->predicate->uri =~ /$ns_re/;
	return 0;
};

sub new
{
	my $self = RDF::RDFa::Linter::Service::new(@_);
	
	$self->{'filtered'}->add_statement(rdf_statement(
		$self->{'uri'},
		'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 
		'urn:x-rdf-rdfa-linter:internals:OpenGraphProtocolNode',
		));
	
	return $self;
}

sub info
{
	return {
		short        => 'Facebook',
		title        => 'Facebook / Open Graph Protocol',
		description  => 'The Open Graph Protocol, from Facebook. See http://ogp.me/ for details.',
		};
}

sub prefixes
{
	return {
		og      => OGP_NS,
		fb      => FB_NS,
		article => ARTICLE_NS,
		book    => BOOK_NS,
		music   => MUSIC_NS,
		profile => PROFILE_NS,
		video   => VIDEO_NS,
		website => WEBSITE_NS,
		};
}

sub find_errors
{
	my $self = shift;
	my @rv = $self->SUPER::find_errors(@_);
	
	push @rv, $self->_check_unknown_types; # has a side-effect of generating $self->{typemap}
	push @rv, $self->_check_required_properties;
	push @rv, $self->_check_url_properties;
	push @rv, $self->_check_datetime_properties;
	push @rv, $self->_check_old_ns;
	push @rv, $self->_check_deprecated_properties;
	push @rv, $self->_check_unknown_properties;
	push @rv, $self->_check_sane_coordinates;
	push @rv, $self->_check_verticals; # uses $self->{typemap}
	
	return @rv;
}

sub _check_sane_coordinates
{
	my ($self) = @_;
	my @errs;
	
	my $sparql = sprintf('SELECT * WHERE { { ?subject <%s%s> ?latitude . } UNION { ?subject <%s%s> ?longitude . } }', OGP_NS, 'latitude', OGP_NS, 'longitude');
	my $iter   = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph);
	
	my $r = {};
	while (my $row = $iter->next)
	{
		$r->{ $row->{'subject'}->as_ntriples }->{'subject'} = $row->{'subject'};
		push @{ $r->{ $row->{'subject'}->as_ntriples }->{'longitude'} }, $row->{'longitude'}
			if defined $row->{'longitude'};
		push @{ $r->{ $row->{'subject'}->as_ntriples }->{'latitude'} }, $row->{'latitude'}
			if defined $row->{'latitude'};
	}
	
	foreach my $x (values %$r)
	{		
		if (@{ $x->{latitude} } && !@{ $x->{longitude} })
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $x->{'subject'},
					'text'    => 'og:latitude is defined, but og:longitude is not',
					'level'   => 1,
					'link'    => 'http://opengraphprotocol.org/#location',
				);
		}
		if (!@{ $x->{latitude} } && @{ $x->{longitude} })
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $x->{'subject'},
					'text'    => 'og:longitude is defined, but og:latitude is not',
					'level'   => 1,
					'link'    => 'http://opengraphprotocol.org/#location',
				);
		}
		if (defined $x->{latitude}->[1])
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $x->{'subject'},
					'text'    => 'Multiple values for og:latitude',
					'level'   => 2,
					'link'    => 'http://opengraphprotocol.org/#location',
				);
		}
		if (defined $x->{longitude}->[1])
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $x->{'subject'},
					'text'    => 'Multiple values for og:longitude',
					'level'   => 2,
					'link'    => 'http://opengraphprotocol.org/#location',
				);
		}
		if (defined $x->{longitude}->[0] && defined $x->{latitude}->[0]
		&& $x->{longitude}->[0]->is_literal && $x->{latitude}->[0]->is_literal
		&& $x->{longitude}->[0]->literal_value == 0 && $x->{latitude}->[0]->literal_value == 0)
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $x->{'subject'},
					'text'    => 'The co-ordinates (0,0) are given for latitude and longitude. These refer to a location in the Atlantic Ocean not too far away from Ghana. These co-ordinates are rarely genuine and are more often the result of dumping data into a page without checking if it contains null values.',
					'level'   => 1,
					'link'    => 'http://opengraphprotocol.org/#location',
				);
		}
		foreach my $l (@{ $x->{latitude} })
		{
			if (!$l->is_literal)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'Non-literal value for og:latitude: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://opengraphprotocol.org/#location',
					);
			}
			elsif ($l->literal_value !~ /^[\+\-]?\d+(\.\d+)?$/)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'Non-numeric value for og:latitude: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://opengraphprotocol.org/#location',
					);
			}
			elsif ($l->literal_value + 0 > 90)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'og:latitude is further North than Santa Claus: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://en.wikipedia.org/wiki/Latitude',
					);
			}
			elsif ($l->literal_value + 0 < -90)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'og:latitude is further South than possible: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://en.wikipedia.org/wiki/Latitude',
					);
			}
		}
		foreach my $l (@{ $x->{longitude} })
		{
			if (!$l->is_literal)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'Non-literal value for og:longitude: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://opengraphprotocol.org/#location',
					);
			}
			elsif ($l->literal_value !~ /^[\+\-]?\d+(\.\d+)?$/)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'Non-numeric value for og:longitude: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://opengraphprotocol.org/#location',
					);
			}
			elsif ($l->literal_value + 0 > 180)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'og:longitude is further East than possible: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://en.wikipedia.org/wiki/Longitude',
					);
			}
			elsif ($l->literal_value + 0 < -180)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $x->{'subject'},
						'text'    => 'og:longitude is further West than possible: '.$l->as_ntriples,
						'level'   => 3,
						'link'    => 'http://en.wikipedia.org/wiki/Longitude',
					);
			}
		}
	}
	
	return @errs;
}

sub _check_unknown_types
{
	my ($self) = @_;
	my @errs;
	
	my $regexp = 'activity|sport|bar|company|cafe|hotel|restaurant|
	              cause|sports_league|sports_team|band|government|
	              non_profit|school|university|actor|athlete|author|
	              director|musician|politician|public_figure|city|
	              country|landmark|state_province|album|book|drink|
	              food|game|movie|product|song|tv_show|article|blog|website|
	              profile|.+\:.+|video\.(movie|episode|tv_show|other)|video|
	              music\.(song|album|playlist|radio_station)|music';
	
	my $sparql = sprintf('SELECT * WHERE { ?subject <%s%s> ?type . }', OGP_NS, 'type');
	my $iter   = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph);
	
	my $already = {};
		
	while (my $row = $iter->next)
	{
		if ($already->{ $row->{'subject'} })
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $row->{'subject'},
					'text'    => 'Multiple og:type values.',
					'level'   => 3,
					'link'    => 'http://ogp.me/#types',
				);
		}
		push @{ $already->{ $row->{'subject'} } }, $row->{type}->literal_value
			if $row->{type}->literal;
		
		if (not $row->{'type'}->is_literal)
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $row->{'subject'},
					'text'    => 'Non-literal value for og:type: '.$row->{'type'}->as_ntriples,
					'level'   => 3,
					'link'    => 'http://ogp.me/#types',
				);
		}
		elsif ($row->{'type'}->literal_value !~ m/^($regexp)$/x)
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $row->{'subject'},
					'text'    => 'Unrecognised value for og:type: '.$row->{'type'}->literal_value,
					'level'   => 3,
					'link'    => 'http://ogp.me/#types',
				);
		}
	}
	
	$self->{typemap} = $already;
	
	return @errs;
}

sub _check_url_properties
{
	my ($self) = @_;
	my @errs;

	my @props = (
		OGP_NS.'url',
		OGP_NS.'image',
		OGP_NS.'audio',
		OGP_NS.'video',
		OGP_NS.'image:url',
		OGP_NS.'audio:url',
		OGP_NS.'video:url',
		OGP_NS.'image:secure_url',
		OGP_NS.'audio:secure_url',
		OGP_NS.'video:secure_url',
		MUSIC_NS.'musician',
		MUSIC_NS.'creator',
		VIDEO_NS.'actor',
		VIDEO_NS.'director',
		VIDEO_NS.'writer',
		ARTICLE_NS.'author',
		BOOK_NS.'author',
		);
	
	foreach my $prop (@props)
	{
		my $iter = $self->filtered_graph->get_statements(undef, RDF::Trine::Node::Resource->new($prop), undef);
		
		while (my $row = $iter->next)
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $row->subject,
					'text'    => "Non-URL value for property <$prop>: ".$row->object->as_ntriples,
					'level'   => 2,
					'link'    => 'http://ogp.me/',
				)
				unless $row->object->is_resource
				||     ($row->object->is_literal and $row->object->literal_value =~ /^(https?|s?ftps?|mailto):/i);
		}
	}
	
	return @errs;
}

sub _check_datetime_properties
{
	my ($self) = @_;
	my @errs;

	my @props = (
		MUSIC_NS.'release_date',
		VIDEO_NS.'release_date',
		ARTICLE_NS.'published_time',
		ARTICLE_NS.'modified_time',
		ARTICLE_NS.'expiration_time',
		BOOK_NS.'release_date',
		);
	
	foreach my $prop (@props)
	{
		my $iter = $self->filtered_graph->get_statements(undef, RDF::Trine::Node::Resource->new($prop), undef);
		
		while (my $row = $iter->next)
		{
			push @errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => $row->subject,
					'text'    => "Non-DateTime value for property <$prop>: ".$row->object->as_ntriples.". Use format YYYY-MM-DD.",
					'level'   => 2,
					'link'    => 'http://ogp.me/',
				)
				unless ($row->object->is_literal and $row->object->literal_value =~ /^(\d{4}-\d{2}-\d{2})(T\d{2}:\d{2}(:\d{2}(\.\d+)?)?)?(Z|([+-]\d{2}:?\d{2}))?/i);
		}
	}
	
	return @errs;
}

sub _check_required_properties
{
	my ($self) = @_;
	my @errs;
	
	my $sparql  = sprintf('DESCRIBE <%s>', $self->{'uri'});
	my $hashref = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph)->as_hashref;
	
	foreach my $prop (@$Required)
	{
		push @errs,
			RDF::RDFa::Linter::Error->new(
				'subject' => RDF::Trine::Node::Resource->new($self->{'uri'}),
				'text'    => 'Missing property: og:'.$prop,
				'level'   => 2,
				'link'    => 'http://ogp.me/#metadata',
			)
			unless defined $hashref->{ $self->{'uri'} }->{ OGP_NS.$prop };
	}
	
	return @errs;
}

sub _check_unknown_properties
{
	my ($self) = @_;
	my @errs;
	
	my $sparql  = sprintf('SELECT ?prop { ?s ?prop ?o . }');
	my $results = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph);
	
	while (my $row = $results->next)
	{
		next unless $row->{prop}->can('uri');
		my ($ns,$term) = ($row->{prop}->uri =~ $ns_re);
		next unless ref $Terms->{$ns};
		next if grep { $_ eq $term } @{$Terms->{$ns}};
		
		push @errs,
			RDF::RDFa::Linter::Error->new(
				'subject' => RDF::Trine::Node::Resource->new($self->{'uri'}),
				'text'    => 'Unknown property '.$row->{prop},
				'level'   => 2,
				'link'    => 'http://ogp.me/',
			);
	}
	
	return @errs;
}

sub _check_deprecated_properties
{
	my ($self) = @_;
	my @errs;
	
	foreach my $prop (@$Deprecated)
	{
		push @errs,
			RDF::RDFa::Linter::Error->new(
				'subject' => RDF::Trine::Node::Resource->new($self->{'uri'}),
				'text'    => 'Deprecated property: og:'.$prop,
				'level'   => 2,
				'link'    => 'http://ogp.me/ns/ogp.me.ttl',
			)
			if $self->filtered_graph->count_statements(undef, RDF::Trine::Node::Resource->new(OGP_NS.$prop), undef);
	}
	
	return @errs;
}

sub _check_old_ns
{
	my ($self) = @_;
	my @errs;
	
	my $sparql  = sprintf('SELECT DISTINCT ?s ?p { ?s ?p ?o . FILTER regex(STR(?p), "^%s", "i") }', OLD_NS);
	my $results = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph);
	
	while (my $row = $results->next)
	{
		push @errs,
			RDF::RDFa::Linter::Error->new(
				'subject' => $row->{'s'},
				'text'    => '<'.$row->{'p'}->uri.'> URI is deprecated. Use the <http://ogp.me/ns#> namespace instead.',
				'level'   => 2,
				'link'    => 'http://groups.google.com/group/open-graph-protocol/msg/7391c87e994edc4d',
			);
	}
	
	return @errs;
}

sub _check_verticals
{
	my ($self) = @_;
	my @errs;
	
	my %verticals = (
		music   => MUSIC_NS,
		book    => BOOK_NS,
		website => WEBSITE_NS,
		article => ARTICLE_NS,
		video   => VIDEO_NS,
		profile => PROFILE_NS,
		);
	
	while (my ($type, $namespace) = each %verticals)
	{
		my $sparql  = sprintf('SELECT DISTINCT ?s ?p { ?s ?p ?o . FILTER regex(STR(?p), "^%s", "i") }', $namespace);
		my $results = RDF::RDFa::Linter::__rdf_query($sparql, $self->filtered_graph);
		
		while (my $row = $results->next)
		{
			my @types = @{ $self->{typemap}{$row->{s}} };
			next unless @types;
			
			unless (grep { $_ =~ /^$type\./ } @types)
			{
				push @errs,
					RDF::RDFa::Linter::Error->new(
						'subject' => $row->{'s'},
						'text'    => 'Property <'.$row->{'p'}->uri.'> should only be used for nodes of og:type "'.$type.'".',
						'level'   => 3,
						'link'    => 'http://ogp.me/',
					);
			}
		}
	}
	
	return @errs;
}

1;
