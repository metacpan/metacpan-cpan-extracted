package RDF::Query::Functions::Buzzword::DateTime;

our $VERSION = '0.002';

use strict;
use DateTime;
use DateTime::Format::Duration;
use DateTime::Format::ISO8601;
use DateTime::Format::Natural;
use RDF::Query::Error qw(:try);
use Scalar::Util qw(blessed reftype refaddr looks_like_number);

sub _NS
{
	my ($prefix) = @_;
	return sub {
		return $prefix . $_[0];
	};
}

sub _DateTime
{
	my ($node) = @_;
	
	throw RDF::Query::Error::TypeError(-text => "Expected literal.")
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'));

	my $XSD = _NS('http://www.w3.org/2001/XMLSchema#');
	
	if ($node->literal_datatype eq $XSD->('dateTime')
	or  $node->literal_datatype eq $XSD->('date'))
	{
		my $iso = DateTime::Format::ISO8601->new;
		my $dt;
		local $@ = undef;
		eval { $dt = $iso->parse_datetime($node->literal_value); };
		throw RDF::Query::Error::FilterEvaluationError(-text => $@) if $@;
		return $dt;
	}

	my $dt;
	eval {
		(my $lang = $node->literal_value_language) =~ s/[\-\_].*$//;
		# English (US, Canada, Philippines and Belize) = assume M/D/Y.
		# Spanish (US, Philippines) = assume M/D/Y.
		# Tagalog = assume M/D/Y.
		# All else, assume D/M/Y
		# Really should add Y/M/D for countries where it's more common
		my $format = ($node->literal_value_language =~ /^(en-(us|ca|ph|bz)|es-(us|ph)|tl)/i) ? 'm/d/y' : 'd/m/y';
		my $p = DateTime::Format::Natural->new(
			lang   => $lang,
			format => $format,
			);
		$dt = $p->parse_datetime($node->literal_value);
		$dt = undef unless $p->success;
	};
	return $dt if $dt;

	throw RDF::Query::Error::FilterEvaluationError(-text => "Format unrecognised.");
}

sub _Duration
{
	my ($node) = @_;
	
	throw RDF::Query::Error::TypeError(-text => "Expected literal.")
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'));

	my $XSD = _NS('http://www.w3.org/2001/XMLSchema#');

	if ($node->literal_datatype eq $XSD->('duration')
	and $node->literal_value =~ /^
			\s*
			([\+\-])?          # Potentially negitive...
			P                  # Period of...
			(?:([\d\.]*)Y)?    # n Years
			(?:([\d\.]*)M)?    # n Months
			(?:([\d\.]*)W)?    # n Weeks
			(?:([\d\.]*)D)?    # n Days
			(?:                 
				T               # And a time of...
				(?:([\d\.]*)H)? # n Hours
				(?:([\d\.]*)M)? # n Minutes
				(?:([\d\.]*)S)? # n Seconds
			)?
			\s*
			/ix)
	{
		my $X = {};
		$X->{'I'}   = $1;
		$X->{'y'}   = $2;
		$X->{'m'}   = $3;
		$X->{'w'}   = $4;
		$X->{'d'}   = $5;
		$X->{'h'}   = $6;
		$X->{'min'} = $7;
		$X->{'s'}   = $8;
		$X->{'n'}   = 0;
		
		# Handle fractional
		no strict;
		foreach my $frac (qw(y=12.m m=30.d w=7.d d=24.h h=60.min min=60.s s=1000000000.n))
		{
			my ($big, $mult, $small) = split /[\=\.]/, $frac;
			next unless ($X->{$big} =~ /\./);
			
			my $int_part  = int($X->{$big});
			my $frac_part = $X->{$big} - $int_part;
			
			$X->{$big}    =  $int_part;
			$X->{$small} += ($mult * $frac_part);
		}
		use strict;
		$X->{'n'} = int($X->{'n'});
		
		# Construct and return object.
		my $dur = DateTime::Duration->new(
			years       => $X->{'y'}||0,
			months      => $X->{'m'}||0,
			weeks       => $X->{'w'}||0,
			days        => $X->{'d'}||0,
			hours       => $X->{'h'}||0,
			minutes     => $X->{'min'}||0,
			seconds     => $X->{'s'}||0,
			nanoseconds => $X->{'n'}||0
		);
		
		return $X->{'I'} eq '-' ? $dur->inverse : $dur;
	}

	throw RDF::Query::Error::FilterEvaluationError(-text => "Format unrecognised.");
}

