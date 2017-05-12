package Net::Async::Webservice::UPS;
$Net::Async::Webservice::UPS::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use XML::Simple;
use Types::Standard 1.000003 qw(Str Int Bool Object Dict Optional ArrayRef HashRef Undef);
use Types::URI qw(Uri);
use Type::Params qw(compile);
use Error::TypeTiny;
use Net::Async::Webservice::UPS::Types qw(:types to_Service);
use Net::Async::Webservice::UPS::Exception;
use Try::Tiny;
use List::AllUtils 'pairwise';
use HTTP::Request;
use Encode;
use namespace::autoclean;
use Net::Async::Webservice::UPS::Rate;
use Net::Async::Webservice::UPS::Address;
use Net::Async::Webservice::UPS::Service;
use Net::Async::Webservice::UPS::Response::Rate;
use Net::Async::Webservice::UPS::Response::Address;
use Net::Async::Webservice::UPS::Response::ShipmentConfirm;
use Net::Async::Webservice::UPS::Response::ShipmentAccept;
use Net::Async::Webservice::UPS::Response::QV;
use MIME::Base64;
use Future;
use 5.010;

# ABSTRACT: UPS API client, non-blocking


my %code_for_pickup_type = (
    DAILY_PICKUP            => '01',
    DAILY                   => '01',
    CUSTOMER_COUNTER        => '03',
    ONE_TIME_PICKUP         => '06',
    ONE_TIME                => '06',
    ON_CALL_AIR             => '07',
    SUGGESTED_RETAIL        => '11',
    SUGGESTED_RETAIL_RATES  => '11',
    LETTER_CENTER           => '19',
    AIR_SERVICE_CENTER      => '20'
);

my %code_for_customer_classification = (
    WHOLESALE               => '01',
    OCCASIONAL              => '03',
    RETAIL                  => '04'
);

my %base_urls = (
    live => 'https://onlinetools.ups.com/ups.app/xml',
    test => 'https://wwwcie.ups.com/ups.app/xml',
);


has live_mode => (
    is => 'rw',
    isa => Bool,
    trigger => 1,
    default => sub { 0 },
);


has base_url => (
    is => 'lazy',
    isa => Uri,
    clearer => '_clear_base_url',
    coerce => Uri->coercion,
);

sub _trigger_live_mode {
    my ($self) = @_;

    $self->_clear_base_url;
}
sub _build_base_url {
    my ($self) = @_;

    return $base_urls{$self->live_mode ? 'live' : 'test'};
}


has user_id => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has password => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has access_key => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has account_number => (
    is => 'ro',
    isa => Str,
);


has customer_classification => (
    is => 'rw',
    isa => CustomerClassification,
);


has pickup_type => (
    is => 'rw',
    isa => PickupType,
    default => sub { 'ONE_TIME' },
);


has cache => (
    is => 'ro',
    isa => Cache|Undef,
);


sub does_caching {
    my ($self) = @_;
    return defined $self->cache;
}


sub _build_ssl_options {
    eval "require IO::Socket::SSL; require IO::Socket::SSL::Utils; require Mozilla::CA;"
        or return {};

    my $cert = IO::Socket::SSL::Utils::PEM_string2cert(<<'PEM');
-----BEGIN CERTIFICATE-----
MIICPDCCAaUCEHC65B0Q2Sk0tjjKewPMur8wDQYJKoZIhvcNAQECBQAwXzELMAkGA1UEBhMCVVMx
FzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMTcwNQYDVQQLEy5DbGFzcyAzIFB1YmxpYyBQcmltYXJ5
IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTk2MDEyOTAwMDAwMFoXDTI4MDgwMTIzNTk1OVow
XzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMTcwNQYDVQQLEy5DbGFzcyAz
IFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIGfMA0GCSqGSIb3DQEBAQUA
A4GNADCBiQKBgQDJXFme8huKARS0EN8EQNvjV69qRUCPhAwL0TPZ2RHP7gJYHyX3KqhEBarsAx94
f56TuZoAqiN91qyFomNFx3InzPRMxnVx0jnvT0Lwdd8KkMaOIG+YD/isI19wKTakyYbnsZogy1Ol
hec9vn2a/iRFM9x2Fe0PonFkTGUugWhFpwIDAQABMA0GCSqGSIb3DQEBAgUAA4GBALtMEivPLCYA
TxQT3ab7/AoRhIzzKBxnki98tsX63/Dolbwdj2wsqFHMc9ikwFPwTtYmwHYBV4GSXiHx0bH/59Ah
WM1pF+NEHJwZRDmJXNycAA9WjQKZ7aKQRUzkuxCkPfAyAw7xzvjoyVGM5mKf5p/AfbdynMk2Omuf
Tqj/ZA1k
-----END CERTIFICATE-----
PEM
    return {
        SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
        SSL_ca => [ $cert ],
        SSL_ca_file => Mozilla::CA::SSL_ca_file(),
    };
}


