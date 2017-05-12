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
package Net::HTTPServer::Session;

=head1 NAME

Net::HTTPServer::Session

=head1 SYNOPSIS

Net::HTTPServer::Session handles server side client sessions
  
=head1 DESCRIPTION

Net::HTTPServer::Session provides a server side data store for client
specific sessions.  It uses a cookie stored on the browser to tell
the server which session to restore to the user.  This is modelled
after the PHP session concept.  The session is valid for 4 hours from
the last time the cookie was sent.

=head1 EXAMPLES

sub pageHandler
{
    my $request = shift;
    
    my $session = $request->Session();

    my $response = $request->Response();

    # Logout
    $session->Destroy() if $request->Env("logout");

    $response->Print("<html><head><title>Hi there</title></head><body>");
    
    # If the user specified a username on the URL, then save it.
    if ($request->Env("username"))
    {
        $session->Set("username",$request->Env("username"));
    }
    
    # If there is a saved username, then use it.
    if ($session->Get("username"))
    {
        $response->Print("Hello, ",$session->Get("username"),"!");
    }
    else
    {
        $response->Print("Hello, stranger!");
    }

    $response->Print("</body></html>");

    return $response;
}

The above would behave as follows:

  http://server/page                - Hello, stranger!
  http://server/page?username=Bob   - Hello, Bob!
  http://server/page                - Hello, Bob!
  http://server/page?username=Fred  - Hello, Fred!
  http://server/page                - Hello, Fred!
  http://server/page?logout=1       - Hello, stranger!
  http://server/page                - Hello, stranger!

=head1 METHODS

=head2 Delete(var)

Delete the specified variable from the session.

=head2 Destroy()

Destroy the session.  The server side data is deleted and the cookie
will be expired.

=head2 Exists(var)

Returns if the specified variable exists in the sesion.

=head2 Get(var)

Return the value of the specified variable from the session if it
exists, undef otherwise.

=head2 Set(var,value)

Store the specified value (scalar or reference to any Perl data
structure) in the session.

=head1 AUTHOR

Ryan Eatmon

=head1 COPYRIGHT

Copyright (c) 2003-2005 Ryan Eatmon <reatmon@mail.com>. All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
  
use strict;
use Carp;
use Data::Dumper;

use vars qw ( $VERSION $SESSION_COUNT %data );

$VERSION = "1.0.3";

$SESSION_COUNT = 0;

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = { };
    
    bless($self, $proto);

    my (%args) = @_;
    
    $self->{ARGS} = \%args;

    $self->{KEY} = $self->_arg("key",undef);
    $self->{SERVER} = $self->_arg("server",undef);

    return unless $self->{SERVER}->{CFG}->{SESSIONS};

    $self->{KEY} = $self->_genkey()
        if (!defined($self->{KEY}) ||
            ($self->{KEY} eq "") ||
            ($self->{KEY} =~ /\//)
           );

    $self->{FILE} = $self->{SERVER}->{CFG}->{DATADIR}."/".$self->{KEY};
    
    #XXX Check that server (Net::HTTPServer object) is defined
    
    $self->{VALID} = 1;
    $self->{DATA} = {};
    $self->_load();

    return $self;
}


sub Delete
{
    my $self = shift;
    my $var = shift;

    return unless $self->Exists($var);
    delete($self->{DATA}->{$var});
}


sub Destroy
{
    my $self = shift;

    $self->{VALID} = 0;
}


sub Exists
{
    my $self = shift;
    my $var = shift;

    return unless $self->_valid();
    return exists($self->{DATA}->{$var});
}


sub Get
{
    my $self = shift;
    my $var = shift;

    return unless $self->Exists($var);
    return $self->{DATA}->{$var};
}


sub Set
{
    my $self = shift;
    my $var = shift;
    my $value = shift;

    return unless $self->_valid();
    $self->{DATA}->{$var} = $value if defined($value);
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


sub _genkey
{
    my $self = shift;

    $SESSION_COUNT++;
    my $key = "NetHTTPServerSession".$SESSION_COUNT.$$.time;

    if ($Net::HTTPServer::DigestMD5 == 1)
    {
        $key = Digest::MD5::md5_hex($key);
    }

    return $key;
}


sub _key
{
    my $self = shift;

    return $self->{KEY};
}


sub _load
{
    my $self = shift;

    return unless $self->_valid();

    return unless (-f $self->{FILE});

    undef(%data);
    
    my $data;
    open(DATA,$self->{FILE}) || return;
    read(DATA, $data, (-s DATA));
    close(DATA);

    eval $data;
    
    if (!$@)
    {
        $self->{DATA} = \%data;
    }
}


sub _save
{
    my $self = shift;

    if (!$self->_valid())
    {
        unlink($self->{FILE}) if (-f $self->{FILE});
        return;
    }

    my $dumper = new Data::Dumper([$self->{DATA}],["*data"]);
    $dumper->Purity(1);

    open(DATA,">".$self->{FILE});
    print DATA $dumper->Dump();
    close(DATA);
}


sub _valid
{
    my $self = shift;

    return (exists($self->{VALID}) && ($self->{VALID} == 1));
}


1;

