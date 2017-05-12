package Net::UPS;

# $Id: UPS.pm,v 1.12 2005/11/11 00:06:14 sherzodr Exp $


use strict;
use Carp ('croak');
use XML::Simple;
use LWP::UserAgent;
use Net::UPS::ErrorHandler;
use Net::UPS::Rate;
use Net::UPS::Service;
use Net::UPS::Address;
use Net::UPS::Package;


@Net::UPS::ISA          = ( "Net::UPS::ErrorHandler" );
$Net::UPS::VERSION      = '0.04';
$Net::UPS::LIVE         = 0;

sub RATE_TEST_PROXY () { 'https://wwwcie.ups.com/ups.app/xml/Rate'  }
sub RATE_LIVE_PROXY () { 'https://www.ups.com/ups.app/xml/Rate'     }
sub AV_TEST_PROXY   () { 'https://wwwcie.ups.com/ups.app/xml/AV'    }
sub AV_LIVE_PROXY   () { 'https://www.ups.com/ups.app/xml/AV'       }

sub PICKUP_TYPES () {
    return {
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
    };
}

sub CUSTOMER_CLASSIFICATION () {
    return {
        WHOLESALE               => '01',
        OCCASIONAL              => '03',
        RETAIL                  => '04'
    };
}


sub import {
    my $class = shift;
    @_ or return;
    if ( @_ % 2 ) {
        croak "import(): argument list has tobe in key=>value format";
    }
    my $args = { @_ };
    $Net::UPS::LIVE = $args->{live} || 0;
}


sub live {
    my $class = shift;
    unless ( @_ ) {
        croak "$class->live(): usage error";
    }
    $Net::UPS::LIVE = shift;
}



my $ups = undef;
sub new {
    my $class = shift;
    croak "new(): usage error" if ref($class);

    unless ( (@_ >= 1) || (@_ <= 4) ) {
        croak "new(): invalid number of arguments";
    }
    $ups = bless({
        __userid      => $_[0] || undef,
        __password    => $_[1] || undef,
        __access_key  => $_[2] || undef,
        __args        => $_[3] || {},
        __last_service=> undef
    }, $class);

    if ( @_ < 3 ) {
        $ups->_read_args_from_file(@_) or return undef;
    }

    unless ( $ups->userid && $ups->password && $ups->access_key ) {
        croak "new(): usage error. Required arguments missing";
    }
    if ( my $cache_life = $ups->{__args}->{cache_life} ) {
        eval "require Cache::File";
        if (my $errstr = $@ ) {
            croak "'cache_life' requires Cache::File module";
        }
        unless ( $ups->{__args}->{cache_root} ) {
            require File::Spec;
            $ups->{__args}->{cache_root} = File::Spec->catdir(File::Spec->tmpdir, 'net_ups');
        }
        $ups->{__cache} = Cache::File->new( cache_root      => $ups->{__args}->{cache_root},
                                            default_expires => "$cache_life m",
                                            cache_depth     => 5,
                                            lock_level      => Cache::File::LOCK_LOCAL()
                                            );
    }
    $ups->init();
    return $ups;
}





sub instance {
    return $ups if defined($ups);
    croak "instance(): no object instance found";
}




sub _read_args_from_file {
    my $self = shift;
    my ($path, $args) = @_;
    $args ||= {};

    unless ( defined $path ) {
        croak "_read_args_from_file(): required arguments are missing";
    }

    require IO::File;
    my $fh = IO::File->new($path, '<') or return $self->set_error("couldn't open $path: $!");
    my %config = ();
    while (local $_ = $fh->getline) {
        next if /^\s*\#/;
        next if /^\n/;
        next unless /^UPS/;
        chomp();
        my ($key, $value) = m/^\s*UPS(\w+)\s+(\S+)$/;
        $config{ $key } = $value;
    }
    unless ( $config{UserID} && $config{Password} && $config{AccessKey} ) {
        return $self->set_error( "_read_args_from_file(): required arguments are missing" );
    }
    $self->{__userid}       = $config{UserID};
    $self->{__password}     = $config{Password};
    $self->{__access_key}   = $config{AccessKey};


    $self->{__args}->{customer_classification} = $args->{customer_classification} || $config{CustomerClassification};
    $self->{__args}->{ups_account_number}      = $args->{ups_account_number}      || $config{AccountNumber};
    $self->cache_life( $args->{cache_life} || $config{CacheLife} );
    $self->cache_root( $args->{cache_root} || $config{CacheRoot} );

    return $self;
}

