use warnings;
use strict;
use XML::Compile::WSDL11 3.04;
use XML::Compile::SOAP11 3.12;
use XML::Compile::Transport::SOAPHTTP 3.12;
use Test::More tests => 43;
use Test::Exception 0.40;
use Log::Report mode => 'NORMAL';
use Siebel::SOAP::Auth;
use File::Spec;
use Digest::MD5 qw(md5_base64);
use constant MAGIC_NUMBER => 5;
use Time::HiRes qw(time);

my $wsdlfile = File::Spec->catfile( 't', 'SWIContactServices.WSDL' );
my %request = (
    ListOfSwicontactio => {
        Contact =>
          { Id => '0-1', FirstName => 'Siebel', LastName => 'Administrator' }
    }
);

# code reference used globally
our $TOKENIZER = token_handler();
our $REQUESTOR = request_handler();

my $wsdl = XML::Compile::WSDL11->new($wsdlfile);
my $auth = Siebel::SOAP::Auth->new(
    {
        user          => 'sadmin',
        password      => 'XXXXXXX',
        token_timeout => MAGIC_NUMBER,
        remain_ttl    => 0
    }
);
my $call = $wsdl->compileClient(
    operation      => 'SWIContactServicesQueryByExample',
    transport_hook => \&mock_server
);

my ( $answer, $trace ) = $call->(%request);

if ( my $e = $@->wasFatal ) {

    BAIL_OUT($e);

}

$auth->find_token($answer);
my $previous_token = $TOKENIZER->();
is( $auth->get_token(), $previous_token,
    'Siebel::SOAP::Auth instance has the expected token' );

note('Testing token expiration in a loop');

for my $i ( 1 .. 20 ) {

    try sub {

        sleep(1);
        my ( $answer, $trace ) = $call->(%request);
        $auth->find_token($answer);

        isnt( $auth->get_token(), $previous_token,
            'Siebel::SOAP::Auth instance has a different token now' );
        $previous_token = $auth->get_token();

    };

    if ( my $e = $@->wasFatal ) {

        if ( $e =~ /token expired/ ) {

            die
'Server returned an error due token expiration, check remain_ttl attribute value ( was: '
              . $auth->get_remain_ttl . ')';

        }
        else {

            $e->throw;

        }
    }

}

TODO: {

    local $TODO = 'fault_response must be created' if 1;

    my $call2 = $wsdl->compileClient(
        operation      => 'SWIContactServicesQueryByExample',
        transport_hook => \&fake_response
    );

    my ( $answer, $trace ) = $call2->(%request);

    dies_ok { $auth->check_fault($answer) } 'instance can detect SOAP faults';

}

# SUBS

sub fake_response {

    my $token = shift;

    my $response = q(<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <SOAP-ENV:Header>
        <siebel-header:SessionToken xmlns:siebel-header="http://siebel.com/webservices">MY_TOKEN</siebel-header:SessionToken>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body>
        <ns:SWIContactServicesQueryByExample_Output xmlns:ns="http://siebel.com/asi/V0">
            <ListOfSwicontactio xmlns="http://www.siebel.com/xml/SWIContactIO">
                <Contact>
                    <Id>0-1</Id>
                    <Alias/>
                    <CellularPhone/>
                    <ContactPersonTitle/>
                    <CurrencyCode/>
                    <DateofBirth/>
                    <EmailAddress>sadmin@siebel.com</EmailAddress>
                    <FaxPhone/>
                    <FirstName>Siebel</FirstName>
                    <HomePhone/>
                    <IntegrationId/>
                    <JobTitle>Sys Admin</JobTitle>
                    <LastName>Administrator</LastName>
                    <Gender/>
                    <MM/>
                    <MaritalStatus/>
                    <MiddleName/>
                    <MotherMaidenName/>
                    <PrimaryOrganizationId>0-R9NH</PrimaryOrganizationId>
                    <PrimaryPersonalAddressId>1-7JZ-2</PrimaryPersonalAddressId>
                    <RowId>0-1</RowId>
                    <SocialSecurityNumber/>
                    <Status>Active</Status>
                    <SuppressAllCalls>N</SuppressAllCalls>
                    <SuppressAllEmails>N</SuppressAllEmails>
                    <SuppressAllFaxes>N</SuppressAllFaxes>
                    <SuppressAllMailings>N</SuppressAllMailings>
                    <WorkPhone/>
                    <ConsumerLink/>
                    <ListOfAccount/>
                    <ListOfComInvoiceProfile/>
                    <ListOfOrganization>
                        <Organization>
                            <Id>0-R9NH</Id>
                            <Name>Default Organization</Name>
                            <Organization>Default Organization</Organization>
                            <OrganizationId>0-R9NH</OrganizationId>
                        </Organization>
                    </ListOfOrganization>
                    <ListOfPersonalAddress/>
                    <ListOfUcmContactPrivacy/>
                    <ListOfFmLocation/>
                </Contact>
            </ListOfSwicontactio>
        </ns:SWIContactServicesQueryByExample_Output>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>);

    $response =~ s/MY_TOKEN/$token/;

    my $headers = HTTP::Headers->new(
        'client-ssl-socket-class' => 'IO::Socket::SSL',
        'client-ssl-cert-issuer' =>
'/C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=Terms of use at https://www.verisign.com/rpa (c)10/CN=VeriSign Class 3 International Server CA - G3',
        'keep-alive' => 'timeout=15',
        '::std_case' => {
            'client-ssl-socket-class' => 'Client-SSL-Socket-Class',
            'client-ssl-cert-issuer'  => 'Client-SSL-Cert-Issuer',
            'client-ssl-cert-subject' => 'Client-SSL-Cert-Subject',
            'keep-alive'              => 'Keep-Alive',
            'client-peer'             => 'Client-Peer',
            'client-date'             => 'Client-Date',
            '_charset'                => '_charset',
            'client-response-num'     => 'Client-Response-Num',
            'client-ssl-cipher'       => 'Client-SSL-Cipher'
        },
        '_charset'         => 'UTF-8',
        'server'           => 'Siebel-SOAP-Auth',
        'content-type'     => 'text/xml;charset=UTF-8',
        'cache-control'    => 'no-cache, must-revalidate, max-age=0',
        'content-language' => 'en',
        'connection'       => 'Keep-Alive',
        'client-ssl-cert-subject' =>
'/C=US/ST=California/L=Mojave Desert/O=Foo Bar/OU=CIT/CN=*.foobar.org',
        'client-peer'         => '144.23.28.181:443',
        'client-date'         => 'Fri, 30 Oct 2015 20:53:29 GMT',
        'client-response-num' => 1,
        'content-length'      => '2220',
        'date'                => 'Fri, 30 Oct 2015 20:53:30 GMT',
        'pragma'              => 'no-cache',
        'client-ssl-cipher'   => 'AES128-SHA'
    );

    return HTTP::Response->new( 200, 'Constant', $headers, $response );

}

