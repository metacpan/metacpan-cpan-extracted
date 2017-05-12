package Net::Async::Webservice::DHL;
use Moo;
use Types::Standard qw(Str Bool Object Dict Num Optional ArrayRef HashRef Undef Optional);
use Types::URI qw(Uri);
use Types::DateTime
    DateTime => { -as => 'DateTimeT' },
    Format => { -as => 'DTFormat' };
use Net::Async::Webservice::DHL::Types qw(Address RouteType RegionCode CountryCode);
use Net::Async::Webservice::DHL::Exception;
use Type::Params qw(compile);
use Error::TypeTiny;
use Try::Tiny;
use List::AllUtils 'pairwise';
use HTTP::Request;
use XML::Compile::Cache;
use XML::Compile::Util 'type_of_node';
use XML::LibXML;
use Encode;
use namespace::autoclean;
use Future;
use DateTime;
use File::ShareDir 'dist_dir';
use 5.010;
our $VERSION = '1.2.2'; # VERSION

# ABSTRACT: DHL API client, non-blocking


my %base_urls = (
    live => 'https://xmlpi-ea.dhl.com/XMLShippingServlet',
    test => 'https://xmlpitest-ea.dhl.com/XMLShippingServlet',
);


has live_mode => (
    is => 'rw',
    isa => Bool,
    trigger => 1,
    default => sub { 0 },
);


has base_url => (
    is => 'lazy',
    isa => Str,
    clearer => '_clear_base_url',
);

sub _trigger_live_mode { ## no critic(ProhibitUnusedPrivateSubroutines)
    my ($self) = @_;

    $self->_clear_base_url;
}
sub _build_base_url { ## no critic(ProhibitUnusedPrivateSubroutines)
    my ($self) = @_;

    return $base_urls{$self->live_mode ? 'live' : 'test'};
}


has username => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has password => (
    is => 'ro',
    isa => Str,
    required => 1,
);


with 'Net::Async::Webservice::Common::WithUserAgent';

has _xml_cache => (
    is => 'lazy',
);

sub _build__xml_cache { ## no critic(ProhibitUnusedPrivateSubroutines)
    my ($self) = @_;

    my $dir = dist_dir('Net-Async-Webservice-DHL');
    my $c = XML::Compile::Cache->new(
        schema_dirs => [ $dir ],
        opts_rw => {
            elements_qualified => 'TOP',
        },
    );
    for my $f (qw(datatypes datatypes_global
                  DCT-req DCTRequestdatatypes
                  DCT-Response DCTResponsedatatypes
                  routing-global-req routing-global-res
                  routing-err-res err-res)) {
        $c->importDefinitions("$f.xsd");
    }
    $c->declare('WRITER' => '{http://www.dhl.com}DCTRequest');
    $c->declare('READER' => '{http://www.dhl.com}DCTResponse');

    $c->declare('WRITER' => '{http://www.dhl.com}RouteRequest');
    $c->declare('READER' => '{http://www.dhl.com}RouteResponse');
    $c->declare('READER' => '{http://www.dhl.com}RoutingErrorResponse');

    $c->declare('READER' => '{http://www.dhl.com}ErrorResponse');

    $c->compileAll;

    return $c;
}


with 'Net::Async::Webservice::Common::WithConfigFile';


sub _mr {
    if ($_[0]->{message_reference}) {
        return ( message_reference => $_[0]->{message_reference} );
    }
    return;
}

sub get_capability {
    state $argcheck = compile(
        Object,
        Dict[
            from => Address,
            to => Address,
            is_dutiable => Bool,
            currency_code => Str,
            shipment_value => Num,
            product_code => Optional[Str],
            date => Optional[DateTimeT->plus_coercions(DTFormat['ISO8601'])],
            message_reference => Optional[Str],
        ],
    );
    my ($self,$args) = $argcheck->(@_);

    $args->{date} = $args->{date}
        ? $args->{date}->clone->set_time_zone('UTC')
        : DateTime->now(time_zone => 'UTC');

    my $req = {
        From => $args->{from}->as_hash('capability'),
        To => $args->{to}->as_hash('capability'),
        BkgDetails => {
            PaymentCountryCode => $args->{to}->country_code,
            Date => $args->{date}->ymd,
            ReadyTime => 'PT' . $args->{date}->hour . 'H' . $args->{date}->minute . 'M',
            DimensionUnit => 'CM',
            WeightUnit => 'KG',
            IsDutiable => ($args->{is_dutiable} ? 'Y' : 'N'),
            NetworkTypeCode => 'AL',
            ( defined $args->{product_code} ? (
                QtdShp => {
                    GlobalProductCode => $args->{product_code},
                    QtdShpExChrg => {
                        SpecialServiceType => 'OSINFO',
                    },
                },
            ) : () ),
        },
        Dutiable => {
            DeclaredCurrency => $args->{currency_code},
            DeclaredValue => $args->{shipment_value},
        },
    };

    return $self->xml_request({
        data => $req,
        request_method => 'GetCapability',
        _mr($args),
    })->then(
        sub {
            my ($response) = @_;
            return Future->wrap($response);
        },
    );
}


