##########################################################################
#
# Module template
#
##########################################################################
package Pots::Thread::MethodServer;

##########################################################################
#
# Modules
#
##########################################################################
use threads;
use threads::shared;

use strict;

use base qw(Pots::Thread);

use Pots::Thread::MethodClient;
use Pots::Message;

Pots::Thread::MethodServer->mk_shared_accessors(
qw(cclass clients)
);

Pots::Thread::MethodServer->mk_accessors(
qw(cobj)
);
##########################################################################
#
# Global variables
#
##########################################################################

##########################################################################
#
# Private methods
#
##########################################################################
sub error {
    my $self = shift;

    print "Pots::Thread::MethodServer : error : ", join(' ', @_), "\n";
}

sub add_client {
    my $self = shift;
    my $cliobj = shift;

    my $cliref = $self->clients();

    lock(%{$cliref});
    my $client_serial = $cliobj->serial();
    $cliref->{$client_serial} = $cliobj;
}

sub get_client {
    my $self = shift;
    my $client_serial = shift;

    my $cliref = $self->clients();

    if (!exists($cliref->{$client_serial})) {
        $self->error("No active client with serial", $client_serial);
        return undef;
    }

    return $cliref->{$client_serial};
}

##########################################################################
#
# Public methods
#
##########################################################################
sub new {
    my $class = shift;
    my %p = @_;

    my $self = $class->SUPER::new(%p);

    return $self;
}

sub initialize {
    my $self = shift;
    my %p = @_;

    $self->SUPER::initialize(%p);

    if (!defined($p{cclass})) {
        $self->error("missing cclass parameter");
        return 0;
    }

    $self->cclass($p{cclass});

    my %clients : shared = ();
    $self->clients(\%clients);

    return 1;
}

sub pre_run {
    my $self = shift;
    my @args = shift;

    my $cclass = $self->cclass();

    # Check if client class is already known
    if (!$cclass->can("new")) {
        # No, try to load it
        if (!eval "require $cclass") {
            $self->error("failed to load class $cclass");
            return 0;
        }
    }

    # Create object
    my $cobj = $cclass->new(@args);

    if (!defined($cobj)) {
        $self->error("failed to create $cclass object");
        return 0;
    }

    $self->cobj($cobj);

    return 1;
}

sub run {
    my $self = shift;
    my $quit = 0;
    my $msg;

    while (!$quit) {
        $msg = $self->getmsg();
        next unless defined($msg);

        for ($msg->type()) {
            if (/quit/) {
                $quit = 1;
                last;
            } elsif (/call/) {
                my $callspec = $msg->get('callspec');
                my $client_serial = $msg->get('client_serial');

                my @ret = $self->call($callspec->{method}, @{$callspec->{args}});

                my $rmsg = Pots::Message->new();
                $rmsg->type('call_return');
                $rmsg->set('retdata', \@ret);

                my $cliobj = $self->get_client($client_serial);
                $cliobj->postmsg($rmsg);
            }
        }
    }
}

sub post_run {
    my $self = shift;
}

sub call {
    my $self = shift;
    my $method = shift;

    if ($self->cobj->can($method)) {
        return $self->cobj->$method(@_);
    } else {
        print "Object has no method named $method.\n";
        return undef;
    }
}

sub client {
    my $self = shift;

    return undef unless ($self->startcode() == 1);

    # Create object
    my $cli = Pots::Thread::MethodClient->new($self->cclass(), $self);
    $self->add_client($cli);

    return $cli->client_object();
}

sub destroy {
    my $self = shift;
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::Thread::MethodServer - Perl ObjectThreads server class for exposing
classes to other threads.

=head1 SYNOPSIS

    use Pots::Thread::MethodServer;

    my $ms = Pots::Thread::MethodServer(cclass => 'Some::Class');
    $ms->start();

    my $cli = $ms->client();

    $cli->method1($arg1);
    $cli->method2();

    $ms->stop();

=head1 DESCRIPTION

This class starts a thread and exposes an object to other threads through a
C<Pots::Thread::MethodClient> object. Using that client object, you can call
methods as if your were using a locally created object.
All method calls are transparently forwarded to the server thread.

This class is a subclass of C<Pots::Thread>.

=head1 METHODS

=over

=item new (cclass => 'Some::Class')

Creates a new thread which will load and instantiate an object of class
"Some::Class".

=item start ()

Following the behavior of the C<Pots::Thread> class, you must call "start()"
to start the server thread.

=item stop ()

Calling this method will stop the server thread.

=item client ()

This method returns an object of class C<Pots::Thread::MethodClient>, which allows
you to transparently call methods of the "Some::Class" object in the server
thread.

=back

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
