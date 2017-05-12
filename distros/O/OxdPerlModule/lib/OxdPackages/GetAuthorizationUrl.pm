#!/usr/bin/perl
# GetAuthorizationUrl.pm, a number as an object

##########################################
# Oxd client update site registration class
#
# Class is connecting to oXD-server via socket, and updating registered site data in gluu server.
#
# @package		Gluu-oxd-library
# @subpackage	Libraries
# @category	Relying Party (RP) and User Managed Access (UMA)
# @author		Ourdesignz
# @author		inderpal6785@gmail.com
# @see	        OxdClientSocket
# @see	        OxdClient
# @see	        OxdConfig
#######################################

use JSON::PP;

package GetAuthorizationUrl;	
	use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	#use base 'OxdClient';
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	use vars qw($VERSION);
    $VERSION = '0.01';
	
	sub new {
		my $class = shift;
		
		my $self = {
			
			# @var string $request_oxd_id                          This parameter you must get after registration site in gluu-server
			
			_request_oxd_id => shift,
			
			# @var array $request_scope                            May be skipped (by default takes scopes that was registered during register_site command)
			
			_request_scope => shift,
			
			# @var array $request_acr_values                        It is gluu-server login parameter type
			
			_request_acr_values => shift,
			
			# @var string $request_prompt                           Skipped if no value specified or missed. prompt=login is required if you want to force alter current user session (in case user is already logged in from site1 and site2 construsts authorization request and want to force alter current user session)
			
			_request_prompt => shift,
			
			# @var string $request_prompt                           Hosted domain google OP parameter https://developers.google.com/identity/protocols/OpenIDConnect#hd-param
			
			_request_hd => shift,

			
			# It is authorization url to gluu server.
			# After getting this parameter go to that url and you can login to gluu server, and get response about your users
			# @var string $response_authorization_url
			
			_response_authorization_url => shift
		
		};
		
		bless $self, $class;
		return $self;
	}  
	
    
    
    # @return string
    
    sub getRequestOxdId
    {  
		my( $self ) = @_;
        return $self->{_request_oxd_id};
    }

    
    # @param string $request_oxd_id
    # @return void
    
    sub setRequestOxdId
    {  
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
		
    }

    
    # @return array
    
    sub getRequestAcrValues
    {   
		my( $self ) = @_;
        return $self->{_request_acr_values};
    }

    
    # @param array $request_acr_values
    # @return void
    
    sub setRequestAcrValues
    {   
		my ( $self, $request_acr_values ) = @_;
		$self->{_request_acr_values} = $request_acr_values if defined($request_acr_values);
		return $self->{_request_acr_values};
	}

    
    # @return array
    
    sub getRequestScope
    {
        my( $self ) = @_;
        return $self->{_request_scope};
    }

    
    # @param array $request_scope
    
    sub setRequestScope
    {
		my ( $self, $request_scope ) = @_;
		$self->{_request_scope} = $request_scope if defined($request_scope);
		return $self->{_request_scope};
	}

    
    # @return string
    
    sub getRequestPrompt
    {
		my( $self ) = @_;
        return $self->{_request_prompt};
    }

    
    # @param string $request_prompt
    
    sub setRequestPrompt
    {
		my ( $self, $request_prompt ) = @_;
		$self->{_request_prompt} = $request_prompt if defined($request_prompt);
		return $self->{_request_prompt};
	}

    
    # @return string
    
    sub getRequestHd
    {   
		my( $self ) = @_;
        return $self->{_request_hd};
    }

    
    # @param string $request_hd
    
    sub setRequestHd
    {   
		my ( $self, $request_hd ) = @_;
		$self->{_request_hd} = $request_hd if defined($request_hd);
		return $self->{_request_hd};
	}

    
    # @return string
    
    sub getResponseAuthorizationUrl
    {
		my( $self ) = @_;
		$self->{_response_authorization_url} = $self->getResponseData()->{authorization_url};
        return $self->{_response_authorization_url};
    }
    
    # Protocol command to oxd server
    # @return void
    
    sub setCommand
    {
        my ( $self, $request_hd ) = @_;
		$self->{_command} = 'get_authorization_url';
		return $self->{_command};
    }
    
    # Protocol parameter to oxd server
    # @return void
    
    sub setParams
    {   
		my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "scope" => $self->getRequestScope(),
            "acr_values" => $self->getRequestAcrValues(),
            "prompt" => $self->getRequestPrompt(),
            "hd" => $self->getRequestHd()
        };
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }	

1;		# this 1; is neccessary for our class to work
