package RDF::iCalendar::Exporter;

use 5.008;
use base qw[RDF::vCard::Exporter];
use strict;
use warnings;
no warnings qw(uninitialized);

use DateTime;
use MIME::Base64 qw[];
use RDF::iCalendar::Entity;
use RDF::iCalendar::Line;
use RDF::TrineX::Functions
	-shortcuts,
	statement => { -as => 'rdf_statement' },
	iri       => { -as => 'rdf_resource' };
use Scalar::Util qw[blessed];
use URI;

require RDF::vCard;

# kinda constants
sub I    { return 'http://www.w3.org/2002/12/cal/icaltzd#' . shift; }
sub IX   { return 'http://buzzword.org.uk/rdf/icaltzdx#' . shift; }
sub RDF  { return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' . shift; }
sub V    { return 'http://www.w3.org/2006/vcard/ns#' . shift; }
sub VX   { return 'http://buzzword.org.uk/rdf/vcardx#' . shift; }
sub XSD  { return 'http://www.w3.org/2001/XMLSchema#' . shift; }

sub flatten_node
{
	my $node = shift;
	return $node->value if $node->is_resource || $node->is_literal;
	return $node->as_ntriples;
}

use namespace::clean;

our $VERSION = '0.005';
our $PRODID  = sprintf("+//IDN cpan.org//NONSGML %s v %s//EN", __PACKAGE__, $VERSION);

our %cal_dispatch = (
	);

our %dispatch = (
	IX('contact')    => \&_prop_export_contact,
	I('contact')     => \&_prop_export_contact,
	I('geo')         => \&_prop_export_geo,
	IX('organizer')  => \&_prop_export_Person,
	I('organizer')   => \&_prop_export_Person,
	IX('attendee')   => \&_prop_export_Person,
	I('attendee')    => \&_prop_export_Person,
	I('attach')      => \&RDF::vCard::Exporter::_prop_export_binary,
	I('dtstart')     => \&_prop_export_DateTime,
	I('dtend')       => \&_prop_export_DateTime,
	I('due')         => \&_prop_export_DateTime,
	I('completed')   => \&_prop_export_DateTime,
	I('created')     => \&_prop_export_DateTime,
	I('dtstamp')     => \&_prop_export_DateTime,
	I('last-modified') => \&_prop_export_DateTime,
	IX('location')   => \&_prop_export_location,
	I('location')    => \&_prop_export_location,
	I('rrule')       => \&_prop_export_Recur,
	I('exrule')      => \&_prop_export_Recur,
	I('valarm')      => \&_prop_export_valarm,
	I('freebusy')    => \&_prop_export_freebusy,
	# RELATED-TO
	);

our %list_dispatch = (
	I('exdate')      => ['exdate',     \&_value_export_DateTime],
	I('rdate')       => ['rdate',      \&_value_export_DateTime],
	I('resources')   => ['resources',  \&_value_export_category],
	I('categories')  => ['categories', \&_value_export_category],
	I('category')    => ['categories', \&_value_export_category],
	IX('category')   => ['categories', \&_value_export_category],
	);
	
sub _rebless
{
	my ($self, $thing) = @_;
	if ($thing->isa('RDF::vCard::Line'))
	{
		return bless $thing, 'RDF::iCalendar::Line';
	}
	if ($thing->isa('RDF::vCard::Entity'))
	{
		return bless $thing, 'RDF::iCalendar::Entity';
	}
}

sub _debug
{
#	my ($self, @debug) = @_;
#	printf(@debug);
#	print "\n";
}

sub export_cards # need to really use superclass for these
{
	my ($self, $model, %options) = @_;	
	return RDF::vCard::Exporter->new->export_cards($model, %options);
}

sub export_card # need to really use superclass for these
{
	my ($self, $model, $subject, %options) = @_;	
	return RDF::vCard::Exporter->new->export_card($model, $subject, %options);
}

sub export_calendars
{
	my ($self, $model, %options) = @_;
	$model = rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my @subjects =  $model->subjects(rdf_resource(RDF('type')), rdf_resource(I('Vcalendar')));
	push @subjects, $model->subjects(rdf_resource(I('component')), undef);	
	my %subjects = map { flatten_node($_) => $_ } @subjects;
	
	my @cals;
	foreach my $s (values %subjects)
	{
		push @cals, $self->export_calendar($model, $s, %options);
	}
	
	if ($options{sort})
	{
		return sort { $a->entity_order cmp $b->entity_order } @cals;
	}
	
	return @cals;
}

sub export_calendar
{
	my ($self, $model, $subject, %options) = @_;
	$model = RDF::TrineShortcuts::rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my $ical = RDF::iCalendar::Entity->new( profile=>'VCALENDAR' );
	
	my %categories;
	my $triples = $model->get_statements($subject, undef, undef);
	while (my $triple = $triples->next)
	{
#		next
#			unless (substr($triple->predicate->uri, 0, length(&I)) eq &I or
#					  substr($triple->predicate->uri, 0, length(&IX)) eq &IX);

		if ($triple->predicate->uri eq I('component'))
		{
			$ical->add_component($self->export_component($model, $triple->object));
		}
		elsif (defined $cal_dispatch{$triple->predicate->uri}
		and    ref($cal_dispatch{$triple->predicate->uri}) eq 'CODE')
		{
			my $code = $cal_dispatch{$triple->predicate->uri};
			my $r    = $code->($self, $model, $triple);
			if (blessed($r) and $r->isa('RDF::iCalendar::Line'))
				{ $ical->add($r); }
			elsif (blessed($r) and $r->isa('RDF::iCalendar::Entity'))
				{ $ical->add_component($r); }
		}
		elsif ((substr($triple->predicate->uri, 0, length(&I)) eq &I
		or substr($triple->predicate->uri, 0, length(&IX)) eq &IX))
		{
			$ical->add($self->_prop_export_simple($model, $triple))
				unless $triple->object->is_blank;
		}
	}
			
	$ical->add(
		RDF::iCalendar::Line->new(
			property        => 'version',
			value           => '2.0',
			)
		);
		
	$ical->add(
		RDF::iCalendar::Line->new(
			property        => 'prodid',
			value           => (defined $options{prodid} ? $options{prodid} : $PRODID),
			)
		) unless exists $options{prodid} && !defined $options{prodid};

	$ical->add(
		RDF::iCalendar::Line->new(
			property        => 'source',
			value           => $options{source},
			type_parameters => {value=>'URI'},
			)
		) if defined $options{source};

	return $ical;
}

sub export_component
{
	my ($self, $model, $subject, %options) = @_;
	$model = RDF::TrineShortcuts::rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my $profile = 'VEVENT';
	$profile = 'VTIMEZONE'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vtimezone')));
	$profile = 'VFREEBUSY'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vfreebusy')));
	$profile = 'VALARM'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Valarm')));
	$profile = 'VJOURNAL'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vjournal')));
	$profile = 'VTODO'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vtodo')));
	$profile = 'VEVENT'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vevent')));
	
	my $c = RDF::iCalendar::Entity->new( profile=>$profile );
	
	$self->_debug("COMPONENT: %s", flatten_node($subject));
	
	my $lists = {};
	
	my $triples = $model->get_statements($subject, undef, undef);
	while (my $triple = $triples->next)
	{
		$self->_debug("  %s %s", $triple->predicate->sse, $triple->object->sse);
	
		if (defined $dispatch{$triple->predicate->uri}
		and ref($dispatch{$triple->predicate->uri}) eq 'CODE')
		{
			$self->_debug("   -> dispatch");
			my $code = $dispatch{$triple->predicate->uri};
			my $r    = $code->($self, $model, $triple);
			if (blessed($r) and $r->isa('RDF::iCalendar::Line'))
				{ $c->add($r); }
			elsif (blessed($r) and $r->isa('RDF::iCalendar::Entity'))
				{ $c->add_component($r); }
		}
		elsif (defined $list_dispatch{$triple->predicate->uri}
		and ref($list_dispatch{$triple->predicate->uri}) eq 'ARRAY')
		{
			$self->_debug("   -> list_dispatch");
			my ($listname, $code) = @{ $list_dispatch{$triple->predicate->uri} };
			push @{ $lists->{$listname} }, $code->($self, $model, $triple);
		}
		elsif ((substr($triple->predicate->uri, 0, length(&I)) eq &I
		or substr($triple->predicate->uri, 0, length(&IX)) eq &IX))
		{
			$self->_debug("   -> default");
			$c->add($self->_prop_export_simple($model, $triple))
				unless $triple->object->is_blank;
		}
		else
		{
			$self->_debug("   -> NO ACTION");
		}
	}
	
	foreach my $listname (keys %$lists)
	{
		$c->add(RDF::iCalendar::Line->new(
			property => $listname,
			value    => [[ sort keys %{{ map { $_ => 1 } @{$lists->{$listname}} }} ]],
			));
	}	
			
	return $c;
}

sub _prop_export_valarm
{
	my ($self, $model, $triple) = @_;
	
	unless ($triple->object->is_literal)
	{
		return $self->export_component($model, $triple->object);
	}
}

sub _prop_export_simple
{
	my ($self, $model, $triple) = @_;
	my $rv = $self->SUPER::_prop_export_simple($model, $triple);
	return $self->_rebless($rv);
}

# iCalendar forces different datetime/date formats than
# the generalised text/directory ones used by vCard...
sub _prop_export_DateTime
{
	my ($self, $model, $triple) = @_;

	my $prop = 'x-data';
	if ($triple->predicate->uri =~ m/([^\#\/]+)$/)
	{
		$prop = $1;
	}
	
	my $val    = undef;
	my $params = undef;

	my ($dt, $has_time) = $self->_node2dt($triple->object, $model);
	my $tz = $dt->time_zone;

	if ($dt and $has_time)
	{
		$params = { value=>'DATE-TIME' };
		
		unless ($tz->is_floating ||
				  $tz->is_utc ||
				  $tz->is_olson )
		{
			$dt = $dt->clone->set_time_zone('UTC');
			$tz = $dt->time_zone;
		}
		
		$val = sprintf('%04d%02d%02dT%02d%02d%02d',
			$dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second);
		
		if ($tz->is_utc)
		{
			$val .= "Z";
		}
		elsif (!$tz->is_floating)
		{
			$params->{tzid} = $tz->name;
		}
	}
	elsif ($dt)
	{
		$params = { value=>'DATE' };
		
		unless ($tz->is_floating ||
				  $tz->is_utc ||
				  $tz->is_olson )
		{
			$dt = $dt->clone->set_time_zone('UTC');
			$tz = $dt->time_zone;
		}
		
		$val = sprintf('%04d%02d%02d',
			$dt->year, $dt->month, $dt->day);
	}

	return RDF::iCalendar::Line->new(
		property        => $prop,
		value           => $val,
		type_parameters => $params,
		);
}

sub _node2dt
{
	my ($self, $node, $model) = @_;
	
	# Shouldn't happen!
	return DateTime->now unless $node->is_literal;
	
	my ($date, $time) = split /T/i, $node->literal_value;	
	my $has_time = (defined $time and length $time);

	my $dt;
	if ($date =~ m'^([0-9]{4})\-?([0-9]{2})\-?([0-9]{2})$')
	{
		$dt = DateTime->new(year => $1, month => $2, day => $3);
	}
	elsif ($date =~ m'^([0-9]{1,4})\-([0-9]{1,2})\-([0-9]{1,2})$')
	{
		$dt = DateTime->new(year => $1, month => $2, day => $3);
	}
	else
	{
		$dt = DateTime->now;
	}
	
	my $zone;
	if ($time =~ /^(.+)(Z|[\+\-]00\:?00])$/i)
	{
		$time = $1;
		$zone = DateTime::TimeZone->new(name => 'UTC');
	}
	elsif ($time =~ /^(.+)([\+\-][0-9][0-9]\:?[0-9][0-9])$/i)
	{
		$time = $1;
		$zone = DateTime::TimeZone->new(name => $2);
	}
	elsif ($node->has_datatype
	and $node->literal_datatype =~ m'^http://www\.w3\.org/2002/12/cal/tzd/(.+)#tz$')
	{
		$zone = DateTime::TimeZone->new(name => $1);
	}
	elsif ($node->has_datatype
	and $node->literal_datatype !~ m'^http://www\.w3\.org/2001/XMLSchema#'
	and defined $model)
	{
		# Some funny datatype; let's try our best!
		my @locations = grep
			{ $_->is_literal }
			$model->objects(
				rdf_resource($node->literal_datatype),
				rdf_resource('http://www.w3.org/2002/12/cal/prod/Ximian_NON_de8f2a9bed573980#location'),
				rdf_resource(RDF('value')),
				rdf_resource(RDFS('label')),
				);
		$zone = DateTime::TimeZone->new(name => $locations[0]->literal_value)
			if @locations;
	}

	$dt->set_time_zone($zone) if $zone;

	if ($time =~ m'^([0-2][0-9])\:?([0-5][0-9])\:?([0-6][0-9](\.[0-9]*)?)?$')
	{
		$dt->set_hour($1)->set_minute($2);
		$dt->set_second($3) if defined $3;
	}
	elsif ($time =~ m'^([0-2]?[0-9])\:([0-5]?[0-9])\:([0-6]?[0-9](\.[0-9]*)?)$')
	{
		$dt->set_hour($1)->set_minute($2)->set_second($3);
	}
	elsif ($time =~ m'^([0-2]?[0-9])\:([0-5]?[0-9])\:?$')
	{
		$dt->set_hour($1)->set_minute($2);
	}

	return ($dt, $has_time);
}

sub _prop_export_contact
{
	my ($self, $model, $triple) = @_;

	if ($triple->object->is_literal)
	{
		return $self->_prop_export_simple($model, $triple);
	}
	
	my $card = $self->export_card($model, $triple->object);
	my $uri  = URI->new('data:');
	$uri->media_type('text/directory');
	$uri->data("$card");

	my $label = '';
	my ($fn)     = $card->get('fn');
	my ($email)  = $card->get('email');
	if ($fn and $email)
	{
		$label = sprintf('%s <%s>',
			$fn->_unescape_value($fn->value_to_string),
			$email->_unescape_value($email->value_to_string),
			);
	}
	elsif ($fn)
	{
		$label = $fn->_unescape_value($fn->value_to_string);
	}
	elsif ($email)
	{
		$label = $email->_unescape_value($email->value_to_string);
	}

	return RDF::iCalendar::Line->new(
		property => 'contact',
		value    => $label,
		type_parameters => {
			altrep   => "\"$uri\"",
			},
		);
}

sub _prop_export_location
{
	my ($self, $model, $triple) = @_;

	$self->_debug("      Location: %s", flatten_node($triple->object));

	if ($triple->object->is_literal)
	{
		$self->_debug("       -> literal");
		return $self->_prop_export_simple($model, $triple);
	}

	if ($model->count_statements(
			$triple->object,
			rdf_resource(RDF('type')),
			rdf_resource(V('VCard')),
			)
	or  $model->count_statements(
			$triple->object,
			rdf_resource(V('fn')),
			undef,
			)
		)
	{
		$self->_debug("       -> vcard");
		my $card = $self->export_card($model, $triple->object);
		return RDF::iCalendar::Line->new(
			property => 'location',
			value    => "$card",
			type_parameters => {
				value => "VCARD",
				},
			);
	}

	elsif ($model->count_statements(
			$triple->object,
			rdf_resource(RDF('type')),
			rdf_resource(V('Address')),
			)
	or $model->count_statements(
			$triple->object,
			rdf_resource(V('locality')),
			undef,
			)
	or $model->count_statements(
			$triple->object,
			rdf_resource(V('street-address')),
			undef,
			)
		)
	{
		$self->_debug("       -> adr");
		my $line = $self->_rebless( $self->_prop_export_adr($model, $triple) );
		$line->{property} = 'location';
		return $line;
	}

	elsif ($model->count_statements(
			$triple->object,
			rdf_resource(RDF('type')),
			rdf_resource(V('Location')),
			)
	or $model->count_statements(
			$triple->object,
			rdf_resource(V('latitude')),
			undef,
			)
		)
	{
		$self->_debug("       -> geo");
		my $line = $self->_rebless( $self->SUPER::_prop_export_geo($model, $triple) );
		$line->{property} = 'location';
		return $line;
	}

	return $self->_prop_export_simple($model, $triple);
}


sub _prop_export_geo
{
	my ($self, $model, $triple) = @_;
	
	if ($triple->object->is_literal)
	{
		return $self->_prop_export_simple($model, $triple);
	}
	elsif ($triple->object->is_resource
	and    $triple->object->uri =~ /^geo:(.+)$/i)
	{
		my $g = $1;
		return RDF::iCalendar::Line->new(
			property => 'geo',
			value    => [ split /[,;]/, $g, 2 ],
			);
	}
	
	my ($lat, $lon);
	{
		my @latitudes = grep
			{ $_->is_literal }
			$model->objects($triple->object, rdf_resource(RDF('first')));
		$lat = $latitudes[0]->literal_value if @latitudes;
		
		my @nodes = grep
			{ !$_->is_literal }
			$model->objects($triple->object, rdf_resource(RDF('next')));
		if (@nodes)
		{
			my @longitudes = grep
				{ $_->is_literal }
				$model->objects($nodes[0], rdf_resource(RDF('first')));
			$lon = $longitudes[0]->literal_value if @longitudes;
		}
	}
	
	return RDF::iCalendar::Line->new(
		property => 'geo',
		value    => [$lat||0, $lon||0],
		);
}

sub _prop_export_Person
{
	my ($self, $model, $triple) = @_;

	if ($triple->object->is_literal)
	{
		return $self->_prop_export_simple($model, $triple);
	}
	
	my $property = {
		I('organizer')  => 'organizer',
		IX('organizer') => 'organizer',
		I('attendee')   => 'attendee',
		IX('attendee')  => 'attendee',
		}->{ $triple->predicate->uri };
	
	my ($name, $email, $role, $partstat, $rsvp, $cutype, %thing_values);
	
	my %thing_meta = (
		'sent-by'        => [map {rdf_resource($_)} IX('sentBy'), I('sent-by')],
		'delegated-to'   => [map {rdf_resource($_)} IX('delegatedTo'), I('delegated-to')],
		'delegated-from' => [map {rdf_resource($_)} IX('delegatedFrom'), I('delegated-from')],
		);
	
	if ($triple->object->is_resource
	and $triple->object->uri =~ /^mailto:.+$/i)
	{
		$email = $triple->object->uri;
	}
	else
	{
		($name) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(IX('cn')), rdf_resource(V('fn')));

		($role) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(V('role')), rdf_resource(I('role')), rdf_resource(IX('role')));

		($partstat) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(I('partstat')), rdf_resource(IX('partstat')));

		($rsvp) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(I('rsvp')), rdf_resource(IX('rsvp')));

		($cutype) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(VX('kind')), rdf_resource(I('cutype')), rdf_resource(IX('cutype')));

		($email) = $model->objects($triple->object, rdf_resource(V('email')));
		if ($email
		and ($email->is_blank or ($email->is_resource and $email->uri !~ /^mailto:/i)))
		{
			($email) = grep
				{ !$_->is_blank }
				$model->objects($email, rdf_resource(RDF('value')));
		}

		# This bit doesn't just work for sent-by, but also delegated-from/delegated-to
		while (my ($P, $X) = each %thing_meta)
		{
			my ($sentby) = $model->objects_for_predicate_list($triple->object, @$X);
			# if $sentby isn't an email address
			if (!defined $sentby) {}
			elsif ($sentby->is_blank or $sentby->is_resource && $sentby->uri !~ /^mailto:/i)
			{
				# Maybe it's a vcard:Email resource; if so, then get the rdf:value.
				my ($value) = grep
					{ !$_->is_blank }
					$model->objects($triple->object, rdf_resource(RDF('value')));
				if ($value)
				{
					$sentby = $value;
				}
				# If it's not then it might be a vcard:VCard...
				else
				{
					my ($sb_email) = $model->objects($sentby, rdf_resource(V('email')));
					if (!defined $sb_email) {}
					elsif ($sb_email->is_literal or $sb_email->is_resource && $sb_email->uri !~ /^mailto:/i)
					{
						$sentby = $sb_email;
					}
					else
					{
						my ($value) = grep
							{ !$_->is_blank }
							$model->objects($sb_email, rdf_resource(RDF('value')));
						if ($value)
						{
							$sentby = $value;
						}
					}
				}
			}
			
			$thing_values{$P} = $sentby if $sentby;
		}
	}
	
	my %params = ();
	$params{'cn'} = flatten_node($name)
		if defined $name;
	
	foreach my $P (keys %thing_meta)
	{
		$params{$P} = flatten_node($thing_values{$P})
			if defined $thing_values{$P};
	}

	$params{'cutype'} = flatten_node($cutype)
		if (defined $cutype and $property eq 'attendee');
	$params{'partstat'} = flatten_node($partstat)
		if (defined $partstat and $property eq 'attendee');
	$params{'role'} = flatten_node($role)
		if (defined $role and $property eq 'attendee');
	$params{'rsvp'} = flatten_node($rsvp)
		if (defined $rsvp and $property eq 'attendee');

	$params{'value'} = 'CAL-ADDRESS';

	if (!$email)
	{
		$email = $name;
		$params{'value'} = 'TEXT';
	}
	
	return RDF::iCalendar::Line->new(
		property => $property,
		value    => flatten_node($email),
		type_parameters => \%params,
		);
}

