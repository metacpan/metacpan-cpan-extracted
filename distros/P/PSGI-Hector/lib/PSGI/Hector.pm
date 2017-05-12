#main framework object
package PSGI::Hector;

=pod

=head1 NAME

PSGI::Hector - Very simple PSGI web framework

=head1 SYNOPSIS

	my $app = App->init({
		'responsePlugin' => 'Some::Class',
	});
	###########################
	###########################
	package App;
	use PSGI::Hector;
	use parent qw(PSGI::Hector);
	###########################
	sub handleDefault{
		#add code here for landing page
	}

=head1 DESCRIPTION

All action subs are passed a L<PSGI::Hector> object as the only parameter, from this you should be able to reach
everything you need.

=head1 METHODS

=cut

use strict;
use warnings;
use File::Basename;
use Class::Load qw(is_class_loaded);
use parent qw(PSGI::Hector::Base PSGI::Hector::Utils);
use PSGI::Hector::Response;
use PSGI::Hector::Session;	#for session management
use PSGI::Hector::Request;
use PSGI::Hector::Log;
our $VERSION = "1.9";
#########################################################

=head2 init(\%options)

	my $options = {
		'responsePlugin' => 'Some::Class',
		'checkReferer' => 0,
		'sessionClass' => 'Some::Class',
		'requestClass' => 'Some::Class',
		'sefUrls' => 0,
		'debug' => 1
	};
	my $h = PSGI::Hector->init($options);
	
Factory class method, used in creating the application from the F<app.psgi> file. The return value 
from this method can be used where ever $app would be used.

This hash reference passed to the method contains any general options for the framework.

=cut

#########################################################
sub init{
	my($class, $options) = @_;
	return sub {
		my $env = shift;
		my $h = $class->new($options, $env);
		return $h->run();	#do this thing!
	};
}
#########################################################

=head2 new(\%options, \%env)

	my $options = {};
	my $h = PSGI::Hector->new($options, $env);

Constructor, requires a hash references of options to be passed and the PSGI environment. 

Usually this method is invoked from the init() class method.

=cut

#########################################################
sub new{
	my($class, $options, $env) = @_;
	if($options->{'responsePlugin'}){	#this option is mandatory
		my $self = $class->SUPER::new();
		$self->{'_env'} = $env;
		$self->{'_options'} = $options;
		my $requestClass = $self->__getFullClassName("Request");
		if($self->getOption('requestClass')){
			$requestClass = $self->getOption('requestClass');
		}
		if(!defined($self->getOption('debug'))){	#turn off debugging by default
			$self->_setOption("debug", 0);
		}
		$self->{'_request'} = $requestClass->new($env);
		$self->{'_response'} = PSGI::Hector::Response->new($self, $self->getOption('responsePlugin'));	#this could need access to a request object	
		$self->{'_log'} = PSGI::Hector::Log->new({
			'debug' => $self->getOption('debug')
		});
		$self->_init();	#perform initial setup
		return $self;
	}
	else{
		die("No response plugin option provided");
	}
	return undef;
}
#########################################################

=pod

=head2 getResponse()

	my $response = $h->getResponse();

Returns the current instance of the response plugin object, previously defined in the constructor options.
See L<PSGI::Hector::Response> for more details.

=cut

###########################################################
sub getResponse{
	my $self = shift;
	return $self->{'_response'};
}
#########################################################

=pod

=head2 getSession()

	my $session = $h->getSession();

Returns the current instance of the L<PSGI::Hector::Session> object.

=cut

###########################################################
sub getSession{
	my $self = shift;
	if(!$self->{'_session'}){
		my $sessionClass = $self->__getFullClassName("Session");
		if($self->getOption('sessionClass')){
			$sessionClass = $self->getOption('sessionClass');
		}
		$self->{'_session'} = $sessionClass->new($self);		
	}
	return $self->{'_session'};
}
#########################################################

=pod

=head2 getRequest()

	my $request = $h->getRequest();

Returns the current instance of the L<PSGI::Hector::Request> object.

=cut

###########################################################
sub getRequest{
	my $self = shift;
	my $request = $self->{'_request'};
	if(!$request){
		die("No request object found");
	}
	return $request;
}
#########################################################

=pod

=head2 getLog()

	my $logger = $h->getLog();

returns an current instance of the L<PSGI::Hector::Log> object.

=cut

#########################################################
sub getLog{
	return shift->{'_log'};
}
#########################################################

=pod

=head2 getAction()

	my $action = $h->getAction();

Returns the curent action that the web application is performing. This is the current value of the "action"
request form field or query string item.

If search engine friendly URLs are turned on the action will be determined from the last part of the script URL.

=cut

###########################################################
sub getAction{
	my $self = shift;
	my $action = "default";
	my $request = $self->getRequest();
	my $params = $request->getParameters();
	if(defined($params->{'action'})){	#get action from query string or post string
		$action = $params->{'action'};
	}
	else{	#do we have search engine friendly urls
		my $sefAction = $self->_getSefAction();
		if($sefAction){
			$action = $sefAction;
		}
	}
	return $action;	
}
#########################################################

=pod

=head2 getUrlForAction($action, $queryString)

	my $url = $h->getUrlForAction("someAction", "a=b&c=d");

Returns the URL for the application with the given action and query string.

=cut

#########################################################
sub getUrlForAction{
	my($self, $action, $query) = @_;
	my $url = "/" . $action;
	if($query){	#add query string
		$url .= "?" . $query;
	}
	return $url;
}
#########################################################

=pod

=head2 getFullUrlForAction($action, $queryString)

	my $url = $h->getFullUrlForAction("someAction", "a=b&c=d");