sub init        {                                                       }
sub rate_proxy  { $Net::UPS::LIVE ? RATE_LIVE_PROXY : RATE_TEST_PROXY   }
sub av_proxy    { $Net::UPS::LIVE ? AV_LIVE_PROXY   : AV_TEST_PROXY     }
sub cache_life  { return $_[0]->{__args}->{cache_life} = $_[1]          }
sub cache_root  { return $_[0]->{__args}->{cache_root} = $_[1]          }
sub userid      { return $_[0]->{__userid}                              }
sub password    { return $_[0]->{__password}                            }
sub access_key  { return $_[0]->{__access_key}                          }
sub account_number{return $_[0]->{__args}->{ups_account_number}         }
sub customer_classification { return $_[0]->{__args}->{customer_classification} }
sub dump        { return Dumper($_[0])                                  }

sub access_as_xml {
    my $self = shift;
    return XMLout({
        AccessRequest => {
            AccessLicenseNumber  => $self->access_key,
            Password            => $self->password,
            UserId              => $self->userid
        }
    }, NoAttr=>1, KeepRoot=>1, XMLDecl=>1);
}

sub transaction_reference {
    return {
        CustomerContext => "Net::UPS",
        XpciVersion     => '1.0001'
    };
}

sub rate {
    my $self = shift;
    my ($from, $to, $packages, $args) = @_;
    croak "rate(): usage error" unless ($from && $to && $packages);

    unless ( ref $from ) {
        $from = Net::UPS::Address->new(postal_code=>$from);
    }
    unless ( ref $to ) {
        $to   = Net::UPS::Address->new(postal_code=>$to);
    }
    unless ( ref $packages eq 'ARRAY' ) {
        $packages = [$packages];
    }
    $args                   ||= {};
    $args->{mode}             = "rate";
    $args->{service}        ||= "GROUND";

    my $services = $self->request_rate($from, $to, $packages, $args);
    if ( @$packages == 1 ) {
        return $services->[0]->rates()->[0];
    }

    return $services->[0]->rates();
}


sub shop_for_rates {
    my $self = shift;
    my ($from, $to, $packages, $args) = @_;

    unless ( $from && $to && $packages ) {
        croak "shop_for_rates(): usage error";
    }
    unless ( ref $from ) {
        $from = Net::UPS::Address->new(postal_code=>$from);
    }
    unless ( ref $to ) {
        $to =  Net::UPS::Address->new(postal_code=>$to);
    }
    unless ( ref $packages eq 'ARRAY' ) {
        $packages = [$packages];
    }
    $args           ||= {};
    $args->{mode}     = "shop";
    $args->{service}||= "GROUND";
    return [sort{$a->total_charges <=>$b->total_charges} @{$self->request_rate($from, $to, $packages, $args)}];
}