sub _value_export_simple
{
	my ($self, $model, $triple) = @_;
	my $rv = $self->_prop_export_simple($model, $triple);
	return $rv->_unescape_value($rv->value_to_string);
}

sub _value_export_DateTime
{
	my ($self, $model, $triple) = @_;
	my $rv = $self->_prop_export_DateTime($model, $triple);
	return $rv->_unescape_value($rv->value_to_string);
}

sub _value_export_category
{
	my ($self, $model, $triple) = @_;

	if ($triple->object->is_literal)
	{
		return uc $triple->object->literal_value;
	}

	my @labels = grep
		{ $_->is_literal }
		$model->objects_for_predicate_list(
			$triple->object,
			rdf_resource('http://www.w3.org/2004/02/skos/core#prefLabel'),
			rdf_resource('http://www.holygoat.co.uk/owl/redwood/0.1/tags/name'),
			rdf_resource('http://www.w3.org/2000/01/rdf-schema#label'),
			rdf_resource('http://www.w3.org/2004/02/skos/core#altLabel'),
			rdf_resource('http://www.w3.org/2004/02/skos/core#notation'),
			rdf_resource(RDF('value')),
			);
	
	if (@labels)
	{
		return uc $labels[0]->literal_value;
	}
	elsif ($triple->object->is_resource)
	{
		return $triple->object->uri;
	}
}

