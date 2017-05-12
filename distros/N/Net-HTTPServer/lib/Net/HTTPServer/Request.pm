##############################################################################
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA  02111-1307, USA.
#
#  Copyright (C) 2003-2005 Ryan Eatmon
#
##############################################################################
package Net::HTTPServer::Request;

=head1 NAME

Net::HTTPServer::Request

=head1 SYNOPSIS

Net::HTTPServer::Request handles the parsing of a request.
  
=head1 DESCRIPTION

Net::HTTPServer::Request takes a full request, parses it, and then provides
a nice OOP interface to pulling out the information you want from a request.

=head1 METHODS

=head2 Cookie([cookie])

Returns a hash reference of cookie/value pairs.  If you specify a cookie,
then it returns the value for that cookie, or undef if it does not exist.

=head2 Env([var])

Returns a hash reference of variable/value pairs.  If you specify a
variable, then it returns the value for that variable, or undef if it does
not exist.

=head2 Header([header])

Returns a hash reference of header/value pairs.  If you specify a header,
then it returns the value for that header, or undef if it does not exist.

=head2 Method()

Returns the method of the request (GET,POST,etc...)

=head2 Path()

Returns the path portion of the URL.  Does not include any query
strings.

=head2 Procotol()

Returns the name and revision that the request came in with.

=head2 Query()

Returns the query portion of the URL (if any).  You can combine the Path
and the Query with a ? to get the real URL that the client requested.

=head2 Request()

Returns the entire request as a string.

=head2 Response()

Returns a Net::HTTPServer::Response object with various bits prefilled
in.  If you have created session via the Session() method, then the
session will already be registered with the response.

=head2 Session()

Create a new Net::HTTPServer::Session object.  If the cookie value is set,
then the previous state values are loaded, otherwise a new session is
started.

=head2 URL()

Returns the URL of the request.

=head1 AUTHOR

Ryan Eatmon

=head1 COPYRIGHT

Copyright (c) 2003-2005 Ryan Eatmon <reatmon@mail.com>. All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
  
use strict;
use Carp;
use URI;
use URI::QueryParam;
use URI::Escape;

use vars qw ( $VERSION );

$VERSION = "1.0.3";

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = { };
    
    bless($self, $proto);

    my (%args) = @_;

    $self->{ARGS} = \%args;

    $self->{HEADERS} = {};
    $self->{ENV} = {};
    $self->{COOKIES} = {};
    $self->{FAILURE} = "";
    $self->{CHROOT} = $self->_arg("chroot",1);
    $self->{REQUEST} = $self->_arg("request",undef);
    $self->{SERVER} = $self->_arg("server",undef);

    $self->_parse() if defined($self->{REQUEST});

    return $self;
}


sub Cookie
{
    my $self = shift;
    my $cookie = shift;

    return $self->{COOKIES} unless defined($cookie);
    return unless exists($self->{COOKIES}->{$cookie});
    return $self->{COOKIES}->{$cookie};
}


sub Env
{
    my $self = shift;
    my $env = shift;

    return $self->{ENV} unless defined($env);
    return unless exists($self->{ENV}->{$env});
    return $self->{ENV}->{$env};
}


sub Header
{
    my $self = shift;
    my $header = shift;

    return $self->{HEADERS} unless defined($header);
    return unless exists($self->{HEADERS}->{lc($header)});
    return $self->{HEADERS}->{lc($header)};
}


sub Method
{
    my $self = shift;

    return $self->{METHOD};
}


sub Path
{
    my $self = shift;

    return $self->{PATH};
}


sub Protocol
{
    my $self = shift;

    return $self->{PROTOCOL};
}


sub Query
{
    my $self = shift;

    return $self->{QUERY};
}


sub Request
{
    my $self = shift;

    return $self->{REQUEST};
}


sub Response
{
    my $self = shift;

    my $response = new Net::HTTPServer::Response();

    if (exists($self->{SESSION}))
    {
        $response->Session($self->{SESSION});
    }

    return $response;
}


sub Session
{
    my $self = shift;

    return unless $self->{SERVER}->{CFG}->{SESSIONS};
    
    if (!exists($self->{SESSION}))
    {
        my $cookie = $self->Cookie("NETHTTPSERVERSESSION");
    
        $self->{SESSION} =
            new Net::HTTPServer::Session(key=>$cookie,
                                         server=>$self->{SERVER},
                                        );
    }

    return $self->{SESSION};
}


