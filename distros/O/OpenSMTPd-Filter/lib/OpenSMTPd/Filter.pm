package OpenSMTPd::Filter;
use utf8;        # so literals and identifiers can be in UTF-8
use v5.16;       # or later to get "unicode_strings" feature and "charnames"
use strict;      # quote strings, declare variables
use warnings;    # on by default
use warnings qw(FATAL utf8);           # fatalize encoding glitches
use open qw(:std :encoding(UTF-8));    # undeclared streams in UTF-8

# This happens automatically, but to make pledge(2) happy
# it has to happen earlier than it would otherwise.
use IO::File;

use Carp;
use Time::HiRes qw< time >;

# ABSTRACT: Easier filters for OpenSMTPd in perl
our $VERSION = 'v0.0.1'; # VERSION

my @report_fields = qw< version timestamp subsystem event session suffix >;
my %report_events = (
    'smtp-in' => {
        'link-connect'    => [qw< rdns fcrdns src dest >],
        'link-greeting'   => [qw< hostname >],
        'link-identify'   => [qw< method identity >],
        'link-tls'        => [qw< tls-string >],
        'link-disconnect' => [qw< >],
        'link-auth'       => [qw< username result >],
        'tx-reset'        => [qw< message-id >],
        'tx-begin'        => [qw< message-id >],
        'tx-mail'         => [qw< message-id result address >],
        'tx-rcpt'         => [qw< message-id result address>],
        'tx-envelope'     => [qw< message-id envelope-id >],
        'tx-data'         => [qw< message-id result >],
        'tx-commit'       => [qw< message-id message-size >],
        'tx-rollback'     => [qw< message-id >],
        'protocol-client' => [qw< command >],
        'protocol-server' => [qw< response >],
        'filter-report'   => [qw< filter-kind name message >],
        'filter-response' => [qw< phase response param>],
        'timeout'         => [qw< >],
    },
);

my @filter_fields
    = qw< version timestamp subsystem phase session opaque-token suffix >;
my %filter_events = (
    'smtp-in' => {
        'connect'   => [qw< rdns fcrdns src dest >],
        'helo'      => [qw< identity >],
        'ehlo'      => [qw< identity >],
        'starttls'  => [qw< tls-string >],
        'auth'      => [qw< auth >],
        'mail-from' => [qw< address >],
        'rcpt-to'   => [qw< address >],
        'data'      => [qw< >],
        'data-line' => [qw< line >],
        'commit'    => [qw< >],

        'data-lines' => sub {'data-line'},    # special case
    },
);

my @filter_result_fields    = qw< session opaque-token >;
my %filter_result_decisions = (

    #'dataline'   => [qw< line >], # special case
    'proceed'    => [qw< >],
    'junk'       => [qw< >],
    'reject'     => [qw< error >],
    'disconnect' => [qw< error >],
    'rewrite'    => [qw< parameter >],
    'report'     => [qw< parameter >],
);

sub new {
    my ( $class, %params ) = @_;

    $params{on}     ||= {};
    $params{input}  ||= \*STDIN;
    $params{output} ||= \*STDOUT;

    STDERR->autoflush;
    $params{output}->autoflush;

    # We expect to read and write bytes from the remote
    $_->binmode(':raw') for @params{qw< input output >};

    my $check_supported_events;
    $check_supported_events = sub {
        my ( $c, $e, $ms ) = @_;
        my $m = shift @{$ms} || return;

        my @s = sort keys %{$c};
        if ( my @u = grep { !$e->{$_} } @s ) {
            my $s = @u == 1 ? '' : 's';
            croak("Unsupported $m$s @u");
        }

        $check_supported_events->( $c->{$_}, $e->{$_}, $ms ) for @s;
    };

    $check_supported_events->(
        $params{on},
        { report => \%report_events, filter => \%filter_events },
        [ "event type", "event subsystem", "event" ]
    );

    # Only save data-lines if we're using the helper to process them
    $params{_save_data_lines}
       = $params{on}
      && $params{on}{filter}
      && $params{on}{filter}{'smtp-in'}
      && $params{on}{filter}{'smtp-in'}{'data-lines'};

    my $self = bless \%params, $class;
    return $self->_init;
}