sub _ISO_Duration
{
	my ($d) = @_;
	my $str;
	
	# We coerce weeks into days and nanoseconds into fractions of a second
	# for compatibility with xsd:duration.
	
	if ($d->is_negative)
		{ $str .= '-P'; }
	else
		{ $str .= 'P'; }
		
	if ($d->years)
		{ $str .= $d->years.'Y'; }

	if ($d->months)
		{ $str .= $d->months.'M'; }

	if ($d->weeks || $d->days)
		{ $str .= ($d->days + (7 * $d->weeks)).'D'; }

	$str .= 'T';

	if ($d->hours)
		{ $str .= $d->hours.'H'; }

	if ($d->minutes)
		{ $str .= $d->minutes.'M'; }

	if ($d->seconds || $d->nanoseconds)
		{ $str .= ($d->seconds + ($d->nanoseconds / 1000000000)).'S'; }
		
	$str =~ s/T$//;
	
	return $str;
}

sub install
{
	my $XSD = _NS('http://www.w3.org/2001/XMLSchema#');
	my $DT  = _NS('http://buzzword.org.uk/2011/functions/datetime#');

	$RDF::Query::functions{ $DT->('now') } ||= sub {
		my ($query) = @_;
		$query->{_query_cache}{ $DT->('now') } ||= DateTime->now;
		my $now = $query->{_query_cache}{ $DT->('now') };		
		return RDF::Query::Node::Literal->new($now->strftime('%FT%T.%9N%z'), undef, $XSD->('dateTime'));
	};

	$RDF::Query::functions{ $DT->('today') } ||= sub {
		my ($query) = @_;
		$query->{_query_cache}{ $DT->('today') } ||= DateTime->now;
		my $now = $query->{_query_cache}{ $DT->('today') };
		return RDF::Query::Node::Literal->new($now->strftime('%F'), undef, $XSD->('date'));
	};

	$RDF::Query::functions{ $DT->('difference') } ||= sub {
		my ($query, $dt1, $dt2) = @_;		
		$dt1 = _DateTime($dt1);
		$dt2 = _DateTime($dt2);
		my $diff = $dt1->subtract_datetime($dt2);
		return RDF::Query::Node::Literal->new(_ISO_Duration($diff), undef, $XSD->('duration'));
	};

	$RDF::Query::functions{ $DT->('add') } ||= sub {
		my ($query, $dt1x, $durx) = @_;		
		my $dt1 = _DateTime($dt1x);
		my $dur = _Duration($durx);
		my $rv = $dt1->add_duration($dur);
		return RDF::Query::Node::Literal->new($rv->strftime('%F'), undef, $XSD->('date'))
			if ($dt1x->literal_datatype eq $XSD->('date') and $durx !~ /T/i);
		return RDF::Query::Node::Literal->new($rv->strftime('%FT%T.%9N%z'), undef, $XSD->('dateTime'));
	};

	$RDF::Query::functions{ $DT->('strftime') } ||= sub {
		my ($query, $dtx, $fmt) = @_;		
		my $dt = _DateTime($dtx);
		throw RDF::Query::Error::TypeError(-text => "Expected literal.")
			unless (blessed($fmt) and $fmt->isa('RDF::Trine::Node::Literal'));
		
		return RDF::Query::Node::Literal->new(
			$dt->strftime($fmt->literal_value),
			$fmt->literal_value_language,
			$fmt->literal_datatype,
			);
	};

	$RDF::Query::functions{ $DT->('format_duration') } ||= sub {
		my ($query, $durx, $fmt) = @_;		
		my $dur = _Duration($durx);
		throw RDF::Query::Error::TypeError(-text => "Expected literal.")
			unless (blessed($fmt) and $fmt->isa('RDF::Trine::Node::Literal'));
		
		my $formatter = DateTime::Format::Duration->new(normalise => 1, pattern => $fmt->literal_value);
		return RDF::Query::Node::Literal->new(
			$formatter->format_duration($dur),
			$fmt->literal_value_language,
			$fmt->literal_datatype,
			);
	};

	$RDF::Query::functions{ $DT->('strtotime') } ||= sub {
		my ($query, $dt1x) = @_;
		my $dt1;
		eval { $dt1 = _DateTime($dt1x); };
		return undef unless $dt1;
		return RDF::Query::Node::Literal->new($dt1->strftime('%FT%T.%9N%z'), undef, $XSD->('dateTime'));
	};

	$RDF::Query::functions{ $DT->('strtodate') } ||= sub {
		my ($query, $dt1x) = @_;
		my $dt1;
		eval { $dt1 = _DateTime($dt1x); };
		return undef unless $dt1;
		return RDF::Query::Node::Literal->new($dt1->strftime('%F'), undef, $XSD->('date'));
	};

} #/sub install


