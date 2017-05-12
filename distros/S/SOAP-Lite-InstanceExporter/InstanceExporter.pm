package SOAP::Lite::InstanceExporter;
#
# Name:  SOAP::Lite::InstanceExporter
#
# Author: Sean Meisner
#
# Usage: use SOAP::Lite::InstanceExporter qw(bareword_objectname, bareword_objectname);
#
# Purpose: Allow SOAP objects to persist in the main package namespace between SOAP calls
#
# Detailed Description: This class is used to provide a SOAP interface wrapped around 
# a reference to an object residing in a package namespace on the server.  SOAP objects
# exported without this wrapper are initialized and destroyed on a per session basis.
# SOAP::Lite::InstanceExporter allows the server to preserve the state of an object across 
# sessions.
#

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.02';

# Set up an array in the package namespace to hold names of objects we 
# will allow an instance of SOAP::Lite::InstanceExporter to access
our @allowedObjects = ();


# CLASS METHODS

# Return the list of object names to which we will allow access
sub allowedObjects
{
	return @allowedObjects;	
}

# Here we store the object names we will allow SOAP to access
sub import
{
	# Test to be sure the array of allowed objects is empty.
	# This hopes to ensure that import can not be called again
	# on the client side to force access to objects we don't 
	# want SOAP clients to be able to access.
	unless (scalar(@allowedObjects))
	{
		push (@allowedObjects, @_);
	} 		
}

# Return list of available objects
sub getAvailableObjects
{
	return @allowedObjects;
}


# Constructor.  We save a reference to an object residing in another package's namespace
# (defaults to main::), and attempt to set up dispatcher methods to access the object's 
# methods from SOAP
sub new 
{
	my $self = shift(@_);
	my $class = ref($self) || $self;
	my $objectname = shift(@_);
	my @requestedMethods;
	my $requestedMethod;
	my $allowedObject;
	my $thisObjectAllowed = 0;

	unless (ref $objectname) # This case handles a string passed in representing
				 # the name of a non-lexically scoped variable
				 # somewhere in the address space of the server. 
	{

		# Check to see that we have permission from the SOAP server
		# to access the object the remote SOAP client wants to access
		foreach $allowedObject (@allowedObjects)
		{
			# exact match: its all good
			if ($allowedObject eq $objectname)
			{
				$thisObjectAllowed = 1;
				last;	
			}	
			# Match when the SOAP client has specified main:: or just :: on the requested 
			# object, but the server allowed an object without package qualification, assuming 
			# the package to default to main
			elsif (($objectname =~ /.*::.*/) && ($allowedObject !~ /.*::.*/) )
			{
				# try sticking a main:: onto allowedObject to match
		     		if ("main::$allowedObject" eq $objectname)
				{
					$thisObjectAllowed = 1;
					last;	
				}	
				# try sticking a :: onto allowedObject to match
				elsif ("::$allowedObject" eq $objectname)
				{
					$thisObjectAllowed = 1;
					last;		
				}		
			}

			# Match when the SOAP server has specified main:: or just :: on the allowed 
			# object, but the client requested an object without package qualification, assuming 
			# the package to default to main
			elsif (($allowedObject =~ /.*::.*/) && ($objectname !~ /.*::.*/) )
			{
				# try sticking a main:: onto $objectname to match
		     		if ($allowedObject eq "main::$objectname")
				{
					$thisObjectAllowed = 1;
					last;	
				}
				# try sticking a :: onto $objectname to match
		     		elsif ($allowedObject eq "::$objectname")
				{
					$thisObjectAllowed = 1;
					last;	
				}				
			}
		}

		unless ($thisObjectAllowed)
		{
			die "Attempting to define a SOAP interface on an object which is not allowed!\n";
		}

		# Prepare a string containing the name of the object we want to wrap to be eval'ed.  
		# We don't know the name of the wrapped object until the InstanceExporter is 
		# instantiated, so we use eval.
	
		# First, check to see if there are ::'s existing in the objectname.  If not, we will
		# assume the object exists in the main namespace.  We can't assume it exists in the 
		# calling package's namespace, as that would put it somewhere in Paul Kulchenko's 
		# SOAP libraries.  This assumption could change in a future version.

		if ($objectname =~ /.*::.*/)
		{
			# if we found a qualifying ::, just stick a $ onto the beginning
			# to make it a valid variable name when given to eval.
			$objectname = "\$$objectname";
		}
		else
		{
			# We found no ::, so append $main:: to the beginning
			$objectname = "\$main::$objectname";
		}

		# Check to see that the object the remote client wants to access has been initialized
		unless (defined eval $objectname && ref eval $objectname)
		{
			die "Attempting to define a SOAP interface on $objectname, which has not been initialized!\n";
		}
	
		# Store a reference to the requested object
		my $objRefstring = "\\"."$objectname";
		$self = bless 
			{
				#objRef => \ eval $objectname
				objRef => eval $objRefstring
			}, $class;
	}
	else	# Special case of a reference being passed in rather than a string..
		# useless to a SOAP client, but we can use it when we want to instantiate
		# an InstanceExporter directly on the server side, to pass a usable
		# reference to a lexically scoped variable to the client.
	{
		$self = bless 
			{
				objRef => $objectname
			}, $class;
	
	}
	
	# Set up methods to dispatch to the contained object
	@requestedMethods = $self->getAvailableMethods();

	foreach $requestedMethod (@requestedMethods)
	{
		$self->generateDispatcher($requestedMethod);
	}

	return $self;
}

