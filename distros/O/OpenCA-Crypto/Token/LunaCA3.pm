## OpenCA::Token.pm 
##
## Copyright (C) 2003 Michael Bell <michael.bell@web.de>
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

###############################################################
##        ============    LunaCA3 Token    =============     ##
###############################################################

## OpenCA::OpenSSL includes code to support the Chrysalis-ITS token too
## errorcodes 713*  71 -> token ; 3 -> third implemented token

package OpenCA::Token::LunaCA3;

use OpenCA::OpenSSL;

our ($errno, $errval);

($OpenCA::Token::OpenSSL::VERSION = '$Revision: 1.3 $' )=~ s/(?:^.*: (\d+))|(?:\s+\$$)/defined $1?"0\.9":""/eg;

# Preloaded methods go here.

## create a new LunaCA3 token
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
    $self->{CRYPTO}    = $keys->{OPENCA_CRYPTO};
    $self->{NAME}      = $keys->{OPENCA_TOKEN};
    $self->{MODE}      = $keys->{TOKEN_MODE};
    $self->{UTILITY}   = $keys->{UTILITY};
    $self->{SLOT}      = $keys->{SLOT};
    $self->{APPID}     = $keys->{APPID};
    $self->{LOCK_FILE} = $keys->{LOCK_FILE};
    return undef if (not $self->{CRYPTO});
    return undef if (not $self->{NAME});

    ## create openssl object
    $keys->{ENGINE} = "LunaCA3 -enginearg ".
                      $self->{SLOT}.":".$self->{APPID};
    $self->{OPENSSL} = OpenCA::OpenSSL->new ( $keys );
    $errno  = $OpenCA::OpenSSL::errno;
    $errval = $OpenCA::OpenSSL::errval;

    return undef if not $self->{OPENSSL}

    return $self;
}

sub setError {
    my $self = shift;

    if (scalar (@_) == 4) {
        my $keys = { @_ };
        $errval = $keys->{ERRVAL};
        $errno  = $keys->{ERRNO};
    } else {
        $errno  = $_[0];
        $errval = $_[1];
    }

    return undef if (not $errno);

    print $STDERR "PKI Master Alert: OpenCA::Token::LunaCA3 error\n";
    print $STDERR "PKI Master Alert: Aborting all operations\n";
    print $STDERR "PKI Master Alert: Error:   $errno\n";
    print $STDERR "PKI Master Alert: Message: $errval\n";
    print $STDERR "PKI Master Alert: debugging messages of empty token follow\n";
    $self->{debug_fd} = $STDERR;
    $self->debug ();
    $self->{debug_fd} = $STDOUT;

    ## support for: return $self->setError (1234, "Something fails.") if (not $xyz);
    return undef;
}

## failover to default token OpenSSL which uses -engine
## see new to get an idea what's going on
sub AUTOLOAD {
    my $self = shift;

    my $ret = $self->{OPENSSL}->$AUTOLOAD ( @_ );
    setError ($OpenCA::OpenSSL::errno, $OpenCA::OpenSSL::errval);
    return $ret;
}

sub login {
    my $self = shift;

    my $keys = { @_ };

    my $command = $self->{UTILITY};
    $command .= " -o ";
    $command .= " -s ".$self->{SLOT};
    $command .= " -i ".$self->{APPID};

    my $ret = `$command`;
    if ($? != 0)
    {
        setError ($?, $ret);
        return undef;
    } else {
        $self->{ONLINE} = 1;
	if ($self->{MODE} =~ /^(SESSION|DAEMON)$/)
        {
            my $command = "touch ".$self->{LOCK_FILE};
            `$command`;
        }
        return 1;
    }
}

sub logout {
    my $self = shift;

    my $keys = { @_ };

    my $command = $self->{UTILITY};
    $command .= " -c ";
    $command .= " -s ".$self->{SLOT};
    $command .= " -i ".$self->{APPID};

    my $ret = `$command`;
    if ($? != 0)
    {
        setError ($?, $ret);
        return undef;
    } else {
        $self->{ONLINE} = 0;
	unlink $self->{LOCK_FILE} if (-e $self->{LOCK_FILE});
        return 1;
    }
}

sub online {
    ## FIXME: how we can test a HSM to be online?
    ## FIXME: while we cannot test this we have no chance to
    ## FIXME: run this HSM in mode session or daemon
    my $self = shift;

    if ($self->{ONLINE} or -e $self->{LOCK_FILE}) {
        return 1;
    } else {
        return undef;
    }
}

sub keyOnline {
    return $self->online;
}

sub getMode {
    my $self =  shift;
    return $self->{MODE};
}

sub genKey {
    my $self = shift;

    my $keys = { @_ };

    return setError (7134012, "You try to generate a key for a Chrysalis-ITS Luna CA3 token but you don't specify the number of bits.")
        if (not $keys->{BITS});
    return setError (7134014, "You try to generate a key for a Chrysalis-ITS Luna CA3 token but you don't specify the filename where to store the keyreference.")
        if (not $keys->{OUTFILE});

    my $command = $self->{UTILITY};
    $command .= " -s ".$self->{SLOT};
    $command .= " -i ".$self->{APPID};
    $command .= " -g ".$keys->{BITS};
    $command .= " -f ".$keys->{OUTFILE};

    my $ret = `$command`;
    if ($? != 0)
    {
        setError ($?, $ret);
        return undef;
    } else {
        return 1;
    }
}

1;