sub request_rate {
    my $self = shift;
    my ($from, $to, $packages, $args) = @_;

    croak "request_rate(): usage error" unless ($from && $to && $packages && $args);
    unless (ref($from) && $from->isa("Net::UPS::Address")&&
            ref($to) && $to->isa("Net::UPS::Address") &&
            ref($packages) && (ref $packages eq 'ARRAY') &&
            ref($args) && (ref $args eq 'HASH')) {
        croak "request_rate(): usage error";
    }
    if ( defined($args->{limit_to}) ) {
        unless ( ref($args->{limit_to}) && ref($args->{limit_to}) eq 'ARRAY' ) {
            croak "request_rate(): usage error. 'limit_to' should be of type ARRAY";
        }
    }
    if ( defined $args->{exclude} ) {
        unless ( ref($args->{exclude}) && ref($args->{exclude}) eq 'ARRAY' ) {
            croak "request_rate(): usage error. 'exclude' has to be of type 'ARRAY'";
        }
    }
    if ( $args->{exclude} && $args->{limit_to} ) {
        croak "request_rate(): usage error. You cannot use both 'limit_to' and 'exclude' at the same time";
    }
    for (my $i=0; $i < @$packages; $i++ ) {
        $packages->[$i]->id( $i + 1 );
    }
    my $cache_key = undef;
    my $cache     = undef;
    if ( defined($cache = $self->{__cache}) ) {
        $cache_key = $self->generate_cache_key($from, $to, $packages, $args);
        if ( my $services = $cache->thaw($cache_key) ) {
            return $services;
        }
    }
    my %data = (
        RatingServiceSelectionRequest => {
            Request => {
                RequestAction   => 'Rate',
                RequestOption   =>  $args->{mode},
                TransactionReference => $self->transaction_reference,
            },
            PickupType  => {
                Code    => PICKUP_TYPES->{$self->{__args}->{pickup_type}||"ONE_TIME"}
            },
            Shipment    => {
                Service     => { Code   => Net::UPS::Service->new_from_label( $args->{service} )->code },
                Package     => [map { $_->as_hash()->{Package} } @$packages],
                Shipper     => $from->as_hash(),
                ShipTo      => $to->as_hash()
            }
    });
    if ( my $shipper_number = $self->{__args}->{ups_account_number} ) {
        $data{RatingServiceSelectionRequest}->{Shipment}->{Shipper}->{ShipperNumber} = $shipper_number;
    }
    if (my $classification_code = $self->{__args}->{customer_classification} ) {
        $data{RatingServiceSelectionRequest}->{CustomerClassification}->{Code} = CUSTOMER_CLASSIFICATION->{$classification_code};
    }
    my $xml         = $self->access_as_xml . XMLout(\%data, KeepRoot=>1, NoAttr=>1, KeyAttr=>[], XMLDecl=>1);
    my $response    = XMLin( $self->post( $self->rate_proxy, $xml ),
                                            KeepRoot => 0,
                                            NoAttr => 1,
                                            KeyAttr => [],
                                            ForceArray => ['RatedPackage', 'RatedShipment']);
    if ( my $error  =  $response->{Response}->{Error} ) {
        return $self->set_error( $error->{ErrorDescription} );
    }
    my @services;
    for (my $i=0; $i < @{$response->{RatedShipment}}; $i++ ) {
        my $ref = $response->{RatedShipment}->[$i] or die;
        my $service = Net::UPS::Service->new_from_code($ref->{Service}->{Code});
        $service->total_charges( $ref->{TotalCharges}->{MonetaryValue} );
        $service->guaranteed_days(ref($ref->{GuaranteedDaysToDelivery}) ?
                                                undef : $ref->{GuaranteedDaysToDelivery});
        $service->rated_packages( $packages );
        my @rates = ();
        for (my $j=0; $j < @{$ref->{RatedPackage}}; $j++ ) {
            push @rates, Net::UPS::Rate->new(
                billing_weight  => $ref->{RatedPackage}->[$j]->{BillingWeight}->{Weight},
                total_charges   => $ref->{RatedPackage}->[$j]->{TotalCharges}->{MonetaryValue},
                weight          => $ref->{Weight},
                rated_package   => $packages->[$j],
                service         => $service,
                from            => $from,
                to              => $to
            );
        }
        $service->rates(\@rates);
        if ( (lc($args->{mode}) eq 'shop') && defined($cache) ) {
            local ($args->{mode}, $args->{service});
            $args->{mode} = 'rate';
            $args->{service} = $service->label;
            my $cache_key = $self->generate_cache_key($from, $to, $packages, $args);
            $cache->freeze($cache_key, [$service]);
        }
        if ( $args->{limit_to} ) {
            my $limit_ok = 0;
            for ( @{$args->{limit_to}} ) {
                ($_ eq $service->label) && $limit_ok++;
            }
            $limit_ok or next;
        }
        if ( $args->{exclude} ) {
            my $exclude_ok = 0;
            for ( @{$args->{exclude}} ) {
                ($_ eq $service->label) && $exclude_ok++;
            }
            $exclude_ok and next;
        }
        push @services, $service;
        $self->{__last_service} = $service;

    }
    if ( defined $cache ) {
        $cache->freeze($cache_key, \@services);
    }
    return \@services;
}