with 'Net::Async::Webservice::Common::WithUserAgent';
with 'Net::Async::Webservice::Common::WithConfigFile';

around BUILDARGS => sub {
    my ($orig,$class,@args) = @_;

    my $ret = $class->$orig(@args);

    if ($ret->{cache_life}) {
        require CHI;
        if (not $ret->{cache_root}) {
            require File::Spec;
            $ret->{cache_root} =
                File::Spec->catdir(File::Spec->tmpdir,'naws_ups'),
              }
        $ret->{cache} = CHI->new(
            driver => 'File',
            root_dir => $ret->{cache_root},
            depth => 5,
            expires_in => $ret->{cache_life} . ' min',
        );
    }

    return $ret;
};


sub transaction_reference {
    my ($self,$args) = @_;
    no warnings 'once';
    return {
        CustomerContext => ($args->{customer_context} // "Net::Async::Webservice::UPS"),
        XpciVersion     => "".($Net::Async::Webservice::UPS::VERSION||0),
    };
}


sub access_as_xml {
    my $self = shift;
    return XMLout({
        AccessRequest => {
            AccessLicenseNumber  => $self->access_key,
            Password            => $self->password,
            UserId              => $self->user_id,
        }
    }, NoAttr=>1, KeepRoot=>1, XMLDecl=>1);
}


sub request_rate {
    state $argcheck = compile(Object, Dict[
        from => Address|Shipper,
        to => Address,
        packages => PackageList,
        limit_to => Optional[ArrayRef[Str]],
        exclude => Optional[ArrayRef[Str]],
        mode => Optional[RequestMode],
        service => Optional[Service],
        customer_context => Optional[Str],
    ]);
    my ($self,$args) = $argcheck->(@_);
    $args->{mode} ||= 'rate';
    $args->{service} ||= to_Service('GROUND');
    if ($args->{from}->isa('Net::Async::Webservice::UPS::Address')) {
        $args->{from} ||= $self->_shipper_from_address($args->{from});
    }

    if ( $args->{exclude} && $args->{limit_to} ) {
        Error::TypeTiny::croak("You cannot use both 'limit_to' and 'exclude' at the same time");
    }

    my $packages = $args->{packages};

    unless (scalar(@$packages)) {
        Error::TypeTiny::croak("request_rate() was given an empty list of packages");
    }

    my $cache_key;
    if ($self->does_caching) {
        $cache_key = $self->generate_cache_key(
            'rate',
            [ $args->{from},$args->{to},@$packages, ],
            {
                mode => $args->{mode},
                service => $args->{service}->code,
                pickup_type => $self->pickup_type,
                customer_classification => $self->customer_classification,
            },
        );
        if (my $cached_services = $self->cache->get($cache_key)) {
            return Future->wrap($cached_services);
        }
    }

    my %request = (
        RatingServiceSelectionRequest => {
            Request => {
                RequestAction   => 'Rate',
                RequestOption   =>  $args->{mode},
                TransactionReference => $self->transaction_reference($args),
            },
            PickupType  => {
                Code    => $code_for_pickup_type{$self->pickup_type},
            },
            Shipment    => {
                Service     => { Code   => $args->{service}->code },
                Package     => [map { $_->as_hash() } @$packages],
                Shipper     => $args->{from}->as_hash('AV'),
                ShipTo      => $args->{to}->as_hash('AV'),
            },
            ( $self->customer_classification ? (
                CustomerClassification => { Code => $code_for_customer_classification{$self->customer_classification} }
            ) : () ),
        }
    );

    # default to "all allowed"
    my %ok_labels = map { $_ => 1 } @{ServiceLabel->values};
    if ($args->{limit_to}) {
        # deny all, allow requested
        %ok_labels = map { $_ => 0 } @{ServiceLabel->values};
        $ok_labels{$_} = 1 for @{$args->{limit_to}};
    }
    elsif ($args->{exclude}) {
        # deny requested
        $ok_labels{$_} = 0 for @{$args->{exclude}};
    }

    $self->xml_request({
        data => \%request,
        url_suffix => '/Rate',
        XMLin => {
            ForceArray => [ 'RatedPackage', 'RatedShipment' ],
        },
    })->transform(
        done => sub {
            my ($response) = @_;

            my @services;
            for my $rated_shipment (@{$response->{RatedShipment}}) {
                my $code = $rated_shipment->{Service}{Code};
                my $label = Net::Async::Webservice::UPS::Service::label_for_code($code);
                next if not $ok_labels{$label};

                push @services, my $service = Net::Async::Webservice::UPS::Service->new({
                    code => $code,
                    label => $label,
                    total_charges => $rated_shipment->{TotalCharges}{MonetaryValue},
                    # TODO check this logic
                    ( ref($rated_shipment->{GuaranteedDaysToDelivery})
                          ? ()
                          : ( guaranteed_days => $rated_shipment->{GuaranteedDaysToDelivery} ) ),
                    rated_packages => $packages,
                    # TODO check this pairwise
                    rates => [ pairwise {
                        Net::Async::Webservice::UPS::Rate->new({
                            %$a,
                            rated_package   => $b,
                            from            => $args->{from},
                            to              => $args->{to},
                        });
                    } @{$rated_shipment->{RatedPackage}},@$packages ],
                });

                # fixup service-rate-service refs
                $_->_set_service($service) for @{$service->rates};
            }
            @services = sort { $a->total_charges <=> $b->total_charges } @services;

            my $ret = Net::Async::Webservice::UPS::Response::Rate->new({
                %$response,
                services => \@services,
            });

            $self->cache->set($cache_key,$ret) if $self->does_caching;

            return $ret;
        },
    );
}


sub validate_address {
    state $argcheck = compile(
        Object,
        Address, Optional[Tolerance],
    );
    my ($self,$address,$tolerance) = $argcheck->(@_);

    $tolerance //= 0.05;

    my %data = (
        AddressValidationRequest => {
            Request => {
                RequestAction => "AV",
                TransactionReference => $self->transaction_reference(),
            },
            %{$address->as_hash('AV')},
        },
    );

    my $cache_key;
    if ($self->does_caching) {
        $cache_key = $self->generate_cache_key(
            'AV',
            [ $address ],
            { tolerance => $tolerance },
        );
        if (my $cached_services = $self->cache->get($cache_key)) {
            return Future->wrap($cached_services);
        }
    }

    $self->xml_request({
        data => \%data,
        url_suffix => '/AV',
        XMLin => {
            ForceArray => [ 'AddressValidationResult' ],
        },
    })->transform(
        done => sub {
            my ($response) = @_;

            my @addresses;
            for my $address (@{$response->{AddressValidationResult}}) {
                next if $address->{Quality} < (1 - $tolerance);
                for my $possible_postal_code ($address->{PostalCodeLowEnd} .. $address->{PostalCodeHighEnd}) {
                    $address->{Address}{PostalCode} = $possible_postal_code;
                    push @addresses, Net::Async::Webservice::UPS::Address->new($address);
                }
            }


            my $ret = Net::Async::Webservice::UPS::Response::Address->new({
                %$response,
                addresses => \@addresses,
            });

            $self->cache->set($cache_key,$ret) if $self->does_caching;
            return $ret;
        },
    );
}


sub validate_street_address {
    state $argcheck = compile(
        Object,
        Address,
    );
    my ($self,$address) = $argcheck->(@_);

    my %data = (
        AddressValidationRequest => {
            Request => {
                RequestAction => 'XAV',
                RequestOption => '3',
                TransactionReference => $self->transaction_reference(),
            },
            %{$address->as_hash('XAV')},
        },
    );

    my $cache_key;
    if ($self->does_caching) {
        $cache_key = $self->generate_cache_key(
            'XAV',
            [ $address ],
        );
        if (my $cached_services = $self->cache->get($cache_key)) {
            return Future->wrap($cached_services);
        }
    }

    $self->xml_request({
        data => \%data,
        url_suffix => '/XAV',
        XMLin => {
            ForceArray => [ 'AddressValidationResponse','AddressLine', 'AddressKeyFormat' ],
        },
    })->then(
        sub {
            my ($response) = @_;


            if ($response->{NoCandidatesIndicator}) {
                return Future->new->fail(Net::Async::Webservice::UPS::Exception::UPSError->new({
                    error => {
                        ErrorDescription => 'The Address Matching System is not able to match an address from any other one in the database',
                        ErrorCode => 'NoCandidates',
                    },
                }),'ups');
            }
            if ($response->{AmbiguousAddressIndicator}) {
                return Future->new->fail(Net::Async::Webservice::UPS::Exception::UPSError->new({
                    error => {
                        ErrorDescription => 'The Address Matching System is not able to explicitly differentiate an address from any other one in the database',
                        ErrorCode => 'AmbiguousAddress',
                    },
                }),'ups');
            }

            my $quality = 0;
            if ($response->{ValidAddressIndicator}) {
                $quality = 1;
            }

            my @addresses;
            for my $ak (@{$response->{AddressKeyFormat}}) {
                push @addresses, Net::Async::Webservice::UPS::Address->new({
                    AddressKeyFormat => $ak,
                    Quality => $quality,
                });
            }

            my $ret = Net::Async::Webservice::UPS::Response::Address->new({
                %$response,
                addresses => \@addresses,
            });

            $self->cache->set($cache_key,$ret) if $self->does_caching;
            return Future->wrap($ret);
        },
    );
}


sub ship_confirm {
    state $argcheck = compile(Object, Dict[
        from => Contact,
        to => Contact,
        shipper => Optional[Shipper],
        service => Optional[Service],
        description => Str,
        payment => Payment,
        label => Optional[Label],
        packages => PackageList,
        return_service => Optional[ReturnService],
        customer_context => Optional[Str],
        delivery_confirmation => Optional[Int],
    ]);
    my ($self,$args) = $argcheck->(@_);

    $args->{service} //= to_Service('GROUND');
    $args->{shipper} //= $self->_shipper_from_contact($args->{from});

    my $packages = $args->{packages};

    unless (scalar(@$packages)) {
        Error::TypeTiny::croak("ship_confirm() was given an empty list of packages");
    }
    my $package_data = [map { $_->as_hash() } @$packages];
    if ($args->{delivery_confirmation}) {
        for my $p (@$package_data) {
            $p->{PackageServiceOptions}{DeliveryConfirmation}{DCISType} =
                $args->{delivery_confirmation};
        }
    }

    my %data = (
        ShipmentConfirmRequest => {
            Request => {
                TransactionReference => $self->transaction_reference($args),
                RequestAction => 'ShipConfirm',
                RequestOption => 'validate', # this makes the request
                                             # fail if there are
                                             # address problems
            },
            Shipment => {
                Service => { Code => $args->{service}->code },
                Description => $args->{description},
                ( $args->{return_service} ? (
                    ReturnService => { Code => $args->{return_service}->code }
                ) : () ),
                Shipper => $args->{shipper}->as_hash,
                ( $args->{from} ? ( ShipFrom => $args->{from}->as_hash ) : () ),
                ShipTo => $args->{to}->as_hash,
                PaymentInformation => $args->{payment}->as_hash,
                Package => $package_data,
            },
            ( $args->{label} ? ( LabelSpecification => $args->{label}->as_hash ) : () ),
        }
    );

    $self->xml_request({
        data => \%data,
        url_suffix => '/ShipConfirm',
    })->transform(
        done => sub {
            my ($response) = @_;

            return Net::Async::Webservice::UPS::Response::ShipmentConfirm->new({
                %$response,
                packages => $packages,
            });
        },
    );
}


sub ship_accept {
    state $argcheck = compile( Object, Dict[
        confirm => ShipmentConfirm,
        customer_context => Optional[Str],
    ]);
    my ($self,$args) = $argcheck->(@_);

    my %data = (
        ShipmentAcceptRequest => {
            Request => {
                TransactionReference => $self->transaction_reference($args),
                RequestAction => 'ShipAccept',
            },
            ShipmentDigest => $args->{confirm}->shipment_digest,
        },
    );

    my $packages = $args->{confirm}->packages;

    $self->xml_request({
        data => \%data,
        url_suffix => '/ShipAccept',
        XMLin => {
            ForceArray => [ 'PackageResults' ],
        },
    })->transform(
        done => sub {
            my ($response) = @_;

            return Net::Async::Webservice::UPS::Response::ShipmentAccept->new({
                packages => $packages,
                %$response,
            });
        },
    );
}


sub qv_events {
    state $argcheck = compile( Object, Dict[
        subscriptions => Optional[ArrayRef[QVSubscription]],
        bookmark => Optional[Str],
        customer_context => Optional[Str],
    ]);

    my ($self,$args) = $argcheck->(@_);

    my %data = (
        QuantumViewRequest => {
            Request => {
                TransactionReference => $self->transaction_reference($args),
                RequestAction => 'QVEvents',
            },
            ( $args->{subscriptions} ? ( SubscriptionRequest => [
                map { $_->as_hash } @{$args->{subscriptions}}
            ] ) : () ),
            ($args->{bookmark} ? (Bookmark => $args->{bookmark}) : () ),
        },
    );

    $self->xml_request({
        data => \%data,
        url_suffix => '/QVEvents',
    })->transform(
        done => sub {
            my ($response) = @_;
            return Net::Async::Webservice::UPS::Response::QV->new($response);
        }
    );
}


sub xml_request {
    state $argcheck = compile(
        Object,
        Dict[
            data => HashRef,
            url_suffix => Str,
            XMLout => Optional[HashRef],
            XMLin => Optional[HashRef],
        ],
    );
    my ($self, $args) = $argcheck->(@_);

    # default XML::Simple args
    my $xmlargs = {
        NoAttr     => 1,
        KeyAttr    => [],
    };

    my $request =
        $self->access_as_xml .
            XMLout(
                $args->{data},
                %{ $xmlargs },
                XMLDecl     => 1,
                KeepRoot    => 1,
                %{ $args->{XMLout}||{} },
            );

    return $self->post( $self->base_url . $args->{url_suffix}, $request )->then(
        sub {
            my ($response_string) = @_;

            my $response = XMLin(
                $response_string,
                %{ $xmlargs },
                %{ $args->{XMLin} },
            );

            if ($response->{Response}{ResponseStatusCode}==0) {
                return Future->new->fail(
                    Net::Async::Webservice::UPS::Exception::UPSError->new({
                        error => $response->{Response}{Error}
                    }),
                    'ups',
                  );
            }
            return Future->wrap($response);
        },
    );
}


with 'Net::Async::Webservice::Common::WithRequestWrapper';


sub generate_cache_key {
    state $argcheck = compile(Object, Str, ArrayRef[Cacheable],Optional[HashRef]);
    my ($self,$kind,$things,$args) = $argcheck->(@_);

    return join ':',
        $kind,
        ( map { $_->cache_id } @$things ),
        ( map {
            sprintf '%s:%s',
                $_,
                ( defined($args->{$_}) ? '"'.$args->{$_}.'"' : 'undef' )
            } sort keys %{$args || {}}
        );
}

sub _shipper_from_address {
    my ($self,$addr) = @_;

    require Net::Async::Webservice::UPS::Shipper;

    return Net::Async::Webservice::UPS::Shipper->new({
        address => $addr,
        ( $self->account_number ? ( account_number => $self->account_number ) : () ),
    });
}

sub _shipper_from_contact {
    my ($self,$contact) = @_;

    return $contact if $contact->isa('Net::Async::Webservice::UPS::Shipper');

    require Net::Async::Webservice::UPS::Shipper;

    return Net::Async::Webservice::UPS::Shipper->new({
        %$contact, # ugly!
        ( $self->account_number ? ( account_number => $self->account_number ) : () ),
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS - UPS API client, non-blocking

=head1 VERSION

version 1.1.4

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::Webservice::UPS;

 my $loop = IO::Async::Loop->new;

 my $ups = Net::Async::Webservice::UPS->new({
   config_file => $ENV{HOME}.'/.naws_ups.conf',
   loop => $loop,
 });

 $ups->validate_address($postcode)->then(sub {
   my ($response) = @_;
   say $_->postal_code for @{$response->addresses};
   return Future->wrap();
 });

 $loop->run;

Alternatively:

 use Net::Async::Webservice::UPS;

 my $ups = Net::Async::Webservice::UPS->new({
   config_file => $ENV{HOME}.'/.naws_ups.conf',
   user_agent => LWP::UserAgent->new,
 });

 my $response = $ups->validate_address($postcode)->get;

 say $_->postal_code for @{$response->addresses};

=head1 DESCRIPTION

This class implements some of the methods of the UPS API, using
L<Net::Async::HTTP> as a user agent I<by default> (you can still pass
something like L<LWP::UserAgent> and it will work). All methods that
perform API calls return L<Future>s (if using a synchronous user
agent, all the Futures will be returned already completed).

B<NOTE>: I've kept many names and codes from the original L<Net::UPS>,
so the API of this distribution may look a bit strange. It should make
it simpler to migrate from L<Net::UPS>, though.

=head1 ATTRIBUTES

=head2 C<live_mode>

Boolean, defaults to false. When set to true, the live API endpoint
will be used, otherwise the test one will. Flipping this attribute
will reset L</base_url>, so you generally don't want to touch this if
you're using some custom API endpoint.

=head2 C<base_url>

A L<URI> object, coercible from a string. The base URL to use to send
API requests to (actual requests will be C<POST>ed to an actual URL
built from this by appending the appropriate service path). Defaults
to the standard UPS endpoints:

=over 4

=item *

C<https://onlinetools.ups.com/ups.app/xml> for live

=item *

C<https://wwwcie.ups.com/ups.app/xml> for testing

=back

See also L</live_mode>.

=head2 C<user_id>

=head2 C<password>

=head2 C<access_key>

Strings, required. Authentication credentials.

=head2 C<account_number>

String. Used in some requests as "shipper number".

=head2 C<customer_classification>

String, usually one of C<WHOLESALE>, C<OCCASIONAL>, C<RETAIL>. Used
when requesting rates.

=head2 C<pickup_type>

String, defaults to C<ONE_TIME>. Used when requesting rates.

=head2 C<cache>

Responses are cached if this is set. You can pass your own cache
object (that implements the C<get> and C<set> methods like L<CHI>
does), or use the C<cache_life> and C<cache_root> constructor
parameters to get a L<CHI> instance based on L<CHI::Driver::File>.

=head2 C<user_agent>

A user agent object, looking either like L<Net::Async::HTTP> (has
C<do_request> and C<POST>) or like L<LWP::UserAgent> (has C<request>
and C<post>). You can pass the C<loop> constructor parameter to get a
default L<Net::Async::HTTP> instance.

=head2 C<ssl_options>

Optional hashref, its contents will be passed to C<user_agent>'s
C<do_request> method.

If L<IO::Socket::SSL> and L<Mozilla::CA> are installed, the default
value sets full TLS validation, and makes sure that the Verisign
certificate currently (as of 2015-02-03) used by the UPS servers is
recognised (see L<UPS SSL/TLS notes>).

=head1 METHODS

=head2 C<does_caching>

Returns a true value if caching is enabled.

=head2 C<new>

Async:

  my $ups = Net::Async::Webservice::UPS->new({
     loop => $loop,
     config_file => $file_name,
     cache_life => 5,
  });

Sync:

  my $ups = Net::Async::Webservice::UPS->new({
     user_agent => LWP::UserAgent->new,
     config_file => $file_name,
     cache_life => 5,
  });

In addition to passing all the various attributes values, you can use
a few shortcuts.

=over 4

=item C<loop>

a L<IO::Async::Loop>; a locally-constructed L<Net::Async::HTTP> will be registered to it and set as L</user_agent>

=item C<config_file>

a path name; will be parsed with L<Config::Any>, and the values used as if they had been passed in to the constructor

=item C<cache_life>

lifetime, in I<minutes>, of cache entries; a L</cache> will be built automatically if this is set (using L<CHI> with the C<File> driver)

=item C<cache_root>

where to store the cache files for the default cache object, defaults to C<naws_ups> under your system's temporary directory

=back

A few more examples:

=over 4

=item *

no config file, no cache, async:

   ->new({
     user_id=>$user,password=>$pw,access_key=>$ak,
     loop=>$loop,
   }),

=item *

no config file, no cache, custom user agent (sync or async):

   ->new({
     user_id=>$user,password=>$pw,access_key=>$ak,
     user_agent=>$ua,
   }),

it's your job to register the custom user agent to the event loop, if
you're using an async agent

=item *

config file, async, custom cache:

   ->new({
     loop=>$loop,
     cache=>CHI->new(...),
   }),

=back

=head2 C<transaction_reference>

Constant data used to fill something in requests. I don't know what
it's for, I just copied it from L<Net::UPS>.

=head2 C<access_as_xml>

Returns a XML document with the credentials.

=head2 C<request_rate>

  $ups->request_rate({
    from => $address_a,
    to => $address_b,
    packages => [ $package_1, $package_2 ],
  }) ==> (Net::Async::Webservice::UPS::Response::Rate)

C<from> and C<to> are instances of
L<Net::Async::Webservice::UPS::Address>, or postcode strings that will
be coerced to addresses.

C<packages> is an arrayref of L<Net::Async::Webservice::UPS::Package>
(or a single package, will be coerced to a 1-element array ref).

I<NOTE>: the C<id> field of the packages I<used to be modified>. It no
longer is.

Optional parameters:

=over 4

=item C<limit_to>

only accept some services (see L<Net::Async::Webservice::UPS::Types/ServiceLabel>)

=item C<exclude>

exclude some services (see L<Net::Async::Webservice::UPS::Types/ServiceLabel>)

=item C<mode>

defaults to C<rate>, could be C<shop>

=item C<service>

defaults to C<GROUND>, see L<Net::Async::Webservice::UPS::Service>

=item C<customer_context>

optional string for reference purposes

=back

The L<Future> returned will yield an instance of
L<Net::Async::Webservice::UPS::Response::Rate>, or fail with an
exception.

Identical requests can be cached.

=head2 C<validate_address>

  $ups->validate_address($address)
    ==> (Net::Async::Webservice::UPS::Response::Address)

  $ups->validate_address($address,$tolerance)
    ==> (Net::Async::Webservice::UPS::Response::Address)

C<$address> is an instance of L<Net::Async::Webservice::UPS::Address>,
or a postcode string that will be coerced to an address.

Optional parameter: a tolerance (float, between 0 and 1). Returned
addresses with quality below 1 minus tolerance will be filtered out.

The L<Future> returned will yield an instance of
L<Net::Async::Webservice::UPS::Response::Address>, or fail with an
exception.

Identical requests can be cached.

=head2 C<validate_street_address>

  $ups->validate_street_address($address)
    ==> (Net::Async::Webservice::UPS::Response::Address)

C<$address> is an instance of L<Net::Async::Webservice::UPS::Address>,
or a postcode string that will be coerced to an address.

The L<Future> returned will yield an instance of
L<Net::Async::Webservice::UPS::Response::Address>, or fail with an
exception.

Identical requests can be cached.

=head2 C<ship_confirm>

  $ups->ship_confirm({
     from => $source_contact,
     to => $destination_contact,
     description => 'something',
     payment => $payment_method,
     packages => \@packages,
  }) ==> $shipconfirm_response

Performs a C<ShipConfirm> request to UPS. The parameters are:

=over 4

=item C<from>

required, instance of L<Net::Async::Webservice::UPS::Contact>, where the shipments starts from

=item C<to>

required, instance of L<Net::Async::Webservice::UPS::Contact>, where the shipments has to be delivered to

=item C<shipper>

optional, instance of L<Net::Async::Webservice::UPS::Shipper>, who is requesting the shipment; if not specified, it's taken to be the same as the C<from> with the L</account_number> of this UPS object

=item C<service>

the shipping service to use, see L<Net::Async::Webservice::UPS::Types/Service>, defaults to C<GROUND>

=item C<description>

required string, description of the shipment

=item C<payment>

required instance of L<Net::Async::Webservice::UPS::Payment>, how to pay for this shipment

=item C<label>

optional instance of L<Net::Async::Webservice::UPS::Label>, what kind of label to request

=item C<packages>

an arrayref of L<Net::Async::Webservice::UPS::Package> (or a single package, will be coerced to a 1-element array ref), the packages to ship

=item C<return_service>

optional, instance of L<Net::Async::Webservice::UPS::ReturnService>, what kind of return service to request

=item C<delivery_confirmation>

optional, 1 means "signature required", 2 mean "adult signature required"

=item C<customer_context>

optional string for reference purposes

=back

Returns a L<Future> yielding an instance of
L<Net::Async::Webservice::UPS::Response::ShipmentConfirm>.

B<NOTE>: the API of this call may change in the future, let me know if
features you need are missing or badly understood!

=head2 C<ship_accept>

  $ups->ship_accept({
      confirm => $shipconfirm_response,
  }) ==> $shipaccept_response

Performs a C<ShipAccept> request to UPS. The parameters are:

=over 4

=item C<confirm>

required, instance of L<Net::Async::Webservice::UPS::Response::ShipmentConfirm>,as returned by L</ship_confirm>

=item C<customer_context>

optional string for reference purposes

=back

Returns a L<Future> yielding an instance of
L<Net::Async::Webservice::UPS::Response::ShipmentAccept>.

=head2 C<qv_events>

  $ups->qv_events({
      subscriptions => [ Net::Async::Webservice::UPS::QVSubscription->new(
        name => 'MySubscription',
      ) ],
  }) ==> $qv_response

Performs a C<QVEvennts> request to UPS. The parameters are:

=over 4

=item C<subscriptions>

optional, array of L<Net::Async::Webservice::UPS::QVSubscription>, specifying what you want to retrieve

=item C<bookmark>

optional, string retrieved from a previous call, used for pagination (see L<Net::Async::Webservice::UPS::Response::QV>)

=item C<customer_context>

optional string for reference purposes

=back

Returns a L<Future> yielding an instance of
L<Net::Async::Webservice::UPS::Response::QV>.

=head2 C<xml_request>

  $ups->xml_request({
    url_suffix => $string,
    data => \%request_data,
    XMLout => \%xml_simple_out_options,
    XMLin => \%xml_simple_in_options,
  }) ==> ($parsed_response);

This method is mostly internal, you shouldn't need to call it.

It builds a request XML document by concatenating the output of
L</access_as_xml> with whatever L<XML::Simple> produces from the given
C<data> and C<XMLout> options.

It then posts (possibly asynchronously) this to the URL obtained
concatenating L</base_url> with C<url_suffix> (see the L</post>
method). If the request is successful, it parses the body (with
L<XML::Simple> using the C<XMLin> options) and completes the returned
future with the result.

If the parsed response contains a non-zero
C</Response/ResponseStatusCode>, the returned future will fail with a
L<Net::Async::Webservice::UPS::Exception::UPSError> instance.

=head2 C<post>

  $ups->post($url_suffix,$body) ==> ($decoded_content)

Posts the given C<$body> to the URL obtained concatenating
L</base_url> with C<$url_suffix>. If the request is successful, it
completes the returned future with the decoded content of the
response, otherwise it fails the future with a
L<Net::Async::Webservice::Common::Exception::HTTPError> instance.

=head2 C<generate_cache_key>

Generates a cache key (a string) identifying a request. Two requests
with the same cache key should return the same response.

=for Pod::Coverage BUILDARGS

=head1 UPS SSL/TLS notes

In December 2014, UPS notified all its users that it would stop
supporting SSLv3 in March 2015. This library has no problems with
that, since LWP has supported TLS for years.

Another, unrelated, issue cropped up at rougly the same time, to
confuse the situation: L<Mozilla::CA>, which is used to get the root
certificates to verify connections, dropped a top-level Verisign
certificate that Verisign stopped using in 2010, but the UPS servers'
certificate was signed with it, so LWP stopped recognising the
servers' certificate. Net::Async::Webservice::UPS 1.1.3 works around
the problem by always including the root certificate in the default
L</ssl_options>. If you use custom options, you may want to check that
you're including the correct certificate. See also
https://rt.cpan.org/Ticket/Display.html?id=101908

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
