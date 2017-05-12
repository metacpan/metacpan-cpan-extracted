package Net::Ikano;

use warnings;
use strict;
use Net::Ikano::XMLUtil;
use LWP::UserAgent;
use Data::Dumper;

=head1 NAME

Net::Ikano - Interface to Ikano wholesale DSL API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $URL = 'https://orders.value.net/OsirisWebService/XmlApi.aspx';

our $SCHEMA_ROOT = 'https://orders.value.net/osiriswebservice/schema/v1';

our $API_VERSION = "1.0";

our @orderType = qw( NEW CANCEL CHANGE );

our @orderStatus = qw( NEW PENDING CANCELLED COMPLETED ERROR );

our $AUTOLOAD;

=head1 SYNOPSIS

    use Net::Ikano;

    my $ikano = Net::Ikano->new(
	       'keyid' => $your_ikano_api_keyid,
	       'password'  => $your_ikano_admin_user_password,
	       'debug' => 1 # remove this for prod
               'reqpreviewonly' => 1 # remove this for prod
               'minimalQualResp' => 1 # on quals, return pairs of ProductCustomId+TermsId only
               'minimalOrderResp' => 1 # return minimal data on order responses
        );

=head1 SUPPORTED API METHODS

=over 4

=item ORDER

NOTE: supports orders by ProductCustomId only

$ikano->ORDER(
    {
	orderType => 'NEW',
	ProductCustomId => 'abc123',
	TermsId => '123',
	DSLPhoneNumber => '4167800000',
	Password => 'abc123',
	PrequalId => '12345',
	CompanyName => 'abc co',
	FirstName => 'first',
	LastName => 'last',
	MiddleName => '',
	ContactMethod => 'PHONE',
	ContactPhoneNumber => '4167800000',
	ContactEmail => 'x@x.ca',
	ContactFax => '',
	DateToOrder => '2010-11-29',
	RequestClientIP => '127.0.0.1',
	IspChange => 'NO',
	IspPrevious => '',
	CurrentProvider => '',
    }
);


=item CANCEL

$i->CANCEL(
    { OrderId => 555 }
);


=item PREQUAL

$ikano->PREQUAL( {
    AddressLine1 => '123 Test Rd',
    AddressUnitType => '', 
    AddressUnitValue =>  '',
    AddressCity =>  'Toronto',
    AddressState => 'ON',
    ZipCode => 'M6C 2J9', # or 12345
    Country => 'CA', # or US
    LocationType => 'R', # or B
    PhoneNumber => '4167800000',
    RequestClientIP => '127.0.0.1',
    CheckNetworks => 'ATT,BELLCA,VER', # either one or command-separated like this
} );


=item ORDERSTATUS

$ikano->ORDERSTATUS( 
    { OrderId => 1234 }
);


=item PASSWORDCHANGE 

$ikano->PASSWORDCHANGE( {
	    DSLPhoneNumber => '4167800000',
	    NewPassword => 'xxx',
	} );


=item CUSTOMERLOOKUP

$ikano->CUSTOMERLOOKUP( { PhoneNumber => '4167800000' } );


=item ACCOUNTSTATUSCHANGE

