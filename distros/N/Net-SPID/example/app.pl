#!/usr/bin/env perl

# This demo application is an example of how to use the Net::SPID module directly
# with any web framework (in this case Dancer was chosen but Net::SPID is
# framework-agnostic).
# In the specific case of Dancer, you might want to use the Dancer::Plugin::SPID
# plugin which abstracts away this plumbing work.

use Dancer2;
use Net::SPID;

# Initialize our Net::SPID object with information about this SP.
my $spid = Net::SPID->new(
    sp_entityid     => 'https://www.prova.it/',
    sp_key_file     => 'sp.key',
    sp_cert_file    => 'sp.pem',
    sp_assertionconsumerservice => [
        'http://localhost:3000/spid-sso',
    ],
    sp_singlelogoutservice => {
        'http://localhost:3000/spid-slo' => 'HTTP-Redirect',
    },
    sp_attributeconsumingservice => [
        { servicename => 'Service 1', attributes => [qw(fiscalNumber name familyName dateOfBirth)] },
    ],
);

# Load Identity Providers from their XML metadata.
$spid->load_idp_metadata('idp_metadata/');

get '/' => sub {
    # If we have an active SPID session, display a page with user attributes,
    # otherwise show a generic login page containing the SPID button.
    if (session 'spid_session') {
        template 'user';
    } else {
        template 'index', { spid => $spid };
    }
};

# This endpoint exposes our metadata.
get '/metadata' => sub {
    content_type 'application/xml';
    return $spid->metadata;
};

# This endpoint initiates SSO through the user-chosen Identity Provider.
get '/spid-login' => sub {
    # Check that we have the mandatory 'idp' parameter and that it matches
    # an available Identity Provider.
    my $idp = $spid->get_idp(param 'idp')
        or return status 400;
    
    # Craft the AuthnRequest.
    my $authnreq = $idp->authnrequest(
        #acs_url     => 'http://localhost:3000/spid-sso',
        acs_index   => 0,
        attr_index  => 1,
        level       => 1,
    );
    
    # Save the ID of the Authnreq so that we can check it in the response
    # in order to prevent forgery.
    session 'spid_authnreq_id' => $authnreq->ID;
    
    # Uncomment the following line to use the HTTP-POST binding instead of HTTP-Redirect:
    ###return $authnreq->post_form;
    
    # Redirect user to the IdP using its HTTP-Redirect binding.
    redirect $authnreq->redirect_url, 302;
};

# This endpoint exposes an AssertionConsumerService for our Service Provider.
# During SSO, the Identity Provider will redirect user to this URL POSTing
# the resulting assertion.
post '/spid-sso' => sub {
    # Parse and verify the incoming assertion. This may throw exceptions so we
    # enclose it in an eval {} block.
    my $response = eval {
        $spid->parse_response(
            param('SAMLResponse'),
            session('spid_authnreq_id'),  # Match the ID of our authentication request for increased security.
        );
    };
    
    # Clear the ID of the outgoing Authnreq, regardless of the result.
    session 'spid_authnreq_id' => undef;
    
    # TODO: better error handling:
    # - authentication failure
    # - authentication cancelled by user
    # - temporary server error
    # - unavailable SPID level
    
    # In case of SSO failure, display an error page.
    if (!$response) {
        warning "Bad Assertion received: $@";
        status 400;
        content_type 'text/plain';
        return "Bad Assertion: $@";
    }
    
    # Log response as required by the SPID rules.
    # TODO: log it in a way that does not mangle whitespace preventing signature from 
    # being verified at a later time
    info "SPID Response: " . $response->xml;
    
    if ($response->success) {
        # Login successful! Initialize our application session and store
        # the SPID information for later retrieval.
        # $response->spid_session is a Net::SPID::Session object which is a
        # simple hashref thus it's easily serializable.
        # TODO: this should be stored in a database instead of the current Dancer
        # session, and it should be indexed by SPID SessionID so that we can delete
        # it when we get a LogoutRequest from an IdP.
        session 'spid_session' => $response->spid_session;
    
        # TODO: handle SPID level upgrade:
        # - does session ID remain the same? better assume it changes
    
        redirect '/';
    } else {
        content_type 'text/plain';
        return sprintf "Authentication Failed: %s (%s)",
            $response->StatusMessage, $response->StatusCode2;
    }
};

# This endpoint initiates logout.
get '/logout' => sub {
    # If we don't have an open SPID session, do nothing.
    return redirect '/'
        if !session 'spid_session';
    
    # Craft the LogoutRequest.
    my $spid_session = session 'spid_session';
    my $idp = $spid->get_idp($spid_session->idp_id);
    my $logoutreq = $idp->logoutrequest(session => $spid_session);
    
    # Save the ID of the LogoutRequest so that we can check it in the response
    # in order to prevent forgery.
    session 'spid_logoutreq_id' => $logoutreq->ID;
    
    # Uncomment the following line to use the HTTP-POST binding instead of HTTP-Redirect:
    ###return $logoutreq->post_form;
    
    # Redirect user to the Identity Provider for logout.
    redirect $logoutreq->redirect_url, 302;
};

# This endpoint exposes a SingleLogoutService for our Service Provider, using
# a HTTP-POST or HTTP-Redirect binding (Net::SPID does not support SOAP).
# Identity Providers can direct both LogoutRequest and LogoutResponse messages
# to this endpoint.
any '/spid-slo' => sub {
    if (param('SAMLResponse') && session('spid_logoutreq_id')) {
        # This is the response to a SP-initiated logout.
        
        # Parse the response and catch validation errors.
        my $logoutres = eval {
            $spid->parse_logoutresponse(
                param('SAMLResponse'),
                request->uri,
                session('spid_logoutreq_id'),
            )
        };
        
        if ($@) {
            warning "Bad LogoutResponse received: $@";
            status 400;
            content_type 'text/plain';
            return "Bad LogoutResponse: $@";
        }
        
        # Logout was successful! Clear the local session.
        session 'spid_logoutreq_id' => undef;
        session 'spid_session'      => undef;
        
        # TODO: handle partial logout. Log? Show message to user?
        # if ($response->status eq 'partial') { ... }
        
        # Redirect user back to main page.
        redirect '/';
    } elsif (param 'SAMLRequest') {
        # This is a LogoutRequest (IdP-initiated logout).
        
        my $logoutreq = eval {
            $spid->parse_logoutrequest(param('SAMLRequest'), request->uri)
        };
        
        if ($@) {
            warning "Bad LogoutRequest received: $@";
            status 400;
            content_type 'text/plain';
            return "Bad LogoutRequest: $@";
        }
        
        # Now we should retrieve the local session corresponding to the SPID
        # session $request->session. However, since we are implementing a HTTP-POST
        # binding, this HTTP request comes from the user agent so the current Dancer
        # session is automatically the right one. This simplifies things a lot as
        # retrieving another session by SPID session ID is tricky without a more
        # complex architecture.
        my $status = 'success';
        if ($logoutreq->SessionIndex eq session->{spid_session}->session_index) {
            session 'spid_session' => undef;
        } else {
            $status = 'partial';
            warning sprintf "SAML LogoutRequest session (%s) does not match current SPID session (%s)",
                $logoutreq->SessionIndex, session->{spid_session}->session_index;
        }
        
        # Craft a LogoutResponse and send it back to the Identity Provider.
        my $logoutres = $logoutreq->make_response(status => $status);
        redirect $logoutres->redirect_url, 302;
    } else {
        status 400;
    }
};

dance;
 
__END__