sub _init {
    my ($self) = @_;

    my $fh       = $self->{input};
    my $blocking = $fh->blocking // die "Unable to get blocking on input: $!";
    $fh->blocking(0) // die "Unable to set input to non-blocking: $!";

    my $timeout = 0.25;    # no idea how long we should actually wait
    my $now     = time;

    my %config;
    while ( not $self->{_ready} and ( time - $now ) < $timeout ) {
        my $line = $fh->getline // next;
        STDERR->print("< $line") if $self->{debug};
        chomp $line;
        $self->_dispatch($line);
        $now = time;    # continue waiting, we got a line
    }

    $fh->blocking($blocking) // die "Unable to reset blocking on input: $!";

    return $self;
}

sub ready {
    my ($self) = @_;
    croak("Input stream is not ready") unless $self->{_ready};

    my @reports = map {"report|smtp-in|$_"}
        sort keys %{ $report_events{'smtp-in'} };

    my @filters;
    for my $subsystem ( sort keys %{ $self->{on}->{filter} } ) {
        for ( sort keys %{ $self->{on}->{filter}->{$subsystem} } ) {
            my $v     = $filter_events{$subsystem}{$_};
            my $phase = ref $v eq 'CODE' ? $v->($_) : $_;
            push @filters, "filter|$subsystem|$phase";
        }
    }

    for ( @reports, @filters, 'ready' ) {
        STDERR->say("> register|$_") if $self->{debug};
        $self->{output}->say("register|$_");
    }

    $self->{input}->blocking(1);

    while ( defined( my $line = $self->{input}->getline ) ) {
        STDERR->print("< $line") if $self->{debug};
        chomp $line;
        $self->_dispatch($line);
    }
}

# The char "|" may only appear in the last field of a payload, in which
# case it should be considered a regular char and not a separator.  Other
# fields have strict formatting excluding the possibility of having a "|".
sub _dispatch {
    my ( $self, $line ) = @_;
    $line //= 'undef';          # no unitialized warnings
    my ( $type, $extra ) = split /\|/, $line, 2;
    $type //= 'unsupported';    # no uninitialized warnings

    my $method = $self->can("_handle_$type");
    return $self->$method($extra) if $method;

    croak("Unsupported: $line");
}

# general configuration information in the form of key-value lines
sub _handle_config {
    my ( $self, $config ) = @_;

    return $self->{_ready} = $config
        if $config eq 'ready';

    my ( $key, $value ) = split /\|/, $config, 2;
    $self->{_config}->{$key} = $value;

    return $key, $value;
}

# Each report event is generated by smtpd(8) as a single line
#
# The format consists of a protocol prefix containing the stream, the
# protocol version, the timestamp, the subsystem, the event and the unique
# session identifier separated by "|":
#
# It is followed by a suffix containing the event-specific parameters, also
# separated by "|"

sub _handle_report {
    my ( $self, $report ) = @_;

    my %report;
    @report{@report_fields} = split /\|/, $report, @report_fields;

    my $event  = $report{event} // '';
    my $suffix = delete $report{suffix};

    my %params;
    my @fields = $self->_report_fields_for( @report{qw< subsystem event >} );
    @params{@fields} = split /\|/, $suffix, @fields
        if @fields;

    my $session = $self->{_sessions}->{ $report{session} } ||= {};
    $session->{state}->{$_} = $report{$_} for keys %report;
    push @{ $session->{events} }, { %report, %params, request => 'report' };

    # If the session disconncted we can't do anything more with it
    delete $self->{_sessions}->{ $report{session} }
        if $event eq 'link-disconnect';

    if ( $event =~ /^tx-(.*)$/ ) {
        my $phase = $1;

        push @{ $session->{messages} }, $session->{state}->{message} = {}
            if $phase eq 'begin';

        my $message = $session->{messages}->[-1];

        if ( $phase eq 'mail' ) {
            $message->{'mail-from'} = $params{address};
            $message->{result} = $params{result};
        }
        elsif ( $phase eq 'rcpt') {
            push @{ $message->{'rcpt-to'} }, $params{address};
            $message->{result} = $params{result};
        }
        else {
            $message->{$_} = $params{$_} for keys %params;
        }
    }
    else {
        $session->{state}->{$_} = $params{$_} for keys %params;
    }

    my $cb = $self->_cb_for( report => @report{qw< subsystem event >} );
    $cb->( $event, $session ) if $cb;

    return $session->{events}->[-1];
}