Returns the Full URL for the application with the given action and query string and hostname.

=cut

#########################################################
sub getFullUrlForAction{
	my($self, $action, $query) = @_;
	$self->getSiteUrl() . $self->getUrlForAction($action, $query);
}
#########################################################

=pod

=head2 run()

	$h->run();

This methood is required for the web application to deal with the current request.
It should be called after any setup is done.

If the response object decides that the response has not been modified then this 
method will not run any action functions.

The action sub run will be determined by first checking the actions hash if previously
given to the object then by checking if a method prefixed with "handle" exists in the
current class.

=cut

###########################################################
sub run{	#run the code for the given action
	my $self = shift;
	my $response = $self->getResponse();
	if($response->code() != 304){	#need to do something
		$self->getLog()->log("Need to run action sub", 'debug');
		my $action = $self->getAction();	
		$self->getLog()->log("Using action: '$action'", 'debug');
		my $subName = "handle" . ucfirst($action);	#add prefix for security
		my $class = ref($self);
		if($class->can($subName)){	#default action sub exists
			eval{
				$self->$subName();
			};
			if($@){	#problem with sub
				$response->setError($@);
			}
		}
		else{	#no code to execute
			$response->code(404);
			$response->message('Not Found');
			$response->setError("No action found for: $action");
		}
	}
	return $response->display();	#display the output to the browser
}
##########################################################

=pod

=head2 getOption("key")

	my $value = $h->getOption("debug");

Returns the value of the configuration option given.

=cut

##########################################################
sub getOption{
	my($self, $key) = @_;
	my $value = undef;
	if(defined($self->{'_options'}->{$key})){	#this config option has been set
		$value = $self->{'_options'}->{$key};
	}
	return $value;
}
##########################################################
sub getEnv{
    my $self = shift;
    return $self->{'_env'};
}
###########################################################
# Private methods
#########################################################
sub __getFullClassName{
	my($self, $name) = @_;
	no strict 'refs';
	my $class = ref($self);
	my $baseClass = @{$class . "::ISA"}[0];	#get base classes
	my $full = $baseClass . "::" . $name;	#default to base class
	if(is_class_loaded($class . "::" . $name)){
		$full = $class . "::" . $name
	}
	return $full;
}
#########################################################
sub __getActionDigest{
	my $self = shift;
	my $sha1 = Digest::SHA1->new();
	$sha1->add($self->getAction());
	return $sha1->hexdigest();
}
###########################################################
sub _getSefAction{
	my $self = shift;
	my $action = undef;
	my $env = $self->getEnv();
	if(defined($env->{'PATH_INFO'}) && $env->{'PATH_INFO'} =~ m/\/(.+)$/){	#get the action from the last part of the url
		$action = $1;
	}
	return $action;
}
###########################################################
sub _init{	#things to do when this object is created
	my $self = shift;
	if(!defined($self->getOption('checkReferer')) || $self->getOption('checkReferer')){	#check the referer by default
		$self->_checkReferer();	#check this first
	}
	return 1;
}
###########################################################
sub _checkReferer{	#simple referer check for very basic security
	my $self = shift;
	my $result = 0;
	my $env = $self->getEnv();
	my $host = $env->{'HTTP_HOST'};
	if($host && $env->{'HTTP_REFERER'} && $env->{'HTTP_REFERER'} =~ m/^(http|https):\/\/$host/){	#simple check here
		$result = 1;
	}
	else{
		my $response = $self->getResponse();
		$response->setError("Details where not sent from the correct web page");
	}
	return $result;
}
##########################################################
sub _getActions{
	my $self = shift;
	return $self->{'_actions'};
}
###########################################################
sub _setOption{
	my($self, $key, $value) = @_;
	$self->{'_options'}->{$key} = $value;
	return 1;
}
##########################################################
sub _getScriptName{ #returns the basename of the running script
	my $self = shift;
	my $env = $self->getEnv();
	my $scriptName = $env->{'REQUEST_URI'};
	if($scriptName){
		return basename($scriptName);
	}
	else{
		die("Cant find scriptname, are you running a CGI");
	}
	return undef;
}
###########################################################

=pod

=head1 CONFIGURATION SUMMARY

The following list gives a summary of each Hector 
configuration options. 

=head3 responsePlugin

A scalar string consisting of the response class to use.

See L<PSGI::Hector::Response::Base> for details on how to create your own response class, or
a list of response classes provided in this package.

=head3 checkReferer

Flag to indicate if referer checking should be performed. When enabled an
error will raised when the referer is not present or does not contain the server's
hostname.

This option is enabled by default.

=head3 sessionClass

A scalar string consisting of the session class to use. Useful if you want to change the way
session are stored.

Defaults to ref($self)::Session

=head3 requestClass

A scalar string consisting of the request class to use. Useful if you want to change the way
requests are handled.

Defaults to ref($self)::Request

=head3 sefUrls

A boolean value indicating if search engine friendly URLs are to be used.

=head3 debug

A boolean value indicating if debug mode is enabled. This can then be used in output views or code to print extra debug.

=head1 Notes

To change the session prefix characters use the following code at the top of your script:

	$PSGI::Hector::Session::prefix = "ABC";
	
To change the session file save path use the following code at the top of your script:

	$PSGI::Hector::Session::path = "/var/tmp";
	
=head2 Reverse proxies

To run your application behind a reverse proxy using apache, please use the following setup:

	<Location /psgi>
		RequestHeader set X-Forwarded-Script-Name /psgi
		RequestHeader set X-Traversal-Path /
		ProxyPass http://localhost:8080/
		ProxyPassReverse http://localhost:8080/
	</Location>

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 See Also

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

###########################################################
return 1;