# INSTANCE METHODS

# Generate a method to pass a specified call to the contained class.
sub generateDispatcher
{
	my $self = shift(@_);
	my $method = shift(@_);

	# Die if this method is not available in the contained class
	unless ( ${$self->{objRef}}->can($method) )
	{
		die "Requested method $method not available!\n";
	}

	# Check to see if this method has already been generated
	unless ($self->can($method))
	{
		# Prepare a string to be eval'ed.  All $s and @s we wish to appear
		# in the eval'ed subroutine are escaped, while the method name undergoes
		# variable expansion.
		
		#my $methodtemplate = 
		#"
		#sub SOAP::Lite::InstanceExporter::${method} 
		#{
		#	my \$self = shift(\@_);
		#	return \${\$self->{objRef}}->${method}(\@_);
		#}
		#";

		# EXPERIMENTAL: Make InstanceExporters properly handle shared memory segments
		# created with IPC::Shareable
		my $methodtemplate = 
		"
		sub SOAP::Lite::InstanceExporter::${method} 
		{
			my \$self = shift(\@_);
			my \$returnvalue;
		
			# Handle shared memory correctly
			my \$sharedmemoryhandle = (tied \${\$self->{objRef}});
			if ( defined \$sharedmemoryhandle )
			{
				# Check if we can call shlock, if so call it
				if (\$sharedmemoryhandle->can(shlock))
				{
					\$sharedmemoryhandle->shlock()		
				}
		
				# Call the method
				\$returnvalue =	\${\$self->{objRef}}->${method}(\@_);	
		
				# Check if we can call shunlock, if so call it
				if (\$sharedmemoryhandle->can(shunlock))
				{
					\$sharedmemoryhandle->shunlock()		
				}
		
				return \$returnvalue;
		
			}
			 
			# If we got to this line, we are not dealing with shared 
			# memory so just call the method and return
			return \${\$self->{objRef}}->${method}(\@_);
		}
		";

		# Declare our subroutine
		eval $methodtemplate;
	}
}


# Return list of available methods for this instance
sub getAvailableMethods
{
	my $self = shift(@_);
	my $packageName = ref(${$self->{objRef}});
	my @availableMethods = ();

	my %stash;
	my $varName;
	my $globValue;
	my $evalstring = "\%stash = \%${packageName}::"; 
		
	eval $evalstring;  # %stash now contains the symbol table
			   # for the class of which ${$self->{objRef}} 
			   # is an instance.

	while (($varName) = each %stash)  # Iterate through each symbol name
						      # in the stash
	{
		# Check each to see if it refers
		# to a subroutine
		if (${$self->{objRef}}->can($varName))
		{
			push(@availableMethods,$varName);	
		}
	}
	@availableMethods;
}

1; 

# End of the code
__END__

#
# POD DOCUMENTATION
#

=head1 NAME

SOAP::Lite::InstanceExporter.pm 

=head1 SYNOPSIS

use SOAP::Lite::InstanceExporter qw(bareword_objectname1,..,bareword_objectnameN);

=head1 PURPOSE

Purpose: Allow SOAP objects to persist in the main package namespace on a SOAP server
         between client sessions

=head1 DESCRIPTION

This class is used to provide a SOAP interface wrapped around 
a reference to an object residing in a package namespace on the server.  
SOAP objects exported without this wrapper are initialized and destroyed on 
a per session basis.  SOAP::Lite::InstanceExporter allows the server to preserve the state 
of an object across sessions.  Used in conjunction with SOAP::Lite object_by_reference 
feature.

=head1 METHODS

B<new> (I<bareword_object_name>)

Call new from a SOAP client, passing in the name of the remote object instance you wish 
to access.  Do not attach a $ to the beginning of the requested object name, this parameter
should just be a string.

B<getAvailableObjects>

Returns a list of all the objects to which SOAP::Lite::InstanceExporter is allowing access

B<getAvailableMethods>

Returns a list of available methods which may be called on this instance


=head1 EXAMPLES

See examples/server.pl and examples/client.pl for a trivial example of SOAP::Lite::InstanceExporter use.

=head1 LICENSE

Copyright (c) 2003 Sean Meisner. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 SEE ALSO

L<SOAP::Lite>

=head1 AUTHOR

Sean Meisner

=cut
