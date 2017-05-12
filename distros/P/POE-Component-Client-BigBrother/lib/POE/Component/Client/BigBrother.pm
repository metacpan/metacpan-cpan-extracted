package POE::Component::Client::BigBrother;

use strict;
use warnings;

use Carp;
use POE qw< Component::Client::TCP >;

our $VERSION = '1.00';


#
# send()
# ----
sub send {
    my ($class, %param) = @_;

    # check for mandatory parameters
    my @mandatory = qw< host event command_type command_fields >;
    for my $name (@mandatory) {
        croak "error: $class requires a '$name' parameter"
            unless $param{$name};
    }

    # default values
    $param{port}    = 1984  unless defined $param{port};
    $param{timeout} = 10    unless defined $param{timeout};
    $param{retry}   = 2     unless defined $param{retry};

    # aliases
    my $field   = $param{command_fields};

    # check for mandatory fields common to all commands
    @mandatory = qw< host service message >;
    for my $name (@mandatory) {
        croak "error: '$param{command_type}' command requires a '$name' field"
            unless $field->{$name};
    }

    # check and adapt some values to Big Brother message format
    (my $host   = $field->{host}) =~ s/\./,/g;
    my $service = $field->{service};
    my $color   = $field->{color};
    my $offset  = $field->{offset} ? "+$field->{offset}" : "";

    # construct the Big Brother message
    if ($param{command_type} eq "status" or $param{command_type} eq "page") {
        $param{message} = "$param{command_type}$offset"
                        . " $host.$service $color $field->{message}";
    }
    elsif ($param{command_type} eq "disable") {
        $param{message} = "$param{command_type}$offset"
                        . " $host.$service $field->{duration} $field->{message}";
    }
    elsif ($param{command_type} eq "enable") {
        $param{message} = "$param{command_type}$offset"
                        . " $host.$service $field->{message}";
    }
    elsif ($param{command_type} eq "event") {
        $field->{activation} ||= time();
        $param{message} = join "", "event\n",
            map { "$_: $field->{$_}\n" } sort keys %$field;
    }
    else {
        croak "error: Unknown command type '$param{command_type}'"
    }

    # spawn a PoCo::Client::TCP to send the message
    POE::Component::Client::TCP->new(
        RemoteAddress   => $param{host},
        RemotePort      => $param{port},
        ConnectTimeout  => $param{timeout},
        Args            => [ { %param } ],

        Started         => sub {
            my ($kernel, $heap, $sender, $param)
                = @_[ KERNEL, HEAP, SENDER, ARG0 ];

            my $sender_id;

            # resolve sender session
            if ($param->{session}) {
                if (my $ref = $kernel->alias_resolve($param->{session})) {
                    $sender_id = $ref->ID;
                }
                else {
                    croak "error: Could not resolve 'session' to a valid "
                        . "POE session";
                }
            }
            else {
                $sender_id = $sender->ID;
            }

            # store some information in the heap
            $heap->{sender_id}  = $sender_id;           # sender session ID
            $heap->{retry}      = $param->{retry} + 1;  # number of retries left
            $heap->{param}      = $param;               # input parameters

            # store the future response in the heap
            $heap->{response} = {
                host    => $param->{host},
                message => $param->{message},
                context => $param->{context},
                success => 1,
            };
        },

        Connected       => sub {
            my ($kernel, $heap) = @_[ KERNEL, HEAP ];
            my $data = $heap->{param}{message};
            $heap->{server}->put($data);    # send the message
            $kernel->yield("shutdown");     # close the connection
        },

        ServerInput     => sub {}, # no input is expected from the server

        Disconnected    => sub {
            my ($kernel, $heap) = @_[ KERNEL, HEAP ];
            $kernel->yield("_send_response");
        },

        ConnectError    => sub {
            my ($kernel, $heap, $op, $errno, $errstr)
                = @_[ KERNEL, HEAP, ARG0..ARG2 ];

            $heap->{retry}--;

            if ($heap->{retry} > 0) {
                $kernel->yield("reconnect");
            }
            else {
                $heap->{response}{success}  = 0;
                $heap->{response}{error}    = "$op error $errno: $errstr";
                $kernel->yield("_send_response");
            }
        },

        InlineStates => {
            _send_response  => sub {
                my ($kernel, $heap) = @_[ KERNEL, HEAP ];

                my $session = $heap->{sender_id};
                my $event   = $heap->{param}{event};
                my $response= $heap->{response};

                # send the response to the send session
                $kernel->post($session, $event, $response);
            },
        },
    );
}


