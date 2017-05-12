#Session functions
package PSGI::Hector::Session;

=pod

=head1 NAME

PSGI::Hector::Session - Session class

=head1 SYNOPSIS

	my $s = $hector->getSession();
	$s->setVar('name', 'value');
	my $var = $s->getVar('name');

=head1 DESCRIPTION

Class to deal with session management.

=head1 METHODS

=cut

use strict;
use warnings;
use Digest::MD5;
use Data::Dumper;
use CGI::Simple::Cookie;
use File::Spec;
use parent qw(PSGI::Hector::Base);
our $prefix = "HT";
our $path = "/tmp";
##############################################################################################################################
sub new{	#constructor
	my($class, $hector) = @_;
	my $self = $class->SUPER::new();
	$self->{'_hector'} = $hector;
	$self->{'id'} = undef;
	$self->{'error'} = "";
	$self->{'vars'} = {};
	$self->_readOrCreate();
	return $self;
}
#########################################################################################################################
sub DESTROY{
	__PACKAGE__->_expire();	#remove old sessions
}
#########################################################################################################################
sub validate{	#runs the defined sub to see if this sesion is validate
	my $self = shift;
	if($self->getVar('remoteIp')){
		my $env = $self->_getHector()->getEnv();
		if($self->getVar('remoteIp') eq $env->{'REMOTE_ADDR'}){
			if($self->getVar('scriptPath') && $self->getVar('scriptPath') eq $env->{'SCRIPT_NAME'}){
				return 1;
			}
			else{
				$self->_getHector()->getLog()->log("Session " . $self->getVar('scriptPath') . " <> " . $env->{'SCRIPT_NAME'}, 'debug');
			}
		}
		else{
			$self->_getHector()->getLog()->log("Session " . $self->getVar('remoteIp') . " <> " . $env->{'REMOTE_ADDR'}, 'debug');
		}
	}
	else{
		$self->_getHector()->getLog()->log("Session has no remote IP", 'debug');
	}
	return 0;
}
################################################################################################################

=head2 setVar()

	$s->setVar('name', 'value');

Takes two arguments, first the name of the variable then the value of the variable to store.

=cut

##########################################################################################################################
sub setVar{	#stores a variable in the session
	my($self, $name, $value) = @_;
	$self->_storeVar($name, $value);
	return $self->_write();
}
##########################################################################################################################
sub getVar{	#gets a stored variable from the session
	my($self, $name) = @_;
	if(defined($self->{'vars'}->{$name})){
		return $self->{'vars'}->{$name};
	}
	else{return undef;}
}
###########################################################################################################################
sub setError{
	my($self, $error) = @_;
	$self->{'error'} = $error;	#save the error
	return 1;
}
###########################################################################################################################
sub getError{	#returns the last error
	my $self = shift;
	return $self->{'error'};
}
###########################################################################################################################
sub getId{	#returns the session id
	my $self = shift;
	return $self->{'id'};
}
##############################################################################################################

=head2 create()

	$response = $wf->getResponse();
	my $hashref = {
		username => "bob"
	};
	$s->create($hashref, $response);

Creates a new session for the visitor.

This saves the contents of the given hash reference into the session.

The correct Set-Cookie header will be issued through the provided L<PSGI::Hector::Response> object.

=cut

##############################################################################################################
sub create{	#creates a server-side cookie for the session
	my $self = shift;
	my $result = 0;
	$self->setError("");	#as we are starting a new session we clear any previous errors first
	my $sessionId = time() * $$;	#time in seconds * process id
	my $ctx = Digest::MD5->new;
	$ctx->add($sessionId);
	$sessionId = $self->_getPrefix() . $ctx->hexdigest;
	$self->_setId($sessionId);	#remember the session id
	my $env = $self->_getHector()->getEnv();
	#set some initial values
	$self->_storeVar('remoteIp', $env->{'REMOTE_ADDR'});
	$self->_storeVar('scriptPath', $env->{'SCRIPT_NAME'});
	if(!$self->getError()){	#all ok so far
		my $cookie = $self->_setCookie(VALUE => $self->getId());
		my $response = $self->_getHector()->getResponse();
		$response->header("Set-Cookie" => $cookie);
		$result = 1;
	}
	$result;
}
##############################################################################################################
sub read{	#read an existing session
	my $self = shift;
	my $result = 0;
	my $sessionId = $self->_getHector()->getRequest()->getCookie("SESSION");	#get the session id from the browser
	if(defined($sessionId)){	#got a sessionid of some sort
		my $prefix = $self->_getPrefix();
		if($sessionId =~ m/^($prefix[a-f0-9]+)$/){	#filename valid
			my $path = $self->_getPath();
			my $sessionFile = File::Spec->catfile($path, $1);
			if(open(SSIDE, "<", $sessionFile)){	#try to open the session file
				my $contents = "";
				while(<SSIDE>){	#read each line of the file
					$contents .= $_;
				}
				close(SSIDE);
				if($contents =~ m/^(\$VAR1 = \{.+\};)$/m){	#check session contents
					my $validContents = $1; #untaint variable
					my $VAR1;	#the session contents var
					{
						eval $validContents;
					}
					$self->{'vars'} = $VAR1;
					$result = 1;
					$self->_setId($sessionId);	#remember the session id
				}
				else{
					$self->setError("Session contents invalid");
				}
			}
			else{
				$self->setError("Cant open session file: $sessionFile: $!");
			}
		}
		else{
			$self->setError("Session ID invalid: $sessionId");
		}
	}
	return $result;
}
###########################################################################################

