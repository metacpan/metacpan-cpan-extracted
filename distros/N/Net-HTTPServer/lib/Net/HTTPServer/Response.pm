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
package Net::HTTPServer::Response;

=head1 NAME

Net::HTTPServer::Response

=head1 SYNOPSIS

Net::HTTPServer::Response handles formatting the response to the client.
  
=head1 DESCRIPTION

Net::HTTPServer::Response provides a nice OOP interface for easy control
of headers, cookies, sessions, and/or the content that will be sent to
the requesting client.

=head1 EXAMPLES

my $response = new Net::HTTPServer::Response();



my $response = new Net::HTTPServer::Response(code=>200,
                                             headers=>{
                                            );

my $response = $request->Response();

=head1 METHODS

=head2 new(%cfg)

Given a config hash, return a server object that you can start, process,
and stop.  The config hash takes the options:

    body => string      - The contents of the response.
                          ( Default: "" )

    code => int         - The return code of this reponse.
                          ( Default: 200 )
                      
    cookies => hashref  - Hash reference to a set of cookies to send.
                          Most people should just use the Cookie method
                          to set these.
                          ( Default: {} )

    headers => hashref  - Hash reference to the headers to send.  Most
                          people should just use the Header method.
                          ( Default: {} )

=head2 Body([string])

Returns the current value of the response body.  Sets the content of
the response if a value is specified.

=head2 Clear()

Reset the body to "".

=head2 Code(int)

Returns the current value of the response code.  Set the status code
of the response if a value is specified.

=head2 Cookie(name[,value[,%options]])

Returns the cookie value for the specified name, or undef if it is
not set.  If the value is also specified, then the cookie is set
to the value.  The optional hash options that you can provide to
the cookie are:

    domain => string   - If specified, the client will return the
                         cookie for any hostname that is part of
                         the domain.

    expires => string  - When should the cookie expire.  Must be
                         formatted according to the rules:
                             Wednesday, 30-June-2004 18:14:24 GMT
                         Optionally you can specify "now" which
                         will resolve to the current time.
                      
    path => string     - The path on the server that the client should
                         return the cookie for.

    secure => 0|1      - The client will only return the cookie over
                         an HTTPS connection.

=head2 Header(name[,value])

Returns the header value for the specified name, or undef if it is not
set.  If the value is specified, then the header is set to the value.

=head2 Print(arg1[,arg2,...,argN])

Appends the arguments to the end of the body.

=head2 Redirect(url)

Redirect the client to the specified URL.

=head2 Session(object)

Register the Net::HTTPServer::Session object with the response.  When
the server builds the actual reponse to the client it will set the
appropriate cookie and save the session.  If the response is
created from the request object, and there was a session created
from the request object then this, will be prepopulated with that
session.

=head2 CaptureSTDOUT()

If you use the CGI perl module then it wants to print everything to
STDOUT.  CaptureSTDOUT() will put the Reponse object into a mode
where it will capture all the output from the module. See
ProcessSTDOUT() for more information.

=head2 ProcessSTDOUT([%args])

This will harvest all of the data printed to STDOUT and put it into
the Response object via a Print() call.  This will also stop
monitoring STDOUT and release it.  You can specify some options:

  strip_header => 0|1     - If you use the CGI module and you
                            print the headers then ProcessSTDOUT()
                            can try to strip those out.  The best
                            plan is not to print them.
                            
See CaptureSTDOUT() for more information.

=head1 AUTHOR

Ryan Eatmon

=head1 COPYRIGHT

Copyright (c) 2003-2005 Ryan Eatmon <reatmon@mail.com>. All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
  
use strict;
use Carp;
use URI::Escape;
use Net::HTTPServer::CaptureSTDOUT;

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

    $self->{CODE} = $self->_arg("code","200");
    $self->{HEADERS} = $self->_arg("headers",{});
    $self->{COOKIES} = $self->_arg("cookies",{});
    $self->{BODY} = $self->_arg("body","");

    return $self;
}


sub Body
{
    my $self = shift;
    my $body = shift;

    return $self->{BODY} unless defined($body);
    $self->{BODY} = $body;
}


sub Clear
{
    my $self = shift;
    
    $self->{BODY} = "";
}


sub Code
{
    my $self = shift;
    my $code = shift;

    return $self->{CODE} unless defined($code);
    $self->{CODE} = $code;
}