sub _handle_filter {
    my ( $self, $filter ) = @_;

    my %filter;
    @filter{@filter_fields} = split /\|/, $filter, @filter_fields;

    my $suffix = delete $filter{suffix};

    # For use in error messages
    my $subsystem  = $filter{subsystem};
    my $phase      = $filter{phase};
    my $session_id = $filter{session};
    $_ = defined $_ ? "'$_'" : "undef" for $subsystem, $phase, $session_id;

    my %params;
    my @fields = $self->_filter_fields_for( @filter{qw< subsystem phase >} );
    @params{@fields} = split /\|/, $suffix, @fields
        if defined $suffix and @fields;

    my $session = $self->{_sessions}->{ $filter{session} || '' }
        or croak("Unknown session $session_id in filter $subsystem|$phase");
    push @{ $session->{events} }, { %filter, %params, request => 'filter' };

    return $self->_handle_filter_data_line( $params{line}, \%filter, $session )
        if $filter{subsystem} eq 'smtp-in'
       and $filter{phase} eq 'data-line';

    my @ret;
    if ( my $cb = $self->_cb_for( filter => @filter{qw< subsystem phase >} ) )
    {
        @ret = $cb->( $filter{phase}, $session );
    }
    else {
        carp("No handler for filter $subsystem|$phase, proceeding");
        @ret = 'proceed';
    }

    my $decisions = $filter_result_decisions{ $ret[0] };
    unless ($decisions) {
        carp "Unknown return from filter $subsystem|$phase: @ret";

        $ret[0] = 'reject';
        $decisions = $filter_result_decisions{ $ret[0] };
    }

    # Pass something as the reason for the rejection
    push @ret, "550 Nope"
        if @ret == 1
        and ( $decisions->[0] || '' ) eq 'error';

    carp(
        sprintf "Incorrect params from filter %s|%s, expected %s got %s",
            $subsystem, $phase,
            join( ' ', map {"'$_'"} 'decision', @$decisions ),
            join( ' ', map {"'$_'"} @ret),
    ) unless @ret == 1 + @{$decisions};

    my $response = join '|',
        'filter-result',
        @filter{qw< session opaque-token >},
        @ret;

    STDERR->say("> $response") if $self->{debug};
    $self->{output}->say($response);

    return {%filter};
}

sub _handle_filter_data_line {
    my ( $self, $line, $filter, $session ) = @_;
    $line //= '';    # avoid uninit warnings

    my @lines;
    if ( my $cb
        = $self->_cb_for( filter => @{$filter}{qw< subsystem phase >} ) )
    {
        @lines = $cb->( $filter->{phase}, $session, $line );
    }

    my $message = $session->{messages}->[-1];
    push @{ $message->{'data-line'} }, $line if $self->{_save_data_lines};

    if ( $line eq '.' ) {
        my $cb
            = $self->_cb_for( filter => $filter->{subsystem}, 'data-lines' );
        push @lines, $cb->( 'data-lines', $session, $message->{'data-line'} )
            if $cb;

        # make sure we end the message;
        push @lines, $line;
    }

    for ( map { $_ ? split /\n/ : $_ } @lines ) {
        last if $message->{'sent-dot'};

        my $response = join '|', 'filter-dataline',
            @{$filter}{qw< session opaque-token >}, $_;

        STDERR->say("> $response") if $self->{debug};
        $self->{output}->say($response);

        $message->{'sent-dot'} = 1 if $_ eq '.';
    }

    return $filter;
}

sub _report_fields_for { shift->_fields_for( report => \%report_events, @_ ) }
sub _filter_fields_for { shift->_fields_for( filter => \%filter_events, @_ ) }

sub _fields_for {
    my ( $self, $type, $map, $subsystem, $item ) = @_;

    if ( $subsystem and $item and my $items = $map->{$subsystem} ) {
        return @{ $items->{$item} } if $items->{$item};
    }

    $_ = defined $_ ? "'$_'" : "undef" for $subsystem, $item;
    croak("Unsupported $type $subsystem|$item");
}