1;

__END__

=head1 NAME

RDF::Query::Functions::Buzzword::DateTime - plugin for buzzword.org.uk datetime functions

=head1 SYNOPSIS

  use RDF::TrineX::Functions -shortcuts;
  use RDF::Query;
  
  my $data = rdf_parse(<<'TURTLE', type=>'turtle', base=>$baseuri);
  @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
  
  <http://tobyinkster.co.uk/#i>
    foaf:birthday "1980-06-01"^^<http://www.w3.org/2001/XMLSchema#date> .
  TURTLE
  
  my $query = RDF::Query->new(<<'SPARQL');
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX util: <http://buzzword.org.uk/2011/functions/util#>
  PREFIX dt:   <http://buzzword.org.uk/2011/functions/datetime#>
  PREFIX xsd:  <http://www.w3.org/2001/XMLSchema#>
  SELECT
    (dt:now() AS ?now)
    (dt:today() AS ?today)
    ?bday
    (dt:format_duration(dt:difference(dt:now(), ?bday), "%Y years, %m months") AS ?age)
    (dt:add(?bday, "P10Y"^^xsd:duration) AS ?tenthbday)
    (dt:strtotime("yesterday morning"@en) AS ?yesterdaymorning)
    (dt:strftime(?bday, "%a, %d %b %Y"@en) AS ?fmtbday)
    (dt:strtodate("1/6/1980"@en-gb) AS ?guessbday)
  WHERE
  {
    ?person foaf:birthday ?bday .
  }
  SPARQL

  print $query->execute($data)->as_xml;

=head1 DESCRIPTION

This is a plugin for RDF::Query providing a number of extension functions
for dates and times.

=over

=item * http://buzzword.org.uk/2011/functions/datetime#add

Given an xsd:dateTime or xsd:date, and an xsd:duration, adds the
duration to the datetime. Returns an xsd:date if it was passed an
xsd:date and the xsd:duration didn't specify any hours, minutes or
seconds. Returns an xsd:dateTime otherwise.

=item * http://buzzword.org.uk/2011/functions/datetime#difference

Given two xsd:dateTime or xsd:date literals, returns an xsd:duration
representing the difference between them.

=item * http://buzzword.org.uk/2011/functions/datetime#format_duration

Given an xsd:duration and a literal formatting string, returns a
formatted duration. See L<DateTime::Format::Duration>.

=item * http://buzzword.org.uk/2011/functions/datetime#now

Returns the current xsd:dateTime, with supposed nanosecond precision.
If called multiple times in the same SPARQL query, will always return
the same instant.

=item * http://buzzword.org.uk/2011/functions/datetime#strftime

Takes a xsd:datetime and a literal formatting string and returns
a formattted date. See L<DateTime>.

=item * http://buzzword.org.uk/2011/functions/datetime#strtodate

Attempts to parse an arbitrary literal using natural language and
convert it into an xsd:date. Smart enough to tell the difference
between "1/6/1980"@en-us and "1/6/1980"@en-gb.

Can safely be passed an existing xsd:date or xsd:dateTime.

=item * http://buzzword.org.uk/2011/functions/datetime#strtotime

As per C<strtodate> but returns an xsd:dateTime.

C<add>, C<difference> and C<strftime> all implicitly call C<strtotime>
on their xsd:dateTime arguments, which means they don't need to be
given strict xsd:date/dateTime input.

=item * http://buzzword.org.uk/2011/functions/datetime#today

Like C<now> but returns an xsd:date.

=back

=begin trustme

=item C<install>

=end trustme

=head1 SEE ALSO

L<RDF::Query>,
L<RDF::Query::Functions::Buzzword::Util>.

L<DateTime>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
