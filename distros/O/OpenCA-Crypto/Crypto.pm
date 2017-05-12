## OpenCA::Crypto.pm 
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

package OpenCA::Crypto;

use FileHandle;
our ($STDERR, $STDOUT);
$STDOUT = \*STDOUT;
$STDERR = \*STDERR;

our ($errno, $errval);
our $AUTOLOAD;

($OpenCA::Crypto::VERSION = '$Revision: 1.6 $' )=~ s/(?:^.*: (\d+))|(?:\s+\$$)/defined $1?"0\.9":""/eg;

# Preloaded methods go here.

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
    $self->{configfile}    = $keys->{CONFIG};
    $self->{DEBUG}         = 1 if ($keys->{DEBUG});
    $self->{DEFAULT_TOKEN} = $self->{DEFAULT_TOKEN} if ($keys->{DEFAULT_TOKEN});
    $self->{cache}         = $keys->{CACHE};

    print "Content-type: text/html\n\n" if ($self->{DEBUG});

    ## set default token
    $self->{DEFAULT_TOKEN} = $self->{cache}->get_xpath (
                                 FILENAME => $self->{configfile},
                                 XPATH    => [ 'token_config/default_token' ],
                                 COUNTER  => [ 0 ])
        if ($self->{configfile});

    $self->debug ("new: configfile: $self->{configfile}");
    $self->debug ("new: DEFAULT_TOKEN: $self->{DEFAULT_TOKEN}");

    ## this default token overrides the configuration
    if ($self->{DEFAULT_TOKEN})
    {
        if ($self->{configfile})
        {
            return undef if (not $self->addToken ($self->{DEFAULT_TOKEN}));
        } else {
            return setError (7110010, "There was token specified but there is no configurationfile.");
        }
    }

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

sub setConfig {

    my $self = shift;

    $self->{configfile} = $_[0];
    return $self->getConfig;

}

sub debug {

    my $self = shift;
    if ($_[0]) {
        $self->{debug_msg}[scalar @{$self->{debug_msg}}] = $_[0];
        $self->debug () if ($self->{DEBUG});
    } else {
        my $msg;
        foreach $msg (@{$self->{debug_msg}}) {
            $msg =~ s/ /&nbsp;/g;
            my $oldfh = select $self->{debug_fd};
            print "OpenCA::Crypto->".$msg."<br>\n";
            select $oldfh;
        }
        $self->{debug_msg} = ();
    }

}

######################################################################
##                     slot management                              ##
######################################################################

## implicit use token
sub getToken {

    my $self = shift;
    $self->debug ("OpenCA::Crypto->getToken");

    my $name = $_[0];
    if (not $_[0])
    {
        if (not $self->{DEFAULT_TOKEN})
        {
            return $self->setError (7121010, "No default token specified.");
        }
        $name = $self->{DEFAULT_TOKEN};
    }
    $self->debug ("OpenCA::Crypto->getToken: $name");

    $self->addToken ($name)
        if (not $self->{TOKEN}->{$name});
    $self->debug ("OpenCA::Crypto->getToken: token added");

    return $self->setError (7121030, "The token is not present in the system")
        if (not $self->{TOKEN}->{$name});
    $self->debug ("OpenCA::Crypto->getToken: token is present");

    return $self->setError (7121040, "The token is not usable.")
        if (not $self->useToken ($name));
    $self->debug ("OpenCA::Crypto->getToken: token is usable");

    return $self->{TOKEN}->{$name};
}

sub addToken {

    my $self = shift;
    $self->debug ("OpenCA::Crypto->addToken");

    my $name = $_[0];
    if (not $_[0])
    {
        if (not $self->{DEFAULT_TOKEN})
        {
            return $self->setError (7121010, "No default token specified");
        }
        $name = $self->{DEFAULT_TOKEN};
    }
    $self->debug ("OpenCA::Crypto->addToken: $name");

    ## get matching config
    my $token_count = $self->{cache}->get_xpath_count (
                          FILENAME => $self->{configfile},
                          XPATH    => 'token_config/token');
    for (my $i=0; $i<$token_count; $i++)
    {
        $self->debug ("OpenCA::Crypto->addToken: checking name");
        next if ($name ne $self->{cache}->get_xpath (
                              FILENAME => $self->{configfile},
                              XPATH    => [ 'token_config/token', 'name' ],
                              COUNTER  => [ $i, 0 ]));
        $self->debug ("OpenCA::Crypto->addToken: name ok");
        my @args = ();

        ## load CRYPTO, NAME and MODE to array
        push @args, "OPENCA_CRYPTO", $self;
        push @args, "OPENCA_TOKEN", $name;
        $self->debug ("OpenCA::Crypto->addToken: loading mode");
        my $help = $self->{cache}->get_xpath (
                               FILENAME => $self->{configfile},
                               XPATH    => [ 'token_config/token', 'mode' ],
                               COUNTER  => [ $i, 0 ]);
        push @args, "TOKEN_MODE", $help;

        ## load complete config in array
        $self->debug ("OpenCA::Crypto->addToken: loading options");
        my $option_count = $self->{cache}->get_xpath_count (
                               FILENAME => $self->{configfile},
                               XPATH    => [ 'token_config/token', 'option' ],
                               COUNTER  => [ $i ]);
        for (my $k=0; $k<$option_count; $k++)
        {
            $help = $self->{cache}->get_xpath (
                               FILENAME => $self->{configfile},
                               XPATH    => [ 'token_config/token', 'option', 'name' ],
                               COUNTER  => [ $i, $k, 0 ]),
            $self->debug ("OpenCA::Crypto->addToken: option name: $help");
            push @args, $help;
            $help = $self->{cache}->get_xpath (
                               FILENAME => $self->{configfile},
                               XPATH    => [ 'token_config/token', 'option', 'value' ],
                               COUNTER  => [ $i, $k, 0 ]);
            $self->debug ("OpenCA::Crypto->addToken: option value: $help");
            push @args, $help;
        }
        $self->debug ("OpenCA::Crypto->addToken: loaded options");

        ## init token
        my $type = $self->{cache}->get_xpath (
                               FILENAME => $self->{configfile},
                               XPATH    => [ 'token_config/token', 'type' ],
                               COUNTER  => [ $i, 0 ]);
        $self->{TOKEN}->{$name} = $self->newToken ($type, @args);
        $self->setError (7123080, "Cannot create new OpenCA Token object. ".$self->errval)
            if (not $self->{TOKEN}->{$name});
        return $self->{TOKEN}->{$name};
    }
    return $self->setError (7123090, "The requested token is not configured ($name).");
}