sub URL
{
    my $self = shift;

    return $self->{URL};
}


###############################################################################
#
# _arg - if the arg exists then use it, else use the default.
#
###############################################################################
sub _arg
{
    my $self = shift;
    my $arg = shift;
    my $default = shift;

    return (exists($self->{ARGS}->{$arg}) ? $self->{ARGS}->{$arg} : $default);
}


###############################################################################
#
# _chroot - take the path and if we are running under chroot, massage it so
#           that is cannot leave DOCROOT.
#
###############################################################################
sub _chroot
{
    my $self = shift;
    my $url = shift;

    return $url unless $self->{CHROOT};
    
    my $change = 1;
    while( $change )
    {
        $change = 0;
        
        #-----------------------------------------------------------------
        # Look for multiple / in a row and make them one /
        #-----------------------------------------------------------------
        while( $url =~ s/\/\/+/\// ) { $change = 1; }
    
        #-----------------------------------------------------------------
        # look for something/.. and remove it
        #-----------------------------------------------------------------
        while( $url =~ s/[^\/]+\/\.\.(\/|$)// ) { $change = 1; }

        #-----------------------------------------------------------------
        # Look for ^/.. and remove it
        #-----------------------------------------------------------------
        while( $url =~ s/^\/?\.\.(\/|$)/\// ) { $change = 1; }
        
        #-----------------------------------------------------------------
        # Look for /.../ and make it /
        #-----------------------------------------------------------------
        while( $url =~ s/(^|\/)\.+(\/|$)/\// ) { $change = 1; }
    }

    return $url;
}


sub _failure
{
    my $self = shift;

    return $self->{FAILURE};
}


sub _env
{
    my $self = shift;
    my $env = shift;
    my $value = shift;

    $self->{ENV}->{$env} = $value;
}


sub _parse
{
    my $self = shift;

    ($self->{METHOD},$self->{URL},$self->{PROTOCOL}) = ($self->{REQUEST} =~ /(\S+)\s+(\S+)\s+(.+?)\015?\012/s);
    
    my $uri = new URI($self->{URL},"http");

    #-------------------------------------------------------------------------
    # What did they ask for?
    #-------------------------------------------------------------------------
    $self->{PATH} = $self->_chroot($uri->path());

    my ($headers,$body) = ($self->{REQUEST} =~ /^(.+?)\015?\012\015?\012(.*?)$/s);
    
    my $last_header = "";
    foreach my $header (split(/[\r\n]+/,$headers))
    {
        my $folded;
        my $key;
        my $value;
        
        ($folded,$value) = ($header =~ /^(\s*)(.+?)\s*$/);
        if ($folded ne "")
        {
            $self->{HEADERS}->{lc($last_header)} .= $value;
            next;
        }
        
        ($key,$value) = ($header =~ /^([^\:]+?)\s*\:\s*(.+?)\s*$/);
        next unless defined($key);

        $last_header = $key;
        
        $self->{HEADERS}->{lc($key)} = $value;

        if ((lc($key) eq "expect") && ($value ne "100-continue"))
        {
            $self->{FAILURE} = "expect";
            return;
        }
    }

    #-------------------------------------------------------------------------
    # Did they send any ?xxx=yy on the URL?
    #-------------------------------------------------------------------------
    $self->{QUERY} = $uri->query();
    foreach my $key ($uri->query_param())
    {
        $self->{ENV}->{$key} = $uri->query_param($key);
    }

    #-------------------------------------------------------------------------
    # If this was POST, then the body contains more xxx=yyyy
    #-------------------------------------------------------------------------
    if ($self->{METHOD} eq "POST")
    {
        my $post_uri = new URI("?$body","http");

        foreach my $key ($post_uri->query_param())
        {
            $self->{ENV}->{$key} = $post_uri->query_param($key);
        }
    }

    #-------------------------------------------------------------------------
    # Finally, parse out any cookies.
    #-------------------------------------------------------------------------
    if (exists($self->{HEADERS}->{cookie}))
    {
        foreach my $cookie ( split( /\s*;\s*/,$self->{HEADERS}->{cookie}) )
        {
            my ($name,$value) = split("=",$cookie,2);
            $self->{COOKIES}->{$name} = uri_unescape($value);
        }
    }
}



1;

