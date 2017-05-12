package Net::Amazon::AWIS;
use strict;
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
our $VERSION = "0.36";

sub new {
    my ( $class, $aws_access_key_id, $secret_access_key ) = @_;
    my $self = {};
    bless $self, $class;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
    $self->ua($ua);
    $self->libxml( XML::LibXML->new );
    $self->aws_access_key_id($aws_access_key_id);
    $self->secret_access_key($secret_access_key);
    return $self;
}

sub url_info {
    my ( $self, %options ) = @_;

    my $parms = {
        Operation => 'UrlInfo',
        Url       => $options{url},
        ResponseGroup =>
            'AdultContent,Categories,Language,Rank,Related,Speed',
    };

    my $xpc = $self->_request($parms);

    my @categories;
    foreach my $node ( $xpc->findnodes("//CategoryData") ) {
        my $title = $xpc->findvalue( ".//Title",        $node );
        my $path  = $xpc->findvalue( ".//AbsolutePath", $node );
        push @categories,
            {
            title => $title,
            path  => $path,
            };
    }

    my @related;
    foreach my $node ( $xpc->findnodes("//RelatedLink") ) {
        push @related,
            {
            canonical => $xpc->findvalue( ".//DataUrl",      $node ),
            url       => $xpc->findvalue( ".//NavigableUrl", $node ),
            relevance => $xpc->findvalue( ".//Relevance",    $node ),
            title     => $xpc->findvalue( ".//Title",        $node ),
            };
    }

    my $data = {
        adult_content => $xpc->findvalue(".//Content") eq 'yes',
        categories => \@categories,
        encoding => $xpc->findvalue(".//Alexa/ContentData/Language/Encoding"),
        locale   => $xpc->findvalue(".//Alexa/ContentData/Language/Locale"),
        median_load_time =>
            $xpc->findvalue(".//Alexa/ContentData/Speed/MedianLoadTime"),
        percentile_load_time =>
            $xpc->findvalue(".//Alexa/ContentData/Speed/Percentile"),
        rank    => $xpc->findvalue(".//Alexa/TrafficData/Rank"),
        related => \@related,
    };
    return $data;
}

sub web_map {
    my ( $self, %options ) = @_;

    my $parms = {
        Operation     => 'SitesLinkingIn',
        Url           => $options{url},
        ResponseGroup => 'SitesLinkingIn',
        Count         => $options{count} || 20,
        Start         => $options{start} || 0,
    };

    my $xpc = $self->_request($parms);

    my @in;
    foreach my $node ( $xpc->findnodes("//Site") ) {
        my $url = $xpc->findvalue( ".//Url", $node );
        push @in, $url;
    }

    my @out;
    return {
        links_in  => \@in,
        links_out => \@out,
    };
}

sub crawl {
    my ( $self, %options ) = @_;

    my $parms = {
        Operation     => 'Crawl',
        Url           => $options{url},
        ResponseGroup => 'MetaData',
        Count         => $options{count}
            && $options{count} >= 0
            && $options{count} < 10 ? $options{count} : 10,
    };

    my $xpc = $self->_request($parms);

    my $format = new DateTime::Format::Strptime( pattern => '%Y%m%d%H%M%S', );

    my @results;
    foreach my $node ( $xpc->findnodes("//MetaData") ) {

        my @other_urls;
        foreach my $subnode ( $xpc->findnodes( ".//OtherUrl", $node ) ) {
            push @other_urls, 'http://' . $subnode->textContent;

        }
        my @images;
        foreach my $subnode ( $xpc->findnodes( ".//Image", $node ) ) {
            push @images, 'http://' . $subnode->textContent;
        }
        my @links;
        foreach my $subnode ( $xpc->findnodes( ".//Link", $node ) ) {
            push @links,
                {
                name => $xpc->findvalue( ".//Name", $subnode ),
                uri  => 'http://'
                    . $xpc->findvalue( ".//LocationURI", $subnode ),
                };
        }

        my $result = {
            url => $xpc->findvalue( ".//RequestInfo/OriginalRequest", $node ),
            ip  => $xpc->findvalue( ".//RequestInfo/IPAddress",       $node ),
            date => $format->parse_datetime(
                $xpc->findvalue( ".//RequestInfo/RequestDate", $node )
            ),
            content_type =>
                $xpc->findvalue( ".//RequestInfo/ContentType", $node ),
            code   => $xpc->findvalue( ".//RequestInfo/ResponseCode", $node ),
            length => $xpc->findvalue( ".//RequestInfo/Length",       $node ),
            language => (
                split(
                    ' ', $xpc->findvalue( ".//RequestInfo/Language", $node )
                )
                )[0],
            images     => \@images,
            other_urls => \@other_urls,
            links      => \@links,
        };
        push @results, $result;
    }
    return @results;
}