sub service {
    return $_[0]->{__last_service};
}


sub post {
    my $self = shift;
    my ($url, $content) = @_;

    unless ( $url && $content ) {
        croak "post(): usage error";
    }

    my $user_agent  = LWP::UserAgent->new();
    my $request     = HTTP::Request->new('POST', $url);
    $request->content( $content );
    my $response    = $user_agent->request( $request );
    if ( $response->is_error ) {
        die $response->status_line();
    }
    return $response->content;
}




sub validate_address {
    my $self    = shift;
    my ($address, $args) = @_;

    croak "verify_address(): usage error" unless defined($address);
    
    unless ( ref $address ) {
        $address = {postal_code => $address};
    }
    if ( ref $address eq 'HASH' ) {
        $address = Net::UPS::Address->new(%$address);
    }
    $args ||= {};
    unless ( defined $args->{tolerance} ) {
        $args->{tolerance} = 0.05;
    }
    unless ( ($args->{tolerance} >= 0) && ($args->{tolerance} <= 1) ) {
        croak "validate_address(): invalid tolerance threshold";
    }
    my %data = (
        AddressValidationRequest    => {
            Request => {
                RequestAction   => "AV",
                TransactionReference => $self->transaction_reference(),
            }
        }
    );
    if ( $address->city ) {
        $data{AddressValidationRequest}->{Address}->{City} = $address->city;
    }
    if ( $address->state ) {
        if ( length($address->state) != 2 ) {
            croak "StateProvinceCode has to be two letters long";
        }
        $data{AddressValidationRequest}->{Address}->{StateProvinceCode} = $address->state;
    }
    if ( $address->postal_code ) {
        $data{AddressValidationRequest}->{Address}->{PostalCode} = $address->postal_code;
    }
    my $xml = $self->access_as_xml . XMLout(\%data, KeepRoot=>1, NoAttr=>1, KeyAttr=>[], XMLDecl=>1);
    my $response = XMLin($self->post($self->av_proxy, $xml),
                                                KeepRoot=>0, NoAttr=>1,
                                                KeyAttr=>[], ForceArray=>["AddressValidationResult"]);
    if ( my $error = $response->{Response}->{Error} ) {
        return $self->set_error( $error->{ErrorDescription} );
    }
    my @addresses = ();
    for (my $i=0; $i < @{$response->{AddressValidationResult}}; $i++ ) {
        my $ref = $response->{AddressValidationResult}->[$i];
        next if $ref->{Quality} < (1 - $args->{tolerance});
        while ( $ref->{PostalCodeLowEnd} <= $ref->{PostalCodeHighEnd} ) {
            my $address = Net::UPS::Address->new(
                quality         => $ref->{Quality},
                postal_code     => $ref->{PostalCodeLowEnd},
                city            => $ref->{Address}->{City},
                state           => $ref->{Address}->{StateProvinceCode},
                country_code    => "US"
            );
            push @addresses, $address;
            $ref->{PostalCodeLowEnd}++;
        }
    }
    return \@addresses;
}

