#!/usr/bin/perl
# OxdLogout.pm, a number as an object

package OxdLogout;	# This is the &quot;Class&quot;
    use vars qw($VERSION);
    $VERSION = '0.01';
    
    use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	sub new {
		my $class = shift;
		my $self = {
			
			# @var string $request_oxd_id                             Need to get after registration site in gluu-server
			_request_oxd_id => shift,
			
			# @var string $request_id_token                           Need to get after registration site in gluu-server
			_request_id_token => shift,
			
			# @var string $request_post_logout_redirect_uri           Need to get after registration site in gluu-server
			_request_post_logout_redirect_uri => shift,
			
			# @var string $request_session_state                      Need to get after registration site in gluu-server
			_request_session_state => shift,
			
			# @var string $request_state                              Need to get after registration site in gluu-server
			_request_state => shift,
			
			# Response parameter from oxd-server
			# Doing logout user from all sites
			# @var string $response_claims
			_response_html => shift,
        };
		# Print all the values just for clarification.
		bless $self, $class;
		
		return $self;
	} 
	
	# @return string
    sub getRequestState
    {
        my( $self ) = @_;
		return $self->{_request_state};
    }

    
    # @param string $request_state
    # @return	void
    sub setRequestState
    {
        my ( $self, $request_state ) = @_;
		$self->{_request_state} = $request_state if defined($request_state);
		return $self->{_request_access_token};
	}

    
    # @return string
    sub getRequestSessionState
    {   
		my( $self ) = @_;
		return $self->{_request_session_state};
    }

    
    # @param string $request_session_state
    # @return	void
    sub setRequestSessionState
    {  
		my ( $self, $request_session_state ) = @_;
		$self->{_request_session_state} = $request_session_state if defined($request_session_state);
		return $self->{_request_session_state};
	}

    # @param string $request_post_logout_redirect_uri
    # @return	void
    sub setRequestPostLogoutRedirectUri
    {
        my ( $self, $request_post_logout_redirect_uri ) = @_;
		$self->{_request_post_logout_redirect_uri} = $request_post_logout_redirect_uri if defined($request_post_logout_redirect_uri);
		return $self->{_request_post_logout_redirect_uri};
    }

    
    # @return string
    sub getResponseHtml()
    {   
		my( $self ) = @_;
		$self->{_response_html} = $self->getResponseData()->{url};
		return $self->{_response_html};
    }

    # @return string
    sub getRequestIdToken
    {
        my( $self ) = @_;
		return $self->{_request_id_token};
    }

    
    # @return string
    sub getRequestPostLogoutRedirectUri
    {
        my( $self ) = @_;
		return $self->{_request_post_logout_redirect_uri};
	}

    # @param string $request_id_token
    # @return	void
    sub setRequestIdToken
    {
        my ( $self, $request_id_token ) = @_;
		$self->{_request_id_token} = $request_id_token if defined($request_id_token);
		return $self->{_request_id_token};
	}

    # @return string
    sub getRequestOxdId
    {
        my( $self ) = @_;
		return $self->{_request_oxd_id};
	}

    # @param string $request_oxd_id
    # @return	void
    sub setRequestOxdId
    {   
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
	}
    
    # Protocol command to oxd server
    # @return void
    
    sub setCommand
    {
        my ( $self, $command ) = @_;
		$self->{_command} = 'get_logout_uri';
		return $self->{_command};
	}
    
    # Protocol parameter to oxd server
    # @return void
    sub setParams
    {   
		my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "id_token_hint" => $self->getRequestIdToken(),
            "post_logout_redirect_uri" => $self->getRequestPostLogoutRedirectUri(),
            "state" => $self->getRequestState(),
            "session_state" => $self->getRequestSessionState()
        };
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }
	 
	
1;		# this 1; is neccessary for our class to work
