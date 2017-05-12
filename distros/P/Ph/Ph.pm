
#
# Ph.pm - a module for talking to CCSO Ph servers
#
# Copyright 1995-1998, Garrett D'Amore. <garrett@yavin.org>
# See the Artistic License for licensing details and use
# agreements.
#
# Important: READ THE Artistic FILE -- it limits my liability
# and provids the specific agreements to which you must agree
# if you use this package.
#
package Ph;

use strict;
use vars qw($VERSION $DefaultPhPort $DefaultPhServer @ISA);

$VERSION = '2.01';
@ISA = qw();

require 5.003;

use IO::Socket;
use Carp;

$DefaultPhPort = "ns(105)";
$DefaultPhServer = "ns";

sub new
{
    my ($class, %arg) = @_;
    return bless \%arg, $class;
}

sub Add
{
    my $self = shift;
    my $entry = shift;
    my $request = "add";

    $request .= $self->_MakeFieldsLine($entry);
    $self->_SendRequest($request);

    return $self->_IsSuccessful($self->_GetCode());
}

sub Change
{
    my $self = shift;
    my ($query,$changes) = @_;
    my $request = "change ";

    $request .= $self->_MakeFieldsLine($query);
    $request .= " make";
    $request .= $self->_MakeFieldsLine($changes);

    $self->_SendRequest($request);

    return $self->_IsSuccessful($self->_GetCode());
}

sub Connect
{
    my $self = shift;
    my $code;
    my ($PhServer, $PhPort) = @_;
    if (!defined $PhServer)
    {
	$PhServer = $DefaultPhServer;
    }
    if (!defined $PhPort)
    {
	$PhPort = $DefaultPhPort;
    }

    my $sock = IO::Socket::INET->new(PeerAddr	=> $PhServer,
				     PeerPort	=> $PhPort,
				     Proto	=> 'tcp');

    if (!defined $sock)
    {
	$self->{last_message} = $@;
	$self->{last_message} =~ s/^IO::Socket::INET/connect/;
	$self->{last_code} = 998;
	return 0;
    }

    # make socket unbuffered, this is the default under 5.004_04
    $sock->autoflush;
    $self->{sock} = $sock;

    # send id -- we send our UNIX account name -- this is not
    # strictly required but it is polite
    $self->_SendRequest("id $<"); 
    $code = $self->_GetCode();

    if (!$self->_IsSuccessful($code))
    {
	return 0;
    }

    # get the database status
    $self->_SendRequest("status");
    return $self->_IsSuccessful($self->_GetCode());
}

sub Delete
{
    my $self	= shift;
    my $entry	= shift;
    my $request = "delete";

    $request .= $self->_MakeFieldsLine($entry);
    $self->_SendRequest($request);

    return $self->_IsSuccessful($self->_GetCode());
}

sub Disconnect
{
    my $self = shift;
    my $code;
    if (defined $self->{sock})
    {
	$self->_SendRequest("quit");
	# we don't care about the value, we just throw it away
	$self->_GetCode();
	close($self->{sock});
	delete $self->{sock};
    }
}

sub ErrorMessage
{
    my $self = shift;
    my $code = shift;

    my %messages =  (
	100	=>     'In progress (general).',
	101	=>     'Echo of current command.',
	102	=>     'Count of number of matches to query.',
	200	=>     'Success (general).',
	201	=>     'Database ready, but read only.',
	300	=>     'More information (general).',
	301	=>     'Encrypt this string.',
	400	=>     'Temporary error (general).',
	401	=>     'Internal database error.',
	402	=>     'Lock not obtained within timeout period.',
	475	=>     'Database unavailable; try later.',
	500	=>     'Permanent error (general).',
	501	=>     'No matches to query.',
	502	=>     'Too many matches to query.',
	503	=>     'Not authorized for requested information.',
	504	=>     'Not authorized for requested search criteria.',
	505	=>     'Not authorized to change requested field.',
	506	=>     'Request refused; must be logged in to execute.',
	507	=>     'Field does not exist.',
	508	=>     'Field is not present in requested entry.',
	509	=>     'Alias already in use.',
	510	=>     'Not authorized to change this entry.',
	511	=>     'Not authorized to add entries.',
	512	=>     'Illegal value.',
	513	=>     'Unknown option.',
	514	=>     'Unknown command.',
	515	=>     'No indexed field in query.',
	516	=>     'No authorization for request.',
	517	=>     'Operation failed because database is read only.',
	518	=>     'Too many entries selected by change command.',
	520	=>     'CPU usage limit exceeded.',
	521	=>     'Change command would have overridden existing field, and the "addonly" option is on.',
	522	=>     'Attempt to view "Encrypted" field.',
	523	=>     'Expecting "answer" or "clear"',
	524	=>     'Names of help topics may not contain "/".',
	598	=>     'Command unknown.',
	599	=>     'Syntax error.',
        995	=>     '[socket failure]',
        996	=>     '[bind failure]',
	997     =>     '[unknown host]',
        998	=>     '[connection failure]',
	999	=>     '[connection closed]'
	);
    return $messages{$code};
}