sub generate_cache_key {
    my $self = shift;
    my ($from, $to, $packages, $args) = @_;
    unless ( $from && $to && $packages && ref($from) && ref($to) && ref($packages) ) {
        croak "generate_cache_key(): usage error";
    }
    my @keys = ($from->cache_id, $to->cache_id);
    for my $package ( @$packages ) {
        push @keys, $package->cache_id;
    }
    for my $key ( sort keys %{$self->{__args}} ) {
        push @keys, sprintf("%s:%s", lc $key, lc $self->{__args}->{$key} );
    }
    for my $key (sort keys %$args ) {
        next if $key eq 'limit_to';
        next if $key eq 'exclude';
        push @keys, sprintf("%s:%s", lc $key, lc $args->{$key});
    }
    return join(":", @keys);
}




1;
__END__

=head1 NAME

Net::UPS - Implementation of UPS Online Tools API in Perl

=head1 SYNOPSIS

    use Net::UPS;
    $ups = Net::UPS->new($userid, $password, $accesskey);
    $rate = $ups->rate($from_zip, $to_zip, $package);
    printf("Shipping this package $from_zip => $to_zip will cost you \$.2f\n", $rate->total_charges);

=head1 DESCRIPTION

Net::UPS implements UPS' Online Tools API in Perl. In a nutshell, Net::UPS knows how to retrieve rates and service information for shipping packages using UPS, as well as for validating U.S. addresses.

This manual is optimized to be used as a quick reference. If you're knew to Net::UPS, and this manual doesn't seem to help, you're encouraged to read L<Net::UPS::Tutorial|Net::UPS::Tutorial> first.

=head1 METHODS

Following are the list and description of methods available through Net::UPS. Provided examples may also use other Net::UPS::* libraries and their methods. For the details of those please read their respective manuals. (See L<SEE ALSO|/"SEE ALSO">)

=over 4

=item live ($bool)

By default, all the API calls in Net::UPS are directed to UPS.com's test servers. This is necessary in testing your integration interface, and not to exhaust UPS.com live servers.

Once you want to go live, L<live()|/"live"> class method needs to be called with a true argument to indicate you want to switch to the UPS.com's live interface. It is recommended that you call live() before creating a Net::UPS instance by calling L<new()|/"new">, like so:

    use Net::UPS;
    Net::UPS->live(1);
    $ups = Net::UPS->new($userid, $password, $accesskey);

=item new($userid, $password, $accesskey)

=item new($userid, $password, $accesskey, \%args)

=item new($config_file)

=item new($config_file, \%args)

Constructor method. Builds and returns Net::UPS instance. If an instance exists, C<new()> returns that instance.

C<$userid> and C<$password> are your login information to your UPS.com profile. C<$accesskey> is something you have to request from UPS.com to be able to use UPS Online Tools API.

C<\%args>, if present, are the global arguments you can pass to customize Net::UPS instance, and further calls to UPS.com. Available arguments are as follows:

=over 4

=item pickup_type

Type of pickup to be assumed by subsequent L<rate()|/"rate"> and L<shop_for_rates()|/"shop_for_rates"> calls. See L<PICKUP TYPES|PICKUP_TYPES> for the list of available pickup types.

=item ups_account_number

If you have a UPS account number, place it here.

=item customer_classification

Your Customer Classification. For details refer to UPS Online Tools API manual. In general, you'll get the lowest quote if your I<pickup_type> is I<DAILY> and your I<customer_classification> is I<WHOLESALE>. See L<CUSTOMER CLASSIFICATION|/"CUSTOMER CLASSIFICATION">

=item cache_life

Enables caching, as well as defines the life of cache in minutes.

=item cache_root

File-system location of a cache data. Return value of L<tmpdir()|File::Spec/tempdir> is used as default location.

=back

