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
##        ============    OpenSSL Token    =============     ##
###############################################################

package OpenCA::Token::OpenSSL;

use OpenCA::OpenSSL;

use FileHandle;
our ($STDERR, $STDOUT);
$STDOUT = \*STDOUT;
$STDERR = \*STDERR;

our ($errno, $errval);
our $AUTOLOAD;

($OpenCA::Token::OpenSSL::VERSION = '$Revision: 1.6 $' )=~ s/(?:^.*: (\d+))|(?:\s+\$$)/defined $1?"0\.9":""/eg;

# Errorcode prefix: 711*
# 71 token modules
# 1  first implemented token

# Preloaded methods go here.

## create a new OpenSSL tokens
sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    my $self = {
                DEBUG     => 0,
                debug_fd  => $STDERR,
                ## debug_msg => ()
               };

    bless $self, $class;

    $self->debug ("new: class instantiated");

    my $keys = { @_ };
    $self->{CRYPTO}       = $keys->{OPENCA_CRYPTO};
    $self->{NAME}         = $keys->{OPENCA_TOKEN};
    ## TOKEN_MODE will be ignored
    $self->{PASSWD_PARTS} = $keys->{PASSWD_PARTS};
    ## FIXME: I hope this fixes @_
    delete $keys->{OPENCA_CRYPTO};
    delete $keys->{OPENCA_TOKEN};
    delete $keys->{PASSWD_PARTS};
    return $self->setError (7111010, "Crypto layer is not defined.")
        if (not $self->{CRYPTO});
    return $self->setError (7111012, "The name of the token is not defined.")
        if (not $self->{NAME});

    $self->debug ("new: crypto and name present");

    $keys->{CERT} = $keys->{PEM_CERT};
    $self->{OPENSSL} = OpenCA::OpenSSL->new ( %{$keys} );
    return $self->setError ($OpenCA::OpenSSL::errno, $OpenCA::OpenSSL::errval)
        if (not $self->{OPENSSL});

    $self->debug ("new: NAME ".$self->{NAME});
    $self->debug ("new: PASSWD_PARTS ".$self->{PASSWD_PARTS});

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

    ## FIXME: this is usually a bug
    return undef if (not $self->{errno});

    if ($self->{DEBUG})
    {
        $self->{debug_fd} = $STDERR;
        $self->debug ();
        $self->{debug_fd} = $STDOUT;
    }

    ## support for: return $self->setError (1234, "Something fails.") if (not $xyz);
    return undef;
}

sub errno {
    my $self = shift;
    return $self->{errno};
}

sub errval {
    my $self = shift;
    return $self->{errval};
}

sub debug {

    my $self = shift;
    if ($_[0]) {
        $self->{debug_msg}[scalar @{$self->{debug_msg}}] = $_[0];
        $self->debug () if ($self->{DEBUG});
    } else {
        my $oldfh;
        if ($self->{errno})
        {
            $oldfh = select $self->{debug_fd};
            print "PKI Debugging: OpenCA::Token::OpenSSL error\n";
            print "PKI Debugging: Aborting all operations\n";
            print "PKI Debugging: Error:   ".$self->{errno}."\n";
            print "PKI Debugging: Message: ".$self->{errval}."\n";
            print "PKI Debugging: debugging messages of OpenSSL token follow\n";
            select $oldfh;
        }
        my $msg;
        foreach $msg (@{$self->{debug_msg}}) {
            $msg =~ s/ /&nbsp;/g if ($self->{debug_fd} eq $STDOUT);
            my $oldfh = select $self->{debug_fd};
            print "OpenCA::Token::OpenSSL->$msg<br>\n";
            select $oldfh;
        }
        $self->{debug_msg} = ();
    }
}

sub login {
    my $self = shift;
    my @result = ($self->{CRYPTO}->getAccessControl())->getTokenParam (
                  $self->{NAME},
                  $self->{PASSWD_PARTS});
    $self->{PASSWD} = join '', @result;
    $self->{OPENSSL}->{PASSWD} = $self->{PASSWD};

    return $self->setError (7113050, "Wrong passphrase for private key!")
        if (not $self->{OPENSSL}->dataConvert (DATATYPE => "KEY", PUBKEY =>"1"));

    $self->{ONLINE} = 1;
    return 1;
}

sub logout {
    my $self = shift;
    undef $self->{PASSWD};
    undef $self->{OPENSSL}->{PASSWD};
    $self->{ONLINE} = 0;
    return 1;
}

sub online {
    my $self = shift;
    return 1;
}

sub keyOnline {
    my $self = shift;
    return undef if (not $self->{ONLINE});
    return 1;
}

sub getMode {
    return "standby";
}

## use OpenSSL by default but take care about the errorcodes
sub AUTOLOAD {
    my $self = shift;

    if ($AUTOLOAD =~ /OpenCA::OpenSSL/)
    {
        print STDERR "PKI Master Alert: OpenCA::OpenSSL is missing a function\n";
        print STDERR "PKI Master Alert: $AUTOLOAD\n";
        $self->setError (666, "OpenCA::OpenSSL is missing a function. $AUTOLOAD");
        return undef;
    }
    $self->debug ("OpenCA::Token::OpenSSL: AUTOLOAD => $AUTOLOAD");

    return 1 if ($AUTOLOAD eq 'OpenCA::Token::OpenSSL::DESTROY');

    my $function = $AUTOLOAD;
    $function =~ s/.*:://g;
    my $ret = $self->{OPENSSL}->$function ( @_ );
    $self->setError ($OpenCA::OpenSSL::errno, $OpenCA::OpenSSL::errval);
    return $ret;
}

1;