sub Fields
{
    my $self = shift;
    my %result = ();
    my $name;
    my $code;

    # get the field descriptions
    $self->_SendRequest("fields");
    do
    {
	my @response = $self->_ParseResponse($self->_GetResponse());
	$code = $response[0];
	$name = $response[2];
	# second line is just the description
	if (defined $result{$name})
	{
	    $result{$name}->{desc} = $response[3];
	}
	# first line contains the good stuff
	else
	{
	    my $flag;
	    my @flags = split(/\s+/, $response[3]);

	    $result{$name} = {};
	    $result{$name}->{number} = $response[1];
	    $result{$name}->{name} = $name;

	    foreach $flag (@flags)
	    {
		if ($flag =~ /^\d+$/)
		{
		    $result{$name}->{max} = $flag;
		}
		elsif ($flag eq 'max')
		{
		    # nop
		}
		else
		{
		    $result{$name}->{$flag} = $flag;
		}
	    } # foreach $flag
	} # defined $result{$name}, i.e. end of field description
    } while ($code < 200);
    return ($self->_IsSuccessful($code)) ? %result : undef;
}

sub _IsSuccessful
{
    my $self = shift;
    my $code = shift;
    return (int($code / 100) == 2);
}

sub _GetCode
{
    my $self = shift;
    my $code;
    do
    {
	my @result = $self->_ParseResponse($self->_GetResponse());
	$code = $result[0];
    } while ($code < 200);
    return $code;
}

sub _GetResponse
{
    my $self = shift;
    my $sock = $self->{sock};
    my $response;

    if (!defined $sock)
    {
	$response="999: [no active connection]\n";
    }
    else 
    {
	$response = $sock->getline();
    }

    if (!defined $response)
    {
	$response="999: [connection closed]\n";
	delete $self->{sock};
    }
    chomp $response;
    print STDERR "server> $response\n" if ($self->{Debug});
    return $response;
}

sub GetLastCode
{
    my $self = shift;
    return $self->{last_code};
}

sub GetLastMessage
{
    my $self = shift;
    return $self->{last_message};
}

sub IsConnected
{
    my $self = shift;
    return defined($self->{sock});
}

sub Login
{
    my $self = shift;
    my ($alias, $password) = @_;
    my ($code, $challenge, $answer);

    $self->_SendRequest("login $alias");

    $code = $self->_GetCode();

    # abort if we were not challenged!
    return 0 if $code != 301;

    #
    # unfortunately, I don't know how to answer the challenge
    # Dorner's code is *very* hard to understand!  But if we
    # ever figure it out, here's where we'll put the challenge
    # response.
    #

    # so for now we send the password in the clear (blech!)
    $self->_SendRequest("clear $password");

    # overwrite password to minimize exposure; not sure if
    # this really helps with perl
    $password = "xxxxxxxxxxxxxx";  

    return $self->_IsSuccessful($self->_GetCode());
}

sub Logout
{
    my $self = shift;
    
    $self->_SendRequest("logout");
    return $self->_IsSuccessful($self->_GetCode());
}

sub _MakeFieldsLine
{
    my $self	= shift;
    my $fields	= shift;
    my ($output, $field);

    $output = "";

    if (ref($fields) eq 'HASH')
    {
	foreach $field (keys %$fields)
	{
	    $fields->{$field} =~ s/"/\\"/;
	    $output .= " $field=\"$fields->{$field}\"";
	}
    }
    elsif (ref($fields) eq 'ARRAY')
    {
	foreach $field (@$fields)
	{
	    $output .= " $field";
	}
    }
    else
    {
	$output = " $fields";
    }
    return $output;
}

sub _ParseResponse
{
    my $self = shift;
    my $unparsed = shift;
    my @parsed = split(/: */, $unparsed, 4);
    $self->{last_code} = $parsed[0];
    $self->{last_message} = $parsed[1];
    return @parsed;
}

sub Query
{
    my $self = shift;
    my ($query, $fieldlist) = @_;
    my ($key, $request, $index, @response, $lastfield, $code, $field, $value);
    my @matches = ();

    $index = 0;

    $request = "query";
    $request .= $self->_MakeFieldsLine($query);
    if (defined ($fieldlist))
    {
	$request .= " return";
        $request .= $self->_MakeFieldsLine($fieldlist);
    }
    $self->_SendRequest($request);

    do
    {
	@response = ();
	@response = $self->_ParseResponse($self->_GetResponse());
        $code = $response[0];
        if (defined $response[3])
	{
	    $index = $response[1] - 1;
	    $field = length($response[2]) ? $response[2] : $lastfield;
	    $lastfield = $field;
	    $value = $response[3];

	    if (!defined $matches[$index])
	    {
		$matches[$index] = { };
	    }	

	    if (!defined $matches[$index]->{$field} )
	    {
		$matches[$index]->{$field} = '';
	    }
	    else
	    {
		$matches[$index]->{$field} .= "\n";
	    }

	    $matches[$index]->{$field} .= $value;
	}
    } while ($code < 200);
    return $self->_IsSuccessful($code) ? @matches : undef;
}

