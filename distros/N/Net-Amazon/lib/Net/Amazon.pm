###################################################################
package Net::Amazon;
######################################################################
# Mike Schilli <m@perlmeister.com>, 2003
######################################################################

use 5.006;
use strict;
use warnings;

our $VERSION          = '0.62';
our $WSDL_DATE        = '2011-08-01';
our $Locale           = 'us';
our @CANNED_RESPONSES = ();
our $IS_CANNED        = 0;

use LWP::UserAgent;
use HTTP::Message;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;
use URI;
use Log::Log4perl qw(:easy get_logger);
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Digest::SHA qw(hmac_sha256_base64);
use URI::Escape qw(uri_escape);

# Each key represents a search() type, and each value indicates which
# Net::Amazon::Request:: class to use to handle it.
use constant SEARCH_TYPE_CLASS_MAP => {
    actor        => 'Actor',
    artist       => 'Artist',
    all          => 'All',
    author       => 'Author',
    asin         => 'ASIN',
    blended      => 'Blended',
    browsenode   => 'BrowseNode',
    director     => 'Director',
    ean          => 'EAN',
    exchange     => 'Exchange',
    isbn         => 'ISBN',
    keyword      => 'Keyword',
    manufacturer => 'Manufacturer',
    musiclabel   => 'MusicLabel',
    power        => 'Power',
    publisher    => 'Publisher',
    seller       => 'Seller',
    similar      => 'Similar',
    textstream   => 'TextStream',
    title        => 'Title',
    upc          => 'UPC',
};

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    if(! exists $options{token}) {
        die "Mandatory paramter 'token' not defined";
    }

    if(! exists $options{secret_key}) {
        die "Mandatory paramter 'secret_key' not defined";
    }

    if(! exists $options{associate_tag}) {
        die "Mandatory paramter 'associate_tag' not defined";
    }

    my $self = {
        strict         => 1,
        response_dump  => 0,
        rate_limit     => 1.0,  # 1 req/sec
        max_pages      => 5,
        ua             => LWP::UserAgent->new(),
        compress       => 1,
        %options,
    };

    # XXX: this has to be set as soon as possible to ensure
    # the validators pick up the correct locale.  I don't
    # like the way this works, and need to think of a better
    # solution.
    if (exists $self->{locale}) {
        $Net::Amazon::Locale = $self->{locale};
    }

    help_xml_simple_choose_a_parser();

    bless $self, $class;
}

##################################################
sub search {
##################################################
    my($self, %params) = @_;

    foreach my $key ( keys %params ) {
        next unless ( my $class = SEARCH_TYPE_CLASS_MAP->{$key} );
        
        return $self->_make_request($class, \%params);
    }

    # FIX?
    # This seems like it really should be a die() instead...this is
    # indicative of a programming problem. Generally speaking, it's
    # best to issue warnings from a module--you can't be sure that the
    # client has a stderr to begin with, or that he wants errors
    # spewed to it.
    warn "No Net::Amazon::Request type could be determined";

    return undef;
}

##################################################
sub intl_url {
##################################################
    my($self, $url) = @_;

    if(! exists $self->{locale}) {
        return $url;
    }

    if (0) {
    } elsif ($self->{locale} eq "ca") {
        $url =~ s/\.com/.ca/;
    } elsif ($self->{locale} eq "de") {
        $url =~ s/\.com/.de/;
    } elsif ($self->{locale} eq "es") {
        $url =~ s/\.com/.es/;
    } elsif ($self->{locale} eq "fr") {
        $url =~ s/\.com/.fr/;
    } elsif ($self->{locale} eq "jp") {
        $url =~ s/\.com/.co.jp/;
    } elsif ($self->{locale} eq "it") {
        $url =~ s/\.com/.it/;
    } elsif ($self->{locale} eq "uk") {
        $url =~ s/\.com/.co.uk/;
    }

    return $url;
}