sub Cookie
{
    my $self = shift;
    my $cookie = shift;
    my $value = shift;
    my (%args) = @_;

    return unless (defined($cookie) && defined($value));
    
    $self->{COOKIES}->{$cookie}->{value} = $value;
    if (exists($args{expires}))
    {
        $self->{COOKIES}->{$cookie}->{expires} = $args{expires};
        $self->{COOKIES}->{$cookie}->{expires} = &Net::HTTPServer::_date()
            if ($args{expires} eq "now");
    }
    $self->{COOKIES}->{$cookie}->{domain} = $args{domain}
        if exists($args{domain});
    $self->{COOKIES}->{$cookie}->{path} = $args{path}
        if exists($args{path});
    $self->{COOKIES}->{$cookie}->{secure} = $args{secure}
        if exists($args{secure});
}


sub Header
{
    my $self = shift;
    my $header = shift;
    my $value = shift;

    return unless defined($header);
    $self->{HEADERS}->{$header} = $value if defined($value);
    return unless exists($self->{HEADERS}->{$header});
    return $self->{HEADERS}->{$header};
}


sub Print
{
    my $self = shift;
    
    $self->{BODY} .= join("",@_);
}


sub Redirect
{
    my $self = shift;
    my $url = shift;

    $self->Code(307);
    $self->Clear();
    $self->Header("Location",$url);
}


sub Session
{
    my $self = shift;
    my $session = shift;

    $self->{SESSION} = $session if defined($session);
    return unless exists($self->{SESSION});
    return $self->{SESSION};
}


sub CaptureSTDOUT
{
    my $self = shift; 

    if (tied *STDOUT)
    {
		croak("You cannot call CaptureSTDOUT more than once without calling ProcessSTDOUT");
	}

    tie(*STDOUT, "Net::HTTPServer::CaptureSTDOUT");
}


sub ProcessSTDOUT
{
    my $self = shift; 
    my (%args) = @_;

    my $output = join("",<STDOUT>);

    #--------------------------------------------------------------------------
    # Try and strip out the headers if the user printed any...
    #--------------------------------------------------------------------------
    if (exists($args{strip_header}) && ($args{strip_header} == 1))
    {
        $output =~ s/^.+\015?\012\015?\012//;
    }

    $self->Print($output);

    untie(*STDOUT);
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


sub _build
{
    my $self = shift;

    #-------------------------------------------------------------------------
    # Format the return headers
    #-------------------------------------------------------------------------
    my $header = "HTTP/1.1 ".$self->{CODE}."\n";
    foreach my $key (sort {$a cmp $b} keys(%{$self->{HEADERS}}))
    {
        $header .= "$key: ".$self->{HEADERS}->{$key}."\n";
    }

    #-------------------------------------------------------------------------
    # Session in, cookie out
    #-------------------------------------------------------------------------
    if (exists($self->{SESSION}))
    {
        my $value = $self->{SESSION}->_key();
        my $delta = 4*60*60; # 4 hours from now

        if ($self->{SESSION}->_valid())
        {
            $self->{SESSION}->_save();
        }
        else
        {
            $value = "";
            $delta = -(100*24*60*60); # 100 days ago
        }

        $self->Cookie("NETHTTPSERVERSESSION",
                      $value,
                      expires=>&Net::HTTPServer::_date(time,$delta),
                     );
    }

    #-------------------------------------------------------------------------
    # Mmmm.... Cookies....
    #-------------------------------------------------------------------------
    foreach my $cookie (sort {$a cmp $b} keys(%{$self->{COOKIES}}))
    {
        my $value = uri_escape($self->{COOKIES}->{$cookie}->{value});
        
        $header .= "Set-Cookie: $cookie=$value";
        
        foreach my $key (sort {$a cmp $b} keys(%{$self->{COOKIES}->{$cookie}}))
        {
            next if ($key eq "value");
            if ($key eq "secure")
            {
                if ($self->{COOKIES}->{$cookie}->{$key} == 1)
                {
                    $header .= ";$key";
                }
            }
            else
            {
                $header .= ";$key=".$self->{COOKIES}->{$cookie}->{$key};
            }
        }

        $header .= "\n";
    }

    chomp($header);
    $header .= "\r\n\r\n";

    return ($header,$self->{BODY});
}




1;

