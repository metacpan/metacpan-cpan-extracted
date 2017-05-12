# vim600: set ts=4 sw=4 tw=80 expandtab nowrap noai cin foldmethod=marker:
# A Multiplex TCP Component designed for performance.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------
# See TCPMulti.otl (TVO format) or TCPMulti.pod (POD format) for documentation
package POE::Component::Client::TCPMulti;

# Settings and Initialization {{{

use strict;
use warnings FATAL => qw( all );
use constant CHEAP => -1;

# POE::Component::Server::TCPMulti can export cheap also
# We're not going to require order from the user.
sub import {
    no strict "refs";
    my $caller = caller;

    unless (defined *{"${caller}::CHEAP"}) {
        *{"${caller}::CHEAP"} = \&CHEAP;
    }
}


use UNIVERSAL;
use POE qw( Kernel
            Session
            Driver::SysRW
            Filter::Line 
            Wheel::ReadWrite
            Wheel::SocketFactory );

use Carp qw( carp croak );

*VERSION = \0.0524;

our $VERSION;
BEGIN { 
    unless (defined &DEBUG) {
        constant->import(DEBUG => 0);
    }
    unless (defined &TRACE_EVENTS) {
        constant->import(TRACE_EVENTS => 0);
    }
    unless (defined &TRACE_CONNECT) {
        constant->import(TRACE_CONNECT => 0);
    }
    unless (defined &TRACE_FILENAME) {
        constant->import(TRACE_FILENAME => 0);
    }
}

if (DEBUG) {
    print "TCPMulti: DEBUG MODE ENABLED\n";
}
if (TRACE_FILENAME) {
    open TRACE, ">", TRACE_FILENAME;
}
else {
    *TRACE = *STDERR;
}

# Heap is now package global.  This is fine, each wheel throughout the POE
# Kernel has its own unique identification.  So multiple component sessions
# can utilize the same hash for Connection Heaps.

# Note: Explicit lexical was not accessable by the inline states (This seems to
# be a bug in perl >= 5.8.1, although its marked as simply changed behavior in
# the changelog.  Its only with strange combinations of lexicals anonymous
# subroutines and anonymous hashrefs (As commonly used in POE
# programming...bastards :P)
our %heap;

# }}}
# new (Depriciated) {{{

sub new { goto &create }
    
# }}}
# Constructor {{{