1;

__END__

=head1 NAME

POE::Component::Client::BigBrother - a POE Component for sending Big Brother commands


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use strict;
    use POE qw< Component::Client::BigBrother >;

    POE::Session->create(
        inline_states => {
            _start => sub {
                POE::Component::Client::BigBrother->send(
                    host    => $bbhost,
                    event   => "_result",
                    command_type    => "status",
                    command_fields  => {
                        host        => "front01.domain.net",
                        service     => "cpu",
                        color       => "red",
                        message     => "load average is 105.45",
                    },
                );
            },
            _result => sub {
                my $result = $_[ARG0];
            },
        },
    );

=head1 DESCRIPTION

POE::Component::Client::BigBrother is a POE component which can be used
to send commands to a Big Brother server.

This module tries to follow POE::Component::Client::NSCA API whenever
possible.


=head1 METHODS

=head2 send()

B<Parameters>

=over

=item * host

I<(mandatory)> Big Brother server name

=item * port

I<(optional)> Big Brother server port, default 1984

=item * timeout

I<(optional)> number of seconds to wait for socket timeouts, default is 10

=item * retry

I<(optional)> number of times to retry connecting after an error, default is 2

=item * event

I<(mandatory)> the event handler in your session where the result
should be sent

=item * session

I<(optional)> your session name, in case this component is from from within
another session

=item * command_type

I<(mandatory)> command type, must be one of C<status>, C<page>, C<enable>,
C<disable>, C<event>

=item * command_fields

I<(mandatory)> command fields, must be a hash reference, with the appropriate
fields; see L<"COMMANDS">

=back


=head1 COMMANDS

=head2 C<status> and C<page> commands

=over

=item * host

I<(mandatory)> the host name this command applies to

=item * service

I<(mandatory)> the service name this command applies to

=item * color

I<(mandatory)> the color (result) of this command, must be one of:
C<green>, C<yellow>, C<red>

=item * message

I<(mandatory)> the message body of this command

=item * offset

I<(optional)> the offset of this command

=back


=head2 C<disable> command

=over

=item * host

I<(mandatory)> the host name this command applies to

=item * service

I<(mandatory)> the service name this command applies to

=item * message

I<(mandatory)> the message body of this command

=item * duration

I<(mandatory)> the period of time during which the service is to be disabled

=item * offset

I<(optional)> the offset of this command

=back


=head2 C<enable> command

=over

=item * host

I<(mandatory)> the host name this command applies to

=item * service

I<(mandatory)> the service name this command applies to

=item * message

I<(mandatory)> the message body of this command

=item * offset

I<(optional)> the offset of this command

=back


=head2 C<event> command

=over

=item * host

I<(mandatory)> the host name this command applies to

=item * service

I<(mandatory)> the service name this command applies to

=item * id

I<(mandatory)> the event message ID; should be unique

=item * activation

I<(optional)> the activation time as a Unix timestamp;
defaults to the current time

=item * expiration

I<(optional)> the expiration time as a Unix timestamp

=item * escalation

I<(optional)> the escalation time as a Unix timestamp

=item * color

I<(mandatory)> the color of this event message

=item * escalation_color

=item * title

=item * message

=item * default

=item * order

=item * persistence

=item * suppress

=item * suppress_id

=item * suppress_if_non_defaults

=back


=head1 OUTPUT EVENT

This event is generated by the component. C<ARG0> will be a hash reference
with the following keys:

=over

=item * host

the hostname given

=item * message

the message that was sent

=item * context

anything that you specified

=item * success

indicates that the check was successfully sent to the NSCA daemon

=item * error

only exists if something went wrong

=back


=head1 DIAGNOSTICS

=over

=item '%' command requires a '%' field

B<(E)> The caller did not provide the indicated field for the given command.

=item %s requires a '%s' parameter

B<(E)> The caller did not provide the indicated parameter to the component.

=item Could not resolve 'session' to a valid POE session

B<(E)> The value of the given C<session> parameter could not be resolved to
a running POE session.

=item Unknown command type '%'

B<(E)> An illegal value was given for the C<command_type> parameter.

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-component-client-bigbrother at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=POE-Component-Client-BigBrother>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Client::BigBrother

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=POE-Component-Client-BigBrother>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Client-BigBrother>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Client-BigBrother>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Client-BigBrother/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 SE<eacute>bastien Aperghis-Tramoni.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

