package POE::Component::Generic::Net::SSH2;
# $Id: SSH2.pm 762 2011-05-18 19:34:32Z fil $

use strict;

use POE::Component::Generic;
use POE::Component::Generic::Child;

use Carp qw(carp croak);
use vars qw( @ISA $TIMEOUT $VERSION );

use         # hide from CPANTS
    Net::SSH2;

$VERSION = '0.1400';
@ISA = qw( POE::Component::Generic );
$TIMEOUT = 100;

require Net::SSH2;
if( $Net::SSH2::VERSION < 0.18 ) {
    croak __PACKAGE__, " requires version Net::SSH2 0.18 or better";
}

##########################################################
#
# Create the worker object
# This is called from PoCo::Generic->spawn()
# We set-up everything for the package, so the user doesn't have to.
sub new
{
    my( $package, %params ) = @_;

    $params{package}    ||= 'Net::SSH2';
    $params{factories}  ||= [ qw( channel real_exec ) ];
    $params{packages}   ||= {};
    $params{packages}{'Net::SSH2::Channel'}{ postbacks }
                    ||= [ qw(handler_stderr handler_stdout handler_closed) ];
    $params{postbacks}  ||= { disconnect=>0, real_exec=>[1..4] };
    $params{alias}      ||= 'net-ssh';
    $params{child_package} ||= join '::', __PACKAGE__, 'Child';

    $TIMEOUT = delete $params{timeout} if $params{timeout};

    $package->SUPER::new( %params );
}


##########################################################
# This method converts the SomethingEvent hash into a linear
# argument list, so that the user doesn't have to.
sub exec
{
    my( $self, $data, $command, %events ) = @_;

    my @args = ( $data, $command );
    foreach my $ev ( qw(Stdout Stderr Closed Error) ) {
        push @args, $self->__postback_argument( $ev, \%events );
    }

    $self->real_exec( @args );
}

#####################################################################
# Child process worker
package POE::Component::Generic::Net::SSH2::Child;
use strict;

use IO::Poll qw(POLLRDNORM POLLIN);
use Scalar::Util qw( reftype blessed );
use vars qw( @ISA );

sub DEBUG () { 0 }

@ISA = qw( POE::Component::Generic::Child );


sub new
{
    my $package = shift;
    my $self = $package->SUPER::new( @_ );

    $self->{timeout} ||= $POE::Component::Generic::Net::SSH2::TIMEOUT;
    
    $Net::SSH2::CHILD = $self;
    return $self;
}

#######################################
# Poll stdin and the SSH connection
sub get_requests
{
    my( $self ) = @_;

    unless( $self->{ssh_channels} ) {       # no registered SSH channels
        return $self->SUPER::get_requests();
    }
    DEBUG and warn "we have ssh_channel handlers";

    my $rv;
    while( 1 ) {
        $self->poll_ssh;                    # let SSH channels have a chance

        $rv = $self->poll_stdin;
        return $rv if defined $rv;
    }
}

#######################################
sub poll_ssh
{
    my( $self ) = @_;

    my @poll;
    while( my( $name, $hdef ) = each %{ $self->{ssh_channels} || {} } ) {
        push @poll, { handle=>$hdef->{channel},
                      events=>[ grep { $hdef->{$_} } qw( in ext ) ]
                    };
    }
    return unless @poll;
    DEBUG and warn "ssh_poll";
    # Blocking has to be off for polling
    $self->{obj}->blocking( 0 );
    $self->{obj}->poll( $self->{timeout}, [ @poll ] );

    DEBUG and warn "ssh_poll returned ", 0+@poll, " events";

    my( $n, $buf );
    foreach my $poll ( @poll ) {
        my $hdef = $self->{ssh_channels}{ $poll->{handle} };
        foreach my $ev ( qw( in ext ) ) {
            next unless $poll->{revents}{$ev};

            if( $n = $hdef->{channel}->read( $buf, 1024, $ev eq 'ext' ) ) {
                DEBUG and warn "$ev: $n bytes";
                $hdef->{$ev}->( $buf, $n );
            }
        }
        if( $hdef->{channel}->eof ) {
            DEBUG and warn "EOF";
            $hdef->{channel_closed}->();
            delete $self->{ssh_channels}{ $poll->{handle} };
        }
    }
    return;
}