sub _prop_export_Recur
{
	my ($self, $model, $triple) = @_;

	my $prop = 'x-data';
	if ($triple->predicate->uri =~ m/([^\#\/]+)$/)
	{
		$prop = $1;
	}

	if ($triple->object->is_literal)
	{
		return $self->_prop_export_simple($model, $triple);
	}
	
	my (%bits, @bits);
	
	my $iter = $model->get_statements($triple->object, undef, undef);
	while (my $st = $iter->next)
	{
		if ($st->predicate->uri =~ m'^http://www\.w3\.org/2002/12/cal/icaltzd#(.+)$')
		{
			my $p = uc $1;
			my $v = ($p eq 'UNITL') ? $self->_value_export_DateTime($model, $st) : flatten_node($st->object);
			push @{ $bits{$p} }, $v;
		}
	}
	
	while (my ($k, $v) = each %bits)
	{
		push @bits, sprintf('%s=%s', $k, join(',', @$v));
	}
	
	return RDF::iCalendar::Line->new(
		property => $prop,
		value    => [ map { [ split /,/, $_ ] } @bits ],
		type_parameters => { value => 'RECUR' },
		);
}

sub _prop_export_freebusy
{
	my ($self, $model, $triple) = @_;

	if ($triple->object->is_literal)
	{
		return RDF::iCalendar::Line->new(
			property => 'freebusy',
			value    => $triple->object->literal_value,
			type_parameters => { fbtype => 'BUSY' },
			);
	}

	my @values = sort map
		{ $_->literal_value }
		grep
		{ $_->is_literal }
		$model->objects_for_predicate_list(
			$triple->object,
			rdf_resource(RDF('value')),
			);
	
	my ($fbtype) = map
		{ uc $_->literal_value }
		grep
		{ $_->is_literal }
		$model->objects_for_predicate_list(
			$triple->object,
			rdf_resource(I('fbtype')),
			rdf_resource(IX('fbtype')),
			);

	return RDF::iCalendar::Line->new(
		property => 'freebusy',
		value    => [[ @values ]],
		type_parameters => { fbtype => $fbtype || 'BUSY' },
		);

}


1;

__END__

=head1 NAME

RDF::iCalendar::Exporter - export RDF data to iCalendar format

=head1 SYNOPSIS

 use RDF::iCalendar;
 
 my $input    = "http://example.com/calendar-data.ics";
 my $exporter = RDF::iCalendar::Exporter->new;
 
 print $_ foreach $exporter->export_calendars($input);

=head1 DESCRIPTION

This module reads RDF and writes iCalendar files.

This is a subclass of RDF::vCard::Exporter, so it can also export vCards.

=head2 Constructor

=over

=item * C<< new(%options) >>

Returns a new RDF::iCalendar::Exporter object.

There are no valid options at the moment - the hash is reserved
for future use.

=back

=head2 Methods

=over

=item * C<< export_calendars($input, %options) >>

Returns a list of iCalendars found in the input, in no particular order.

The input may be a URI, file name, L<RDF::Trine::Model> or anything else
that can be handled by the C<rdf_parse> method of L<RDF::TrineShortcuts>.

Each item in the list returned is an L<RDF::iCalendar::Entity>, though
that class overloads stringification, so you can just treat each item
as a string mostly.

=item * C<< export_calendar($input, $subject, %options) >>

As per C<export_calendars> but exports just a single calendar.

The subject provided must be an RDF::Trine::Node::Blank or
RDF::Trine::Node::Resource of type icaltzd:Vcalendar.

=item * C<< export_component($input, $subject, %options) >>

Exports a component from a calendar - e.g. a single VEVENT

The subject provided must be an RDF::Trine::Node::Blank or
RDF::Trine::Node::Resource of type icaltzd:Vevent, icaltzd:Vtodo
or similar.

=item * C<< export_cards($input, %options) >>

See L<RDF::vCard::Exporter>.

=item * C<< export_card($input, $subject, %options) >>

See L<RDF::vCard::Exporter>.

=back

=head2 RDF Input

Input is expected to use the newer of the 2005 revision of the W3C's
vCard vocabulary L<http://www.w3.org/TR/rdfcal/>. (Note that even
though this was revised in 2005, the term URIs include "2002" in
them.)

Some extensions from the namespace L<http://buzzword.org.uk/rdf/icaltzdx#>
are also supported. 

=head2 iCalendar Output

The output of this module aims at iCalendar (RFC 2445) compliance.
In the face of weird input data though, (e.g. an DTSTART property that is a
URI instead of a literal) it can pretty easily descend into exporting
junk, non-compliant iCalendars.

The output has barely been tested in any iCalendar-supporting software,
so beware.

=head1 SEE ALSO

L<RDF::iCalendar>.

L<RDF::vCard>, L<HTML::Microformats>, L<RDF::TrineShortcuts>.

L<http://www.w3.org/TR/rdfcal/>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011, 2013 Toby Inkster

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
