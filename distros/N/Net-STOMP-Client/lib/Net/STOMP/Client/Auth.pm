#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/Auth.pm                                               #
#                                                                              #
# Description: Authentication support for Net::STOMP::Client                   #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::Auth;
use strict;
use warnings;
our $VERSION  = "2.3";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.1 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use Params::Validate qw(validate_pos :types);

#
# Authen::Credential is optional
#

eval { require Authen::Credential };

#
# check a single authentication
#

sub _chkauth ($) {
    my($auth) = @_;

    return(Authen::Credential->parse($auth))
        if ref($auth) eq "";
    return($auth)
        if ref($auth) and $auth->isa("Authen::Credential");
    dief("unexpected authentication: %s", $auth);
}

#
# setup
#

sub _setup ($) {
    my($self) = @_;
    my(@list, $scheme, $sslopts);

    # no additional options if Authen::Credential is not available!
    return() unless $self or $Authen::Credential::VERSION;
    # additional options for new()
    return(
        "auth" => { optional => 1, type => SCALAR|ARRAYREF|OBJECT },
    ) unless $self;
    # check the given authentication
    return() unless $self->{"auth"};
    if (ref($self->{"auth"}) eq "ARRAY") {
        @list = map(_chkauth($_), @{ $self->{"auth"} });
    } else {
        @list = (_chkauth($self->{"auth"}));
    }
    # make sure we have at most one X.509 and one plain|none
    foreach my $auth (@list) {
        $auth->check();
        $scheme = $auth->scheme();
        if ($scheme eq "x509") {
            dief("duplicate authentication: %s", $auth->string())
                if exists($self->{"x509_auth"});
            $self->{"x509_auth"} = $auth;
        } elsif ($scheme eq "none") {
            dief("duplicate authentication: %s", $auth->string())
                if exists($self->{"plain_auth"});
            $self->{"plain_auth"} = ""; # special case...
        } elsif ($scheme eq "plain") {
            dief("duplicate authentication: %s", $auth->string())
                if exists($self->{"plain_auth"});
            $self->{"plain_auth"} = $auth;
        } else {
            dief("unsupported authentication scheme: %s", $scheme);
        }
    }
    # use the X.509 authentication via the socket options
    if ($self->{"x509_auth"}) {
        $sslopts = $self->{"x509_auth"}->prepare("IO::Socket::SSL");
        while (my($name, $value) = each(%{ $sslopts })) {
            $self->{"sockopts"}{$name} = $value;
        }
    }
}

#
# hook for the CONNECT frame
#

sub _connect_hook ($$) {
    my($self, $frame) = @_;

    return unless $self->{"plain_auth"};
    # do not override what the user did put in the frame
    $frame->header("login", $self->{"plain_auth"}->name())
        unless defined($frame->header("login"));
    $frame->header("passcode", $self->{"plain_auth"}->pass())
        unless defined($frame->header("passcode"));
}

#
# register the setup and hook
#

{
    no warnings qw(once);
    $Net::STOMP::Client::Setup{"auth"} = \&_setup;
    $Net::STOMP::Client::Hook{"CONNECT"}{"auth"} = \&_connect_hook;
}

1;

__END__

=head1 NAME

Net::STOMP::Client::Auth - Authentication support for Net::STOMP::Client

=head1 SYNOPSIS

  use Net::STOMP::Client;
  $stomp = Net::STOMP::Client->new(
      uri  => "stomp://127.0.0.1:61613",
      auth => "plain name=system pass=manager",
  );

=head1 DESCRIPTION

This module handles STOMP authentication. It is used internally by
L<Net::STOMP::Client> and should not be directly used elsewhere.

If the optional L<Authen::Credential> module is available, an additional
C<auth> attribute can be given to L<Net::STOMP::Client>'s new() method.
If the module is not available, the C<auth> attribute cannot be used.

This attribute can take either a single authentication credential (either as
a string or an L<Authen::Credential> object) or multiple credentials (via an
array reference). See L<Authen::Credential> for more information about these
credentials.

If an X.509 credential is given, it will be used at SSL connection time. If
a plain credential is given, it will be used in the C<CONNECT> frame. If
needed, both types of credentials could be used for the same STOMP connection.

Using generic authentication credentials is very convenient as they could be
passed as command line options to a script:

  # default authentication
  $Option{auth} = "none";
  # get URI & credential from command line
  GetOptions(\%Option,
      "auth=s",
      "uri=s",
      ...
  );
  $stomp = Net::STOMP::Client->new(uri => $Option{uri}, auth => $Option{auth});

=head1 SEE ALSO

L<Authen::Credential>,
L<Net::STOMP::Client>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2017