#######################################
sub __handler
{
    my( $self, $channel, $event, $coderef ) = @_;

    $self->{ssh_channels} ||= {};

    if( $coderef ) {
        die "Must be a coderef" unless 'CODE' eq reftype $coderef;
        $self->{ssh_channels}{$channel} ||= { channel=> $channel };
        $self->{ssh_channels}{$channel}{$event} = $coderef;
    }
    else {
        delete $self->{ssh_channels}{$channel}{$event};
        delete $self->{ssh_channels}{$channel} 
                             if 1 == keys %{ $self->{ssh_channels}{$channel} };
        delete $self->{ssh_channels} if 0 == keys %{ $self->{ssh_channels} };
    }
}

#######################################
sub __remove_channel
{
    my( $self, $channel ) = @_;

    return unless $self->{ssh_channels};

    delete $self->{ssh_channels}{$channel};
    delete $self->{ssh_channels} if 0 == keys %{ $self->{ssh_channels} };
    return;
}


#######################################
# Poll STDIN for a request
# Return 
#   undef() when STDIN closed (parent shutdown)
#   0 nothing to do
#   [ requests...] what to do
sub poll_stdin
{
    my( $self ) = @_;

    DEBUG and warn "poll_stdin ($self->{timeout})";
    my $poll = IO::Poll->new();

    $poll->mask( *STDIN, POLLIN );
    $poll->poll( $self->{timeout}/1000 );
    my $raw;
    my $ev = $poll->events( *STDIN );
    DEBUG and warn "ev=$ev";
    return unless $ev;

    # This should be encapsulated in Generic::Child somehow.
    return 0 unless sysread ( STDIN, $raw, $self->{size} );
    return $self->{filter}->get([$raw]);
}






#####################################################################
# Extend Net::SSH2
#   Net::SSH2 doesn't play nicely with subclassing, so we just throw
#   Things into their namespace.
package             # On 2 lines so the PAUSE indexer doesn't gripe
    Net::SSH2;

use strict;
use vars qw( $CHILD );
sub DEBUG () { 0 }

*true_channel = \&channel;

#################################
{
    no strict 'subs';
    *channel = sub {
        my( $self, @args ) = @_;
        # Blocking has to be on when setting up a channel
        # And for ->exec and ->cmd, it seems, but ...
        $self->blocking( 1 );
        my $obj = true_channel( $self, @args );
        warn "Can't create channel ".$self->error unless $obj;
        return $obj;
    };
}

#################################
# This method does the heavy-lifting for ->exec
sub real_exec
{
    my( $self, $command, $on_stdout, $on_stderr, 
                         $on_closed, $on_error ) = @_;

    my $channel = $self->channel;
    unless( $channel ) {
        $on_error->( $self->error ) if $on_error;
        return
    }
    DEBUG and warn "Created channel";

    $CHILD->__handler( $channel, 'in', $on_stdout ) if $on_stdout;
    $CHILD->__handler( $channel, 'ext', $on_stderr ) if $on_stderr;
    $CHILD->__handler( $channel, 'channel_closed', $on_closed ) if $on_closed;
    # $CHILD->__handler( $channel, 'channel_error', $on_error ) if $on_error;

    DEBUG and 
        warn "Exec $command";
    my $ok = $channel->exec( $command );

    if( $ok ) {
        return $channel; 
    }

    $CHILD->__remove_channel( $channel );
    warn "Couldn't exec $command";
    $on_error->( $self->error ) if $on_error;
    return;
}


sub cmd
{
    my( $self, $command, $input ) = @_;

    my $channel = $self->channel;
    unless( $channel ) {
        return ( '', "Unable to create channel: ".$self->error );
    }

    return $channel->cmd( $command, $input );
}


#####################################################################
# Extend Net::SSH2::Channel
#   Net::SSH2 doesn't play nicely with subclassing, so we just throw
#   things into their namespace.
package                     # on 2 lines so PAUSE indexer doesn't gripe
    Net::SSH2::Channel;

use strict;
sub DEBUG () { 0 }