All the C<%args> can also be defined in the F<$config_file>. C<%args> can be used to overwrite the default arguments. See L<CONFIGURATION FILE|/"CONFIGURATION FILE">

=item instance ()

Returns an instance of Net::UPS object. Should be called after an instance is created previously by calling C<new()>. C<instance()> croaks if there is no object instance.

=item userid ()

=item password ()

=item access_key ()

Return UserID, Password and AccessKey values respectively

=item rate ($from, $to, $package)

=item rate ($from, $to, \@packages)

=item rate ($from, $to, \@packages, \%args)

Returns one Net::UPS::Rate instance for every package requested. If there is only one package, returns a single reference to Net::UPS::Rate. If there are more then one packages passed, returns an arrayref of Net::UPS::Rate objects.

C<$from> and C<$to> can be either plain postal (zip) codes, or instances of Net::UPS::Address. In latter case, the only value required is C<postal_code()>.

C<$package> should be of Net::UPS::Package type and C<@packages> should be an array of Net::UPS::Package objects.

    $rate = $ups->rate(15146, 15241, $package);
    printf("Your cost is \$.2f\n", $rate->total_charges);

See L<Net::UPS::Package|Net::UPS::Package> for examples of building a package. See L<Net::UPS::Rate|Net::UPS::Rate> for examples of using C<$rate>.

C<\%args>, if present, can be used to customize C<rate()>ing process. Available arguments are:

=over 4

=item service

Specifies what kind of service to rate the package against. Default is I<GROUND>, which rates the package for I<UPS Ground>. See L<SERVICE TYPES|/"SERVICE TYPES"> for a list of available UPS services to choose from.

=back

=item shop_for_rates ($from, $to, $package)

=item shop_for_rates ($from, $to, \@packages)

=item shop_for_rates ($from, $to, \@packages, \%args)

The same as L<rate()|/"rate">, except on success, returns a reference to a list of available services. Each service is represented as an instance of L<Net::UPS::Service|Net::UPS::Service> class. Output is sorted by L<total_charges()|Net::UPS::Service/"total_charges"> in ascending order. Example:

    $services = $ups->shop_for_rates(15228, 15241, $package);
    while (my $service = shift @$services ) {
        printf("%-22s => \$.2f", $service->label, $service->total_charges);
        if ( my $days = $service->guaranteed_days ) {
            printf("(delivers in %d day%s)\n", $days, ($days > 1) ? "s" : "");
        } else {
            print "\n";
        }
    }

Above example returns all the service types available for shipping C<$package> from 15228 to 15241. Output may be similar to this:

    GROUND                 => $5.20
    3_DAY_SELECT           => $6.35  (delivers in 3 days)
    2ND_DAY_AIR            => $9.09  (delivers in 2 days)
    2ND_DAY_AIR_AM         => $9.96  (delivers in 2 days)
    NEXT_DAY_AIR_SAVER     => $15.33 (delivers in 1 day)
    NEXT_DAY_AIR           => $17.79 (delivers in 1 day)
    NEXT_DAY_AIR_EARLY_AM  => $49.00 (delivers in 1 day)

The above example won't change even if you passed multiple packages to be rated. Individual package rates can be accessed through L<rates()|Net::UPS::Service/"rates"> method of L<Net::UPS::Service|Net::UPS::Service>.

C<\%args>, if present, can be used to customize the rating process and/or the return value. Currently supported arguments are:

=over 4

=item limit_to

Tells Net::UPS which service types the result should be limited to. I<limit_to> should always refer to an array of services. For example:

    $services = $ups->shop_for_rates($from, $to, $package, {
                            limit_to=>['GROUND', '2ND_DAY_AIR', 'NEXT_DAY_AIR']
    });

This example returns rates for the selected service types only. All other service types will be ignored. Note, that it doesnt' guarantee all the requested service types will be available in the return value of C<shop_for_rates()>. It only returns the services (from the list provided) that are available between the two addresses for the given package(s).

=item exclude