sub _cb_for {
    my ( $self, @lookup ) = @_;

    my $cb = $self->{on};
    $cb = $cb->{$_} || {} for @lookup;

    return $cb if ref $cb eq 'CODE';

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSMTPd::Filter - Easier filters for OpenSMTPd in perl

=head1 VERSION

version v0.0.1

=head1 SYNOPSIS

    use OpenSMTPD::Filter;
    use OpenBSD::Pledge;

    pledge();

    my $filter = OpenSMTPd::Filter->new(
        on => {
            report => \%report_callbacks,
            filter => \%filter_callbacks,
        },
    );

    $filter->ready;  # Registers and starts listening for updates

=head1 DESCRIPTION

This module is a helper to make writing L<OpenSMTPd|https://opensmtpd.org>
filters in perl easier.

=head1 METHODS

=head2 new

    my $filter = OpenSMTPd::Filter->new(
        input  => \*STDIN,  # the default
        output => \*STDOUT, # the default
        debug  => 0,        # the default,

        on => \%callbacks,
    );

Instantiates a new filter ready to start handling events.

=over

=item on

    my $filter = OpenSMTPd::Filter->new(
        ...,
        on => {
            report => { 'smtp-in' => {
                'link-connect' => \&lookup_spf_async,
            } },
            filter => { 'smtp-in' => {
                helo => \&check_spf,
                ehlo => \&check_spf,
            } },
        },
    );

A hashref of events to add callbacks for.
The top level is the C<stream> to listen on,
either C<report> or C<filter>.
The next level is the C<subsystem> which must be C<smtp-in>.
Finally the C<event> or C<phase> to to handle.

See L</REPORT AND FILTER STREAMS> for details on writing callbacks.

=item input

The filehandle used to receive messages from smtpd.
Will be changed to C<binmode(":raw")>.

Defaults to C<STDIN>.

=item output

The filehandle used to send messages to smtpd.
Will be changed to C<binmode(":raw")>.

Defaults to C<STDOUT>.

=item debug

Set to a true value to enable debugging.
Primarily this means copying all lines
from L</input> and L</output> to C<STDERR>.

=back

=head2 ready

    $filter->ready;

Processes events on L</input> until it hits C<eof>,
which should only happen when smtpd exits.

=head1 REPORT AND FILTER STREAMS

    my $callback = sub {
        my ( $phase_or_event, $session, @extra ) = @_;
        ...;
    };

Each stream triggers events and each event callback adds to a session
state as well as a list of events that have been received in that
session.

Each callback is called with the report event or filter phase
that triggered the callback as the first argument and a session datastructure
as the second argument.
The subsystem can be found in C<< $session->{state}->{subsystem} >>.
Some callbacks will get additional arguments as documented below.

The C<$session> hashref may contain up to three keys:

    $session = {
        state    => \%state,
        events   => \@events,
        messages => \@messages,
    };

Nothing in this session hash is used by this module other than in
each message, the C<data-line> arrayref is passed to the L</data-lines>
filter and the C<sent-dot> boolean is used to know whether to
continue sending L<filter-dataline> responses.
This means your filters can munge the contents or add additional
entries although care must be taken not to change the expected type
of an entry, but adding additional keys or changing values will not
cause issues.

=over

=item state

This is the state filled in by the fields for each received event.
Any C<tx> events go into L</messages> instead of this state.

A state might loook like this, however it only contains the fields
recieved at each point in the connection and will contain any fields
set by a L</REPORT EVENT>:

    my $state = {
        version   => '0.6',
        timestamp => '1613356167.075372',
        subsystem => 'smtp-in',
        event     => 'timeout',
        phase     => 'commit',
        session   => '3647ceea74a815de',

        rdns      => 'localhost',
        fcrdns    => 'pass',
        src       => '[::1]:37403',
        dest      => '[::1]:25',

        hostname  => 'mail.example.test',

        method    => 'HELO',
        identity  => 'mail.afresh1.test',

        command   => '.',
        response  => '250 2.0.0 5e170a6f Message accepted for delivery',

        message   => $session->{messages}->[-1],
    };

See the rest of this section for which events fill in each field.

=item events

This is an arrayref of hashrefs of the fields for each recieved
message, each hashref contains all fields supplied by that report
event or filter phase.
In addition, the event includes a C<request> field indicating
whether the event was a report or a filter.

    my $event = {
        request   => 'report',
        version   => '0.5',
        timestamp => '1576146008.006099',
        subsystem => 'smtp-in',
        event     => 'link-connect',
        session   => '7641df9771b4ed00',
        rdns      => 'mail.openbsd.org',
        fcrdns    => 'pass',
        src       => '199.185.178.25:33174',
        dest      => '45.77.67.80:25',
    };

=item messages

Message states collect the fields provided by each C<tx-*>
L</REPORT EVENT> for each C<message-id> in a session.

    my $message' = {
        'message-id'  => '48f59d87',
        'envelope-id' => '48f59d87264c2287',
        'mail-from',  => 'andrew',
        'rcpt-to',    => ['afresh1'],
        'data-line'   => [
            'Received: from mail (localhost [::1])',
            '	by mail.example.test (OpenSMTPD) with SMTP id 48f59d87',
            '	for <afresh1@mail.afresh1.test>;',
            '	Sat, 27 Feb 2021 20:56:38 -0800 (PST)',
            'From: andrew',
            'To: afresh1',
            'Subject: Hai!',
            '',
            'Hello There',
            '.'
        ],
        'result'   => 'ok',
        'sent-dot' => 1,
    };