sub handler_stdout
{
    my( $self, $coderef ) = @_;

    DEBUG and warn "handler_stdout";
    $Net::SSH2::CHILD->__handler( $self, 'in', $coderef );
}

sub handler_stderr
{
    my( $self, $coderef ) = @_;

    DEBUG and warn "handler_stderr";
    $Net::SSH2::CHILD->__handler( $self, 'ext', $coderef );
}

sub handler_closed
{
    my( $self, $coderef ) = @_;

    DEBUG and warn "handler_closed";
    $Net::SSH2::CHILD->__handler( $self, 'channel_closed', $coderef );
}

sub cmd
{
    my( $self, $command ) = @_;

    DEBUG and warn "cmd: $command";

    return unless $self->exec( $command );

    my @ret = ( '', '' );

    $self->blocking( 0 );
    my @poll = ({ handle => $self, events => [ qw( in ext ) ] });
    do {
        my( $buf, $n );
        $self->session->poll(100, \@poll);
        if( $self->eof ) {
            DEBUG and 
                warn "EOF";
            return @ret if wantarray;
            return $ret[0];
        }
        foreach my $ev ( qw( in ext ) ) {
            next unless $poll[0]->{revents}->{$ev};

            DEBUG and warn "cmd: read $ev";
            if( $n = $self->read($buf, 1024, $ev eq 'ext') ) {
                DEBUG and warn "$ev: $n bytes";
                $ret[ $ev eq 'in' ? 0 : 1 ] .= $buf;
            }
        }
    } while( 1 );
    # we'd never get here
}

no strict 'subs';
*DESTROY = sub {
        my( $self ) = @_;
        $Net::SSH2::CHILD->__remove_channel( $self ) if $Net::SSH2::CHILD;
    };

1;

__END__

=head1 NAME

POE::Component::Generic::Net::SSH2 - A POE component that provides non-blocking access to Net::SSH2

