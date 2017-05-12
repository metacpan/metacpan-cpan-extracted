package RPC::Async::Client;
use strict;
use warnings;

our $VERSION = '1.05';

=head1 NAME

RPC::Async::Client - client side of asynchronous RPC framework

=head1 SYNOPSIS

  use RPC::Async::Client;
  use IO::EventMux;
  
  my $mux = IO::EventMux->new;
  my $rpc = RPC::Async::Client->new($mux, "perl://add-server.pl");
  # or # my $rpc = RPC::Async::Client->new($mux, "tcp://127.0.0.1:1234");

  $rpc->add_numbers(n1 => 2, n2 => 3,
      sub {
          my %reply = @_;
          print "2 + 3 = $reply{sum}\n";
      });
  
  while ($rpc->has_requests || $rpc->has_coderefs) {
      my $event = $rpc->io($mux->mux) or next;
  }

  $rpc->disconnect;
  
=head1 DESCRIPTION

This module provides the magic that hides the details of doing asynchronous RPC
on the client side. It does not dictate how to implement initialisation or main
loop, although it requires the application to use L<IO::EventMux>.

The procedures made available by the remote server can be called directly on the
L<RPC::Async::Client> instance or via the C<call()> method where they are
further documented.

=head1 METHODS

=over

=cut

use Carp;
use Socket;
use RPC::Async::Util qw(make_packet append_data read_packet);
use RPC::Async::Coderef;
use RPC::Async::URL;

=item new($mux, $url, @urlargs)

Connects to an RPC server via the URL given in $url. Such URLs can be of the
forms specified in L<RPC::Async::URL>, although it must connect to a
bi-directional stream socket. Alternatively, pass an open file descriptor.

=cut

sub new {
    my ($class, $mux, $url, @args) = @_;

    my %self = (
        mux => $mux,
        requests => {},
        serial => -1,
        buf => undef,
        coderefs => {},
    );
    my ($fh, @urlargs) = url_connect($url, @args); 
    $mux->add($fh);
    $self{fh} = $fh;
    $self{urlargs} = \@urlargs;

    return bless \%self, (ref $class || $class);
}

sub AUTOLOAD {
    my $self = shift;
    if (@_ < 1) { return; }

    our $AUTOLOAD;
    my $procedure = $AUTOLOAD;
    $procedure =~ s/.*:://;

    return $self->call($procedure, @_);
}

=item call($procedure, @args, $subref)

Performs a remote procedure call. Rather than using this directly, this package
enables some AUTOLOAD magic that allows calls to remote procedures directly on
the L<RPC::Async::Client> instance.

Arguments are passed in key/value style by convention, although any arguments
may be given. The last argument a remote procedure call is a subroutine
reference to be executed upon completion of the call. This framework makes no
guarantees as to when, if ever, this sub will be called. Specifically, remote
procedures may return in a different order than they were called in.

Fairly complex data structures may be given as arguments, except for circular
ones. In particular, subroutine references are allowed.

The call itself is given a uniq id that is returned and can later be used
with other subs.

=cut

sub call {
    my ($self, $procedure, @args) = @_;
    my $callback = pop @args;

    @args = $self->_encode_args(@args);

    my $id = $self->_unique_id;
    $self->{requests}{$id} = $callback;

    #print "RPC::Async::Client sending: $id $procedure @args\n";
    $self->{mux}->send($self->{fh}, make_packet([ $id, $procedure, @args ]));

    return $id;
}

=item disconnect

Call this to gracefully disconnect from the server without leaving zombie
processes or such.

=cut

sub disconnect {
    my ($self) = @_;
    $self->{mux}->kill($self->{fh});
    url_disconnect($self->{fh}, @{$self->{urlargs}});
}

=item has_requests

Returns true iff there is at least one request pending. Usually, this means that
we should not terminate yet.

=cut

sub has_requests {
    my ($self, $event) = @_;
    return scalar %{$self->{requests}};
}

=item has_coderefs

Returns true if the remote side holds a reference to a subroutine given to it
in an earlier call. Depending on the application, this may be taken as a hint
that we should not terminate yet. This information is obtained via interaction
with Perl's garbage collector on the server side.

=cut

sub has_coderefs {
    my ($self, $event) = @_;
    return scalar %{$self->{coderefs}};
}

=item io($event)

Inspect an event from EventMux. All such events must be passed through here in
order to handle asynchronous replies. If the event was handled, C<undef> is
returned. Otherwise, the event is returned for processing by other
RPC::Async::Client handlers or the main program itself.

=cut

