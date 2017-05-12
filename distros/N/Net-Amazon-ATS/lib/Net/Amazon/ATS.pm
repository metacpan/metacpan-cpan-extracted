package Net::Amazon::ATS;

use strict;
use warnings;
use DateTime::Format::Strptime;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Digest::HMAC_SHA1;
use POSIX qw( strftime );
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(libxml aws_access_key_id secret_access_key ua));
our $VERSION = "0.03";

sub new {
	my($class, $aws_access_key_id, $secret_access_key) = @_;
	my $self = {};
	bless $self, $class;

	my $ua = LWP::UserAgent->new;
	$ua->timeout(30);
	$self->ua($ua);
	$self->libxml(XML::LibXML->new);
	$self->aws_access_key_id($aws_access_key_id);
	$self->secret_access_key($secret_access_key);
	return $self;
}

sub topsites {
	my($self, %options) = @_;

	my $parms = {
		Operation => 'UrlInfo',
		Start => $options{Start} || 1,
		Count => $options{Count} || 10,
	};
	$parms->{Count} = 100 if $parms->{Count} > 100;
	$parms->{Count} = 1 if $parms->{Count} < 1;
	for (qw(CountryCode CityCode ResponseGroup)) {
		$parms->{$_} = $options{$_} if exists $options{$_};
	}

	my $xpc = $self->_request($parms);

	my @sites;
	for my $node ($xpc->findnodes("//ats:Site")) {
		my $data = {
			Domain	=> $xpc->findvalue(".//ats:DataUrl", $node),
			Rank	=> $xpc->findvalue(".//ats:Global/ats:Rank", $node),
		};

		# This loop executes at most once.
		for my $country ($xpc->findnodes(".//ats:Country", $node)) {
			$data->{Country} = {
				Rank => $xpc->findvalue(".//ats:Rank", $country),
				ReachPerMillion => $xpc->findvalue(".//ats:Reach/ats:PerMillion", $country),
				ViewsPerMillion => $xpc->findvalue(".//ats:PageViews/ats:PerMillion", $country),
				ViewsPerUser => $xpc->findvalue(".//ats:PageViews/ats:PerUser", $country),
			};
		}

		# This loop executes at most once.
		for my $city ($xpc->findnodes(".//ats:City", $node)) {
			$data->{City} = {
				Rank => $xpc->findvalue(".//ats:Rank", $city),
				ReachPerMillion => $xpc->findvalue(".//ats:Reach/ats:PerMillion", $city),
				ViewsPerMillion => $xpc->findvalue(".//ats:PageViews/ats:PerMillion", $city),
				ViewsPerUser => $xpc->findvalue(".//ats:PageViews/ats:PerUser", $city),
			};
		}

		push(@sites, $data);
	}

	return \@sites;
}

sub _test_request {
	my $self = shift;
	use File::Slurp;
	my $xml = read_file("/tmp/ats.xml");
	my $doc = $self->libxml->parse_string($xml);
	my $xpc = XML::LibXML::XPathContext->new($doc);
	$xpc->registerNs('ats', 'http://ats.amazonaws.com/doc/2005-11-21');
	return $xpc;
}

sub _request {
	my($self, $parms) = @_;
#  sleep 1;

	# Start, Count, Country, ResponseGroup=Country

	$parms->{Action} = 'TopSites';
	$parms->{AWSAccessKeyId} = $self->aws_access_key_id;
	$parms->{Timestamp} = strftime '%Y-%m-%dT%H:%M:%S.000Z', gmtime;
	my $hmac = Digest::HMAC_SHA1->new($self->secret_access_key);
	$hmac->add( $parms->{Action} . $parms->{Timestamp} );
	$parms->{Signature} = $hmac->b64digest . '=';

	unless ($parms->{ResponseGroup}) {
		my @groups;
		push @groups, 'Country' if $parms->{CountryCode};
		push @groups, 'City' if $parms->{CityCode};
		unless (@groups) {
			$parms->{CountryCode} = 'US';
			push @groups, 'Country';
		}
		$parms->{ResponseGroup} = join(',', @groups);
	}

	my $url = 'http://ats.amazonaws.com/';

	my $uri = URI->new($url);
	$uri->query_param($_, $parms->{$_}) foreach keys %$parms;
	my $response = $self->ua->get("$uri");

#  die $uri;

	die "Error fetching response: " . $response->status_line unless $response->is_success;

	my $xml = $response->content;
	my $doc = $self->libxml->parse_string($xml);

	my $xpc = XML::LibXML::XPathContext->new($doc);
	$xpc->registerNs('ats', 'http://ats.amazonaws.com/doc/2005-11-21');

#  warn $doc->toString(1);

	if ($xpc->findnodes("//ats:Error")) {
		die $xpc->findvalue("//ats:Error/ats:Code") . ": " .
		$xpc->findvalue("//ats:Error/ats:Message");
	}

	return $xpc;
}

1;

__END__

=head1 NAME

Net::Amazon::ATS - Use the Amazon Alexa Top Sites Service

=head1 SYNOPSIS

  use Net::Amazon::ATS;
  my $ats = new Net::Amazon::ATS($subscription_id, $secret);
  my $data = $ats->topsites();
  my $data = $ats->topsites(
  	Start		=> 100,
	Count		=> 10,
	CountryCode	=> 'US',
  );

=head1 DESCRIPTION

The Net::Amazon::ATS module allows you to use the Amazon
Alexa Top Sites Service.

The Alexa Top Sites Service (ATS) provides developers with programmatic
access to the information Alexa Internet (www.alexa.com) collects from
its Web Crawl, which currently encompasses more than 100 terabytes of
data from over 4 billion Web pages. Developers and Web site owners
can use AWIS as a platform for finding answers to difficult and
interesting problems on the Web, and incorporating them into their
Web applications.

In order to access the Alexa Web Information Service,
you will need an Amazon Web Services Subscription ID. See
http://www.amazon.com/gp/aws/landing.html

Registered developers have free access to the Alexa Web Information
Service during its beta period, but it is limited to 10,000 requests
per subscription ID per day.

There are some limitations, so be sure to read the The Amazon Alexa
Top Sites Service FAQ.

=head1 INTERFACE

The interface follows. Most of this documentation was copied from the
API reference. Upon errors, an exception is thrown.

=head2 new

The constructor method creates a new Net::Amazon::ATS object. You
must pass in an Amazon Web Services Access Key ID and a Secret Access
Key. See http://www.amazon.com/gp/aws/landing.html:

  my $ats = Net::Amazon::ATS->new($aws_access_key_id, $secret_access_key);
=head1 BUGS

Please report any bugs or feature requests to
C<bug-<Net-Amazon-ATS>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Shevek C<shevek@cpan.org>

Borrowed somewhat heavily from L<Net::Amazon::AWIS> by
Leon Brocard C<acme@astray.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Shevek C<shevek@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
