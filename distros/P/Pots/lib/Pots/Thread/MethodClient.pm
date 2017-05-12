##########################################################################
#
# Module template
#
##########################################################################
package Pots::Thread::MethodClient;

##########################################################################
#
# Modules
#
##########################################################################
use strict;

use base qw(Pots::SharedObject Pots::SharedAccessor);

Pots::Thread::MethodClient->mk_shared_accessors(
qw(serial thread mqueue objclass)
);
##########################################################################
#
# Global variables
#
##########################################################################
our $Serial : shared = 0;

##########################################################################
#
# Private methods
#
##########################################################################

##########################################################################
#
# Public methods
#
##########################################################################
sub new {
    my $class = shift;
    my $objclass = shift;
    my $thread = shift;

    my $self = $class->SUPER::new();

    {
        lock($Serial);
        $self->serial($Serial++);
    }

    $self->objclass($objclass);
    $self->thread($thread);
    $self->mqueue(Pots::MessageQueue->new());

    return $self;
}

sub postmsg {
    my $self = shift;

    if ($self->thread->tid() == threads->tid()) {
        $self->mqueue->postmsg(@_);
    } else {
        $self->thread->postmsg(@_);
    }
}

sub getmsg {
    my $self = shift;

    return $self->mqueue->getmsg();
}

sub sendmsg {
    my $self = shift;

    $self->postmsg(@_);

    return $self->getmsg();
}

sub client_object {
    my $self = shift;

    my $obj = Pots::Thread::MethodClient::Object->new(
        $self->objclass(),
        $self
    );

    return $obj;
}

sub call {
    my $self = shift;
    my $method = shift;

    if ($self->thread->stopped()) {
        print "Server is stopped\n";
        return undef;
    }

    my $msg = Pots::Message->new();
    $msg->type('call');
    $msg->set('client_serial', $self->serial());
    $msg->set(
        'callspec',
        {
            method => "$method",
            args => \@_
        }
    );

    $msg = $self->sendmsg($msg);
    my $data = $msg->get('retdata');

    return @{$data};
}

package Pots::Thread::MethodClient::Object;

use vars qw($AUTOLOAD);
use Pots::Message;

sub new {
    my $class = shift;
    my $objclass = shift;
    my $client = shift;

    $class = ref ($class) || $class;

    no strict 'refs';
    my $oclass = "${class}::$objclass";
    @{"${oclass}::ISA"} = $class unless @{"${oclass}::ISA"};

    my %hself : shared = ();
    my $self = bless (\%hself, $oclass);

    $self->{_client} = $client;

    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $callspec = $AUTOLOAD;
    my $class;
    my $method;

    my $client = $self->{_client};

    if ($callspec =~ /^(.*)::(\w+)$/) {
        $class = $1;
        $method = $2;

        my @ret = $client->call($method, @_);

        return (wantarray ? @ret : $ret[0]);
    } else {
        print "Invalid method spec\n";
        return undef;
    }
}

sub DESTROY {
    my $self = shift;
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::Thread::MethodClient - Perl ObjectThreads client class for inter-thread
method calls

=head1 SYNOPSIS

You should not use this class directly, it is used by the C<Pots::Thread::MethodServer>
class to allow you to transparently call methods of objects in other threads.

=head1 DESCRIPTION

This class uses a sub namespace and AUTOLOAD to transparently allow you to
call methods of objects in other threads. These objects are exposed through
a C<Pots::Thread::MethodServer> object. It is similar, in concept, to
inter-thread RPCs.

Refer to C<Pots::Thread::MethodServer> for further information.

=head1 ACKNOWLEDGMENTS

Ideas and code in here are HEAVILY inspired by Jochen Wiedmann's excellent
PlRPC modules, and C<RPC::PlClient> in particular.

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
