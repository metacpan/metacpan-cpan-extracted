# Copyright (c) 2005 - 2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: SMTP.pm,v 1.25 2009/09/02 08:23:37 UltraDM Exp $

package POE::Component::Client::SMTP;

# TODO:
# * more nice output in debug mode

use warnings;
use strict;

our $VERSION = q{0.22};

use Data::Dumper;
use Carp;
use Socket;
use Symbol qw( gensym );
use POE;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use POE::Filter::Line;
use POE::Filter::Stream;
use POE::Filter::Transparent::SMTP;

# End of line as specified by SMTP RFC
my $EOL = qq{\015\012};

# an alias to _create currently
# perhaps it could have dual behaviour in the future
sub send {
    _create(@_);
    return 1;
}

# Create session
sub _create {
    my $class      = shift;
    my %parameters = @_;

    # some checking
    croak q{not an object method} if ( ref $class );

    # The actual Object;
    # fill the PoCo parameter from the parameters we got and add the
    # defaults where the parameters are not supplied
    my $self = bless _fill_data( \%parameters ), $class;

    # store the caller
    $self->parameter( q{Caller_Session}, $poe_kernel->get_active_session() );

    # did we sent the callback event back?
    # used so that the poco won't send multiple events for the same
    # SMTP session
    $self->parameter( q{message_sent}, 0 );

    # Spawn the PoCoClient::SMTP session
    POE::Session->create(
        q{object_states} => [
            $self => {
                q{_start}   => q{_pococlsmtp_start},
                q{_stop}    => q{_pococlsmtp_stop},
                q{_default} => q{_pococlsmtp_default},

                # public available events
                q{smtp_shutdown} => q{_pococlsmtp_shutdown},
                q{smtp_progress} => q{_pococlsmtp_progress},

                # internal events SMTP codes and stuff
                q{smtp_send} => q{_pococlsmtp_send},

                # network related
                q{connection_established} => q{_pococlsmtp_conn_est},
                q{connection_error}       => q{_pococlsmtp_conn_err},
                q{smtp_session_input}     => q{_pococlsmtp_input},
                q{smtp_session_error}     => q{_pococlsmtp_error},
                q{smtp_timeout_event}     => q{_smtp_timeout_handler},

                q{_build_commands}        => q{_build_commands},
                q{_build_expected_states} => q{_build_expected_states},

                # return events
                q{return_failure} => q{_pococlsmtp_return_error_event},

                # file slurping
                q{_get_file}               => q{_get_file},
                q{_slurp_file_input_event} => q{_slurp_file_input_event},
                q{_slurp_file_error_event} => q{_slurp_file_error_event},
            },
        ],
    );
    return 1;
}

# EVENT HANDLERS

# event: _start
sub _pococlsmtp_start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    carp q{CURRENT STATE: _pococlsmtp_start} if $self->debug;

    # in case there's no alias, use refcount
    if ( $self->parameter(q{Alias}) ) {
        $kernel->alias_set( $self->parameter(q{Alias}) );
    }
    else {
        $kernel->refcount_increment(
            $kernel->get_active_session()->ID() => __PACKAGE__ );
    }

    # build expected states
    $kernel->yield(q{_build_expected_states});

    return 1;
}

# event: _stop
sub _pococlsmtp_stop {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    carp q{CURRENT STATE _pococlsmtp_stop} if $self->debug;
    return 1;
}

# event: _default
sub _pococlsmtp_default {
    my ($self) = $_[OBJECT];
    carp q{CURRENT STATE _pococlsmtp_default} if $self->debug;
    return 1;
}

# this takes care of wheel creation and initial handshake with the SMTP server
# event: smtp_send
sub _pococlsmtp_send {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    my ( %options, $wheel, $alarm );

    carp q{CURRENT STATE: _pococlsmtp_send} if $self->debug;

    %options = (
        q{RemoteAddress}  => $self->parameter(q{Server}),
        q{RemotePort}     => $self->parameter(q{Port}),
        q{SocketDomain}   => AF_INET,
        q{SocketType}     => SOCK_STREAM,
        q{SocketProtocol} => q{tcp},
        q{Reuse}          => q{yes},
        q{SuccessEvent}   => q{connection_established},
        q{FailureEvent}   => q{connection_error},
    );

    # set BindAddress and BindPort if any.
    for my $opt ( q{BindAddress}, q{BindPort} ) {
        if ( defined $self->parameter($opt) ) {
            $options{$opt} = $self->parameter($opt);
        }
    }

    # set the alarm for preventing timeouts
    $alarm =
      $kernel->delay_set( q{smtp_timeout_event}, $self->parameter(q{Timeout}) );

    # store the alarm to be used when talking to the SMTP server
    $self->_alarm($alarm);

    $wheel = POE::Wheel::SocketFactory->new( %options, );

    # store the wheel
    $self->store_sf_wheel($wheel);

    return 1;
}