sub route_request {
    state $argcheck = compile(
        Object,
        Dict[
            region_code => RegionCode,
            routing_type => RouteType,
            address => Address,
            origin_country_code => CountryCode,
            message_reference => Optional[Str],
        ],
    );
    my ($self,$args) = $argcheck->(@_);

    my $req = {
        RequestType => $args->{routing_type},
        RegionCode => $args->{region_code},
        OriginCountryCode => $args->{origin_country_code},
        %{$args->{address}->as_hash('route')},
        schemaVersion => '1.0',
    };

    return $self->xml_request({
        data => $req,
        request_method => 'RouteRequest',
        _mr($args),
    })->then(
        sub {
            my ($response) = @_;
            return Future->wrap($response);
        },
    );
}


my %request_type_map = (
    GetCapability => ['GetCapability','DCTRequest','DCTResponse'],
    RouteRequest => ['','RouteRequest','RouteResponse'],
);

sub xml_request {
    state $argcheck = compile(
        Object,
        Dict[
            data => HashRef,
            request_method => Str,
            message_time => Optional[DateTimeT->plus_coercions(DTFormat['ISO8601'])],
            message_reference => Optional[Str],
        ],
    );
    my ($self, $args) = $argcheck->(@_);

    my ($top_level_elemel,$req_type,$res_type) =
        @{ $request_type_map{$args->{request_method}} || [] };

    $args->{message_time} = $args->{message_time}
        ? $args->{message_time}->clone->set_time_zone('UTC')
        : DateTime->now(time_zone => 'UTC');

    my $doc = XML::LibXML::Document->new('1.0','utf-8');

    my $writer = $self->_xml_cache->writer("{http://www.dhl.com}$req_type");

    my $req = {
        Request => {
            ServiceHeader => {
                MessageTime => $args->{message_time}->iso8601,
                SiteID => $self->username,
                Password => $self->password,
                MessageReference => (sprintf '% 28s',($args->{message_reference} // time())),
            },
        },
        %{$args->{data}},
    };

    if ($top_level_elemel) {
        $req = { $top_level_elemel => $req };
    }

    my $docElem = $writer->($doc,$req);
    $doc->setDocumentElement($docElem);

    my $request = $doc->toString(1);

    return $self->post( $self->base_url, $request )->then(
        sub {
            my ($response_string) = @_;

            my $response_doc = XML::LibXML->load_xml(
                string=>\$response_string,
                load_ext_dtd => 0,
                expand_xincludes => 0,
                no_network => 1,
            );

            my $type = type_of_node $response_doc->documentElement;

            my $reader = $self->_xml_cache->reader($type);
            my $response = $reader->($response_doc);

            if ($response_doc->documentElement->nodeName =~ /Error/) {
                return Future->new->fail(
                    Net::Async::Webservice::DHL::Exception::DHLError->new({
                        error => $response->{Response}{Status}
                    }),
                    'dhl',
                );
            }
            else {
                return Future->wrap($response);
            }
        }
    );
}


with 'Net::Async::Webservice::Common::WithRequestWrapper';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL - DHL API client, non-blocking

=head1 VERSION

version 1.2.2

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::Webservice::DHL;
 use Data::Printer;

 my $loop = IO::Async::Loop->new;

 my $dhl = Net::Async::Webservice::DHL->new({
   config_file => $ENV{HOME}.'/.naws_dhl.conf',
   loop => $loop,
 });

 $dhl->get_capability({
   from => $address_a,
   to => $address_b,
   is_dutiable => 0,
   currency_code => 'GBP',
   shipment_value => 100,
 })->then(sub {
   my ($response) = @_;
   p $response;
   return Future->wrap();
 });

 $loop->run;

Alternatively:

 use Net::Async::Webservice::DHL;
 use Data::Printer;

 my $ups = Net::Async::Webservice::DHL->new({
   config_file => $ENV{HOME}.'/.naws_dhl.conf',
   user_agent => LWP::UserAgent->new,
 });

 my $response = $dhl->get_capability({
   from => $address_a,
   to => $address_b,
   is_dutiable => 0,
   currency_code => 'GBP',
   shipment_value => 100,
 })->get;

 p $response;

=head1 DESCRIPTION

This class implements some of the methods of the DHL XML-PI API, using
L<Net::Async::HTTP> as a user agent I<by default> (you can still pass
something like L<LWP::UserAgent> and it will work). All methods that
perform API calls return L<Future>s (if using a synchronous user
agent, all the Futures will be returned already completed).

=head1 ATTRIBUTES

=head2 C<live_mode>

Boolean, defaults to false. When set to true, the live API endpoint
will be used, otherwise the test one will. Flipping this attribute
will reset L</base_url>, so you generally don't want to touch this if
you're using some custom API endpoint.

=head2 C<base_url>

A L<URI> object, coercible from a string. The base URL to use to send
API requests to. Defaults to the standard DHL endpoints:

=over 4

=item *

C<https://xmlpi-ea.dhl.com/XMLShippingServlet> for live

=item *

C<https://xmlpitest-ea.dhl.com/XMLShippingServlet> for testing

=back

See also L</live_mode>.

=head2 C<username>

=head2 C<password>

Strings, required. Authentication credentials.

=head2 C<user_agent>

A user agent object, looking either like L<Net::Async::HTTP> (has
C<do_request> and C<POST>) or like L<LWP::UserAgent> (has C<request>
and C<post>). You can pass the C<loop> constructor parameter to get a
default L<Net::Async::HTTP> instance.

=head1 METHODS

=head2 C<new>

Async:

  my $dhl = Net::Async::Webservice::DHL->new({
     loop => $loop,
     config_file => $file_name,
  });

Sync:

  my $dhl = Net::Async::Webservice::DHL->new({
     user_agent => LWP::UserAgent->new,
     config_file => $file_name,
  });

In addition to passing all the various attributes values, you can use
a few shortcuts.

=over 4

=item C<loop>

a L<IO::Async::Loop>; a locally-constructed L<Net::Async::HTTP> will be registered to it and set as L</user_agent>

=item C<config_file>

a path name; will be parsed with L<Config::Any>, and the values used as if they had been passed in to the constructor

=back

=head2 C<get_capability>

 $dhl->get_capability({
   from => $address_a,
   to => $address_b,
   is_dutiable => 0,
   currency_code => 'GBP',
   shipment_value => 100,
 }) ==> ($hashref)

C<from> and C<to> are instances of
L<Net::Async::Webservice::DHL::Address>, C<is_dutiable> is a boolean.

Optional parameters:

=over 4

=item C<date>

the date/time for the booking, defaults to I<now>; it will converted to UTC time zone

=item C<product_code>

a DHL product code

=item C<message_reference>

a string, to uniquely identify individual messages

=back

Performs a C<GetCapability> request. Lots of values in the request are
not filled in, this should be used essentially to check for address
validity and little more. I'm not sure how to read the response,
either.

The L<Future> returned will yield a hashref containing the
"interesting" bits of the XML response (as judged by
L<XML::Compile::Schema>), or fail with an exception.

=head2 C<route_request>

 $dhl->route_request({
   region_code => $dhl_region_code,
   routing_type => 'O', # or 'D'
   address => $address,
   origin_country_code => $country_code,
 }) ==> ($hashref)

C<address> is an instance of L<Net::Async::Webservice::DHL::Address>.
C<type> is C<O> for origin routing, or C<D> for destination
routing. C<origin_country_code> is the "country code of origin"
according to the DHL spec.

Optional parameters:

=over 4

=item C<message_reference>

a string, to uniquely identify individual messages

=back

Performs a C<RouteRequest> request.

The L<Future> returned will yield a hashref containing the
"interesting" bits of the XML response (as judged by
L<XML::Compile::Schema>), or fail with an exception.

=head2 C<xml_request>

  $dhl->xml_request({
    request_method => $string,
    data => \%request_data,
  }) ==> ($parsed_response);

This method is mostly internal, you shouldn't need to call it.

It builds a request XML document by passing the given C<data> to an
L<XML::Compile> writer built on the DHL schema.

It then posts (possibly asynchronously) this to the L</base_url> (see
the L</post> method). If the request is successful, it parses the body
with a L<XML::Compile> reader, either the one for the response or the
one for C<ErrorResponse>, depending on the document element. If it's a
valid response, the Future is completed with the hashref returned by
the reader. If it's C<ErrorResponse>, teh Future is failed with a
L<Net::Async::Webservice::DHL::Exception::DHLError> contaning the
response status.

=head2 C<post>

  $dhl->post($body) ==> ($decoded_content)

Posts the given C<$body> to the L</base_url>. If the request is
successful, it completes the returned future with the decoded content
of the response, otherwise it fails the future with a
L<Net::Async::Webservice::Common::Exception::HTTPError> instance.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