sub _SendRequest
{
    my $self = shift;
    my $request = shift;
    my $sock = $self->{sock};
    if (!defined $sock)
    {
	print STDERR "client> [connection not open]\n" if $self->{Debug};
    }
    elsif (print $sock "$request\r\n")
    {
    	print STDERR "client> $request\n" if $self->{Debug};
    }
    else
    {
	print STDERR "client> [connection closed]\n" if $self->{Debug};
	delete $self->{sock};
    }
}

sub SiteInfo
{
    my $self = shift;
    my %results;
    my $code;
    $self->_SendRequest("siteinfo");
    do
    {
	my @response = $self->_ParseResponse($self->_GetResponse());
	if ($response[2])
        {
	    $results{$response[2]} = $response[3];
	}
	$code = $response[0];
    } while ($code < 200);

    return $self->_IsSuccessful($code) ? %results : undef;
}

sub Version
{
    return $VERSION;
}
1;

__END__

=head1 NAME

Ph -- provide a perl API for talking to CSO ph servers.

=head1 SYNOPSIS

    use Ph;

=head1 NOTICE

This version of Ph.pm is not compatbile with pre-2.0 versions.
Users of older versions (primarily at QUALCOMM) will need to
convert their scripts to be compatible with this version of
Ph.pm.  (This was done to make Ph.pm more object-oriented, allowing
multiple connections at once.)

=head1 DESCRIPTION

The B<Ph> module provides a uniform API for I<perl> scripts that need to
talk to CSO ph servers.  It handles many of the messy details automatically.
It also maintains an open connection to the server, minimizing the costs
of repeated openings and closings of server connections (and the associated
costs on the server of repeatedly forking off short-lived processes to service
requests made by the client.)

In order to use the B<Ph> protocol module, you will need to have the
L<IO::Socket> support and associated perl modules installed.  You wil
also need to use perl 5.003 or later. (See L<perl>.)  You should
already be familiar with perl data structures and perl references.  If
not, read L<perldata> and L<perlref>.

It is assumed that you are already familiar with the ph protocol.  If
you are not, please read I<The CCSO Nameserver Server-Client Protocol>
by Steven Dorner and Paul Pomes.  It contains all of the descriptions
of the various ph requests that one can make.  (This API does simplify
the problems associated with parsing server responses.)

=head1 CONSTRUCTOR

=over 4

=item new ( [ARGS])

The constructor takes a number of arguments.

PhServer: Remote Ph server name (default is 'ns').

PhPort:	Remove Ph port (default is 'ns', or '105').

Debug: If set, module debugging is enabled.

=head1 GLOBALS

=item $DefaultPhPort

This constant value is the default port to make connections on if one
is not specified as an argument to C<Connect>.  Its default value
is the value assigned to 'ns' in F</etc/services>, or 105.

=item $DefaultPhServer

The default ph server to use if not specified in the arguments to
C<Connect>.  This defaults to 'ns'.

=head1 METHODS

The following methods are provided as part of the API.

=item Add ENTRY

This is a request to create a B<new> ph record.  The record has
fields with values specified by ENTRY, which can be either a 
reference to an associative array, or it may just be a string itself.
Hero login status is required.  A boolean return indicates whether
the change was successful or not.

=item Change QUERY CHANGES

This is a request to modify existing ph record(s).  The QUERY is a
reference to an associative array, or a query string (Exactly as for
the C<Query> subroutine.)  The CHANGES is another reference to an
associative array (or scalar string), containing the field names to be
changed, and the new values that they are to hold.  The value returned
is the ph result code returned by the server.  B<NOTE>: Fields that
are Encrypted (e.g. password) cannot be changed, yet! I will implement
this as soon as I better understand how the encryption works.  The
return value is a boolean variable indicating whether or not the
change was successful.

=item Connect SERVER PORT

This is a request to establish a connection to a ph server.  In
addition, several other requests are sent to the server.  They are
C<id>, C<siteinfo>, and C<fields>.  The returned values are stored in
variables for use later.  Only one connection to a server can be
active within a perl program at any one time.  Returns truth on
success, false on failure.

=item Delete ENTRY

