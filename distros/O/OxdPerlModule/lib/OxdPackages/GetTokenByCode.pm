#!/usr/bin/perl
# GetTokenByCode.pm, a number as an object

package GetTokenByCode;	# This is the &quot;Class&quot;
    use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	use vars qw($VERSION);
    $VERSION = '0.01';
	
	sub new {
		my $class = shift;
		my $self = {
			
			# @var string $request_oxd_id                           This parameter you must get after registration site in gluu-server
			 
			_request_oxd_id => shift,
			
			# @var string $request_code                             This parameter you must get from URL, after redirecting authorization url
			 
			_request_code => shift,
			
			# @var string $request_state                            This parameter you must get from URL, after redirecting authorization url
			 
			_request_state => shift,
			
			# Response parameter from oxd-server
			# It need to using for get_user_info and logout classes
			#
			# @var string $response_access_token
			 
			_response_access_token => shift,
			
			# Response parameter from oxd-server
			# Showing user expires time
			#
			# @var string $response_expires_in
			 
			_response_expires_in => shift,
			
			# Response parameter from oxd-server
			# It need to using for get_user_info and logout classes
			#
			# @var string $response_id_token
			 
			_response_id_token => shift,
			
			# Response parameter from oxd-server
			# Showing user claimses and data
			#
			# @var string $response_expires_in
			 
			_response_id_token_claims => shift,

		
		};
		# Print all the values just for clarification.
		#print "setRequestOxdId is $self->{_request_oxd_id}<br>";
		#print "setRequestCode is $self->{_request_code}<br>";
		#print "setRequestState is $self->{_request_state}<br>";
		bless $self, $class;
		
		return $self;
	} 
	
	
    # @return string
   
    sub getRequestScopes
    {  
		my( $self ) = @_;
		return $self->{_request_scopes};
    }

    
    # @param string $request_scopes
    # @return	void
    
    sub setRequestScopes
    {   
		my ( $self, $request_scopes ) = @_;
		$self->{_request_scopes} = $request_scopes if defined($request_scopes);
		return $self->{_request_scopes};
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
		return $self->{_request_state};
	}

    
    # @return string
    
    sub getRequestCode
    {   
		my( $self ) = @_;
		return $self->{_request_code};
	}

    
    # @param string $request_code
    # @return	void
    
    sub setRequestCode
    {
        my ( $self, $request_code ) = @_;
		$self->{_request_code} = $request_code if defined($request_code);
		return $self->{_request_code};
	}

    
    # @return string
    
    sub getResponseAccessToken
    {   
		my( $self ) = @_;
		$self->{_response_access_token} = $self->getResponseData()->{access_token};
		return $self->{_response_access_token};
	}

    
    # @return string
    
    sub getResponseExpiresIn
    {  
		my( $self ) = @_;
		$self->{_response_expires_in} = $self->getResponseData()->{expires_in};
		return $self->{_response_expires_in};
	}

    
    # @return string
    
    sub getResponseIdToken
    {  
		my( $self ) = @_;
		$self->{_response_id_token} = $self->getResponseData()->{id_token};
		return $self->{_response_id_token};
	}

    
    # @return string
    
    sub getResponseIdTokenClaims
    {
		my( $self ) = @_;
		$self->{_response_id_token_claims} = $self->getResponseData()->{id_token_claims};
		return $self->{_response_id_token_claims};
	}

    
    # Protocol command to oxd server
    # @return void
    
    sub setCommand
    {
		my ( $self, $command ) = @_;
		$self->{_command} = 'get_tokens_by_code';
		return $self->{_command};
	}
    
    # Protocol parameter to oxd server
    # @return void
    
    sub setParams
    {  
		my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "code" => $self->getRequestCode(),
            "state" => $self->getRequestState()
        };
        #use Data::Dumper;
        #print Dumper( $paramsArray );
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }
	 
	
1;		# this 1; is neccessary for our class to work