# event: connection_established
# event: SuccessEvent
sub _pococlsmtp_conn_est {
    my ( $kernel, $self, $socket ) = @_[ KERNEL, OBJECT, ARG0 ];
    my ( $wheel, $alarm );

    carp q{CURRENT STATE: _pococlsmtp_conn_est} if $self->debug;

    $wheel = POE::Wheel::ReadWrite->new(
        q{Handle}       => $socket,
        q{InputFilter}  => POE::Filter::Transparent::SMTP->new(),
        q{OutputFilter} => POE::Filter::Transparent::SMTP->new(),
        q{InputEvent}   => q{smtp_session_input},
        q{ErrorEvent}   => q{smtp_session_error},
    );

    # set the alarm for preventing timeouts
    $alarm =
      $kernel->delay_set( q{smtp_timeout_event}, $self->parameter(q{Timeout}) );

    # store the wheel
    $self->store_rw_wheel($wheel);

    # store the alarm; this is used while 'talking' with the SMTP server, during
    # _pococlsmtp_input
    $self->_alarm($alarm);

    return 1;
}

# event: connection_error
# event: FailureEvent
sub _pococlsmtp_conn_err {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    carp q{CURRENT STATE: _pococlsmtp_conn_err} if $self->debug;

    # send back to the caller the error which is generated during the
    # connection establishing
    $kernel->yield( q{return_failure},
        { q{POE::Wheel::SocketFactory} => [ @_[ ARG0 .. ARG3 ] ] } );

    return 1;
}