This deletes an entire B<record> from the ph server.  The record is
selected by the query matching ENTRY, which is either a reference to
an associative array, or a string query specification.  The value
returned is the result code returned by the ph server.  B<USE WITH
CAUTION!> Hero mode is required.  Returns true of false to indicate
successful or failed results.

=item Disconnect

This disconnects from the server.  It sends the C<quit> request before
closing, to be polite to the server.  This is also called
automatically by the package destructor, if necessary.  No return
value is used.

=item ErrorMessage CODE

This returns a string representation of the message associated with
the result code returned by the server.

=item Fields

Returns an associative array containing the field attributes for the
fields defined by the currently connected ph server.   The keys are
the field names, and the values are references to an attribute
description hash:

    name	the field name
    max		the maximum length of the field
    desc	textual description for the field
    *		other flags (e.g. Default, Lookup, Public) for the field

=item GetLastCode

This returns the last positive result code returned by the Ph server.

=item GetLastMessage

This returns the last message returned by the Ph server.  This can be
useful in determining the cause of failure -- it sometimes provides
more detail than is possible with just the GetLastCode value.

=item IsConnected

This returns a boolean value which indicates whether or not an active
connection to a server has been established.

=item Login ALIAS PASSWORD

This request logs into the server, if possible.  It should use the
C<answer> method rather than the less secure C<clear> method to
encrypt the response.  Unfortunately, the F<cryptit.c> file included
with the ph distribution is incredibly, well, I<cryptic>!  I am not
exactly sure what it is doing, and converting it to perl is proving
tiresome. (I have been told that the encryption is based upon a 3-rotor
enigma.  If anyone is feeling ambitious enough to provide a perl
equivalent, I would be happy to fix this routine.)  A truth value is
returned to the caller to indicate whether the login succeeded or not.

=item Logout

Simply put, logout of the ph server!  (Obviously, you must be logged
in first!)  B<CAUTION>: There is a serious bug in some Ph servers
which prevents the logout action from removing any privileges.  A hero
mode session that has been logged out can still destroy the database
(accidentally or on purpose).  This was discovered the hard way by the
author of this package, who had to reenter his entire ph record by
hand after running over this bug!

=cut
# Undocumented internals:
# =item _GetCode
#
# Suck in all result lines until a result code >= 200 is returned.
# (Lines that have continuations are negative values.)  Returns the
# final result code.
#
# =item _MakeFieldsLine FIELDS
#
# This takes a B<reference> to an associative array and returns a string
# of the form " field=value ..." based upon the data in the associative
# array.  If it is passed scalar, it returns the scalar unmodified.
# This subroutine is used to simplify building of query specifications
# from associative arrays, and is primarily intended for internal use.
#
# =item _ParseResponse RESPONSE
# 
# This parses the value returned by C<GetResponse> into an array.  The
# array is built as ( code sub-code field-name field-value ).  Note that
# not all elements will be defined for some responses.  This is an
# intermediate access method, and its direct use in user scripts is not
# recommened.
# 
# =item _SendRequest PH_REQUEST
# 
# This sends a ph request to the server.  PH_REQUEST should be string
# (without any terminating newlines or carriage returns) to send to the
# server.  This provides a low-level way to send protocol to the server.
# Its direct use is not recommended.
# 
# =item _GetResponse
# 
# This reads a single line of text from the server (presumably a server
# response) and returns it.  This provides a low-level access method to
# the Ph server, and its use is not recommended.  It may have to be
# called many times to retrieve all returned lines from the server for a
# single request.  Failure to do this will confuse subsequent
# transactions.
# 
=item Query QUERY FIELDS

This sends a query to the ph server and builds an array containing
references to associative arrays.  These associative arrays correspond
to matching records, with each field of the match represented by a key
in the associative array.  QUERY should be a reference to an
associative array containing the fields to query for.  Alternatively,
it can be a string of the form "field=value ...".

FIELDS is reference to an array containing the names of the fields to
return.  If you want to return all fields, just specify the word
"all".  Otherwise, only default fields provided by the server
returned.  Note that the ph server may enforce certain restrictions
about what fields you can view.

The returned value
will be an array filled with references to associative arrays.  For
example, to obtain the phone number of the first person named "Garrett"
into $phone, you might try this:

	@matches = $Ph->Query("name=garrett", "phone");
	$phone = $matches[0]->{phone};

=item SiteInfo

Returns an associative array containing the results of the C<siteinfo>
ph request for the currently connected server.  Each key corresponds
to a field name in the returned result.

=item Version

This function is used merely to determine the RCS revision number of
the module that you are using.  Newer versions may be posted from time
to time, and this allows you to determine if you are using the latest
version of the Ph module.

=head1 AUTHOR

This module was written entirely in perl by Garrett D'Amore.  It is
Copyright 1995, Qualcomm, Inc.  You can reach the author at the
e-mail address B<garrett@qualcomm.com>.

=cut