##################################################
sub request {
##################################################
    my($self, $request) = @_;

    my $resp_class = $request->response_class();

    eval "require $resp_class;" or 
        die "Cannot find '$resp_class'";

    my $res  = $resp_class->new();

    my $url  = URI->new($self->intl_url($request->amzn_xml_url()));
    my $page = (defined $request->page()) ?
	($request->page() - 1) * $self->{max_pages} + 1 :
	0;
    my $ref;
    my $max_pages_in_this_search = $self->{max_pages} + $page - 1;

    REQUEST: {
        my %params = $request->params(page => $page);
        $params{locale} = $self->{locale} if exists $self->{locale};

        $url->query_form(
            'Service'        => 'AWSECommerceService',
            'AWSAccessKeyId' => $self->{token},
            'Version'        => $WSDL_DATE,
            'AssociateTag'   => $self->{associate_tag},
            map { $_, $params{$_} } sort keys %params,
        );
	
        # Signed requests will have different URLs, which breaks caching.
        # Get a cachable URL before signing the request.
        my $url_cachablestr = $url->as_string;

        # New signature for >=2009-03-31. Do not alter URL after this!
        $url = $self->_sign_request($url) if exists $self->{secret_key};

        DEBUG(sub { "request: params = " . Dumper(\%params) . "\n"});

        my $urlstr = $url->as_string;

        DEBUG(sub { "urlstr=" . $urlstr });

        my $xml = fetch_url($self, $urlstr, $url_cachablestr, $res);

        if(!defined $xml) {
            return $res;
        }

        DEBUG(sub { "Received [ " . $xml . "]" });

        # Let the response class parse the XML
        $ref = $res->xml_parse($xml);

        # DEBUG(sub { Data::Dumper::Dumper($ref) });

        if(! defined $ref) {
            ERROR("Invalid XML");
            $res->messages( [ "Invalid XML" ]);
            $res->status("");
            return $res;
        }

        $res->current_page($ref, $page);
        $res->set_total_results($ref);
        
        my $rc = $res->is_page_error($ref);
        if ($rc == 0) {
            return $res;
        } elsif ($rc == -1) {
            last;
        }

        my $new_items = $res->xmlref_add($ref);

        DEBUG("Received valid XML ($new_items items)");

        # Stop if we've fetched max_pages already
        if(defined $page && $max_pages_in_this_search <= $page) {
            DEBUG("Fetched max_pages ($max_pages_in_this_search) -- stopping");
            last;
        }

        if($res->is_page_available($ref, $new_items, $page)) {
            $page++;
            redo REQUEST;
        }

        # We're gonna fall out of this loop here.
    }

    $res->status(1);
    # We have a valid response, so if TotalResults isn't set, 
    # we most likely have a single response
    $res->total_results(1) unless defined $res->total_results();
    return $res;
}