sub mock_server {

    my ( $request, $trace, $transporter ) = @_;

    # request was modified
    my $check   = $auth->add_auth_header($request);
    my $content = $request->decoded_content;

# to validate the request, $REQUESTOR must use the same token that $auth received in the last response
    my $modified_expected = $REQUESTOR->( $auth->get_token() );
    is( $content, $modified_expected,
        'the Session Management header was added as expected' );

    return fake_response( $TOKENIZER->() );

}

sub request_handler {

    my $give_me_token =
q{<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header><PasswordText xmlns="http://siebel.com/webservices">XXXXXXX</PasswordText><SessionType xmlns="http://siebel.com/webservices">Stateless</SessionType><UsernameToken xmlns="http://siebel.com/webservices">sadmin</UsernameToken></SOAP-ENV:Header><SOAP-ENV:Body><tns:SWIContactServicesQueryByExample_Input xmlns:tns="http://siebel.com/asi/V0" xmlns:xsdLocal1="http://www.siebel.com/xml/SWIContactIO"><xsdLocal1:ListOfSwicontactio><xsdLocal1:Contact><xsdLocal1:Id>0-1</xsdLocal1:Id><xsdLocal1:FirstName>Siebel</xsdLocal1:FirstName><xsdLocal1:LastName>Administrator</xsdLocal1:LastName></xsdLocal1:Contact></xsdLocal1:ListOfSwicontactio></tns:SWIContactServicesQueryByExample_Input></SOAP-ENV:Body></SOAP-ENV:Envelope>};
    my $with_token =
q{<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Header><SessionToken xmlns="http://siebel.com/webservices">MY_TOKEN</SessionToken><SessionType xmlns="http://siebel.com/webservices">Stateless</SessionType></SOAP-ENV:Header><SOAP-ENV:Body><tns:SWIContactServicesQueryByExample_Input xmlns:tns="http://siebel.com/asi/V0" xmlns:xsdLocal1="http://www.siebel.com/xml/SWIContactIO"><xsdLocal1:ListOfSwicontactio><xsdLocal1:Contact><xsdLocal1:Id>0-1</xsdLocal1:Id><xsdLocal1:FirstName>Siebel</xsdLocal1:FirstName><xsdLocal1:LastName>Administrator</xsdLocal1:LastName></xsdLocal1:Contact></xsdLocal1:ListOfSwicontactio></tns:SWIContactServicesQueryByExample_Input></SOAP-ENV:Body></SOAP-ENV:Envelope>};
    my $start;
    my $is_first = 1;

    return sub {

        my $token = shift;

        if ($is_first) {

            $start    = time();
            $is_first = 0;
            return $give_me_token;

        }
        else {

            my $elapsed = time() - $start;
            note("request_handler elapsed time = $elapsed");

            if ( $elapsed > MAGIC_NUMBER ) {

                # resets the timer
                $start = time();
                return $give_me_token;

            }
            else {

                my $current   = $with_token;
                my $new_token = $token;
                $current =~ s/MY_TOKEN/$new_token/;
                return $current;

            }

        }

    };

}

sub token_handler {

    my $fixed =
'eUa-fXhWa5XknO5myBSFZQxe7BlT0TLgs7zcfbesbVjwPVpOFfLgmNFCM2Y-M1-Q43GLsrpgqZod8BSLYF2sRI4vYekGlb4trr4sIf3IDqD2LeT8ctYZI7yflfxIvhdwYG9kWhP4fIjcG2v4.UHy2K2u0uWQPdX0nEYIJoYCWU8kWFrQWyQH5HniBD8AIMuwHH3iZeZKXUsWpbAPOgC2hZhM5qkC4YXb-igx-rbHfl';
    my $counter = 0;
    my $first;

    return sub {

        if ( $counter == 0 ) {

            $first = md5_base64( time() ) . $fixed;
            $counter++;
            return $first;

            # see request_handler
        }
        elsif ( $counter == 1 ) {

            $counter++;
            return $first;

        }
        else {

            $counter++;
            return md5_base64( time() ) . $fixed;

        }

    };

}