# we've got our connection established, now we're processing input
# event: InputEvent
# event: smtp_session_input
sub _pococlsmtp_input {
    my ( $kernel, $self, $input, $wheel_id ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    my ( $smtp_code, $smtp_string, $to_send );

    carp q{CURRENT STATE: _pococlsmtp_input} if $self->debug;

    # reset alarm
    $kernel->delay_adjust( $self->_alarm, $self->parameter(q{Timeout}), );

    if ( $self->parameter(q{TransactionLog}) ) {

        # add to the transaction log
        $self->_transaction_log( q{<- } . $input );
    }

    # allright, received something in the form XXX text
    if (
        $input =~ /
                    ^(\d{3})    # first 3 digits
                    \s+
                    (.*)$       # SMTP message corresponding to the SMTP code
                    /xo
        or $input =~ /
			 ^(\d{3})
			 \s*$ # in case there's no status message  ...
		     /xo
      )
    {

        # is the SMTP server letting us know there's a problem?
        ( $smtp_code, $smtp_string ) = ( $1, $2 );
        if ( not defined $smtp_string ) {

            # in case there's no status message from server
            $smtp_string = q{Inserted by PoCoClSMTP: }
              . q{Server didn't sent any status message along with the status code!};
        }
        if ( not defined $smtp_code ) {
            $smtp_code = q{Inserted by PoCoClSMTP: }
              . q{Server didn't replied with a status code as expected!};
        }
        if ( $smtp_code =~ /^(1|2|3)\d{2}$/ ) {

            # we're ok
            # and also stupid, don't know estmp, don't know 1XY codes
            $to_send = $self->command;

            if ( not defined $to_send ) {

                # this is the end of the 'commands' we had stored for sending to
                # the server
                if ( not $self->parameter(q{message_sent}) ) {
                    carp q{Sending SUCCESS event to the caller session}
                      if $self->debug;

                    # send callback only once
                    $kernel->post(
                        $self->parameter(q{Caller_Session}),
                        $self->parameter(q{SMTP_Success}),
                        $self->parameter(q{Context}),
                        $self->_transaction_log(),
                    );
                }

                $self->parameter( q{message_sent}, 1 );
                $self->_smtp_component_destroy;
            }
            else {
                carp qq{PoCoClSMTP TO SEND: "$to_send"} if $self->debug;
                if ( $self->parameter(q{TransactionLog}) ) {
                    $self->_transaction_log( q{-> } . $to_send );
                }
                $self->store_rw_wheel->put($to_send);
            }
        }
        elsif (
            $smtp_code =~ /
                         ^(4|5)\d{2}$    # look for error codes (starting with 4 or 5)
                                /xo
          )
        {
            carp qq{Server Error! $input } if $self->debug;

            # the server responded with 4XY or 5XY code;
            # while 4XY is temporary failure, 5XY is permanent
            # it's unclear to me whether PoCoClientSMTP should retry in case of
            # 4XY or the user should. In case is PoCoClientSMTP's job, then I
            # should define for how many times and what interval
            $kernel->yield( q{return_failure},
                { q{SMTP_Server_Error} => $input } );
        }
        else {

            # oops! we shouldn't end-up here unless the server is buggy
            carp qq{Error! I don't know the SMTP Code! "$input"}
              if $self->debug;
            $kernel->yield( q{return_failure},
                { q{SMTP_Server_Error} => $input } );
        }
    }
    elsif (
        $input =~ /
                        # these lines are advertising SMTP capabilities
                        ^(\d{3})    # 3 digits
                        \-          # separator
                        (.*)$       # capability
                    /xo
      )
    {
        if ( $self->parameter(q{Debug}) > 1 ) {
            carp qq{ESMTP Server capability: "$input"};
        }
    }
    else {
        carp qq{Received unknown string type from SMTP server, "$input"}
          if $self->debug;
        $kernel->yield( q{return_failure}, { q{SMTP_Server_Error} => $input } );
    }

    return 1;
}

# event: smtp_session_error
# event: ErrorEvent
sub _pococlsmtp_error {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    carp q{CURRENT STATE: _pococlsmtp_error} if $self->debug;
    $kernel->yield( q{return_failure},
        { q{POE::Wheel::ReadWrite} => [ @_[ ARG0 .. ARG3 ] ] } );
    return 1;
}

# event: smtp_timeout_event
sub _smtp_timeout_handler {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    carp q{CURRENT STATE: _smtp_timeout_handler} if $self->debug;
    $kernel->yield( q{return_failure},
        { q{Timeout} => $self->parameter(q{Timeout}) } );
    return 1;
}

# event: return_failure
sub _pococlsmtp_return_error_event {
    my ( $kernel, $self, $arg, $session ) = @_[ KERNEL, OBJECT, ARG0, SESSION ];
    carp q{CURRENT STATE: _pococlsmtp_return_error_event} if $self->debug;
    my $error = $arg;

    my $error_line = q{};
    foreach my $key ( keys %{$error} ) {
        $error_line .= $key . q{: };
        my $value = $error->{$key};
        if ( ref $value eq q{ARRAY} ) {
            $error_line .= join( q{, }, @{$value} );
        }
        else {
            $error_line .= $value;
        }
    }

    # send the callback just once
    if ( not $self->parameter(q{message_sent}) ) {
        carp q{Sending FAIL event to the caller session} if $self->debug;
        $kernel->post(
            $self->parameter(q{Caller_Session}),
            $self->parameter(q{SMTP_Failure}),
            $self->parameter(q{Context}),
            $arg,
            $self->_transaction_log,
            $error_line,
        );
    }
    $self->parameter( q{message_sent}, 1 );
    $self->_smtp_component_destroy;
    return 1;
}

sub _smtp_component_destroy {
    my $self = shift;

    carp q{CURRENT STATE: _smtp_component_destroy} if $self->debug;

    # remove alarms set for the Timeout
    $poe_kernel->alarm_remove_all();

    # in case there's no alias, use refcount
    if ( $self->parameter(q{Alias}) ) {
        $poe_kernel->alias_remove( $self->parameter(q{Alias}) );
    }
    else {
        $poe_kernel->refcount_decrement(
            $poe_kernel->get_active_session()->ID() => __PACKAGE__ );
    }

    # delete all wheels
    $self->delete_rw_wheel;
    $self->delete_sf_wheel;
    $self->delete_file_wheel;

    return 1;
}

# place holder for future closing shutdown of the component
# useful in case the component will be sending multiple messages
# event: smtp_shutdown
sub _pococlsmtp_shutdown {
}

# place holder for future sending back "progress events" in case
# sending multiple messages
# event: smtp_progress
sub _pococlsmtp_progress {
}

# END OF EVENT HANDLERS

# UNDER THE HOOD

# take parameters, do checks on them and fill the object with data
sub _fill_data {
    my $parameters = shift;
    my $smtp_hash;

    # defaults
    my %default = (
        q{To}           => q{root@localhost},
        q{From}         => q{root@localhost},
        q{Body}         => q{},
        q{Server}       => q{localhost},
        q{Port}         => 25,
        q{Timeout}      => 30,
        q{MyHostname}   => q{localhost},
        q{BindAddress}  => undef,
        q{BindPort}     => undef,
        q{Debug}        => 0,
        q{Alias}        => undef,
        q{Context}      => undef,
        q{SMTP_Success} => undef,
        q{SMTP_Failure} => undef,
        q{Auth}         => {
            q{mechanism} => undef,
            q{user}      => undef,
            q{pass}      => undef,
        },
        q{MessageFile}    => undef,
        q{FileHandle}     => undef,
        q{TransactionLog} => undef,
    );

    #check parameters and set them to defaults if they don't exist
    for my $parameter ( keys %default ) {
        if ( exists $parameters->{$parameter} ) {
            $smtp_hash->{q{Parameter}}->{$parameter} =
              $parameters->{$parameter};
        }
        else {
            $smtp_hash->{q{Parameter}}->{$parameter} = $default{$parameter};
        }
    }

    # add supported auth methods
    # for this poco
    $smtp_hash->{q{Auth_Mechanism}} = [q{PLAIN}];

    return $smtp_hash;
}

# accessor/mutator
sub parameter {
    my ( $self, $parameter, $value ) = ( shift, shift, shift );

    croak q{This is an object method only} if ( not ref $self );
    croak q{need a parameter!} if ( not defined $parameter );

    if ( defined $value ) {
        $self->{q{Parameter}}->{qq{$parameter}} = $value;
    }

    return $self->{q{Parameter}}->{qq{$parameter}};
}

# accessor/mutator
# stores and returns the SocketFactory wheel
sub store_sf_wheel {
    my ( $self, $wheel ) = ( shift, shift );
    croak q{not a class method} if ( not ref $self );
    if ( defined $wheel ) {
        $self->{q{Wheel}}->{q{SF}}->{$wheel} = $wheel;
    }
    return $self->{q{Wheel}}->{q{SF}};
}

# if specified which SocketFactory wheel to delete it deletes it;
# if not specified, it deletes ALL SocketFactory wheels
sub delete_sf_wheel {
    my ( $self, $wheel ) = ( shift, shift );
    croak q{not a class method} if ( not ref $self );
    if ( defined $wheel ) {
        return delete $self->{q{Wheel}}->{q{SF}}->{$wheel};
    }
    else {
        my $sf_wheel = delete $self->{q{Wheel}}->{q{SF}};
    }
}

sub store_rw_wheel {
    my ( $self, $wheel ) = ( shift, shift );
    my $ret;

    croak q{not a class method} if ( not ref $self );

    if ( defined $wheel ) {
        $self->{q{Wheel}}->{q{RW}}->{$wheel} = $wheel;
        $ret = $self->{q{Wheel}}->{q{RW}}->{$wheel};
    }
    else {
        foreach my $key ( keys %{ $self->{q{Wheel}}->{q{RW}} } ) {
            $ret = $self->{q{Wheel}}->{q{RW}}->{$key};
            last;
        }
    }

    if ( not defined $ret ) {
        $ret = $self->{q{Wheel}}->{q{RW}};
    }

    return $ret;

}

sub delete_rw_wheel {
    my ( $self, $wheel ) = ( shift, shift );
    croak q{not a class method} if ( not ref $self );
    if ( defined $wheel ) {
        return delete $self->{q{Wheel}}->{$wheel};
    }
    else {
        return delete $self->{q{Wheel}}->{q{RW}};
    }
}

# accessor/mutator
sub store_file_wheel {
    my $self  = shift;
    my $wheel = shift;
    croak 'not a class method' if ( not ref $self );
    if ( defined $wheel ) {
        $self->{'Wheel'}->{'FileWheel'}->{$wheel} = $wheel;
    }
    return $self->{'Wheel'}->{'FileWheel'};
}

sub delete_file_wheel {
    my ( $self, $wheel ) = ( shift, shift );
    croak q{not a class method} if ( not ref $self );
    if ( defined $wheel ) {
        return delete $self->{q{Wheel}}->{q{FileWheel}}->{$wheel};
    }
    else {
        return delete $self->{q{Wheel}}->{q{FileWheel}};
    }
}

# accessor/mutator for the alarm
sub _alarm {
    my ( $self, $alarm ) = ( shift, shift );
    croak q{not a class method} if ( not ref $self );
    if ( defined $alarm ) {
        $self->{q{session_alarm}} = $alarm;
        return $self;
    }
    else {
        return $self->{q{session_alarm}};
    }
}

# return the current expected state
# return value is a list of expected values
sub _state {
    my $self = shift;
    croak q{not a class method} if ( not ref $self );
    return shift @{ $self->{q{State}} };
}

# build the expected list of states for every SMTP command we will be sending
# event: _build_expected_states
sub _build_expected_states {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    my ( @states, $rcpt_to );

    croak q{not a class method} if ( not ref $self );

    carp q{CURRENT STATE: _build_expected_states} if $self->debug;

    # initial state, the SMTP server greeting
    push @states, [ 220, 221 ];

    # "ehlo" command
    push @states, [ 250, 251 ];

    # TODO: check if server only supports HELO (is this sane nowadays?)

    if ( defined $self->parameter(q{Auth})->{q{mechanism}} ) {

        # "auth" command
        push @states, [235];
    }

    # "mail from" command
    push @states, [ 250, 251 ], $rcpt_to = \$self->parameter(q{To});

    # "rcpt to" command
    if ( ref( ${$rcpt_to} ) =~ /SCALAR/io ) {
        push @states, [ 250, 251 ];
    }
    elsif ( ref( ${$rcpt_to} ) =~ /ARRAY/io ) {
        for ( 0 .. $#{ ${$rcpt_to} } ) {
            push @states, [ 250, 251 ];
        }
    }
    else {
        push @states, [ 250, 251 ];
    }

    # "data" command:
    push @states, [ 354, ];

    # dot command
    push @states, [ 250, ];

    # "quit" command
    push @states, [ 221, ];

    $self->{q{State}} = @states;

    if (   defined $self->parameter(q{MessageFile})
        or defined $self->parameter(q{FileHandle}) )
    {
        $kernel->yield(q{_get_file});
    }
    else {
        $kernel->yield(q{_build_commands});
    }
    return $self;
}

# event: _get_file
# in case MessageFile is set, slurp the contents of the file into Body
sub _get_file {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    my ( $handle, $wheel );
    carp q{CURRENT STATE: _get_file} if $self->debug;

    if ( not defined $self->parameter(q{FileHandle}) ) {
        $handle = _open_file( $self->parameter(q{MessageFile}) );
    }
    else {
        $handle = $self->parameter(q{FileHandle});
    }

    if ( not defined $handle ) {

        # no file handle
        carp q{File not found!} if $self->debug;
        $kernel->yield(
            q{return_failure},
            {
                q{MessageFile_Error} =>
                  [ $self->parameter(q{MessageFile}) . q{ not found!} ],
            },
        );
        return;
    }

    if ( defined $self->parameter(q{Body}) ) {
        $self->parameter( q{Body}, q{} );
    }

    $wheel = POE::Wheel::ReadWrite->new(
        q{Handle}     => $handle,
        q{Filter}     => POE::Filter::Stream->new,
        q{InputEvent} => q{_slurp_file_input_event},
        q{ErrorEvent} => q{_slurp_file_error_event},
    );
    $self->store_file_wheel($wheel);
    return 1;

}

# event: InputEvent
# event: _slurp_file_input_event
sub _slurp_file_input_event {
    my ( $self, $kernel, $input ) = @_[ OBJECT, KERNEL, ARG0 ];
    carp q{CURRENT STATE: _slurp_file_input_event} if $self->debug;
    $self->parameter( q{Body}, $self->parameter(q{Body}) . $input );
    return 1;
}

# event: ErrorEvent
# event: _slurp_file_error_event
sub _slurp_file_error_event {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    my ( $operation, $errnum, $errstr, $wheel_id ) = @_[ ARG0 .. ARG3 ];
    carp q{CURRENT STATE: _slurp_file_error_event} if $self->debug;
    if ( $self->debug > 1 ) {
        carp <<"EOER";
Operation: $operation
ERRNUM: $errnum
ERRSTR: $errstr
WHEELID: $wheel_id
EOER
    }
    if ( $errnum == 0 ) {

        # go to the next step, building the commands, now that we have
        # the Body filled with the file contents
        # Escape single dots on a line
        my $filter =
          POE::Filter::Transparent::SMTP->new( q{EscapeSingleInputDot} => 1, );
        my $lines = $self->parameter(q{Body});
        $lines = $filter->get( [$lines] );
        $lines = $filter->put($lines);
        $self->parameter( q{Body}, join( q{}, @{$lines} ) );
        $kernel->yield(q{_build_commands});
    }
    else {

        # we've got an wheel error!
        $kernel->yield(
            q{return_failure},
            {
                q{POE::Wheel::ReadWrite} =>
                  [ $operation, $errnum, $errstr, $wheel_id ]
            }
        );
    }

    return 1;
}

# return the next command
sub command {
    my $self = shift;

    croak q{not a class method} if ( not ref $self );

    return shift @{ $self->{q{Command}} };

}

# build the list of commands
# event: _build_commands
sub _build_commands {
    my ( $kernel, $self, $session ) = @_[ KERNEL, OBJECT, SESSION ];
    my ( @commands, $mechanism, $user, $pass, $rcpt_to, $body );

    croak q{not a class method} if ( not ref $self );

    carp q{CURRENT STATE: _build_commands} if $self->debug;

    $mechanism = $self->parameter('Auth')->{'mechanism'};
    $user      = $self->parameter('Auth')->{'user'};
    $pass      = $self->parameter('Auth')->{'pass'};
    if ( defined $mechanism ) {
        if ( $self->_is_auth_supported_by_poco($mechanism) ) {

            # here we start ESMTP ...
            if ( defined $user and defined $pass ) {
                my $encoded_data =
                  $self->_encode_auth( $mechanism, $user, $pass );
                push @commands, q{EHLO } . $self->parameter(q{MyHostname});
                push @commands, q{AUTH PLAIN } . $encoded_data;
            }
            else {

                # ERROR: user data not complete
                # remove the next event which is smtp_send
                $kernel->state(q{smtp_send});
                $kernel->yield(
                    q{return_failure},
                    {
                        q{Configure} =>
                          q{ERROR: You want AUTH but no USER/PASS given!}
                    }
                );
            }
        }
        else {

            # ERROR: method unsupported by Component!
            # remove the next event which is smtp_send
            $kernel->state(q{smtp_send});
            $kernel->yield(
                q{return_failure},
                {
                    q{Configure} =>
qq{ERROR: Method unsupported by Component version: $VERSION}
                }
            );
        }
    }
    else {
        push @commands, q{HELO } . $self->parameter(q{MyHostname});
    }

    push @commands, q{MAIL FROM: <} . $self->parameter(q{From}) . q{>};
    $rcpt_to = \$self->parameter(q{To});
    if ( ref( ${$rcpt_to} ) =~ /ARRAY/io ) {
        for my $recipient ( @{ ${$rcpt_to} } ) {
            push @commands, q{RCPT TO: <} . $recipient . q{>};
        }
    }
    elsif ( ref( ${$rcpt_to} ) =~ /SCALAR/io ) {
        push @commands, q{RCPT TO: <} . ${ ${$rcpt_to} } . q{>};
    }
    else {

        # no ref, just a scalar ;-)
        push @commands, q{RCPT TO: <} . ${$rcpt_to} . q{>};
    }
    $body = $self->parameter(q{Body});
    if (    not $self->parameter(q{MessageFile})
        and not $self->parameter(q{FileHandle}) )
    {

        # GRR
        # create the body
        # escape single dots on a line
        my $filter =
          POE::Filter::Transparent::SMTP->new( q{EscapeSingleInputDot} => 1, );
        my $data = $filter->get( [$body] );
        $data = $filter->put($data);
        $body = join( q{}, @{$data} );
        $body .= q{.};
    }
    else {
        $body .= qq{$EOL.};
    }

    push @commands, q{DATA}, $body, q{QUIT};

    $self->{q{Command}} = \@commands;
    $kernel->yield(q{smtp_send});

    return $self;
}

sub debug {
    my ( $self, $debug_level ) = ( shift, shift );
    croak q{not a class method} if ( not ref $self );
    if ( defined $debug_level ) {
        $self->parameter(q{Debug}) = $debug_level;
    }
    return $self->parameter(q{Debug});
}

sub _is_auth_supported_by_poco {
    my ( $self, $requested_mehtod ) = ( shift, shift );
    for my $mechanism ( @{ $self->{q{Auth_Mechanism}} } ) {
        if ( uc($requested_mehtod) eq $mechanism ) {
            return 1;
        }
    }
    return 0;
}

# encode the authentication string
sub _encode_auth {
    my ( $self, $mechanism, $user, $pass ) = ( shift, shift, shift, shift );
    my $encoded_data;

    if ( $mechanism eq q{PLAIN} ) {
        eval { require MIME::Base64 };
        if ($@) {
            carp q{You need to install MIME::Base64 to use AUTH PLAIN!};
            $encoded_data = q{I don't have MIME::Base64 installed};
        }
        else {
            $encoded_data =
              MIME::Base64::encode_base64( qq{\0} . $user . qq{\0} . $pass,
                q{} );
        }
    }
    else {
        croak q{ There's a bug in PoCoClSMTP, we really shouldn't get here!};
    }

    return $encoded_data;
}

sub _open_file {
    my $filename = shift;
    my $handle;

    # does file exist and is readable?
    if ( -e $filename and -r $filename ) {
        $handle = gensym();
        open $handle, q{<}, qq{$filename};
    }
    else {
        $handle = undef;
    }

    return $handle;
}

# accessor/mutator
sub _transaction_log {
    my ( $self, $log ) = ( shift, shift );

    croak q{not a class method} if ( not ref $self );

    if ( defined $log ) {
        push @{ $self->{q{transaction_log}} }, $log;
        return $self;
    }
    else {
        return $self->{q{transaction_log}};
    }
}

# END UNDER THE HOOD

1;    # End of POE::Component::Client::SMTP

__END__

# POD BELOW

=head1 NAME

POE::Component::Client::SMTP - Asynchronous mail sending with POE

=head1 VERSION

Version 0.22

=head1 DESCRIPTION

PoCoClient::SMTP allows you to send email messages in an asynchronous manner,
using POE.

Thus your program isn't blocking while busy talking with an (E)SMTP server.

=head1 SYNOPSIS

B<Warning!> The following examples are B<not> complete programs, and
aren't designed to be run as full blown applications. Their purpose is to
quickly
introduce you to the module.

For complete examples, check the 'eg' directory that can be found in the
distribution's kit.

A simple example:

 # load PoCoClient::SMTP
 use POE::Component::Client::SMTP;
 # spawn a session
 POE::Component::Client::SMTP->send(
     From    => 'foo@baz.com',
     To      => 'john@doe.net',
     Server  =>  'relay.mailer.net',
     SMTP_Success   =>  'callback_event_for_success',
     SMTP_Failure    =>  'callback_event_for_failure',
 );
 # and you are all set ;-)

A more complex example:

 # load PoCoClient::SMTP
 use POE::Component::Client::SMTP;
 # spawn a session
 POE::Component::Client::SMTP->send(
     # Email related parameters
     From    => 'foo@baz.com',
     To      => [
                'john@doe.net',
                'andy@zzz.org',
                'peter@z.net',
                'george@g.com',
                ],
     Body    =>  \$email_body,   # here's where your message is stored
     Server  =>  'relay.mailer.net',
     Timeout => 100, # 100 seconds before timeouting
     # POE related parameters
     Alias           => 'pococlsmtpX',
     SMTP_Success    =>  'callback_event_for_success',
     SMTP_Failure    =>  'callback_event_for_failure',
 );
 # and you are all set ;-)

=head1 METHODS

Below are the methods this Component has:

=head2 send

This immediately spawns a PoCoClient::SMTP Session and registers
itself with the Kernel in order to have its job done. This method may be
overhead for sending bulk messages, as after sending one message it gets
destroyed. Maybe in the future, there will be a I<spawn> method that will keep
the Session around forever, until received a 'shutdown' like event.

=head3 PARAMETERS

There are two kinds of parameters PoCoClient::SMTP supports: Email related
parameters and POE related parameters:

=over 8

=item From

This holds the sender's email address

B<Defaults> to 'root@localhost', just don't ask why.

B<Note:> that the email address has to be a bare email address
(johndoe@example.com), not an RFC2822 email address ("John
Q. Public" <john.q.public@example.com> (The EveryMan))

=item To

This holds a list of recipients. Note that To/CC/BCC fields are separated in
your email body. From the SMTP server's point of view (and from this
component's too) there is no difference as who is To, who CC and who BCC.

The bottom line is: be careful how you construct your email message.

B<Defaults> to root@localhost', just don't ask why.

B<Note:> that the email address has to be a bare email address
(johndoe@example.com), not an RFC2822 email address ("John
Q. Public" <john.q.public@example.com> (The EveryMan))

=item Body

Here's the meat. This scalar contains the message you are sending composed of
Email Fields and the actual message content. You need to construct this by hand
or use another module. Which one you use is a matter of taste ;-)))

B<Note> that I<MessageFile> and I<FileHandle> take precedense over I<Body>.

In case I<MessageFile> or I<FileHandle> are set, I<Body> is discarded.

B<Defaults> to an empty mail body.

=item Server

Here you specify the relay SMTP server to be used by this component. Currently
piping thru sendmail is not supported so you need a SMTP server to actually
do the mail delivery (either by storing the mail somewhere on the hard
drive, or by relaying to another SMTP server).

B<Defaults> to 'localhost'

=item Port

Usually SMTP servers bind to port 25. (See /etc/services if you are using a
*NIX like O.S.).

Sometimes, SMTP servers are set to listen to other ports, in which case you
need to set this parameter to the correct value to match your setup.

B<Defaults> to 25

=item Timeout

Set the timeout for SMTP transactions (seconds).

B<Defaults> to 30 seconds

=item MyHostname

Hostname to present when sending EHLO/HELO command.

B<Defaults> to "localhost"

=item BindAddress

This attribute is set when creating the socket connection to the SMTP server.
See POE::Wheel::SocketFactory for details.

=item BindPort

This attribute is set when creating the socket connection to the SMTP server.
See POE::Wheel::SocketFactory for details.

=item Debug

Set the debugging level. A value greater than 0 increases the Component's
verbosity

B<Defaults> to 0

=item Alias

In case you have multiple PoCoClient::SMTP Sessions, you'd like to handle them
separately, so use Alias to differentiate them.

This holds the Session's alias.

B<Defaults> to nothing. Internally it refcounts to stay alive.

=item Context

You may want to set a context for your POE::Component::Client::SMTP session.
This is a scalar.

When the caller session receives SMTP_Success or SMTP_Failure event, the
context is also passed to it if defined.

=item MessageFile

Specify a file name from where the email body is slurped.

B<Note:> that you still need to specify the parameters like From, To etc.

=item FileHandle

Specify a filehandle from where the email body is slurped.

POE::Component::Client::SMTP does only a basic check on the filehandle it
obtains from FileHandle value; in case you need to do some more sophisticated
checks on the file and filehandle, please do it on your own, and then pass the
handle to the component.

B<It is important that the handle is readable> so please check that before using it.

B<Note:> that you still need to specify the parameters like From, To etc.

=item TransactionLog

In case you want to get back the Log between the client and the server, you
need to enable this.

B<Defaults> to disabled.

=item SMTP_Success

Event you want to be called by PoCoClient::SMTP in case of success.

B<Defaults> to nothing. This means that the Component will not trigger any
event and will silently go away.

=over 8

=item ARG0

Contains Context if any

=item ARG1

ARG1 Contains the SMTP Transaction log if TransactionLog is enabled, in the
form:
 <- string received from server
 -> string to be sent to server
Note that it is possible the string sent to server may not arrive there

ARG1 is undefined if TransactionLog is not enabled

=back

=item SMTP_Failure

Event you want to be called by PoCoClient::SMTP in case of failure.

You will get back the following information:

=over 8

=item ARG0

The Context you've set when spawning the component, or undef if no Context
specified

=item ARG1

A hash ref that currently has only a key:

* SMTP_Server_Error, in this case, the value is the string as returned by the
server (the error code should be included too by the server in the string)

* Timeout, the value is the amount of seconds the timeout was set to

* POE::Wheel::* depending on the wheel that returned error on us ;-)
the value is a ref to an array containing ARG0 .. ARG3

* Configure, for AUTH misconfiguration

* MessageFile_Error for not being able to slurp the contents of the file given
to MessageFile, in case the parameter was set.

Please B<note> that in case the file is opened successfully and we get an error
from the ReadWrite Wheel, then the hash key is 'POE::Wheel::ReadWrite'

=item ARG2

ARG2 Contains the SMTP Transaction log if TransactionLog is enabled, in the
form:
 <- string received from server
 -> string to be sent to server
Note that it is possible the string sent to server may not arrive there

ARG2 is undefined if TransactionLog is not enabled

=item ARG3

This contains a single line (scalar) describing the error. It's useful
for displaying the error in SMTP clients using PoCo

=back

B<Defaults> to nothing. This means that the Component will not trigger any
event and will silently go away.

=item Auth

ESMTP Authentication

Currently supported mechanism: PLAIN

If you are interested in implementing other mechanisms, please send me an email, it should be piece of cake.

Hash ref with the following fields:

=over 8

=item mechanism

The mechanism to use. Currently only PLAIN auth is supported

=item user

User name

=item pass

User password

=back

=back

=head1 SEE ALSO

RFC2821 L<POE> L<POE::Session>

=head1 BUGS

=over 8

=item * Currently the Component sends only HELO to the server, except for when using Auth.

=item * PoCo doesn't keep a list of expected responses from TCP
server, which means that in case the Server is responding something
during DATA transaction, the PoCo will hapily send the message. Please
let me know if this is an issue for someone.

=back

=head2 Bug Reporting

Please report bugs using the project's page interface, at:
L<https://savannah.nongnu.org/projects/pococlsmtp/>

Unified format patches are more than welcome.

=head1 KNOWN ISSUES

=head2 Bare LF characters

Note that the SMTP protocol forbids bare LF characters in e-mail messages.
PoCoClSMTP doesn't do any checking whether you message is SMTP compliant or not.

Most of the SMTP servers in the wild are tolerant with bare LF characters, but
you shouldn't count on that.

The point is you shouldn't send email messages having bare LF characters.
See: http://cr.yp.to/docs/smtplf.html

=head1 ESMTP error codes 1XY

ESMTP error codes 1XY are ignored and considered as 2XY codes

=head1 ACKNOWLEDGMENTS

=over 4

=item BinGOs for ideas/patches and testing

=item Mike Schroeder for ideas

=back

=head1 AUTHOR

George Nistorica, C<< <ultradm@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 - 2007 George Nistorica, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