The list provided in I<exclude> will be excluded from the list of available services. For example, assume you don't want rates for 'NEXT_DAY_AIR_SAVER', '2ND_DAY_AIR_AM' and 'NEXT_DAY_AIR_EARLY_AM' returned:

    $service = $ups->from_for_rates($from, $to, $package, {
                    exclude => ['NEXT_DAY_AIR_SAVER', '2ND_DAY_AIR_AM', 'NEXT_DAY_AIR_EARLY_AM']});

Note that excluding services may even generate an empty service list, because for some location excluded services might be the only services available. You better contact your UPS representative for consultation. As of this writing I haven't done that yet.

=back

=item service ()

Returns the last service used by the most recent call to C<rate()>.

=item validate_address ($address)

=item validate_address ($address, \%args)

Validates a given address against UPS' U.S. Address Validation service. C<$address> can be one of the following:

=over 4

=item *

US Zip Code

=item *

Hash Reference - keys of the hash should correspond to attributes of Net::UPS::Address

=item *

Net::UPS::Address class instance

=back

C<%args>, if present, contains arguments that effect validation results. As of this release the only supported argument is I<tolerance>, which defines threshold for address matches. I<threshold> is a floating point number between 0 and 1, inclusively. The higher the tolerance threshold, the more loose the address match is, thus more address suggestions are returned. Default I<tolerance> value is 0.05, which only returns very close matches.

    my $addresses = $ups->validate_address($address);
    unless ( defined $addresses ) {
        die $ups->errstr;
    }
    unless ( @$addresses ) {
        die "Address is not correct, nor are there any suggestions\n";
    }
    if ( $addresses->[0]->is_match ) {
        print "Address Matches Exactly!\n";
    } else {
        print "Your address didn't match exactly. Following are some valid suggestions\n";
        for (@$addresses ) {
            printf("%s, %s %s\n", $_->city, $_->state, $_->postal_code);
        }
    }

=pod

=back

=head1 BUGS AND KNOWN ISSUES

No bugs are known of as of this release. If you think you found a bug, document it at http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-UPS. It's more likely to get noticed in there than in my busy inbox.

=head1 TODO

There are still a lot of features UPS.com offers in its Online Tools API that Net::UPS doesn't handle. This is the list of features that need to be supported before Net::UPS can claim full compliance.

=head2 PACKAGE OPTIONS

Following features needs to be supported by Net::UPS::Package class to define additional package options:

=over 4

=item COD

=item Delivery Confirmation

=item Insurance

=item Additional Handling flag

=back

=head2 SERVICE OPTIONS

Following featureds need to be supported by Net::UPS::Service as well as in form of arguments to rate() and shop_for_rates() methods:

=over 4

=item Saturday Pickup

=item Saturday Delivery

=item COD Service request

=item Handling Charge

=back

=head1 AUTHOR

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>, http://author.handalak.com/

=head2 CREDITS

Thanks to Christian - E<lt>cpan [AT] pickledbrain.comE<gt> for locating and fixing a bug in Net::UPS::Package::is_oversized(). See the source for details.

=head1 COPYRIGHT

Copyright (C) 2005 Sherzod Ruzmetov. All rights reserved. This library is free software.
You can modify and/or distribute it under the same terms as Perl itself.

=head1 DISCLAIMER

THIS LIBRARY IS PROVIDED WITH USEFULNES IN MIND, BUT WITHOUT ANY GUARANTEE (NEITHER IMPLIED NOR EXPRESSED) OF ITS FITNES FOR A PARTICUALR PURPOSE. USE IT AT YOUR OWN RISK.

=head1 SEE ALSO

L<Net::UPS::Address|Net::UPS::Address>, L<Net::UPS::Rate>, L<Net::UPS::Service|Net::UPS::Service>, L<Net::UPS::Package|Net::UPS::Package>, L<Net::UPS::Tutorial|Net::UPS::Tutorial>