sub history {
    my ( $self, %options ) = @_;

	my $range = defined $options{days} ? $options{days} : 31;
    my $parms = {
        Operation => 'TrafficHistory',
        Url       => $options{url},
        ResponseGroup =>
            'History',
		Start		=> defined $options{start}
						? $options{start}
						: strftime('%Y%m%d', gmtime(time() - 86400*($range + 1))),
		Range		=> $range,
    };

    my $xpc = $self->_request($parms);

    my @history;
    foreach my $node ( $xpc->findnodes("//TrafficHistory/HistoricalData/Data") ) {
        my $date = $xpc->findvalue( ".//Date",        $node );
        my $perm  = $xpc->findvalue( ".//PageViews/PerMillion", $node );
        my $peru  = $xpc->findvalue( ".//PageViews/PerUser", $node );
        push @history,
            {
			date		=> $date,
			rank		=> $xpc->findvalue(".//Rank", $node),
            viewspermillion	=>
				$xpc->findvalue(".//PageViews/PerMillion", $node),
            viewsperuser	=>
				$xpc->findvalue(".//PageViews/PerUser", $node),
            reachpermillion	=>
				$xpc->findvalue(".//Reach/PerMillion", $node),
            };
    }

	return @history;
}


sub _request {
    my ( $self, $parms ) = @_;

    #  sleep 1;

    $parms->{Service}        = 'AlexaWebInfoService';
    $parms->{AWSAccessKeyId} = $self->aws_access_key_id;
    $parms->{Timestamp}      = strftime '%Y-%m-%dT%H:%M:%S.000Z', gmtime;
    my $hmac = Digest::HMAC_SHA1->new( $self->secret_access_key );
    $hmac->add(
        $parms->{Service} . $parms->{Operation} . $parms->{Timestamp} );
    $parms->{Signature} = $hmac->b64digest . '=';

    my $url = 'http://awis.amazonaws.com/';

    my $uri = URI->new($url);
    $uri->query_param( $_, $parms->{$_} ) foreach keys %$parms;
    my $response = $self->ua->get("$uri");

    #warn $uri;
    #warn $response->as_string;

    die "Error fetching response: " . $response->status_line
        unless $response->is_success;

    my $xml = $response->content;
    $xml =~ s{<aws:}{<}g;      # hates-xml-namespaces
    $xml =~ s{</aws:}{</}g;    # hates-xml-namespaces
    my $doc = $self->libxml->parse_string($xml);

    my $xpc = XML::LibXML::XPathContext->new($doc);

    #warn $doc->toString(1);

    if ( $xpc->findnodes("//Error") ) {
        die $xpc->findvalue("//ErrorCode") . ": "
            . $xpc->findvalue("//ErrorMessage");
    }

    return $xpc;
}

1;

__END__

=head1 NAME

Net::Amazon::AWIS - Use the Amazon Alexa Web Information Service

=head1 SYNOPSIS

  use Net::Amazon::AWIS;
  my $awis = Net::Amazon::AWIS->new($subscription_id);
  my $data1= $awis->url_info(url => "http://use.perl.org/");
  my $data2 = $awis->web_map(url => "http://use.perl.org");
  my @results = $awis->crawl(url => "http://use.perl.org");

=head1 DESCRIPTION

The Net::Amazon::AWIS module allows you to use the Amazon
Alexa Web Information Service.

The Alexa Web Information Service (AWIS) provides developers with
programmatic access to the information Alexa Internet (www.alexa.com)
collects from its Web Crawl, which currently encompasses more than 100
terabytes of data from over 4 billion Web pages. Developers and Web
site owners can use AWIS as a platform for finding answers to
difficult and interesting problems on the Web, and incorporating them
into their Web applications.

In order to access the Alexa Web Information Service, you will need an
Amazon Web Services Subscription ID. See
http://www.amazon.com/gp/aws/landing.html

Registered developers have free access to the Alexa Web Information
Service during its beta period, but it is limited to 10,000
requests per subscription ID per day.

There are some limitations, so be sure to read the The Amazon Alexa
Web Information Service FAQ.

=head1 INTERFACE

The interface follows. Most of this documentation was copied from the
API reference. Upon errors, an exception is thrown.

=head2 new

The constructor method creates a new Net::Amazon::AWIS
object. You must pass in an Amazon Web Services Access Key ID
and a Secret Access Key. See
http://www.amazon.com/gp/aws/landing.html:

  my $sq = Net::Amazon::AWIS->new($aws_access_key_id, $secret_access_key);

=head2 url_info