$ikano->ACCOUNTSTATUSCHANGE(( {
	    type => 'SUSPEND',
	    DSLPhoneNumber => '4167800000',
	    DSLServiecId => 123,
	} );

=back

=cut

sub new {
    my ($class,%data) = @_;
    die "missing keyid and/or password" 
	unless defined $data{'keyid'} && defined $data{'password'};
    my $self = { 
	'keyid' => $data{'keyid'},
	'password' => $data{'password'},
	'username' => $data{'username'} ? $data{'username'} : 'admin',
	'debug' => $data{'debug'} ? $data{'debug'} : 0,
	'reqpreviewonly' => $data{'reqpreviewonly'} ? $data{'reqpreviewonly'} : 0,
	};
    bless $self, $class;
    return $self;
}


sub req_ORDER {
   my ($self, $args) = (shift, shift);

    return "invalid order data" unless defined $args->{orderType}
	&& defined $args->{ProductCustomId} && defined $args->{DSLPhoneNumber};
   return "invalid order type ".$args->{orderType}
    unless grep($_ eq $args->{orderType}, @orderType);

    # XXX: rewrite this uglyness?
    my @ignoreFields = qw( orderType ProductCustomId );
    my %orderArgs = ();
    while ( my ($k,$v) = each(%$args) ) {
	$orderArgs{$k} = [ $v ] unless grep($_ eq $k,@ignoreFields);
    }

    return Order => {
	type => $args->{orderType},
	%orderArgs,
	ProductCustomId => [ split(',',$args->{ProductCustomId}) ],
    };
}

sub resp_ORDER {
   my ($self, $resphash, $reqhash) = (shift, shift);
   return "invalid order response" unless defined $resphash->{OrderResponse};
   return $resphash->{OrderResponse};
}

sub req_CANCEL {
   my ($self, $args) = (shift, shift);

    return "no order id for cancel" unless defined $args->{OrderId};

    return Cancel => {
	OrderId => [ $args->{OrderId} ],
    };
}

sub resp_CANCEL {
   my ($self, $resphash, $reqhash) = (shift, shift);
   return "invalid cancel response" unless defined $resphash->{OrderResponse};
   return $resphash->{OrderResponse};
}

sub req_ORDERSTATUS {
   my ($self, $args) = (shift, shift);

   return "ORDERSTATUS is supported by OrderId only" 
    if defined $args->{PhoneNumber} || !defined $args->{OrderId};

    return OrderStatus => {
	OrderId => [ $args->{OrderId} ],
    };
}

sub resp_ORDERSTATUS {
   my ($self, $resphash, $reqhash) = (shift, shift);
   return "invalid order response" unless defined $resphash->{OrderResponse};
   return $resphash->{OrderResponse};
}

sub req_ACCOUNTSTATUSCHANGE {
   my ($self, $args) = (shift, shift);
   return "invalid account status change request" unless defined $args->{type} 
    && defined $args->{DSLServiceId} && defined $args->{DSLPhoneNumber};

   return AccountStatusChange => {
       type => $args->{type},
	DSLPhoneNumber => [ $args->{DSLPhoneNumber} ],
	DSLServiceId => [ $args->{DSLServiceId} ],
    };
}

sub resp_ACCOUNTSTATUSCHANGE {
   my ($self, $resphash, $reqhash) = (shift, shift);
    return "invalid account status change response" 
	unless defined $resphash->{AccountStatusChangeResponse}
	&& defined $resphash->{AccountStatusChangeResponse}->{Customer};
    return $resphash->{AccountStatusChangeResponse}->{Customer};
}

sub req_CUSTOMERLOOKUP {
   my ($self, $args) = (shift, shift);
   return "invalid customer lookup request" unless defined $args->{PhoneNumber};
   return CustomerLookup => {
	PhoneNumber => [ $args->{PhoneNumber} ],
   };
}

sub resp_CUSTOMERLOOKUP {
   my ($self, $resphash, $reqhash) = (shift, shift);
   return "invalid customer lookup response" 
    unless defined $resphash->{CustomerLookupResponse}
	&& defined $resphash->{CustomerLookupResponse}->{Customer};
   return $resphash->{CustomerLookupResponse}->{Customer};
}

sub req_PASSWORDCHANGE {
   my ($self, $args) = (shift, shift);
   return "invalid arguments to PASSWORDCHANGE" 
	unless defined $args->{DSLPhoneNumber} && defined $args->{NewPassword};

   return PasswordChange => {
	DSLPhoneNumber => [ $args->{DSLPhoneNumber} ],
	NewPassword => [ $args->{NewPassword} ],
   };
}

sub resp_PASSWORDCHANGE {
   my ($self, $resphash, $reqhash) = (shift, shift);
   return "invalid change password response"
      unless defined $resphash->{ChangePasswordResponse}
	  && defined $resphash->{ChangePasswordResponse}->{Customer};
   $resphash->{ChangePasswordResponse}->{Customer};
}

sub req_PREQUAL {
   my ($self, $args) = (shift, shift);
   return PreQual => { 
        Address =>  [ { ( 
	    map { $_ => [ $args->{$_} ]  }  
		qw( AddressLine1 AddressUnitType AddressUnitValue AddressCity 
		    AddressState ZipCode LocationType Country ) 
	    )  } ],
	( map { $_ => [ $args->{$_} ] } qw( PhoneNumber RequestClientIP ) ),
	CheckNetworks => [ {
	    Network => [ split(',',$args->{CheckNetworks}) ]
	} ],
       };
}

sub resp_PREQUAL {
    my ($self, $resphash, $reqhash) = (shift, shift);
    return "invalid prequal response" unless defined $resphash->{PreQualResponse};
    return $resphash->{PreQualResponse};
}

sub orderTypes {
  @orderType;
}

sub AUTOLOAD {
    my $self = shift;
   
    $AUTOLOAD =~ /(^|::)(\w+)$/ or die "invalid AUTOLOAD: $AUTOLOAD";
    my $cmd = $2;
    return if $cmd eq 'DESTROY';

    my $reqsub = "req_$cmd";
    my $respsub = "resp_$cmd";
    die "invalid request type $cmd" 
	unless defined &$reqsub && defined &$respsub;

    my $reqargs = shift;

    my $xs = new Net::Ikano::XMLUtil(RootName => undef, SuppressEmpty => 1 );
    my $reqhash = {
	    OsirisRequest   => {
		type	=> $cmd,
		keyid	=> $self->{keyid},
		username => $self->{username},
		password => $self->{password},
		version => $API_VERSION,
		xmlns   => "$SCHEMA_ROOT/osirisrequest.xsd",
		$self->$reqsub($reqargs),
	    }
	};


    my $reqxml = "<?xml version=\"1.0\"?>\n".$xs->XMLout($reqhash, NoSort => 1);
   
    # XXX: validate against their schema to ensure we're not sending invalid XML?

    warn "DEBUG REQUEST\n\tHASH:\n ".Dumper($reqhash)."\n\tXML:\n $reqxml \n\n"
	if $self->{debug};
    
    my $ua = LWP::UserAgent->new;

    return "posting disabled for testing" if $self->{reqpreviewonly};

    my $resp = $ua->post($URL, Content_Type => 'text/xml', Content => $reqxml);
    return "invalid HTTP response from Ikano: " . $resp->status_line
	unless $resp->is_success;
    my $respxml = $resp->decoded_content;

    $xs = new Net::Ikano::XMLUtil(RootName => undef, SuppressEmpty => '',
	ForceArray => [ 'Address', 'Network', 'Product', 'StaticIp', 'OrderNotes' ] );
    my $resphash = $xs->XMLin($respxml);

    warn "DEBUG RESPONSE\n\tHASH:\n ".Dumper($resphash)."\n\tXML:\n $respxml"
	if $self->{debug};

    # XXX: validate against their schema to ensure they didn't send us invalid XML?

    return "invalid response received from Ikano" 
	unless defined $resphash->{responseid} && defined $resphash->{version}
	    && defined $resphash->{type};

    return "FAILURE response received from Ikano: " 
	. $resphash->{FailureResponse}->{FailureMessage} 
	if $resphash->{type} eq 'FAILURE';

    return "invalid response type ".$resphash->{type}." for request type $cmd"
	unless ( $cmd eq $resphash->{type} 
		|| ($cmd eq 'ORDER' && $resphash->{type} =~ /(NEW|CHANGE|CANCEL)ORDER/ )
		|| ($cmd eq "CANCEL" && $resphash->{type} eq "ORDERCANCEL")
	     );

    return $self->$respsub($resphash,$reqhash);
}


=head1 AUTHOR

Original Author: Erik Levinson

Current Maintainer: Ivan Kohler C<< <ivan-ikano@freeside.biz> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ikano at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Ikano>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Ikano

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Ikano>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Ikano>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Ikano>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Ikano>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Freeside Internet Services, Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ADVERTISEMENT

Need a complete, open-source back-office and customer self-service solution?
The Freeside software includes support for Ikano integration,
invoicing, credit card and electronic check processing, integrated trouble
ticketing, and customer signup and self-service web interfaces.

http://freeside.biz/freeside/

=cut

1;