sub io {
    my ($self, $event) = @_;

    if ($event->{fh} and $event->{fh} == $self->{fh}) {
        my $type = $event->{type};
        if ($type eq "read") {
            #print "RPC::Async::Client got ", length $event->{data}, " bytes\n";
            $self->_handle_read($event->{data});

        } elsif ($type eq "closed") {
            die __PACKAGE__ .": server disconnected\n";
        }

        return;

    } else {
        return $event;
    }
}

=item dump_requests

Returns a string documenting what requests are pending. For debugging only.

=cut

sub dump_requests {
    my ($self) = @_;
    use Data::Dumper;
    return Dumper($self->{requests});
}

=item wait($timeout, [@ids])

Block until we have enough events from the RPC server to matches all the
id's listed or we get a timeout. If no id's are given then any id will be 
used. This function can be useful when we want to make sure the server is 
started in the other end, fx. if we need to connect to it on another socket. 

If all events was received in time, 1 is returned, C<undef> is returned on 
timeout.

Any unrelated events will be buffered and pushed back on the stack when the
wait call has finished.

=cut

sub wait {
    my ($self, $timeout, @ids) = @_;
    my %match = map { $_ => 1 } @ids;
    my $count = (int @ids or 1);
    my $mux = $self->{mux};
     
    # Set timeout only on our own fh.
    $mux->timeout($self->{fh}, $timeout);
    my @events;
    while($count and my $event = $mux->mux()) {
        if ($event->{fh} and $event->{fh} == $self->{fh}) {
            if ($event->{type} eq "read") {
                foreach my $id ($self->_handle_read($event->{data})) {
                    if(exists $match{$id} or @ids == 0) {
                        $count--;
                    }
                }

            } elsif($event->{type} eq 'timeout') {
                last;

            } elsif ($event->{type} eq "closed") {
                die __PACKAGE__ .": server disconnected\n";
            }

        } else {
            push @events, $event;
        }
    }

    $mux->push_event(@events);
    return $count > 0?undef:1;
}

sub _handle_read {
    my ($self, $data) = @_;
    my @ids;

    # TODO: Use buffering code in EventMux and remove functions from Util.pm
    append_data(\$self->{buf}, $data);
    while (my $thawed = read_packet(\$self->{buf})) {
        if (ref $thawed eq "ARRAY" and @$thawed >= 1) {
            my ($id, @args) = @$thawed;
            my $callback = delete $self->{requests}{$id};
            
            push(@ids, $id);

            if (defined $callback) {
                #print __PACKAGE__, ": callback(@args)\n";
                $callback->(@args);

            } elsif (exists $self->{coderefs}{$id}) {
                my ($command, @cb_args) = @args;
                if ($command eq "destroy") {
                    delete $self->{coderefs}{$id};
                } elsif ($command eq "call") {
                    $self->{coderefs}{$id}->(@cb_args);
                } else {
                    warn __PACKAGE__.": Unknown command for callback";
                }

            } else {
                warn __PACKAGE__.": Spurious reply to id $id\n";
            }
        } else {
            warn __PACKAGE__.": Bad data in thawed packet";
        }
    }
    
    return @ids;
}

sub _unique_id {
    my ($self) = @_;

    $self->{serial}++;
    return $self->{serial} &= 0x7FffFFff;
}

sub _encode_args {
    my ($self, @args) = @_;

    return map {
        my $arg = $_;
        if (not ref $arg) {
            $arg;
        } elsif (ref $arg eq "ARRAY") {
            [ $self->_encode_args(@$arg) ];
        } elsif (ref $arg eq "HASH") {
            my %h;
            keys %h = scalar keys %$arg; # preallocate buckets
            foreach my $key (keys %$arg) {
                my ($v) = $self->_encode_args($arg->{$key});
                $h{$key} = $v;
            }
            \%h;
        } elsif (ref $arg eq "Regexp") {
           #TODO: Copy over regexp options /ig etc.
           $arg =~ /:(.*)\)$/;
           $1;
        } elsif (ref $arg eq "REF") {
            my ($v) = $self->_encode_args($$arg);
            \$v;
        } elsif (ref $arg eq "CODE") {
            my $id = $self->_unique_id;
            $self->{coderefs}{$id} = $arg;
            RPC::Async::Coderef->new($id);
        } else {
            $arg;
        }
    } @args;
}

=back

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk>, Jonas Jensen <jbj@knef.dk>

=head1 COPYRIGHT

Copyright(C) 2005-2007 Troels Liebe Bentsen
Copyright(C) 2005-2007 Jonas Jensen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# vim: et sw=4 sts=4 tw=80