The url_info method provides information about URLs. Examples of this
information includes data on how popular a site is, and sites that
are related.

You pass in a URL and get back a hash full of information. This
includes the Alexa three month average traffic rank for the given
site, the median load time and percent of known sites that are slower,
whether the site is likely to contain adult content, the content
language code and character-encoding, which dmoz.org categories the
site is in, and related sites:

  my $data = $awis->url_info(url => "http://use.perl.org/");
  print "Rank:       " . $data->{rank}                 . "\n";
  print "Load time:  " . $data->{median_load_time}     . "\n";
  print "%Load time: " . $data->{percentile_load_time} . "\n";
  print "Likely to contain adult content\n" if $data->{adult_content};
  print "Encoding:   " . $data->{encoding}             . "\n";
  print "Locale:     " . $data->{locale}               . "\n";

  foreach my $cat (@{$data->{categories}}) {
    my $path  = $cat->{path};
    my $title = $cat->{title};
    print "dmoz.org: $path / $title\n";
  }

  foreach my $related (@{$data->{related}}) {
    my $canonical  = $related->{canonical};
    my $url        = $related->{url};
    my $relevance  = $related->{relevance};
    my $title      = $related->{title};
    print "Related: $url / $title ($relevance)\n";
  }

=head2 web_map

The web_map method returns a list of web sites linking to a 
given web site. Within each domain linking into the web site, only 
a single link - the one with the highest page-level traffic - is 
returned. The data is updated once every two months.

  my $data = $awis->web_map(url => "http://use.perl.org");
  my @links_in  = $data->{links_in};

=head2 crawl

The crawl method returns information about a specific URL as provided by
the most recent Alexa Web Crawls. Information about the last few times
the site URL was crawled is returned. Crawl takes the URL and a count.

Information per crawl include: URL, IP address, date of the crawl (as
a DateTime object), status code, page length, content type and language.
In addition, a list of other URLs is included (like "rel" URLs), as is
the list of images and links found.

  my @results = $awis->crawl(url => "http://use.perl.org", count => 10);
  foreach my $result (@results) {
    print "URL: "          . $result->{url} . "\n";
    print "IP: "           . $result->{ip} . "\n";
    print "Date: "         . $result->{date} . "\n";
    print "Code: "         . $result->{code} . "\n";
    print "Length: "       . $result->{length} . "\n";
    print "Content type: " . $result->{content_type} . "\n";
    print "Language: "     . $result->{language} . "\n";

    foreach my $url (@{$result->{other_urls})) {
      print "Other URL: $url\n";
    }

    foreach my $images (@{$result->{images})) {
      print "Image: $image\n";
    }

    foreach my $link (@{$result->{links})) {
      my $name = $link->{name};
      my $uri  = $link->{uri};
      print "Link: $name -> $uri\n";
    }
  }

=head2 history

The history method returns the daily Alexa Traffic Rank, Reach per
Million Users, and Unique Page Views per Million Users for each day
since September 2001. This same data is used to produce the traffic
graphs found on alexa.com. History takes the URL, and optionally,
a start date and a count of days. The response contains an aws:Data
element for each day in the date range specified. Note that no data
will be returned for days when the daily Alexa traffic rank was
greater than 100,000.

  my @history = $awis->history(url => 'google.com', start => '20080731', days => 12);
  foreach my $day (@history) {
    print "Date: "            . $day->{date} . "\n";
    print "Rank: "            . $day->{rank} . "\n";
    print "ViewsPerMillion: " . $day->{viewspermillion} . "\n";
    print "ViewsPerUser: "    . $day->{viewsperuser} . "\n";
    print "ReachPerMillion: " . $day->{reachpermillion} . "\n";
  }

=head1 BUGS AND LIMITATIONS                                                     
                                                                                
This module currently does not support "Browse Category" searches.
                                                                                
Please report any bugs or feature requests to                                   
C<bug-Net-Amazon-AWIS@rt.cpan.org>, or through the web interface at                   
L<http://rt.cpan.org>.  

=head1 AUTHOR

Leon Brocard C<acme@astray.com>

Shevek C<shevek@cpan.org>

=head1 LICENCE AND COPYRIGHT                                                    
                                                                                
Copyright (c) 2005-8, Leon Brocard C<acme@astray.com>. All rights reserved.           

Copyright (c) 2008, Shevek C<shevek@cpan.org>. All rights reserved.           
                                                                                
This module is free software; you can redistribute it and/or                    
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

    BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
    FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
    OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
    PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
    EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
    ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
    YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
    NECESSARY SERVICING, REPAIR, OR CORRECTION.

    IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
    WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
    REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
    TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
    CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
    SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
    RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
    FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
    SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
    DAMAGES.

