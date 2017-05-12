package                         # PAUSE hide
     Saml2Test;
use strict;
use warnings;

=head1 NAME 

Saml2Test - test Dancer app for Net::SAML2

=head1 DESCRIPTION

Demo app to show use of Net::SAML2 as an SP.

=cut

use Dancer ':syntax';
use Net::SAML2;
use MIME::Base64 qw/ decode_base64 /;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/login' => sub {
    my $idp = _idp();
    my $sp = _sp();
    my $authnreq = $sp->authn_request(
        $idp->entityid,
        $idp->format, # default format.
    )->as_xml;
	
    my $redirect = $sp->sso_redirect_binding($idp, 'SAMLRequest');
    my $url = $redirect->sign($authnreq);
    redirect $url, 302;

    return "Redirected\n";
};

get '/logout-local' => sub {
    redirect '/', 302;
};

get '/logout-redirect' => sub {
    my $idp = _idp();
    my $sp = _sp();

    my $logoutreq = $sp->logout_request(
        $idp->entityid, params->{nameid}, $idp->format, params->{session}
    )->as_xml;

    my $redirect = $sp->slo_redirect_binding($idp, 'SAMLRequest');
    my $url = $redirect->sign($logoutreq);
    redirect $url, 302;

    return "Redirected\n";
};

get '/logout-soap' => sub {
    my $idp = _idp();
    my $slo_url = $idp->slo_url('urn:oasis:names:tc:SAML:2.0:bindings:SOAP');
    my $idp_cert = $idp->cert('signing');

    my $sp = _sp();
    my $logoutreq = $sp->logout_request(
        $idp->entityid, params->{nameid}, $idp->format, params->{session}
    )->as_xml;

    my $soap = Net::SAML2::Binding::SOAP->new(
        key	 => 'sign-nopw-cert.pem',
        cert	 => 'sign-nopw-cert.pem',
        url	 => $slo_url,
        idp_cert => $idp_cert,
        cacert   => 'saml_cacert.pem',
    );

    my $res = $soap->request($logoutreq);

    redirect '/', 302;
    return "Redirected\n";
};

post '/consumer-post' => sub {
    my $post = Net::SAML2::Binding::POST->new(
        cacert => 'saml_cacert.pem',
    );
    my $ret = $post->handle_response(
        params->{SAMLResponse}
    );
        
    if ($ret) {
        my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
            xml => decode_base64(params->{SAMLResponse})
        );

        template 'user', { assertion => $assertion };
    }
    else {
        return "<html><pre>Bad Assertion</pre></html>";
    }
};

get '/consumer-artifact' => sub {
    my $idp = _idp();
    my $idp_cert = $idp->cert('signing');
    my $art_url  = $idp->art_url('urn:oasis:names:tc:SAML:2.0:bindings:SOAP');

    my $artifact = params->{SAMLart};

    my $sp = _sp();
    my $request = $sp->artifact_request($idp->entityid, $artifact)->as_xml;

    my $soap = Net::SAML2::Binding::SOAP->new(
        url	 => $art_url,
        key	 => 'sign-private.pem',
        cert	 => 'sign-certonly.pem',
        idp_cert => $idp_cert
    );
    my $response = $soap->request($request);

    if ($response) {
        my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
            xml => $response
        );
                
        template 'user', { assertion => $assertion };
    }
    else {
        return "<html><pre>Bad Assertion</pre></html>";
    }
};

get '/sls-redirect-response' => sub {
    my $idp = _idp();
    my $idp_cert = $idp->cert('signing');

    my $sp = _sp();
    my $redirect = $sp->slo_redirect_binding($idp, 'SAMLResponse');
    my ($response, $relaystate) = $redirect->verify(request->request_uri);
        
    redirect $relaystate || '/', 302;
    return "Redirected\n";
};

get '/metadata.xml' => sub {
    my $sp = _sp();
    return $sp->metadata;
};

sub _sp {
    my $sp = Net::SAML2::SP->new(
        id     => 'http://localhost:3000',
        url    => 'http://localhost:3000',
        cert   => 'sign-nopw-cert.pem',
        cacert => 'saml_cacert.pem',
		
        org_name	 => 'Saml2Test',
        org_display_name => 'Saml2Test app for Net::SAML2',
        org_contact	 => 'saml2test@example.com',
    );
    return $sp;
}	

sub _idp {
    my $idp = Net::SAML2::IdP->new_from_url(
        url    => config->{idp},
        cacert => 'saml_cacert.pem'
    );
    return $idp;
}

true;
