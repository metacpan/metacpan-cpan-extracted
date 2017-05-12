## OpenCA::Session.pm 
##
## Copyright (C) 2000-2003 Michael Bell <michael.bell@web.de>
## All rights reserved.
##
##    This library is free software; you can redistribute it and/or
##    modify it under the terms of the GNU Lesser General Public
##    License as published by the Free Software Foundation; either
##    version 2.1 of the License, or (at your option) any later version.
##
##    This library is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
##    Lesser General Public License for more details.
##
##    You should have received a copy of the GNU Lesser General Public
##    License along with this library; if not, write to the Free Software
##    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##

use strict;

package OpenCA::Session;

use CGI::Session qw/-ip-match/;
use OpenCA::Log::Message;

use FileHandle;
our ($STDERR, $STDOUT);
$STDOUT = \*STDOUT;
$STDERR = \*STDERR;

our ($errno, $errval);

($OpenCA::Session::VERSION = '$Revision: 1.2 $' )=~ s/(?:^.*: (\d+))|(?:\s+\$$)/defined $1?"0\.9":""/eg;

# Preloaded methods go here.

##
## supported functions
##
## new
##
## load
## update
## start
## stop
## clear
## getID
##
## cleanup
##
## getParam
## setParam
## loadParams
## saveParams
##

## Create an instance of the Class
sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    my $self = {
                DEBUG     => 0,
                debug_fd  => $STDOUT,
                ## debug_msg => ()
               };

    bless $self, $class;

    my $keys = { @_ };
    $self->{cgi}         = $keys->{CGI};
    $self->{lifetime}    = 1200;
    $self->{lifetime}    = $keys->{LIFETIME} if ($keys->{LIFETIME});
    $self->{DEBUG}       = 1 if ($keys->{DEBUG});
    $self->{dir}         = $keys->{DIR};
    $self->{journal}     = $keys->{LOG};

    $self->{printed_header} = 0;

    print "Content-type: text/html\n\n" if ($self->{DEBUG});

    return $self;
}

sub setError {
    my $self = shift;

    if (scalar (@_) == 4) {
        my $keys = { @_ };
        $self->{errval} = $keys->{ERRVAL};
        $self->{errno}  = $keys->{ERRNO};
    } else {
        $self->{errno}  = $_[0];
        $self->{errval} = $_[1];
    }
    $errno  = $self->{errno};
    $errval = $self->{errval};

    $self->{journal}->{errno}   = $self->{errno};
    $self->{journal}->{errval}  = $self->{errval};
    $self->{journal}->{message} = "";
    foreach my $msg (@{$self->{debug_msg}}) {
        $self->{journal}->{message} .= $msg."\n";
    }

    ## support for: return $self->setError (1234, "Something fails.") if (not $xyz);
    return undef;
}

#####################################
## operate on the complete session ##
#####################################

sub load {
    my $self = shift;

    return undef if (not $self->{cgi}->cookie("CGISESSID"));

    $self->{session} = new CGI::Session(
                             undef,
                             $self->{cgi}->cookie("CGISESSID"),
                             {Directory=>$self->{dir}});

    return 1 if ($self->{session});

    ## this can happen if the session is timed out
    return undef;
}

sub start {
    my $self = shift;

    ## destroy old session if present
    if ($self->{session}) {
        $self->{session}->delete;
        undef ($self->{session});
    }

    ## create new session
    $self->{session} = new CGI::Session(
                             undef,
                             undef,
                             {Directory=>$self->{dir}});

    ## set lifetime
    $self->{session}->expire($self->{lifetime});

    ## store cookie
    $self->{session}->flush;

    ## prepare header
    $self->{cookie} = $self->{cgi}->cookie(CGISESSID => $self->{session}->id);

    ## send header without content-type
    if (not $self->{printed_header})
    {
        my $header = $self->{cgi}->header( -cookie=>$self->{cookie} );
        $header =~ s/\n*Content-Type:[^\n]*\n*//s;
        print $header;
        $self->{printed_header} = 1;
    }

    return 1;
}

sub update {
    my $self = shift;

    ## set lifetime
    $self->{session}->expire($self->{lifetime});

    ## prepare header
    $self->{cookie} = $self->{cgi}->cookie(CGISESSID => $self->{session}->id);

    ## send header without content-type
    if (not $self->{printed_header})
    {
        my $header = $self->{cgi}->header( -cookie=>$self->{cookie} );
        my @lines = split "\n", $header;
        $header = "";
        foreach my $line (@lines) {
            $line = substr ($line, 0, length($line)-1);
            next if (not $line);
            next if ($line =~ /content-type/i);
            $header .= $line."\n";
        }
        print $header;
        $self->{printed_header} = 1;
    }
    $self->{session}->flush;

    return 1;
}

sub stop {
    my $self = shift;

    $self->{session}->delete;
    undef ($self->{session});

    return 1;
}

sub clear
{
    my $self = shift;
    $self->{session}->clear();
}

sub getID
{
    my $self = shift;
    $self->{session}->id;
}

#############################
## operate on all sessions ##
#############################

sub cleanup {

    my $self = shift;

    my $expired = 0;
    my $dir = $self->{dir};

    ## load all sessions
    opendir DIR, $dir;
    my @session_files = grep /^(?!\.\.$).*/, grep /^(?!\.$)./, readdir DIR;
    closedir DIR;

    return $expired if (not scalar @session_files);

    ## check every session
    foreach my $session_file (@session_files)
    {
        ## extract session_id
        $session_file =~ s/cgisess_//;

        ## load session
        my $session = new CGI::Session(
                             undef,
                             $session_file,
                             {Directory=>$dir});

        $expired++ if (not $session);
    }

    ## return the number of expired sessions
    return $expired;
}

######################
## param operations ##
######################

sub saveParams
{
    my $self = shift;
    $self->{session}->save_param ($self->{cgi});
    $self->{session}->flush;
}

sub loadParams
{
    my $self = shift;
    $self->{session}->load_param ($self->{cgi});
    $self->{session}->flush;
}

sub setParam
{
    my $self = shift;
    $self->{session}->param ($_[0], $_[1]);
    $self->{session}->flush;
}

sub getParam
{
    my $self = shift;
    $self->{session}->param ($_[0]);
}

1;