=pod

=head2 delete()

Remove the current session from memory, disk and expire it in the browser.

=cut

###########################################################################################
sub delete{	#remove a session
	my($self, $response) = @_;
	my $result = 0;
	if($response){
		my $sessionId = $self->getId();
		my $prefix = $self->_getPrefix();
		if($sessionId =~ m/^$prefix[a-f0-9]+$/){	#id valid
			my $path = $self->_getPath();
			my $sessionFile = File::Spec->catfile($path, $sessionId);
			if(unlink($sessionFile)){
				$self->_getHector()->getLog()->log("Deleted session: $sessionId", 'debug');
				my $cookie = $self->_setCookie(EXPIRE => 'now');
				$response->header("Set-Cookie" , => $cookie);
				$self = undef;	#destroy this object
				$result = 1;
			}
			else{
				$self->setError("Could not delete session");
			}
		}
		else{
			$self->setError("Session ID invalid: $sessionId");
		}
	}
	else{
		$self->setError("No response given");
	}
	$result;
}
###############################################################################################################
#private class method
###############################################################################################################
sub _getHector{
	my $self = shift;
	return $self->{'_hector'};
}
###########################################################################################################################
sub _setId{
	my($self, $id) = @_;
	$self->{'id'} = $id;	#save the id
	return 1;
}
###############################################################################################################
sub _setCookie{
	my($self, %options) = @_;
	my $secure = 0;
	my $hector = $self->_getHector();
	my $env = $hector->getEnv();
	if(exists($env->{'HTTPS'})){ #use secure cookies if running on ssl
		$secure = 1;
	}
	my $cookie = CGI::Simple::Cookie->new(
		-name => 'SESSION',
		-value => $options{'VALUE'} || undef,
		-expires => $options{'EXPIRE'} || undef,
		-httponly => 1,
		-secure => $secure
	);
	if($cookie){
		return $cookie->as_string();
	}
	else{
		$self->setError("Can't create cookie");
	}
	return undef;
}
##############################################################################################################
sub _expire{	#remove old session files
	my $self = shift;
	my $path = $self->_getPath();
	if(opendir(COOKIES, $path)){
		my @sessions = readdir(COOKIES);
		my $expire = (time - 86400);
		foreach(@sessions){	#check each of the cookies
			my $prefix = $self->_getPrefix();
			if($_ =~ m/^($prefix[a-f0-9]+)$/){	#found a cookie file
				my $sessionFile = File::Spec->catfile($path, $1);
				my @stat = stat($sessionFile);
				if(defined($stat[9]) && $stat[9] < $expire){	#cookie is more than a day old, so remove it
					unlink $sessionFile;
				}
			}
		}
		closedir(COOKIES);
	}
}
############################################################################################################
#private methods
###########################################################################################
sub _write{	#writes a server-side cookie for the session
	my $self = shift;
	my $prefix = $self->_getPrefix();
	if($self->getId() =~ m/^($prefix[a-f0-9]+)$/){	#filename valid
		my $path = $self->_getPath();
		my $sessionFile = File::Spec->catfile($path, $1);
		if(open(SSIDE, ">", $sessionFile)){
			$Data::Dumper::Freezer = 'freeze';
			$Data::Dumper::Toaster = 'toast';
			$Data::Dumper::Indent = 0;	#turn off formatting
			my $dump = Dumper $self->{'vars'};
			if($dump){	#if we have any data
				print SSIDE $dump;
			}
			close(SSIDE);
		}
		else{$self->setError("Cant write session: $!");}
	}
	else{$self->setError('Session ID invalid');}
	if($self->getError()){return 0;}
	else{return 1;}
}
##########################################################################################################################
sub _storeVar{	#stores a variable in the session
	my($self, $name, $value) = @_;
	if(!defined($value)){	#remove the var
		if($self->{'vars'}){	
			my %vars = %{$self->{'vars'}};
			delete $vars{$name};
			$self->{'vars'} = \%vars;
		}
	}
	else{	#update/create a var
		$self->{'vars'}->{$name} = $value;	#store for later
	}
	return 1;
}
#####################################################################################################################
sub _getPrefix{	#this should be a config option
	return $prefix;
}
#####################################################################################################################
sub _getPath{	#this should be a config option
	return $path;
}
#####################################################################################################################
sub _readOrCreate{
	my $self = shift;
	if($self->read() && $self->validate()){
		$self->_getHector()->getLog()->log("Existing session: " . $self->getId(), 'debug');
	}
	elsif($self->create()){	#start a new session
		$self->_getHector()->getLog()->log("Created new session: " . $self->getId(), 'debug');
	}
}
#####################################################################################################################

=pod

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 See Also

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

##########################################
return 1;
END {}
