#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/Version.pm                                            #
#                                                                              #
# Description: Version support for Net::STOMP::Client                          #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::Version;
use strict;
use warnings;
our $VERSION  = "2.3";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.3 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate_pos :types);

#
# global variables
#

our(
    %Supported,  # hash of the supported STOMP protocol versions
);

foreach my $version (qw(1.0 1.1 1.2)) {
    $Supported{$version}++;
}

#
# check a list of acceptable versions
#

sub _check ($) {
    my($value) = @_;

    unless (defined($value)) {
        # undef: accept all supported
        return(sort(keys(%Supported)));
    }
    if (ref($value) eq "") {
        # scalar
        if ($value =~ /,/) {
            # assume a comma separated list
            $value = [ split(/,/, $value) ];
            # (will be checked further down)
        } else {
            # assume a single version
            dief("unsupported STOMP version: %s", $value)
                unless $Supported{$value};
            return($value);
        }
    }
    if (ref($value) eq "ARRAY") {
        # array reference: accept all given
        foreach my $version (@{ $value }) {
            dief("unsupported STOMP version: %s", $version)
                unless $Supported{$version};
        }
        return(@{ $value });
    }
    dief("unexpected STOMP version: %s", $value);
}

#
# get/set the acceptable versions
#

sub accept_version : method {
    my($self);

    $self = shift(@_);
    return(@{ $self->{"accept_version"} }) if @_ == 0;
    if (@_ == 1) {
        $self->{"accept_version"} = [ _check($_[0]) ];
        return($self);
    }
    # otherwise complain...
    validate_pos(@_, { optional => 1, type => UNDEF|SCALAR|ARRAYREF });
}

#
# get the negotiated version
#

sub version : method {
    my($self) = @_;

    return($self->{"version"});
}

#
# setup
#

sub _setup ($) {
    my($self) = @_;

    # additional options for new()
    return(
        "accept_version" => { optional => 1, type => UNDEF|SCALAR|ARRAYREF },
        "version"        => { optional => 1, type => UNDEF|SCALAR|ARRAYREF },
    ) unless $self;
    # FIXME: compatibility hack for Net::STOMP::Client 1.x (to be removed)
    if (exists($self->{"version"})) {
        dief("options version and accept_version are mutually exclusive")
            if exists($self->{"accept_version"});
        $self->{"accept_version"} = delete($self->{"version"});
    }
    # check the accept_version option (and set defaults)
    $self->accept_version($self->{"accept_version"});
}

#
# hook for the CONNECT frame
#

sub _connect_hook ($$) {
    my($self, $frame) = @_;
    my(@list);

    # do not override what the user did put in the frame
    return if defined($frame->header("accept-version"));
    # do nothing when only STOMP 1.0 is asked
    @list = $self->accept_version();
    return unless grep($_ ne "1.0", @list);
    # add the appropriate header
    $frame->header("accept-version", join(",", @list));
}

#
# hook for the CONNECTED frame
#

sub _connected_hook ($$) {
    my($self, $frame) = @_;
    my(@list, $version);

    @list = $self->accept_version();
    $version = $frame->header("version");
    if (defined($version)) {
        # the server must have chosen an acceptable version
        dief("unexpected STOMP version: %s", $version)
            unless grep($_ eq $version, @list);
    } else {
        # no version header present so assume 1.0
        $version = "1.0";
        dief("server only supports STOMP 1.0")
            unless grep($_ eq $version, @list);
    }
    # so far so good
    $self->{"version"} = $version;
}

#
# register the setup and hooks
#

{
    no warnings qw(once);
    $Net::STOMP::Client::Setup{"version"} = \&_setup;
    $Net::STOMP::Client::Hook{"CONNECT"}{"version"} = \&_connect_hook;
    $Net::STOMP::Client::Hook{"CONNECTED"}{"version"} = \&_connected_hook;
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(accept_version version));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__END__

=head1 NAME

Net::STOMP::Client::Version - Version support for Net::STOMP::Client

=head1 SYNOPSIS

  use Net::STOMP::Client;
  $stomp = Net::STOMP::Client->new(host => "127.0.0.1", port => 61613);
  ...
  # can change the acceptable versions only _before_ connect()
  $stomp->accept_version([ "1.1", "1.2" ]);
  ...
  $stomp->connect();
  ...
  # can get the negotiated version only _after_ connect()
  printf("using STOMP %s\n", $stomp->version());

=head1 DESCRIPTION

This module handles STOMP protocol version negotiation. It is used
internally by L<Net::STOMP::Client> and should not be directly used
elsewhere.

=head1 METHODS

This module provides the following methods to L<Net::STOMP::Client>:

=over

=item accept_version([VALUE])

get/set the list of acceptable STOMP protocol versions; the given
value can either be undef (meaning all supported versions) or a single
version or an array reference for multiple versions

=item version([STRING])

get the negotiated STOMP protocol version

=back

=head1 SUPPORTED VERSIONS

L<Net::STOMP::Client> supports the versions
C<1.0> (see L<http://stomp.github.com/stomp-specification-1.0.html>),
C<1.1> (see L<http://stomp.github.com/stomp-specification-1.1.html>) and
C<1.2> (see L<http://stomp.github.com/stomp-specification-1.2.html>)
of the STOMP protocol.

=head1 SEE ALSO

L<Net::STOMP::Client>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2017