=head1 APPENDIXES

Some options need to be provided to UPS in the form of codes. These two-digit numbers are not ideal for mortals to work with. That's why Net::UPS decided to assign them symbolic names, I<constants>, if you wish.

=head2 SERVICE TYPES

Following is the table of SERVICE TYPE codes, and their symbolic names assigned by Net::UPS. One of these options can be passed as I<service> argument to C<rate()>, as in:

    $rates = $ups->rate($from, $to, $package, {service=>'2ND_DAY_AIR'});

    +------------------------+-----------+
    |    SYMBOLIC NAMES      | UPS CODES |
    +------------------------+-----------+
    | NEXT_DAY_AIR           |    01     |
    | 2ND_DAY_AIR            |    02     |
    | GROUND                 |    03     |
    | WORLDWIDE_EXPRESS      |    07     |
    | WORLDWIDE_EXPEDITED    |    08     |
    | STANDARD               |    11     |
    | 3_DAY_SELECT           |    12     |
    | NEXT_DAY_AIR_SAVER     |    13     |
    | NEXT_DAY_AIR_EARLY_AM  |    14     |
    | WORLDWIDE_EXPRESS_PLUS |    54     |
    | 2ND_DAY_AIR_AM'        |    59     |
    +------------------------+-----------+

=head2 CUSTOMER CLASSIFICATION

Following are the possible customer classifications. Can be passed to C<new()> as part of the argument list, as in:

    $ups = Net::UPS->new($userid, $password, $accesskey, {customer_classification=>'WHOLESALE'});

    +----------------+-----------+
    | SYMBOLIC NAMES | UPS CODES |
    +----------------+-----------+
    | WHOLESALE      |     01    |
    | OCCASIONAL     |     03    |
    | RETAIL         |     04    |
    +----------------+-----------+

=head2 PACKAGE CODES

Following are all valid packaging types that can be set through I<packaging_type> attribute of Net::UPS::Package, as in:

    $package = Net::UPS::Package->new(weight=>10, packaging_type=>'TUBE');

    +-----------------+-----------+
    | SYMBOLIC NAMES  | UPS CODES |
    +-----------------+-----------+
    | LETTER          |     01    |
    | PACKAGE         |     02    |
    | TUBE            |     03    |
    | UPS_PAK         |     04    |
    | UPS_EXPRESS_BOX |     21    |
    | UPS_25KG_BOX    |     24    |
    | UPS_10KG_BOX    |     25    |
    +-----------------+-----------+

=head2 CONFIGURATION FILE

Net::UPS object can also be instantiated using a configuration file. Example:

    $ups = Net::UPS->new("/home/sherzodr/.upsrc");
    # or
    $ups = Net::UPS->new("/home/sherzodr/.upsrc", \%args);

All the directives in the configuration file intended for use by Net::UPS will be prefixed with I<UPS>. All other directives that Net::UPS does not recognize will be conveniently ignored. Configuration file uses the following format:

    DirectiveName  DirectiveValue

Where C<DirectiveName> is one of the keywords documented below.

=head3 SUPPORTED DIRECTIVES

=over 4

=item UPSAccessKey

AccessKey as acquired from UPS.com Online Tools web site. Required.

=item UPSUserID

Online login id for the account. Required.

=item UPSPassword

Online password for the account. Required.

=item UPSCacheLife

To Turn caching on. Value of the directive also defines life-time for the cache.

=item UPSCacheRoot

Place to store cache files in. Setting this directive does not automatically turn caching on. UPSCacheLife needs to be set for this directive to be effective. UPSCacheRoot will defautlt o your system's temporary folder if it's missing.

=item UPSLive

Setting this directive to any true value will make Net::UPS to initiate calls to UPS.com's live servers. Without this directive Net::UPS always operates under test mode.

=item UPSPickupType

=item UPSAccountNumber

=item UPSCustomerClassification


=back

=cut
