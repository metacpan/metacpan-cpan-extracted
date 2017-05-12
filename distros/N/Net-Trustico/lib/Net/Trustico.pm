package Net::Trustico;

use strict;
use warnings;
our $VERSION = '0.02';

use LWP::UserAgent;
use Carp qw/croak/;
use Time::Piece;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/username password/);

my %products = (
    'freessl30' => {
        name => 'FreeSSL 30 Day Trial',
        periods => [ qw/1/ ],
        vetting => 'DOM',
        process => '1',
        reissuance => 0,
        canrenew => 0
    },
    'rapidssl' => {
        name => 'RapidSSL',
        periods => [ qw/12 24 36 48 60/ ],
        vetting => 'DOM',
        process => '1',
        reissuance => 1,
        canrenew => 1,
    },
    rapidsslwildcard => {
        name => 'RapidSSL Wildcard',
        periods => [ qw/12 24 36 48 60/ ],
        vetting => 'DOM',
        process => '1',
        reissuance => 1,
        canrenew => 1,
    },
    geotrust30 => {
        name => 'GeoTrust SSL 30 Day Trial',
        periods => [ qw/1/ ],
        vetting => 'DOM',
        process => '1',
        reissuance => 0,
        canrenew => 0
    },
    quickssl => {
        name => 'QuickSSL Basic',
        periods => [ qw/12 24 36 48 60/ ],
        vetting => 'DOM',
        process => '1',
        reissuance => 0,
        canrenew => 1
    },
    quicksslpremium => {
        name => 'QuickSSL Premium',
        periods => [ qw/12 24 36 48 60 72/ ],
        vetting => 'DOM',
        process => '1',
        reissuance => 0,
        canrenew => 1
    },
    truebusinessid => {
        name => 'True BusinessID',
        periods => [ qw/12 24 36 48 60/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    truebusinessidwild => {
        name => 'True BusinessID Wildcard',
        periods => [ qw/12 24 36 48 60/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    truebusinessidev => {
        name => 'True BusinessID Wildcard',
        periods => [ qw/12 24/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    power => {
        name => 'Power Server ID',
        periods => [ qw/12 24 36 48 60 72/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    powerwild => {
        name => 'Power Server ID Wildcard',
        periods => [ qw/12 24 36 48 60 72/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    secure => {
        name => 'Secure Site',
        periods => [ qw/12 24 36/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    securepro => {
        name => 'Secure Site Pro',
        periods => [ qw/12 24 36/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    secureev => {
        name => 'Secure Site + EV',
        periods => [ qw/12 24/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    secureproev => {
        name => 'Secure Site Pro + EV',
        periods => [ qw/12 24/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    },
    ssl123 => {
        name => 'SSL123',
        periods => [ qw/12 24 36 48 60/ ],
        vetting => 'ORG',
        process => '2',
        reissuance => 0,
        canrenew => 1
    } );

my %process = (
    1 => {
        admin => {
            title => 'AdminTitle', firstname => 'AdminFirstName',
            lastname => 'AdminLastName',
            organisation => 'AdminOrganization',
            taxid => 'AdminTaxID', role => 'AdminRole', 
            email => 'AdminEmail', phonecc => 'AdminPhoneCC',
            phoneac => 'AdminPhoneAC', phonen => 'AdminPhoneN',
            address1 => 'AdminAddress1', address2 => 'AdminAddress2',
            city => 'AdminCity', state => 'AdminState', 
            postcode => 'AdminPostCode', country => 'AdminCountry',
            day => 'AdminMemDateD', 'month' => 'AdminMemDateM',
            year => 'AdminMemDateY'
        },
        tech => {
            title => 'TechTitle', firstname => 'TechFirstName',
            lastname => 'TechLastName',
            organisation => 'TechOrganization', email => 'TechEmail',
            phonecc => 'TechPhoneCC', phoneac => 'TechPhoneAC',
            phonen => 'TechPhoneN', address1 => 'TechAddress1',
            address2 => 'TechAddress2', city => 'TechCity',
            state => 'TechState', postcode => 'TechPostCode',
            country => 'TechCountry'
        },
        techusereseller => 'TechUseReseller', product => 'ProductName',
        csr => 'CSR', domain => 'Domain', period => 'ValidityPeriod',
        insurance => 'Insurance', servercount => 'ServerCount',
        approver => 'ApproverEmail', dnsnames => 'DnsNames',
        special => 'SpecialInstructions', terms => 'AgreedToTerms',
        novalidation => 'NoCSRValidation'
    },
    2 => {
        org => {
            name => 'OrgName', duns => 'OrgDUNS', taxid => 'OrgTaxID',
            address1 => 'OrgAddress1', address2 => 'OrgAddress2',
            city => 'OrgCity', state => 'OrgState', 
            postcode => 'OrgPostCode', country => 'OrgCountry',
            phonecc => 'OrgPhoneCC', phoneac => 'OrgPhoneAC', 
            phonen => 'OrgPhoneN'
        },
        admin => {
            title => 'AdminTitle', firstname => 'AdminFirstName',
            lastname => 'AdminLastName', role => 'AdminRole',
            email => 'AdminEmail', day => 'AdminMemDateD',
            'month' => 'AdminMemDateM', year => 'AdminMemDateY'
        },
        tech => {
            title => 'TechTitle', firstname => 'TechFirstName',
            lastname => 'TechLastName',
            organisation => 'TechOrganization', email => 'TechEmail',
            phonecc => 'TechPhoneCC', phoneac => 'TechPhoneAC',
            phonen => 'TechPhoneN', address1 => 'TechAddress1',
            address2 => 'TechAddress2', city => 'TechCity',
            state => 'TechState', postcode => 'TechPostCode',
            country => 'TechCountry'
        },
        techusereseller => 'TechUseReseller', product => 'ProductName',
        csr => 'CSR', domain => 'Domain', period => 'ValidityPeriod',
        insurance => 'Insurance', servercount => 'ServerCount',
        approver => 'ApproverEmail', special => 'SpecialInstructions',
        terms => 'AgreedToTerms', novalidation => 'NoCSRValidation'
    } );


=head1 NAME

Net::Trustico - Perl extension for ordering SSL certificates from Trustico
via their API.

=head1 SYNOPSIS

  use Net::Trustico;
  
  my $t = Net::Trustico->new( username => $user, password => $pass );

  die unless $t->hello( $testString );

  my $a = {
    title => 'Ms',
    firstname => 'Eliza',
    lastname => 'Xample',
    organisation => 'E.Xample',
    role => 'WebSite Owner',
    email => 'e.xample@example.com',
    phonecc => '44',
    phoneac => '020',
    phonen => '9460234',
    address1 => '1 High Street',
    city => 'MyTown',
    state => 'London',
    postcode => 'SW1 4AA',
    country => 'GB'
  };

  my $t = $a;

  my %result = $t->order( product => $product,
                          csr => $csr,
                          period => 12,
                          approver => 'admin@example.com',
                          insurance => 0,
                          servercount => 1,
                          admin => $a,
                          techusereseller => 1,
                          novalidation => 0
                          );

  my $status = $t->status( orderid => $id );

=head1 DESCRIPTION

Perl module for ordering SSL certificates from Trustico.

=head1 METHODS

=head2 new

Initiates the module. 

Parameters:

username    - your Trustico reseller account username

password    - the password for your reseller account.

=head2 hello

Tests the connection to the Trustico API by sending a string of text and
testing that the same string is returned.

This function returns true if the connection is OK or false if not.

You can call this method with a string of your own or no parameters. If
no parameters are passed a standard string is used to test the connection.

=head2 order

Submits an order to the Trustico API and returns a hash reference 
confirming order details on success or undef.

Parameters:

product     - the product code for the relevant product as provided by
              the products() method.

renewal     - the order will be processed as a renewal if this parameter
              is passed.

csr         - the CSR for the certificate

period      - period for the certificate in months. Valid options are
              detailed in the details provided by the products() method.

approver    - Approver email address. Must be one of admin, administrator
              hostmaster, root, webmaster or postmaster prepended to the
              domain supplied in the request

insurance   - Re-issue insurance required - 1 or 0

servercount - Number of server licenses requires. 

novalidation- If set to 1 the CSR can be blank to be provded later via the
              Trustico reseller management interface.

special     - Special instructions to issuer. Up to 255 characters

admin       - Admin contact details hash ref

tech        - Tech contact details hash ref

org         - Organisation details hash ref (required for products with 
              ORG vetting type only - will be ignored if not required)

Tech contact hash ref must contain either the following fields:

    title, firstname, lastname, organisation, email, phonecc, phoneac, 
    phonen, address1, city, state, postcode, country.

The tech contact may also contain an optional address2 field

Alternatively the tech contact may be omitted if the techusereseller
field is set to 1 in which case the default details provided via the 
Trustico reseller control panel will be used.

Admin contact hash must contain all of the fields required for the Tech
contact plus a role field.

The admin contact may also contain the following optional fields:

    taxid, memdate (ISO format)

=head2 status

Gets the status of the order specified by the orderid parameter.

The returned details are in a hash reference.

=head2 products

Returns a hash containing a list of product codes and the details for each
product.

=head1 SEE ALSO

http://www.trustico.com/


=head1 AUTHOR

Jason Clifford, E<lt>jason@ukfsn.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Jason Clifford

This library is free software; you can redistribute it and/or modify
it under the terms of the FSF GPL version 2.0 or later.

=cut

sub new { shift->SUPER::new({ @_ }) }

sub hello {
    my ( $self, $string ) = @_;

    $string = "Net::Trustico test string" unless $string;

    my $res = $self->_req('Hello', { 'TextToEcho' => $string } );
    return undef unless $res->{TextToEcho} eq $string;
    return 1;
}

sub order {
    my ($self, %args) = @_;

    my $p = $products{$args{product}}->{process};

    for (qw/ product period insurance servercount approver /) {
        croak "You must supply the $_ parameter" unless exists $args{$_};
    }

    if ( $p == 2 ) {
        for (qw/name address1 city state postcode country phonecc
                phoneac phonen/) {
            croak "You must supply the org $_ parameter" unless $args{org}->{$_};
        }
    }

    for (qw/admin tech/) {
        my $type = $_;
        next if $type eq 'tech' && $args{techusereseller} == 1;
        for (qw/ title firstname lastname role email /) {
            croak "you must supply the $type $_ parameter" 
                unless $args{$type}->{$_};
        }
        if ( $type eq 'admin' && $p == 1 ) {
            for (qw/ organisation phonecc phoneac phonen address1 city
                     state postcode country / ) {
                croak "You must supply the $type $_ parameter" unless $args{$type}->{$_};
            }
        }
        if ( $type eq 'tech' ) {
            for (qw/ organisation phonecc phoneac phonen address1 city
                     state postcode country /) {
                croak "You must supply the $type $_ parameter" unless $args{$type}->{$_};
            }
        }
    }

    if ( $args{admin}->{memdate} ) {
        my $d = Time::Piece->strptime($args{admin}->{memdate}, "%F");
        $args{admin}->{day} = $d->mday;
        $args{admin}->{month} = $d->mon;
        $args{admin}->{year} = $d->year;
        delete $args{admin}->{memdate};
    }
    
    my %order = ();

    my $recurse = undef;
    $recurse = sub {
        my ($input, $parent) = @_;
        while ( my ($k, $v) = each %$input) {
            next unless exists $args{$k} || exists $args{$parent}->{$k};
            $recurse->($v, $k), next if ref $v eq 'HASH';
            if ( $parent ) {
                $order{$v} = $args{$parent}->{$k};
            }
            else {
                $order{$v} = $args{$k};
            }
        }
    };
    
    $recurse->($process{$p});
    $order{ProductName} = $products{$args{product}}->{name};
    $order{ProductName} = $order{ProductName} . ' RN' if $args{renewal} == 1;
    $order{AgreedToTerms} = 1;

    my $command = 'ProcessType1';
    $command = 'ProcessType2' if $p == 2;

    $self->_req($command, \%order);
}

sub status {
    my ($self, %args) = @_;
    return undef unless $args{orderid} || $args{issuerid};

    my $args = { };
    if ( $args{orderid} ) {
        $args->{OrderID} = $args{orderid};
    }
    else {
        $args->{IssuerOrderID} = $args{issuerid};
    }

    $self->_req('GetStatus', $args);
}

sub products { return \%products; }

sub _req {
    my ($self, $command, $args) = @_;

    my $a = {
        Command => $command,
        UserName => $self->username,
        Password => $self->password
    };

    foreach (keys %$args) {
        $a->{$_} = $args->{$_};
    }

    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
    my $url = 'https://api.ssl-processing.com/geodirect/postapi/';

    my $res = $ua->post($url, $a);

    croak "Unable to connect to API" unless $res->is_success;

    my %rv = ();
    my @fields = split(/\n/, $res->content);
    foreach (@fields) {
        $_ =~ /(.*?)\|(.*?)\|/;
        $rv{$1} = $2;
    }

    croak $rv{Error} if $rv{SuccessCode} == 0;
    delete $rv{$_} for (qw/Error SuccessCode/);

    return \%rv;
}

1;