=head1 SYNOPSIS

    use POE::Component::Generic::Net::SSH2;

    my $ssh = POE::Component::Generic::Net::SSH2->spawn( 
                    alias   => 'my-ssh',
                    verbose => 1,
                    debug   => 0 );

    my $channel;

    POE::Session->create( 
        inline_states => {
            _start => sub {
                $poe_kernel->delay( 'connect', $N );
            },

            connect => sub {
                $ssh->connect( {event=>'connected'}, $HOST, $PORT );
            },
            connected => sub {
                $ssh->auth_password( {event=>'login'}, $USER, $PASSWORD );
            },
            error => sub {
                my( $resp, $code, $name, $error ) = @_[ARG0, $#_];
                die "Error $name ($code) $error";
            },

            login => sub {
                my( $resp, $OK ) = @_[ARG0..$#_];
                unless( $OK ) {
                    $ssh->error( {event=>'error', wantarray=>1} );
                    return;
                }

                $poe_kernel->yield( 'cmd_do' );
            },

            ################
            cmd_do => sub {
                $ssh->cmd( { event=>'cmd_output', wantarray=>1 }, "ls -l" );
                return;
            },
            cmd_output => sub {
                my( $resp, $stdout, $stderr ) = @_[ARG0..$#_];
                warn "Contents of home directory on $HOST:\n$stdout\n";


                $poe_kernel->yield( 'exec_do' );
            },

            exec_do => sub {
                 
                $ssh->exec( { event=>'exec_running', wantarray=>0 }, 
                                "cat - >$FILE", 
                                StdoutEvent => 'exec_stdout', 
                                StderrEvent => 'exec_stderr', 
                                ClosedEvent => 'exec_closed', 
                                ErrorEvent  => 'exec_error' 
                          );
            },
            exec_running => sub {
                my( $resp, $ch ) = @_[ARG0..$#_];
                # keep channel alive
                $channel = $ch;
                $channel->write( {}, "$$-CONTENTS OF THE FILE\n" );
                $channel->send_eof( {event=>'done'} );
            },

            done => sub {
                undef( $channel );
                $ssh->shutdown;
            }

            exec_error => sub {
                my( $code, $name, $string ) = @_[ARG0..$#_];
                die "ERROR: $name $string";
            },        
            exec_stderr => sub {
                my( $text, $bytes ) = @_[ARG0..$#_];
                die "STDERR: $text";
                return;
            },
            exec_stdout => sub {
                my( $text, $bytes ) = @_[ARG0..$#_];
                warn "STDOUT: $text";
                return;
            },
            exec_closed => sub {
                undef( $channel );
                $ssh->shutdown;
            },
        }
    );


=head1 DESCRIPTION


L<POE::Component::Generic::Net::SSH2> is a component for handling SSH2
connections from POE.  It uses L<POE::Component::Generic> to wrap
L<Net::SSH2> into a non-blocking framework.

This component demonstrates many tricks that you might find useful when you
build your own components based on L<POE::Component::Generic>.

It is still ALPHA quality.  Missing are scp, sftp support and better error
handling.

Patches welcome.


=head1 METHODS

=head2 spawn


=head1 Net::SSH2 METHODS

L<POE::Component::Generic::Net::SSH2> supports most Net::SSH2 method calls 
using L<POE::Component::Generic>'s interface.  The following additional 
methods are added for better POE support.


=head2 cmd

    $ssh->cmd( $data_hash, $command, $input );

Ultra-simple command execution.  Runs C<$command> in a new channel on the
remote host.  C<$input> is then feed to it (NOT YET!).  All output is 
accumulated until the command exits, then is sent to the response event
as C<ARG1> (STDOUT) and C<ARG2> (STDERR).


=head2 exec

    $ssh->exec( $data_hash, $command, %events );

Runs C<$command> in a new channel on the remote host.  The response event
will receive an SSH channel that it may use to write to or read from.

C<%events> is a hash that may contain the following keys:

=over 4

=item StdoutEvent

=item StderrEvent

Called when C<$command> writes to STDOUT or STDERR, respectively, with 2
arguments: C<ARG0> is the data, C<ARG1> is the number of bytes.

=item ErrorEvent

Called when there is an SSH error.  The documentation for libssh2 is
piss-poor, so I'm not really sure what these could be, nor how to detect
them all.  Arguments are the same as C<Net::SSH2/error>: C<ARG0> is error
number, C<ARG1> is error name and C<ARG2> is the error string.

=item ClosedEvent

Called when the we encounter an SSH C<eof> on the channel, which normaly
corresponds to when C<$command> exits.

No arguments.

=back


=head1 Net::SSH2::Channel METHODS

A channel is a conduit by which SSH communicates to a sub-process on the
remote side.  Each command, shell or sub-system uses its own channel.  A
channel may only run one command, shell or sub-system.

Channels are created with the C<channel> factory method:

    $ssh->channel( {event=>'got_channel'} );

    # Your got_channel event
    sub got_channel {
        my( $heap, $resp, $channel ) = @_[HEAP, ARG0, ARG1];
        die $resp->{error} if $resp->{error};

        $heap->{channel} = $channel;
    }

You may call most L<Net::SSH2::Channel> methods on a channel using the
normal L<POE::Component::Generic> calling conventions.

    $heap->{channel}->write( {}, $string );

Channels are closed when you drop all references to the object.

    delete $heap->{channel};


There are some extensions to the channel interface:

=head2 cmd

    $heap->{channel}->cmd( {event=>'cmd_response'}, $command, $input );

Runs C<$command> on the channel.  Response event receives 2 arguments:
C<ARG1> is the commands output to STDOUT,
C<ARG2> is the commands output to STDERR.

If you do not set C<wantarray> to 1, you will only receive STDOUT.

=head2 handler_stdout

=head2 handler_stderr

Registers a postback that is posted when the data is present on STDOUT
(called 'in' in libssh2) or STDERR (called 'ext' in libssh2) respectively.  

These could be used when you call L<Net::SSH2::Channel/exec> on a channel.

=head2 handler_closed

Registers a postback that is posted when the channel closes, which normaly
happens when the command has finished.

These could be used when you call L<Net::SSH2::Channel/exec> on a channel.



=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<Net::SSH2>, L<POE::Component::Generic>.

=head1 RATING

Please rate this module.
L<http://cpanratings.perl.org/rate/?distribution=POE-Component-Generic>

=head1 BUGS

Probably.  Report them here:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE%3A%3AComponent%3A%3AGeneric>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2011 by Philip Gwyn.


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