The L</tx-from> and L</tx-rcpt> events are handled specially and
go into the C<mail-from>, C<rcpt-to>, and C<result> fields.
The C<rcpt-to> ends up in an arrayref as the message can be destined
for multiple recipients.
If a L</data-lines> filter exists,
the C<data-line> field is also an arrayref of each line that has been
recieved so far, with the C<CR> and C<LF> removed.
The C<sent-dot> field is a boolen indicating whether this message
has sent the C<.> indicating it is complete.

=back

=head2 REPORT EVENT

    my $callback = sub {
        my ( $event, $session ) = @_;
        ...;
        return 'anything'; # ignored
    };

All report events will provide these fields:

=over

=item version

=item timestamp

=item subsystem

=item event

=item session

=item suffix

=back

Events for the subsystem below may include additional fields.

=over

=item smtp-in

=over

=item link-connect

=over

=item rdns

=item fcrdns

=item src

=item dest

=back

=item link-greeting

=over

=item hostname

=back

=item link-identify

=over

=item method

=item identity

=back

=item link-tls

=over

=item tls-string

=back

=item link-disconnect

=item link-auth

=over

=item username

=item result

=back

=item protocol-client

=over

=item command

=back

=item protocol-server

=over

=item response

=back

=item filter-report

=over

=item filter-kind

=item name

=item message

=back

=item filter-response

=over

=item phase

=item response

=item param

=back

=item timeout

=back

=back

=head2 MESSAGE REPORT EVENTS

    my $callback = sub {
        my ($event, $session) = @_
        my $message = $session->{state}->{message};
        ...;
    };

All filters that begin with C<tx-> include a C<message-id> field
and possibly other fields.
These events add to the last item in L</messages>,
which is also added as the C<message> field in the C<session> L</state>.

=over

=item message-id

=back

Message events for the C<smtp-in> subsystem may include additional fields.

=over

=item tx-reset

=item tx-begin

=item tx-mail

=over

=item result

=item mail-from

The C<address> field for a C<tx-mail> event is recorded as the
C<mail-from> in the message.

=back

=item tx-rcpt

=over

=item result

=item rcpt-to

The C<address> field for a C<tx-rcpt> events are recorded in the
C<rcpt-to> arrayref in the message.

=back

=item tx-envelope

=over

=item envelope-id

=back

=item tx-data

=over

=item result

=back

=item tx-commit

=over

=item message-size

=back

=item tx-rollback

=back

=head2 FILTER REQUEST

    my $callback = sub {
        my ( $phase, $session, @data_lines ) = @_;
        ...;
        return $response, @params;
    };

See L</FILTER RESPONSE> for details about what can be returned.

The L</data-line> and L</data-lines> callbacks are special in that
they also recieve the current C<data-line> or all lines recieved.
They should also return a list of L</dataline> responses instead of the
normal decision response.

All filter events have these fields:

=over

=item version

=item timestamp

=item subsystem

=item phase

=item session

=item opaque-token

=back

Specific filter events for each subsystem may include additional
fields.

=over

=item smtp-in

=over

=item connect

=over

=item rdns

=item fcrdns