##################################################
sub fetch_url {
##################################################
    my($self, $url, $url_cachablestr, $res) = @_;

    my $max_retries = 2;

    INFO("Fetching $url");

    if(@CANNED_RESPONSES) {
        $IS_CANNED = 1;
        INFO("Serving canned response (testing)");
        return shift @CANNED_RESPONSES;
    }

    if(exists $self->{cache}) {
        my $resp = $self->{cache}->get($url_cachablestr);
        if(defined $resp) {
            INFO("Serving from cache");
            return $resp;
        }

        INFO("Cache miss");
    }

    my $ua = $self->{ua};
    $ua->env_proxy();

    my $resp;

    {
        # wait up to a second before the next request so
        # as to not violate Amazon's 1 query per second
        # rule (or the configured rate_limit).
        $self->pause() if $self->{strict};

        {
            my $req = GET $url;

            $req->header("Accept-Encoding" => [ HTTP::Message::decodable() ])
                if $self->{compress};

            $resp = $ua->request($req);
        }

        $self->reset_timer() if $self->{strict};

        if($resp->is_error) {
            # retry on 503 Service Unavailable errors
            if ($resp->code == 503) {
                if ($max_retries-- >= 0) {
                    INFO("Temporary Amazon error 503, retrying");
                    redo;
                } else {
                    INFO("Out of retries, giving up");
                    $res->status("");
                    $res->messages( [ "Too many temporary Amazon errors" ] );
                    return undef;
                }
            } else {
                $res->status("");
                $res->messages( [ $resp->message ] );
                return undef;
            }
        }

        if($self->{response_dump}) {
            my $dumpfile = "response-$self->{response_dump}.txt";
            open FILE, ">$dumpfile" or die "Cannot open $dumpfile";
            print FILE $resp->decoded_content();
            close FILE;
            $self->{response_dump}++;
        }

        if($resp->decoded_content =~ /<Errors>/ &&
            # Is this the same value of AWS4?
           $resp->decoded_content =~ /Please retry/i) {
            if($max_retries-- >= 0) {
                INFO("Temporary Amazon error, retrying");
                redo;
            } else {
                INFO("Out of retries, giving up");
                $res->status("");
                $res->messages( [ "Too many temporary Amazon errors" ] );
                return undef;
            }
        }
    }

    if(exists $self->{cache}) {
        $self->{cache}->set($url_cachablestr, $resp->decoded_content());
    }

    return $resp->decoded_content();
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;

            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

# An accessor for backward compatability with AWS3.
##################################################
sub make_compatible_accessor{
##################################################
    my($package, $old_name, $new_name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$old_name"} = sub {
            my(\$self, \$value) = \@_;

            if(defined \$value) {
                \$self->{$new_name} = \$value;
            }
            if(exists \$self->{$new_name}) {
                return (\$self->{$new_name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$old_name"}) {
        eval $code or die "$@";
    }
}

##################################################
# Make accessors for arrays
##################################################
sub make_array_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$nameref) = \@_;
            if(defined \$nameref) {
                if(ref \$nameref eq "ARRAY") {
                    \$self->{$name} = \$nameref;
                } else {
                    \$self->{$name} = [\$nameref];
                }
            }
               # Return a list
            if(exists \$self->{$name} and
               ref \$self->{$name} eq "ARRAY") {
                return \@{\$self->{$name}};
            }

            return undef;
        }
EOT

    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

##################################################
sub walk_hash_ref {
##################################################
    my ($package, $href, $aref) = @_;

    return $href if scalar(@$aref) == 0;

    my @a;
    push @a, $_ for @$aref;

    my $tail = pop @a;
    my $ref = $href;

    for my $part (@a) {
        $ref = $ref->{$part};
    }
    
    return $ref->{$tail};
}


##################################################
sub artist {
##################################################
    my($self, $nameref) = @_;

    # Only return the first artist
    return ($self->artists($nameref))[0];
}

##################################################
sub version {
##################################################
    my($self) = @_;
    return $self->{Version};
}

##################################################
sub current_page {
##################################################
    my($self, $ref, $page) = @_;
    if(exists $ref->{Items}->{TotalPages}) {
        INFO("Page $page/$ref->{Items}->{TotalPages}");
    }
}

##################################################
sub set_total_results {
##################################################
    my($self, $ref) = @_;
    if(exists $ref->{Items}->{TotalResults}) {
        $self->total_results( $ref->{Items}->{TotalResults} );
    }
}

##################################################
sub is_page_error {
##################################################
    my($self, $ref) = @_;

    if(exists $ref->{Items}->{Request}->{Errors}) {
        my $errref = $ref->{Items}->{Request}->{Errors};

        if (ref($errref->{Error}) eq "ARRAY") {
            my @errors;
            for my $e (@{$errref->{Error}}) {
                push @errors, $e->{Message};
            }
            # multiple errors, set arrary ref
            $self->messages( \@errors );
        } else {
            # single error, create array
            $self->messages( [ $errref->{Error}->{Message} ] );
        }

        ERROR("Fetch Error: " . $self->message );
        $self->status("");
        return 0;
    }
    return 1;
}

##################################################
sub is_page_available {
##################################################
    my($self, $ref, $new_items, $page) = @_;
    if(exists $ref->{Items}->{TotalPages} and
              $ref->{Items}->{TotalPages} > $page and 
              $IS_CANNED ne 1) {
        DEBUG("Page $page of $ref->{Items}->{TotalPages} fetched - continuing");
        return 1;
    }
    return 0;
}

##################################################
sub xmlref_add {
##################################################
    my($self, $xmlref) = @_;

    my $nof_items_added = 0;
    return $nof_items_added unless defined $xmlref;

    # Push a nested hash structure, retrieved via XMLSimple, onto the
    # object's internal 'xmlref' entry, which holds a ref to an array, 
    # whichs elements are refs to hashes holding an item's attributes
    # (like OurPrice etc.)

    #DEBUG("xmlref_add ", Data::Dumper::Dumper($xmlref));

    unless(ref($self->{xmlref}) eq "HASH" &&
           ref($self->{xmlref}->{Items}) eq "ARRAY") {
        $self->{xmlref}->{Items} = [];
    }

    if(ref($xmlref->{Items}->{Item}) eq "ARRAY") {
        push @{$self->{xmlref}->{Items}}, @{$xmlref->{Items}->{Item}};
        $nof_items_added = scalar @{$xmlref->{Items}->{Item}};
    } else {
        if (exists $xmlref->{Items}->{Item}->{ItemAttributes}) {
            push @{$self->{xmlref}->{Items}}, $xmlref->{Items}->{Item};
            $nof_items_added = 1;
        }
    }

    DEBUG("xmlref_add (after):", Data::Dumper::Dumper($self));
    return $nof_items_added;
}

##################################################
sub help_xml_simple_choose_a_parser {
##################################################
    
    eval "require XML::Parser";
    unless($@) {
        $XML::Simple::PREFERRED_PARSER = "XML::Parser";
        return;
    }

    eval "require XML::SAX::PurePerl";
    unless($@) {
        $XML::Simple::PREFERRED_PARSER = "XML::SAX::PurePerl";
        return;
    }
}

##################################################
# This timer makes sure we don't query Amazon more
# than once a second.
##################################################
sub reset_timer {
##################################################

    my $self = shift;
    $self->{t0} = [gettimeofday];
}

##################################################
# Pause for up to a second if necessary.
##################################################
sub pause {
##################################################

    my $self = shift;
    return unless ($self->{t0});

    my $t1 = [gettimeofday];
    my $dur = (1.0/$self->{rate_limit} - 
               tv_interval($self->{t0}, $t1)) * 1000000;
    if($dur > 0) {
            # Use a pseudo subclass for the logger, since the app
            # might not want to log that as 'ERROR'. Log4perl's
            # inheritance mechanism makes sure it does the right
            # thing for the current class.
        my $logger = get_logger(__PACKAGE__ . "::RateLimit");
        $logger->error("Ratelimiting: Sleeping $dur microseconds"); 
        usleep($dur);
    }
}

##
## 'PRIVATE' METHODS
##

# $self->_make_request( TYPE, PARAMS )
#
# Takes a TYPE that corresponds to a Net::Amazon::Request
# class, require()s that class, instantiates it, and returns
# the result of that instance's request() method.
#
sub _make_request {
    my ($self, $type, $params) = @_;

    my $class = "Net::Amazon::Request::$type";

	# XXX: change me back, this makes debugging a little difficult.
    eval "require $class";

    my $req = $class->new(%{$params});
    
    return $self->request($req);
}

# $self->_sign_request( URI )
#
# Takes a URI object that corresponds to a Net::Amazon::Request
# adds the required Timestamp and Signature parameters, and returns it
# See http://docs.amazonwebservices.com/AWSECommerceService/2009-03-31/DG/Query_QueryAuth.html
sub _sign_request {
    my ($self,$uri) = @_;
    return $uri unless exists $self->{secret_key};
    # This assumes no duplicated keys. Safe assumption?
    my %query = $uri->query_form;
    my @now = gmtime;
    $query{Timestamp} ||= sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ',$now[5]+1900,$now[4]+1,@now[3,2,1,0]);
    my $qstring = join '&', map {"$_=". uri_escape($query{$_},"^A-Za-z0-9\-_.~")} sort keys %query;
    # Use chr(10), not "\n" which varies by platform
    my $signme = join chr(10),"GET",$uri->host,$uri->path,$qstring;
    my $sig = hmac_sha256_base64($signme, $self->{secret_key});
    # Digest does not properly pad b64 strings
    $sig .= '=' while length($sig) % 4;
    $sig = uri_escape($sig,"^A-Za-z0-9\-_.~");
    $qstring .= "&Signature=$sig";
    $uri->query( $qstring );
    return $uri;
}

1;

__END__

=head1 NAME

Net::Amazon - Framework for accessing amazon.com via REST

=head1 SYNOPSIS

  use Net::Amazon;

  my $ua = Net::Amazon->new(
        associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
	token         => 'YOUR_AMZN_TOKEN',
	secret_key    => 'YOUR_AMZN_SECRET_KEY');

    # Get a request object
  my $response = $ua->search(asin => '0201360683');

  if($response->is_success()) {
      print $response->as_string(), "\n";
  } else {
      print "Error: ", $response->message(), "\n";
  }

=head1 ABSTRACT

  Net::Amazon provides an object-oriented interface to amazon.com's
  REST interface. This way it's possible to create applications
  using Amazon's vast amount of data via a functional interface, without
  having to worry about the underlying communication mechanism.

=head1 DESCRIPTION

C<Net::Amazon> works very much like C<LWP>: First you define a useragent
like

  my $ua = Net::Amazon->new(
      associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
      token         => 'YOUR_AMZN_TOKEN',
      secret_key    => 'YOUR_AMZN_SECRET_KEY',
      max_pages     => 3,
  );

which you pass your personal amazon developer's token (can be obtained
from L<http://amazon.com/soap>) and (optionally) the maximum number of 
result pages the agent is going to request from Amazon in case all
results don't fit on a single page (typically holding 20 items).  Note that
each new page requires a minimum delay of 1 second to comply with Amazon's
one-query-per-second policy.

According to the different search methods on Amazon, there's a bunch
of different request types in C<Net::Amazon>. The user agent's 
convenience method C<search()> triggers different request objects, 
depending on which parameters you pass to it:

=over 4

=item C<< $ua->search(asin => "0201360683") >>

The C<asin> parameter has Net::Amazon search for an item with the 
specified ASIN. If the specified value is an arrayref instead of a single
scalar, like in

    $ua->search(asin => ["0201360683", "0596005083"]) 

then a search for multiple ASINs is performed, returning a list of 
results.

=item C<< $ua->search(actor => "Adam Sandler") >>

The C<actor> parameter has the user agent search for items created by
the specified actor. Can return many results.

=item C<< $ua->search(artist => "Rolling Stones") >>

The C<artist> parameter has the user agent search for items created by
the specified artist. Can return many results.

=item C<< $ua->search(author => "Robert Jordan") >>

The C<author> parameter has the user agent search for items created by
the specified author. Can return many results.

=item C<< $ua->search(browsenode=>"4025", mode=>"books" [, keywords=>"perl"]) >>

Returns a list of items by category ID (node). For example node "4025"
is the CGI books category.  You can add a keywords parameter to filter 
the results by that keyword.

=item C<< $ua->search(exchange => 'Y04Y3424291Y2398445') >>

Returns an item offered by a third-party seller. The item is referenced
by the so-called I<exchange ID>.

=item C<< $ua->search(keyword => "perl xml", mode => "books") >>

Search by keyword, mandatory parameters C<keyword> and C<mode>.
Can return many results.

DETAILS
        Net::Amazon is based on Amazon Web Services version 4, and uses
        WSDL version 2011-08-01.

=head1 CACHING

Responses returned by Amazon's web service can be cached locally.
C<Net::Amazon>'s C<new> method accepts a reference to a C<Cache>
object. C<Cache> (or one of its companions like C<Cache::Memory>,
C<Cache::File>, etc.) can be downloaded from CPAN, please check their
documentation for details. In fact, any other type of cache
implementation will do as well, see the requirements below.

Here's an example utilizing a file cache which causes C<Net::Amazon> to
cache responses for 30 minutes:

    use Cache::File;

    my $cache = Cache::File->new( 
        cache_root        => '/tmp/mycache',
        default_expires   => '30 min',
    );

    my $ua = Net::Amazon->new(
        token       => 'YOUR_AMZN_TOKEN',
        secret_key  => 'YOUR_AMZN_SECRET_KEY',
        cache       => $cache,
    );

C<Net::Amazon> uses I<positive> caching only, errors won't be cached. 
Erroneous requests will be sent to Amazon every time. Positive cache 
entries are keyed by the full URL used internally by requests submitted 
to Amazon.

Caching isn't limited to the C<Cache> class. Any cache object which
adheres to the following interface can be used:

        # Set a cache value
    $cache->set($key, $value);

        # Return a cached value, 'undef' if it doesn't exist
    $cache->get($key);

=head1 COMPRESSION

By default C<Net::Amazon> will attempt to use HTTP compression if the 
L<Compress::Zlib> module is available. Pass C<< compress => 0 >> to 
C<< ->new() >> to disable this feature.

=head1 PROXY SETTINGS

C<Net::Amazon> uses C<LWP::UserAgent> under the hood to send
web requests to Amazon's web site. If you're in an environment where
all Web traffic goes through a proxy, there's two ways to configure that.

First, C<Net::Amazon> picks up proxy settings from environment variables:

    export http_proxy=http://proxy.my.place:8080

in the surrounding shell or setting

    $ENV{http_proxy} = "http://proxy.my.place:8080";

in your Perl script
will route all requests through the specified proxy.

Secondly, you can
pass a user agent instance to Net::Amazon's constructor:

    use Net::Amazon;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    my $na = Net::Amazon->new(
	ua            => $ua, 
        associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
	token         => 'YOUR_AMZN_TOKEN',
        secret_key    => 'YOUR_AMZN_SECRET_KEY',
    );
    # ...

This way, you can configure C<$ua> up front before Net::Amazon will use it.

=head1 DEBUGGING

If something's going wrong and you want more verbosity, just bump up
C<Net::Amazon>'s logging level. C<Net::Amazon> comes with C<Log::Log4perl>
statements embedded, which are disabled by default. However, if you initialize 
C<Log::Log4perl>, e.g. like

    use Net::Amazon;
    use Log::Log4perl qw(:easy);

    Log::Log4perl->easy_init($DEBUG);
    my Net::Amazon->new();
    # ...

you'll see what's going on behind the scenes, what URLs the module 
is requesting from Amazon and so forth. Log::Log4perl allows all kinds
of fancy stuff, like writing to a file or enabling verbosity in certain
parts only -- check http://log4perl.sourceforge.net for details.

=head1 LIVE TESTING

Results returned by Amazon can be incomplete or simply wrong at times,
due to their "best effort" design of the service. This is why the test
suite that comes with this module has been changed to perform its test
cases against canned data. If you want to perform the tests against
the live Amazon servers instead, just set the environment variable

    NET_AMAZON_LIVE_TESTS=1

=head1 WHY ISN'T THERE SUPPORT FOR METHOD XYZ?

Because nobody wrote it yet. If Net::Amazon doesn't yet support a method
advertised on Amazon's web service, you could help us out. Net::Amazon
has been designed to be expanded over time, usually it only takes a couple
of lines to support a new method, the rest is done via inheritance within
Net::Amazon.

Here's the basic plot:

=over 4

=item *

Get Net::Amazon from CVS. Use

        # (Just hit enter when prompted for a password)
    cvs -d:pserver:anonymous@cvs.net-amazon.sourceforge.net:/cvsroot/net-amazon login
    cvs -z3 -d:pserver:anonymous@cvs.net-amazon.sourceforge.net:/cvsroot/net-amazon co Net-Amazon

If this doesn't work, just use the latest distribution from 
net-amazon.sourceforge.net.

=item *

Write a new Net::Amazon::Request::XYZ package, start with this template

    ######################################
    package Net::Amazon::Request::XYZ;
    ######################################
    use base qw(Net::Amazon::Request);

    ######################################
    sub new {
    ######################################
        my($class, %options) = @_;

        if(!exists $options{XYZ_option}) {
            die "Mandatory parameter 'XYZ_option' not defined";
        }

        my $self = $class->SUPER::new(%options);

        bless $self, $class;   # reconsecrate
    }

and add documentation. Then, create a new Net::Amazon::Response::XYZ module:

    ##############################
    package Net::Amazon::Response;
    ##############################
    use base qw(Net::Amazon::Response);

    use Net::Amazon::Property;

    ##############################
    sub new {
    ##############################
        my($class, %options) = @_;

        my $self = $class->SUPER::new(%options);

        bless $self, $class;   # reconsecrate
    }

and also add documentation to it. Then, add the line

    use Net::Amazon::Request::XYZ;

to Net/Amazon.pm.

=back

And that's it! Again, don't forget the I<add documentation> part. Modules
without documentation are of no use to anybody but yourself. 

Check out the different Net::Amazon::Request::*
and Net::Amazon::Response modules in the distribution if you need to adapt
your new module to fulfil any special needs, like a different Amazon URL
or a different way to handle the as_string() method. Also, post
and problems you might encounter to the mailing list, we're gonna help you
out.

If possible, provide a test case for your extension. When finished, send 
a patch to the mailing list at 

   net-amazon-devel@lists.sourceforge.net

and if it works, I'll accept it and will work it into the main distribution.
Your name will show up in the contributor's list below (unless you tell
me otherwise).

=head2 SAMPLE SCRIPTS

There's a number of useful scripts in the distribution's eg/ directory.
Take C<power> for example, written by Martin Streicher 
E<lt>martin.streicher@apress.comE<gt>: I lets you perform 
a I<power search> using Amazon's query language. To search for all books 
written by Randal Schwartz about Perl, call this from the command line:

    power 'author: schwartz subject: perl'

Note that you need to quote the query string to pass it as one argument
to C<power>. If a power search returns more results than you want to
process at a time, just limit the number of pages, telling C<power>
which page to start at (C<-s>) and which one to finish with (C<-f>).
Here's a search for all books on the subject C<computer>, limited
to the first 10 pages:

    power -s 1 -f 10 'subject: computer'

Check out the script C<power> in eg/ for more options.

=head2 HOW TO SEND ME PATCHES

If you want me to include your modification or enhancement 
in the distribution of Net::Amazon, please do the following:

=over 4

=item *

Work off the latest CVS version. Here's the steps to get it:

    CVSROOT=:pserver:anonymous@cvs.net-amazon.sourceforge.net:/cvsroot/net-amazon
    export CVSROOT
    cvs login (just hit Enter)
    cvs co Net-Amazon

This will create a new C<Net-Amazon> directory with the latest 
development version of C<Net::Amazon> on your local machine.

=item *

Apply your changes to this development tree.

=item *

Run a diff between the tree and your changes it in this way:

    cd Net-Amazon
    cvs diff -Nau >patch_to_christopher.txt

=item *

Email me C<patch_to_christopher.txt>. If your patch works (and you've included
test cases and documentation), I'll apply it on the spot.

=back

=head1 INSTALLATION

C<Net::Amazon> depends on Log::Log4perl, which can be pulled from CPAN by
simply saying

    perl -MCPAN -eshell 'install Log::Log4perl'

Also, it needs LWP::UserAgent and XML::Simple 2.x, which can be obtained 
in a similar way.

Once all dependencies have been resolved, C<Net::Amazon> installs with
the typical sequence

    perl Makefile.PL
    make
    make test
    make install

Make sure you're connected to the Internet while running C<make test>
because it will actually contact amazon.com and run a couple of live tests.

The module's distribution tarball and documentation are available at

    http://perlmeister.com/devel/#amzn 

and on CPAN.

=head1 SEE ALSO

The following modules play well within the C<Net::Amazon> framework:

=over 4

=item C<Net::Amazon::RemoteCart>

by David Emery E<lt>dave@skiddlydee.comE<gt> provides a complete API for
creating Amazon shopping carts on a local site, managing them and finally 
submitting them to Amazon for checkout. It is available on CPAN.

=back

=head1 CONTACT

The C<Net::Amazon> project's home page is hosted on 

    http://net-amazon.sourceforge.net

where you can find documentation, news and the latest development and
stable releases for download. If you have questions about how to
use C<Net::Amazon>, want to report a bug or just participate in its
development, please send a message to the mailing 
list net-amazon-devel@lists.sourceforge.net

The source code has moved from sourceforge.net to github.com.  The git URL is

    git://github.com/boumenot/p5-Net-Amazon.git

The hope is that github.com makes collaboration much easier, and git is 
a much more modern SCM tool.

=head1 AUTHOR

Mike Schilli, E<lt>na@perlmeister.comE<gt> (Please contact me via the mailing list: net-amazon-devel@lists.sourceforge.net )

Maintainers: Christopher Boumenot, E<lt>boumenot+na@gmail.comE<gt>

Contributors (thanks y'all!):

    Andy Grundman <andy@hybridized.org>
    Barnaby Claydon <bclaydon@perseus.com>
    Batara Kesuma <bkesuma@gaijinweb.com>
    Bill Fitzpatrick
    Brian <brianbrian@gmail.com>
    Brian Hirt <bhirt@mobygames.com>
    Dan Kreft <dan@kreft.net>
    Dan Sully <daniel@electricrain.com>
    Dave Cardwell <http://davecardwell.co.uk/>
    Jackie Hamilton <kira@cgi101.com>
    Konstantin Gredeskoul <kig@get.topica.com>
    Lance Cleveland <lancec@proactivewm.com>
    Martha Greenberg <marthag@mit.edu>
    Martin Streicher <martin.streicher@apress.com>
    Mike Evron <evronm@dtcinc.net>
    Padraic Renaghan <padraic@renaghan.com>
    rayg <rayg@varchars.com>
    Robert Graff <rgraff@workingdemo.com>
    Robert Rothenberg <wlkngowl@i-2000.com>
    Steve Rushe <steve@deeden.co.uk>
    Tatsuhiko Miyagawa <miyagawa@livedoor.jp>
    Tony Bowden <tony@kasei.com>
    Vince Veselosky

=head1 COPYRIGHT AND LICENSE

Copyright 2003, 2004 by Mike Schilli E<lt>na@perlmeister.comE<gt>
Copyright 2007-2009 by Christopher Boumenot E<lt>boumenot+na@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