sub create {
    # Initialization {{{

    shift if $_[0] eq __PACKAGE__;
    my ($code, %user_code);

    %user_code = @_;

    $user_code{$_} ||= sub {} for qw( ErrorEvent
                                     InputEvent
                                     Initialize
                                     Disconnected
                                     SuccessEvent
                                     FlushedEvent
                                     FailureEvent
                                     TimeoutEvent );

    $user_code{Timeout}        ||= 30;
    $user_code{ConnectTimeout} ||= $user_code{Timeout};
    $user_code{InputTimeout}   ||= 300;
    $user_code{Filter}         ||= "POE::Filter::Line";
    $user_code{FilterArgs}     ||= undef;
    $user_code{options}        ||= {};
    $user_code{package_states} ||= [];
    $user_code{object_states}  ||= [];

    if (ref $user_code{Filter} eq "ARRAY") {
        my @FilterData = @{ delete $user_code{Filter} };
        $user_code{Filter} = shift @FilterData;
        $user_code{FilterArgs} = \@FilterData;
    }

    @{ $user_code{UserStates} }{ qw( _start _stop _child ) } =
        delete @{ $user_code{inline_states} }{ qw( _start _stop _child ) };

    # }}}
    # Internal States {{{
    $code = {
        # Session Events {{{
        #   _start:     Session Start {{{

        _start      => sub {
            $_[KERNEL]->alias_set( delete $user_code{Alias} ) 
                if defined $user_code{Alias};
    
            $user_code{UserStates}->{_start}->(@_)
                if ref $user_code{UserStates}->{_start} eq "CODE";
        },
    
        #   }}}
        #   _child:     Session Child {{{

        _child      => sub {
            $user_code{states}->{_child}->(@_)
                if ref $user_code{UserStates}->{_child} eq "CODE";
        },
    
        #   }}}
        #   _stop:      Session End {{{

        _stop       => sub {
            $user_code{UserStates}->{_stop}->(@_)
                if ref $user_code{UserStates}->{_stop} eq "CODE";
        },
    
        #   }}}
        # }}}
        # Connection States {{{
        #   -success:       Connection was successful (Internal) {{{

        -success       => sub {
            my ($kernel, $handle, $old_id) = @_[KERNEL, ARG0, ARG3];
            my $filter;
    
            # We need 1 filter per Wheel...yeah
            if (ref $user_code{Filter} && 
                    UNIVERSAL::isa($user_code{Filter}, "UNIVERSAL")) {
                $filter = $user_code{Filter} = ref $user_code{Filter};
            }

            $filter = $user_code{Filter}->new( @{ $user_code{FilterArgs} } );

            $heap{$old_id}{-SERVER} = POE::Wheel::ReadWrite->new
                ( Handle        => $handle,
                  Driver        => POE::Driver::SysRW->new(BlockSize => 4096),
                  Filter        => $filter,
                  InputEvent    => '-incoming',
                  ErrorEvent    => '-error',
#                 FlushedEvent  => '-flushed',
                  );

            # Transfer entire heap (including wheel), reinstate -ID
            my $new_id = $heap{$old_id}{-SERVER}->ID;
            my $cheap  = $heap{$new_id} = delete $heap{$old_id};

            bless $heap{$new_id}, "POE::Component::Client::TCPMulti::CHEAP";

            # ARG4 differs from Wheel definition...its our new id.
            push @_, $new_id, $cheap;

            $cheap->{-ID} = $new_id;
            $cheap->{-TIMEOUT} = $user_code{InputTimeout};

            if ($user_code{InputTimeout}) {
                if ($cheap->{-ALARM}) {
                    DEBUG && printf "%d << Adjusting alarm %d (%d s)\n",
                        $new_id, @{ $_[CHEAP] }{qw( -ALARM -TIMEOUT )};
                    $kernel->delay_adjust
                        ( $cheap->{-ALARM}, $cheap->{-TIMEOUT} );
                }
                else {
                    $cheap->{-ALARM} = $kernel->delay_set
                        ( -timeout => $cheap->{-TIMEOUT}, $cheap->{-ID} );
                }
            }
            # We should have an alarm ID -> maybe we're not storing it.
            elsif ($cheap->{-ALARM}) {
                $kernel->alarm_remove( delete $cheap->{-ALARM} );
            }

            $user_code{SuccessEvent}->(@_);
    
            printf "%d == Successfull Connection %s:%d\n", $new_id,
                @{ $heap{$new_id} }{qw( -ADDR -PORT )} if DEBUG;
        },
    
        #   }}}
        #   connect:        Open new connection {{{

        # Connect to the next available proxy
        connect         => sub {
            my $cheap;
            if (ref $_[ARG0] eq "HASH" || ref $_[ARG0] eq "ARRAY") {
                $cheap = splice @_, ARG0, 1;
            }

            my ($address, $port, $bindaddress, $bindport) = @_[ARG0..ARG3];

            printf TRACE "connect event invoked (%s, %d) for %s from %s:%d\n",
                   @_[ ARG0, ARG1 ], 
                   $cheap->{email},  # email para poeml lang
                   @_[ CALLER_FILE, CALLER_LINE ] if TRACE_CONNECT;

            unless (defined $address) {
                return printf STDERR   
                    "connect called without address or port, %s: line %d\n",
                    @_[CALLER_FILE, CALLER_LINE];
            }

            printf STDERR "!!! !! connect state invoked from %s:%d\n",
                   @_[CALLER_FILE, CALLER_LINE] if DEBUG;
            
            push @_, POE::Component::Client::TCPMulti->connect
                ( RemoteAddress => $address,
                  RemotePort    => $port,
                  BindAddress   => $bindaddress,
                  BindPort      => $bindport,
                  Timeout       => $user_code{ConnectTimeout},
                  Heap          => $cheap,
                );

            $user_code{Initialize}->(@_);
        }, 
    
        #   }}}
        # }}}
        # IO States {{{
        #   -incoming:      Handling recieved data (Internal) {{{
    
        -incoming  => sub {
            my ($kernel, $id) = @_[ KERNEL, ARG1 ];
            push @_, $heap{$id};

            my $cheap = $_[ CHEAP ];
            return unless $cheap->{-RUNNING};

            if (DEBUG) {
                print "$_[ARG1] << $_[ARG0]\n";
            }

            if ($cheap->{-TIMEOUT}) {
                $kernel->delay_adjust
                    ( $cheap->{-ALARM}, $cheap->{-TIMEOUT} );
            }

            $user_code{InputEvent}(@_);
        },

        #   }}}
        #   send:           Send Data {{{

        send        => sub {
            my $cheap = $heap{$_[ARG0]};

            unless (defined $_[ARG1]) {
                return printf STDERR  
                    "send called without socket or data %s: line %d\n",
                    @_[CALLER_FILE, CALLER_LINE];
            }
            elsif (defined $cheap->{-SERVER}) {
                if (DEBUG) {
                    print "$_[ARG0] >> $_[ARG1]\n";
                }
                $cheap->{-SERVER}->put( @_[ARG1 .. $#_] );
            } 
        },

        #   }}}
        # }}}
        # Error States {{{
        #   -failure:       Handle Connection Failure (Internal) {{{
    
        -failure   => sub {
            printf "%d !! Disconnected - Failed (%s)\n", $_[ARG3], $_[ARG2] 
                if DEBUG;

            push @_, $heap{$_[ARG3]};
            # di ko alam kahit needed ito
            $user_code{FailureEvent}->(@_) if $_[CHEAP]{-RUNNING};

#           Redundant ( This is done in shutdown )
#            delete $_[CHEAP];
#            delete $heap{$_[ARG3]}{-SERVER};

            $_[ARG0] = $_[ARG3];
            $code->{shutdown}->(@_);
        },
    
        #   }}}
        #   -error:         Handle Connection Error (Internal) {{{

        -error     => sub { 
            printf "%d !! Disconnected - Error\n", $_[ARG3] if DEBUG;
    
            push @_, $heap{$_[ARG3]};
            $user_code{ErrorEvent}->(@_) if $_[CHEAP]{-RUNNING};
    
#           Redundant
#            delete $_[CHEAP];
#            delete $heap{$_[ARG3]}{-SERVER};
    
            $_[ARG0] = $_[ARG3];
            $code->{shutdown}->(@_);
        }, 
    
        #   }}}
        #   -timeout:       Handle Connection Timeout (Internal) {{{
        # Occsaionally -timeout is being called after the connection errors,
        # thats what the extra check on -RUNNING is for, as well as in the
        # other error states, just to ensure there is no problem.  This doesn't
        # really happen anymore but I'm not comfortable with it yet.

        -timeout   => sub {
# 20050330: timeouts aren't getting cleaned up!            
#            if ($heap{$_[ARG0]}{-RUNNING}) {
                printf "%d ** Disconnected - Timeout\n", $_[ARG0] if DEBUG;
    
                push @_, delete $heap{$_[ARG0]};

                $user_code{TimeoutEvent}->(@_);

                $user_code{Disconnected}->(@_);

                # Just incase the cheap hangs around clean up the wheel
                delete $_[CHEAP]->{-SERVER};
                delete $_[CHEAP];
    
#               kase sabi ito dalawa ng
#               $code->{shutdown}->(@_);
#            }
        },
    
        #   }}}
        # }}}
        # Closing States {{{
        #   -flushed:       Empty Socket (Internal) {{{

        # flush - our socket is empty - Direct call is faster and fits reqs.
#       -flushed   => sub {
#           unless ($heap{$_[ARG0]}{-RUNNING}) {
#               $code->{shutdown}->(@_);
#           } 
#       },
    
        #   }}}
        #   shutdown:       Handle Socket Shutdown {{{

        # Shutdown... push onto queue if not sent, delete driver.
        shutdown	=> sub {
            my ($kernel, $id) = @_[ KERNEL, ARG0 ];

            unless (defined $id) {
                return printf STDERR  
                    "shutdown called without CHEAP id %s: line %d\n",
                    @_[CALLER_FILE, CALLER_LINE];
            }
            unless (exists $heap{$id}) {
                die "$_[ARG0]: Socket doesn't exist?";
            }


            push @_, my $cheap = delete $heap{$id};

            $cheap->{-RUNNING} = 0;

# Shutdown is now impolite.            
#           if (defined $heap{$_[ARG0]}{-SERVER}) {
#               if ($heap{$_[ARG0]}{-SERVER}->can("get_driver_out_octets")) {
#                   unless ($heap{$_[ARG0]}{-SERVER}->get_driver_out_octets) {
                        printf "%d -- Disconnected - Closed\n", $_[ARG0] 
                            if DEBUG;
    
                        # Remove Alarm, tanga ko ba!? 
                        $kernel->alarm_remove 
                            ( delete $cheap->{-ALARM} );

                        $user_code{Disconnected}->(@_);
                        
                        # Blow shit up
                        delete $_[CHEAP];
#                   }
    
                    # Its either gone and we're out of synch (shouldn't happen),
                    # or we want to wait for a clean shutdown.
                    return;
#               } 
#           }    
            # Our wheel is dead if we didn't return above.
            # This is kind of redundant, but much of this module is.
            $_[KERNEL]->alarm_remove ( delete $heap{$_[ARG0]}{-ALARM} );

            push @_, $heap{$_[ARG0]};
            $user_code{Disconnected}->(@_);
    
            delete $_[CHEAP];
            delete $heap{$_[ARG0]};
    
# Don't do this unless we're flushed...
# delete $heap{$_[ARG0]};
        },
    
        #   }}}
        #   die:            Gracefully close all sockets {{{
        # Shutdown quick, clean and gracefull. 

        die         => sub {
            $_[KERNEL]->call(shutdown => $_) for keys %heap;
            $_[KERNEL]->alias_remove($_) for $_[KERNEL]->alias_list;
            $_[KERNEL]->alarm_remove_all;
        },

        #   }}}
        # }}}
    }; 
    # }}}
    # Session Constructor {{{

    POE::Session->create
        ( inline_states => { %{ delete $user_code{inline_states} }, %$code },
          object_states     => delete $user_code{object_states},
          package_states    => delete $user_code{package_states},
          options           => delete $user_code{options},
          args              => delete $user_code{args},
        );

    # }}}
}

# }}}
# Connect Method {{{

sub connect {
    my %Options = @_[1..$#_];
    $Options{Heap} ||= {};

    printf STDERR "!!! -> connect method called from %s:%d\n",
           (caller)[1,2] if DEBUG;


    my $server = POE::Wheel::SocketFactory->new
        ( RemoteAddress => $Options{RemoteAddress},
          RemotePort    => $Options{RemotePort},
          BindAddress   => $Options{BindAddress},
          BindPort      => $Options{BindPort},
          SuccessEvent  => '-success',
          FailureEvent  => '-failure',
          Reuse         => 'yes',
        );
    
    my $id = $server->ID; 

    printf TRACE "->connect(count %d, id %d, host (%s:%d) %s:%d);\n",
           scalar keys %heap, $id, @Options{qw( RemoteAddress RemotePort )},
           (caller)[1,2] if TRACE_CONNECT;

    $heap{$id} = bless {
        %{ $Options{Heap} },
        -ID         => $server->ID,
        -ADDR       => $Options{RemoteAddress},
        -PORT       => $Options{RemotePort},
        -BINDA      => $Options{BindAddress},
        -BINDP      => $Options{BindPort},
        -RUNNING    => 1,
        -TIMEOUT    => $Options{Timeout},
        -SERVER     => $server,
        -STAMP      => time,
    }, __PACKAGE__ . "::CHEAP";
    
    if ($heap{$id}{-TIMEOUT}) {
        $heap{$id}{-ALARM}  = $poe_kernel->delay_set
            ( -timeout => $heap{$id}{-TIMEOUT}, $id, $heap{$id}{email});
    }
    else {
        $heap{$id}{-ALARM} = 0;
    }

    printf "%d ++ Connecting %s:%d \n", $id, @{ $heap{$id} }{qw( -ADDR -PORT )}
        if DEBUG;

    return $heap{$id};
}

# }}}
# CHEAP Package {{{

package POE::Component::Client::TCPMulti::CHEAP;
use POE::Kernel;

#   Attribute Accessors {{{
sub ID {
    shift->{-ID}
}
sub ADDR {
    shift->{-ADDR}
}
sub PORT {
    shift->{-PORT}
}
#   }}}
#   Filter Settings {{{

sub filter {
    shift->{-SERVER}->set_filter( shift->new(@_) );
}

sub input_filter {
    shift->{-SERVER}->set_input_filter( shift->new(@_) );
}

sub output_filter {
    shift->{-SERVER}->set_output_filter( shift->new(@_) );
}

# }}}
#   Timeout Setting {{{

sub timeout {
    my ($cheap, $timeout) = @_;

    $poe_kernel->alarm_remove($cheap->{-ALARM}) if $cheap->{-ALARM};

    unless (defined $timeout) {
        return $cheap->{-TIMEOUT};
    }
    if ($timeout) {
        $cheap->{-TIMEOUT} = $timeout;
        $cheap->{-STAMP} = time;
        $cheap->{-ALARM} = $poe_kernel->delay_set
            ( -timeout => $cheap->{-TIMEOUT}, $cheap->{-ID});
    }
    else {
        $cheap->{-TIMEOUT} = 0;
        $cheap->{-ALARM}   = 0;
        $cheap->{-STAMP}   = 0;
    }
}

#   }}}
# }}}

return "POE Rules";