sub newToken {

    my $self = shift;
    my $name = shift;
    $self->debug ("OpenCA::Crypto->newToken");

    ## get the token class    
    my $token_class = "OpenCA::Token::$name";
    eval "require $token_class";
    return $self->setError ($@, $@)
        if ($@);
    $self->debug ("OpenCA::Crypto->newToken: class: OpenCA::Token::$name");

    ## get the token
    my $token = eval {$token_class->new (@_)};

    return $self->setError ($@, $@)
        if ($@);
    $self->debug ("OpenCA::Crypto->newToken: no error during new");
    return $self->setError ($token_class::errno, $token_class::errval)
        if (not $token);
    $self->debug ("OpenCA::Crypto->newToken: new token present");

    return $token;
}

sub useToken {
    my $self = shift;

    my $name = $_[0];
    if (not $_[0])
    {
        if (not $self->{DEFAULT_TOKEN})
        {
            return $self->setError (7125010, "No default token specified");
        }
        $name = $self->{DEFAULT_TOKEN};
    }

    ## the token must be present
    return $self->setError (7125020, "The token is not present.")
        if (not $self->{TOKEN}->{$name});

    return $self->{TOKEN}->{$name}->login
        if (not $self->{TOKEN}->{$name}->online);

    return 1;
}

########################################################################
##                          access control                            ##
########################################################################

sub setAccessControl {
    my $self = shift;
    $self->{ACCESS_CONTROL} = $_[0];
    return 1;
}

sub getAccessControl {
    my $self = shift;
    return $self->{ACCESS_CONTROL};
}

sub stopSession {
    my $self = shift;
    my $error = 0;
    foreach my $token (keys %{$self->{TOKEN}})
    {
        next if (not $self->{TOKEN}->{$token}->getMode !~ /^session$/i);
        $error = 1 if (not $self->{TOKEN}->{$token}->logout);
    }
    return $self->setError (7174010, "Logout of at minimum one token failed")
        if ($error);
    return 1;
}

sub startDaemon {
    my $self = shift;
    my $error = 0;
    my $token_count = $self->{cache}->get_xpath_count (
                          FILENAME => $self->{configfile},
                          XPATH    => 'token_config/token');
    for (my $i=0; $i<$token_count; $i++)
    {
        next if ($self->{cache}->get_xpath (
                      FILENAME => $self->{configfile},
                      XPATH    => [ 'token_config/token', 'mode' ],
                      COUNTER  => [ $i, 0 ]) !~ /^daemon$/i);
        my $name = $self->{cache}->get_xpath (
                      FILENAME => $self->{configfile},
                      XPATH    => [ 'token_config/token', 'name' ],
                      COUNTER  => [ $i, 0 ]);
        return $self->setError (7176030, "The token ".$name.
                                         " cannot be initialized.")
            if (not $self->addToken($name));
    }
    return $self->setError (7176080, "Logout of at minimum one token failed")
        if ($error);
    return 1;
}

sub stopDaemon {
    my $self = shift;
    my $error = 0;
    foreach my $token (keys %{$self->{TOKEN}})
    {
        next if (not $self->{TOKEN}->{$token}->getMode !~ /^daemon$/i);
        $error = 1 if (not $self->{TOKEN}->{$token}->logout);
    }
    return $self->setError (7178010, "Logout of at minimum one token failed")
        if ($error);
    return 1;
}

##################################################################
##                 automatic functionality                      ##
##################################################################

## failover to default token
sub AUTOLOAD {
    my $self = shift;

    return setError (7196010, "There is no default token specified.")
        if (not $self->{DEFAULT_TOKEN});

    return setError (7196020, "The default token is not present.")
        if (not $self->{TOKEN}->{$self->{DEFAULT_TOKEN}});

    return $self->{TOKEN}->{$self->{DEFAULT_TOKEN}}->$AUTOLOAD ( @_ );
}

## logout all tokens except sessions and daemons
sub DESTROY {
    my $self = shift;

    my $default_token = $self->{TOKEN}->{$self->{DEFAULT_TOKEN}};
    delete $self->{TOKEN}->{$self->{DEFAULT_TOKEN}};

    my $error = 0;
    foreach my $token (keys %{$self->{TOKEN}})
    {
        next if (not $self->{TOKEN}->{$token}->getMode =~ /^(session|daemon)$/i);
        $error = 1 if (not $self->{TOKEN}->{$token}->logout);
    }

    return $self->setError (7199010, "Logout of at minimum one token failed")
        if ($error);
    return 1;
}

1;