=item src

=item dest

=back

=item helo

=over

=item identity

=back

=item ehlo

=over

=item identity

=back

=item starttls

=over

=item tls-string

=back

=item auth

=over

=item auth

=back

=item mail-from

=over

=item address

=back

=item rcpt-to

=over

=item address

=back

=item data

=item commit

=back

=item data-line

The C<data-line> and C<data-lines> callbacks are special in that
they return a list of L</dataline> responses and not a normal
L</FILTER RESPONSE>.

The returned lines are split on C<\n> so you can return a single
string that is the entire message and it will be split into individual
L</dataline> responses.

You can return any number of lines from an individual C<data-line>
callback until you recieve the single C<.> indicating the end of
the message.
When you recieve the single C<.> as the C<line> you will need to
finish processing the message and return any lines that are still
pending.

=over

=item line

=back

=item data-lines

This is a wrapper around the L</data-line> callback
to make it easier to process the entire message instead
of dealing with it on a line-by-line basis and having to
store it yourself.

See the L</BUGS AND LIMITATIONS>,
although this seemed like a good idea,
to better support C<pledge> it might go away
and leave implementing data-line storage to the filter author.

=over

=item lines

The final argument is an arrayref of all lines in the message.

=back

=back

=head3 FILTER RESPONSE

The return value from a L</FILTER REQUEST> callback determines what
will be done with the message.

=over

=item dataline

This is the special response used by L</data-line> filters.
There is special processing that if the returned line contains
newlines it will be split into multiple responses.

=over

=item line

=back

=item proceed

    my $callback = sub {
        ...;
        return 'proceed';
    };

This is the normal response, it means the message will continue to
additional filters and if all filters return C<proceed> the message
will be accepted.

=item junk

    my $callback = sub {
        ...;
        return 'junk';
    };

Like L</proceed> but will add an C<X-Spam> header to the message.

=item reject

    my $callback = sub {
        ...;
        return reject => "400 Not Sure";
    };

You must provide a valid SMTP error message as the second argument
to the return value including the status code, 5xx or 4xx.

A 421 status will L</disconnect> the client.

=over

=item error

=back

=item disconnect

    my $callback = sub {
        ...;
        return disconnect => "550 Go Away";
    };

As with L</reject> the return from this callback must include a
valid SMTP error message including the status code.
However, like a  C<421> L</reject> status, all messages will
disconnect the client.

=over

=item error

=back

=item rewrite

    my $callback = sub {
        my ($phase, $session) = @_;
        ...;
        if ( $phase eq 'tx-rcpt' ) {
             my $event = $session->{events}->[-1];
             return rewrite => 'afresh1'
                 if $event->{address} eq 'andrew';
        }
        return 'proceed';
    };

=over

=item parameter

=back

=item report

Generates a L</filter-report> event with the C<parameter> as the
message that will be reported.
I'm not entirely sure where they get reported to,
I assume maybe any later filters.

I believe you would do something like this,
and that you could generate any supported event,
but I haven't had good luck with it.

    my $s = $_[1]->{state};
    printf $output "%s|"%010.06f"|%s|%s|%s|%s\n";
        'report', Time::HiRes::time,
        $s->{subsystem}, 'filter-response', $s->{session},
        $parameter
    );

This is not a result response.

=over

=item parameter

=back

=back

=head1 BUGS AND LIMITATIONS

The received L</data-line> are stored in a list in memory
if a L</data-lines> filter exists,
which could easily be very large if the message is sizable.
These should instead be stored in a temporary file.

There is currently no way to stop listening for specific report events,
this module should provide a way to specify which events it should
listen for and gather state from.

=head1 DEPENDENCIES

Perl 5.16 or higher.

=head1 SEE ALSO

L<smtpd-filters(7)|https://github.com/openbsd/src/blob/master/usr.sbin/smtpd/smtpd-filters.7>

L<OpenBSD::Pledge|http://man.openbsd.org/OpenBSD::Pledge>

L<OpenBSD::Unveil|http://man.openbsd.org/OpenBSD::Unveil>

=head1 AUTHOR

Andrew Hewus Fresh <andrew@afresh1.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Andrew Hewus Fresh <andrew@afresh1.com>.

This is free software, licensed under:

  The MIT (X11) License

=cut
