package POE::Component::IRC::Plugin::AlarmClock;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use POE;
use Carp;
use base 'POE::Component::IRC::Plugin::BaseWrap';

sub _make_default_args {
    return (
        trigger          => qr/^alarm\s+(?=\S+)/i,
        response_event   => 'irc_alarm_clock',
        max_alarms       => 5,
        _store           => {},
    );
}

sub PCI_register {
    my ( $self, $irc ) = splice @_, 0, 2;

    $self->{irc} = $irc;

    $irc->plugin_register( $self, 'SERVER', qw(public notice msg) );

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self   => [ qw(
                    _start
                    _shutdown
                    _alarm_rang
                    _alarm_set
                    _alarm_delete
                )
            ],
        ],
    )->ID;

    return 1;
}

sub _alarm_delete {
    my ( $kernel, $timer_id ) = @_[KERNEL, ARG0];
    $kernel->alarm_remove( $timer_id );
}

sub _alarm_set {
    my ( $kernel, $self, $alarm_id ) = @_[KERNEL, OBJECT, ARG0];

    my $store = $self->{_store};
    my $alarm_store = $store->{alarms}{ $alarm_id };

    my $timer_id = $kernel->alarm_set(
        _alarm_rang => $alarm_store->{time} => $alarm_id
    );

    unless ( $timer_id ) {
        my $who = $alarm_store->{in_ref}{who};
        my $nick = ( split /!/, $who )[0];

        $self->{irc}->yield( privmsg => $nick =>
            "Failed to set the alarm ($!)"
        );
        delete $store->{alarms}{ $alarm_id };
        delete $store->{users}{ $who }{ $alarm_id };
        keys %{ $store->{users}{ $who } }
            or delete $store->{users}{ $who };
    }

    $alarm_store->{timer_id} = $timer_id;
}

sub _alarm_rang {
    my ( $self, $alarm_id ) = @_[OBJECT, ARG0];

    my $store = $self->{_store};

    my $alarm_ref = delete $store->{alarms}{$alarm_id};
    my $message = (
        delete $store->{users}{ $alarm_ref->{user} }{$alarm_id}
    )->{message};

    keys %{ $store->{users}{ $alarm_ref->{user} } }
        or delete $store->{users}{ $alarm_ref->{user} };

    $self->{debug}
        and carp "Alarm rang: user => $alarm_ref->{user}";

    my $in_ref = $alarm_ref->{in_ref};
    my $user = ( split /!/, $in_ref->{who} )[0];

    my $type = $in_ref->{type};
    my $where = $user;
    if ( $type eq 'public' ) {
        $type = 'privmsg';
        $where = $in_ref->{channel};
    }

    delete @{ $alarm_ref->{in_ref} }{ qw(rang list del set) };

    my $out_message = "$user, alarm rang $message";
    $self->{irc}->yield( $type => $where => $out_message )
        if $self->{auto};

    $self->{irc}->send_event(
        $self->{response_event} => {
            rang => 1,
            out  => $out_message,
            map { $_ => $alarm_ref->{in_ref}{ $_ } }
                qw( who type channel ),
        }
    );
}

sub _start {
    my ( $kernel, $self ) = @_[KERNEL, OBJECT];
    $self->{session_id} = $_[SESSION]->ID;
    $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
}

sub _shutdown {
    my ( $kernel, $self ) = @_[KERNEL, OBJECT];
    $kernel->alarm_remove_all;
    $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ );
    undef;
}

sub PCI_unregister {
    my $self = shift;

    delete $self->{irc};
    $poe_kernel->call( $self->{session_id} => '_shutdown' );

    return 1;
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;

        delete @$in_ref{ qw(rang list del set) };

    my $in = $in_ref->{what};
    my $store = $self->{_store};
    if ( my ( $time, $message ) = $in
        =~ /^(?:set|start)\s+(\d+[smh]?)\s*(.+)?/xi
    ) {
        $message = ''
            unless defined $message;

        $in_ref->{set} = 1;

        my $user = $in_ref->{who};

        if ( keys %{ $store->{users}{$user} } >= $self->{max_alarms} ) {
            return "Sorry but you may not set any more alarms."
                    . " Clear your old ones or wait for them to ring";
        }

        my %existing_alarm_numbers = map { $_->{num} => 1 }
            values %{ $store->{users}{$user} };
        my $alarm_num = 0;
        while ( 1 ) {
            last
                unless exists $existing_alarm_numbers{ $alarm_num };

            $alarm_num++;
        }

        my $alarm_id = rand() . time() . rand();
        $store->{users}{$user}{$alarm_id}
        = {
            time    => time + $self->_make_offset( $time ),
            message => $message,
            num     => $alarm_num,
        };

        @{ $store->{alarms}{ $alarm_id } }{ qw(
                user
                id
                time
                in_ref
            )
        } = (
            $user,
            $alarm_id,
            $store->{users}{$user}{$alarm_id}{time},
            $in_ref,
        );

        $poe_kernel->post( $self->{session_id} => _alarm_set => $alarm_id );

        return "Alarm will ring in "
         . $self->_seconds_to_readable_time( $self->_make_offset( $time ) );
    }
    elsif ( $in =~ /^(list|show)\b/i) {
        $self->{debug}
            and carp "Alarm LIST from $in_ref->{who}";

        # we will always reply to this command via /notice
        @$in_ref{ qw(list type) } = ( 1, 'notice' );

        return "You don't have any alarms set"
            unless keys %{ $store->{users}{ $in_ref->{who} } || {} };

        my @alarms = sort { $a->{time} <=> $b->{time} }
                        values %{ $store->{users}{ $in_ref->{who} } };

        my @out_messages;
        for ( @alarms ) {
            my $readable_time
            = $self->_seconds_to_readable_time( $_->{time} - time() );
            push @out_messages,
                "[ $_->{num} - $readable_time - $_->{message} ]";
        }

        $self->{debug}
            and carp "About to list these alarms: @out_messages";

        return join q| |, @out_messages;
    }
    elsif ( my ( $id ) = $in =~ /^(?:del(?:ete)?|rem(?:ove)?)\s+(\d)/i) {
        $self->{debug}
            and carp "Alarm REMOVE from $in_ref->{who}";

        # we will always reply to this command via /notice
        @$in_ref{ qw(del type) } = ( 1, 'notice' );

        return "You don't have any alarms set"
            unless keys %{ $store->{users}{ $in_ref->{who} } || {} };


        my $user_store = $store->{users}{ $in_ref->{who} };

        my $alarm_to_delete = (
            grep { $user_store->{ $_ }{num} == $id }
                keys %$user_store
        )[0];

        $alarm_to_delete
            or return "Alarm ID $id does not exist; use `list` command"
                        . " to show your alarms";

        my $poe_timer_id = (
            delete $store->{alarms}{ $alarm_to_delete }
        )->{timer_id};

        $poe_kernel->call(
            $self->{session_id} => _alarm_delete => $poe_timer_id
        );

        my $alarm_info = delete $user_store->{ $alarm_to_delete };

        keys %$user_store
            or delete $store->{users}{ $in_ref->{who} };

        return "Deleted alarm $alarm_info->{num} [$alarm_info->{message}]"
           . " which would have rang in "
           . $self->_seconds_to_readable_time( $alarm_info->{time} - time );
    }
    else {
        $in_ref->{invalid} = 1;
        return "Invalid command in alarm plugin";
    }
}

sub _seconds_to_readable_time {
    my ( $self, $seconds ) = @_;

    my %result = map { $_ => 0 } qw(days hours minutes seconds);
    $result{minutes} =  int( $seconds / 60 );
    $seconds -= $result{minutes} * 60;

    if ( $result{minutes} and $result{minutes} >= 60) {
        $result{hours} = int( $result{minutes} / 60 );
        $result{minutes} -= $result{hours} * 60;
    }

    if ( $result{hours} and $result{hours} >= 24 ) {
        $result{days} = int( $result{hours} / 24 );
        $result{hours} -= $result{days} * 24;
    }

    $result{seconds} = $seconds;

    my @responses;

    $result{days}
        and push @responses, "$result{days} day(s)";

    $result{hours}
        and push @responses, "$result{hours} hour(s)";

    $result{minutes}
        and push @responses, "$result{minutes} minute(s)";

    $result{seconds}
        and push @responses, "$result{seconds} second(s)";

    @responses == 1
        and return $responses[0];

    my $last = pop @responses;
    return join( q|, |, @responses ) . " and $last";
}

sub _make_offset {
    my ( $self, $time ) = @_;
    return $time
        if $time !~ /\D/ or $time =~ s/s//i;

    if (    $time =~ s/h//i ) { return $time * 3600; }
    elsif ( $time =~ s/m//i ) { return $time * 60; }

    croak 'We should never get here; please email to zoffix@cpan.org';
}

sub _message_into_response_event { 'out' }

1;
__END__

=for stopwords bot privmsg regexen usermask usermasks

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::AlarmClock - IRC alarm clock plugin

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::AlarmClock);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'AlarmClockBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'AlarmClock bot',
        plugin_debug => 1,
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start  irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'AlarmClock' =>
                POE::Component::IRC::Plugin::AlarmClock->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }

    [18:13:23] <Zoffix> AlarmClockBot, alarm set 50
    [18:13:23] <AlarmClockBot> Alarm will ring in 50 second(s)

    [18:13:25] <Zoffix> AlarmClockBot, alarm set 10m
    [18:13:25] <AlarmClockBot> Alarm will ring in 10 minute(s)

    [18:13:28] <Zoffix> AlarmClockBot, alarm set 1h
    [18:13:28] <AlarmClockBot> Alarm will ring in 1 hour(s)

    [18:13:30] <Zoffix> AlarmClockBot, alarm list
    [18:13:30] -AlarmClockBot- [ 0 - 43 second(s) -  ] [ 1 - 9 minute(s)
                and 55 second(s) -  ] [ 2 - 59 minute(s) and 58 second(s) -  ]

    [18:13:33] <Zoffix> AlarmClockBot, alarm del 2
    [18:13:33] -AlarmClockBot- Deleted alarm 2 [] which would have rang in
                59 minute(s) and 55 second(s)

    [18:13:52] <Zoffix> AlarmClockBot, alarm set 10s Check your stove!
    [18:13:52] <AlarmClockBot> Alarm will ring in 10 second(s)

    [18:13:56] <Zoffix> AlarmClockBot, alarm list
    [18:13:56] -AlarmClockBot- [ 2 - 6 second(s) - Check your stove! ] [ 0
                - 17 second(s) -  ] [ 1 - 9 minute(s) and 29 second(s) -  ]

    [18:14:02] <AlarmClockBot> Zoffix, alarm rang Check your stove!
    [18:14:13] <AlarmClockBot> Zoffix, alarm rang

    [18:14:16] <Zoffix> AlarmClockBot, alarm list
    [18:14:16] -AlarmClockBot- [ 1 - 9 minute(s) and 9 second(s) -  ]

    [18:14:20] <Zoffix> AlarmClockBot, alarm del 1
    [18:14:20] -AlarmClockBot- Deleted alarm 1 [] which would have rang in
                9 minute(s) and 5 second(s)

    [18:14:22] <Zoffix> AlarmClockBot, alarm del 10
    [18:14:22] -AlarmClockBot- You don't have any alarms set

    [18:14:35] <Zoffix> AlarmClockBot, alarm set 1h
    [18:14:35] <AlarmClockBot> Alarm will ring in 1 hour(s)
    [18:14:36] <Zoffix> AlarmClockBot, alarm set 1h
    [18:14:36] <AlarmClockBot> Alarm will ring in 1 hour(s)
    [18:14:36] <Zoffix> AlarmClockBot, alarm set 1h
    [18:14:36] <AlarmClockBot> Alarm will ring in 1 hour(s)
    [18:14:36] <Zoffix> AlarmClockBot, alarm set 1h
    [18:14:36] <AlarmClockBot> Alarm will ring in 1 hour(s)
    [18:14:36] <Zoffix> AlarmClockBot, alarm set 1h
    [18:14:36] <AlarmClockBot> Alarm will ring in 1 hour(s)
    [18:14:37] <Zoffix> AlarmClockBot, alarm set 1h
    [18:14:37] <AlarmClockBot> Alarm will ring in 1 hour(s)
    [18:14:37] <Zoffix> AlarmClockBot, alarm set 1h

    [18:14:38] <AlarmClockBot> Sorry but you may not set any more alarms. Clear your old ones or wait for them to ring

    [18:15:18] <Zoffix> AlarmClockBot, alarm blah
    [18:15:18] <AlarmClockBot> Invalid command in alarm plugin

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
to remind forgetful users of some evens as an alarm clock.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 COMMANDS/FUNCTIONALITY

B<See end of SYNOPSIS section for examples.>

After stripping the C<trigger> (see constructor description) the plugin
will look for several commands to decide how to act.

If input matches C<< /^(?:set|start)\s+(\d+[smh]?)\s*(.+)?/xi >>
the alarm will be set to ring in said amount of seconds, minutes or hours
and an optional "alarm message" can be added at the end to remind the user
why the alarm was set. B<Note:> if your program shuts down
all alarms are cleared.

If input matches C<< /\b(list|show)\b/i >>. Then plugin will list all
active alarms (if any) for this user. The format of the output is
C<< [ $alarm_id - $when_will_it_ring - $alarm_message ] >>.
In other words, the output
C<< [ 0 - 43 second(s) - foos ] [ 1 - 9 minute(s) and 55 second(s) - ] >>
means the user has two active alarms. Alarm number C<0> will ring in
43 seconds and was set with a message C<foos>. Alarm number C<1> will
ring in 9 minutes, 55 seconds and does not have any message associated with
it. You may use these alarm IDs (numbers) to clear the alarms.

If input matches C<< /^(?:del(?:ete)?|rem(?:ove)?)\s+(\d)/i >> then
alarm with ID number provided will be cleared. The alarm ID numbers can
be obtained via C<list/show> command.

=head1 NOTE ON MESSAGE TYPES

The alarm can be set via public message, private message or notice message.
When it "rings" the user will be notified via the same kind of message which
was used to set the alarm.

The output of C<list> and C<delete> command is B<always> sent via
B<notice messages>. And if you don't like this fact, feel free to set
C<auto> constructor's option to a false value and make output yourself.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'AlarmClock' => POE::Component::IRC::Plugin::AlarmClock->new
    );

    # juicy flavor
    $irc->plugin_add(
        'AlarmClock' =>
            POE::Component::IRC::Plugin::AlarmClock->new(
                auto             => 1,
                max_alarms       => 5,
                response_event   => 'irc_alarm_clock',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                trigger          => qr/^alarm\s+(?=\S)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::AlarmClock> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. B<Note:> all these
arguments can be set dynamically by setting values to keys of your plugin's
object. In other words, if you want to ban some user on the fly you would
do C<< push @{ $your_plugin_object->{banned} }, 'user!ident@host'; >>.
The possible
arguments/values are as follows (their names are case insensitive):

=head3 C<auto>

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emitted by the plugin to retrieve the results (see
EMITTED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 C<max_alarms>

    ->new( max_alarms => 5 );

B<Optional>. Takes a positive integer as a value which specifies the
maximum number of active alarms each user may have. In other words if
C<max_alarms> is set to C<5> and user sets 5 alarms he or she will have
to wait until at least one of them rings (or will have to delete at least
one of them) before he or she would be able to set any more alarms.
B<Defaults to:> C<5>

=head3 C<response_event>

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_alarm_clock>

=head3 C<banned>

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) making the request matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 C<root>

    ->new( root => [ qr/\Qjust.me.and.my.friend.net\E$/i ] );

B<Optional>. As opposed to C<banned> argument, the C<root> argument
B<allows> access only to people whose usermasks match B<any> of
the regexen you specify in the arrayref the argument takes as a value.
B<By default:> it is not specified. B<Note:> as opposed to C<banned>
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 C<trigger>

    ->new( trigger => qr/^alarm\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^alarm\s+(?=\S)/i>

=head3 C<addressed>

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig set 10>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to make a request. Note: this argument has no effect on
C</notice> and C</msg> requests. B<Defaults to:> C<1>

=head3 C<listen_for_input>

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable functionality only via C</notice> and C</msg> messages.
B<Defaults to:> C<[ qw(public  notice  privmsg) ]>

=head3 C<eat>

    ->new( eat => 0 );

B<Optional>. If set to a false value plugin will return a
C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head3 C<debug>

    ->new( debug => 1 );

B<Optional>. Takes either a true or false value. When C<debug> argument
is set to a true value some debugging information will be printed out.
When C<debug> argument is set to a false value no debug info will be
printed. B<Defaults to:> C<0>.

=head1 EMITTED EVENTS

=head2 C<response_event>

    $VAR1 = {
        'out' => 'Alarm will ring in 1 hour(s)',
        'who' => 'Zoffix!Zoffix@i.love.debian.org',
        'what' => 'set 1h',
        'type' => 'public',
        'channel' => '#zofbot',
        'set' => 1,
        'message' => 'AlarmClockBot, alarm set 1h'
    };

    $VAR1 = {
        'out' => '[ 2 - 6 second(s) - Check your stove! ] [ 0 - 17 second(s) -  ] [ 1 - 9 minute(s) and 29 second(s) -  ]',
        'who' => 'Zoffix!Zoffix@i.love.debian.org',
        'what' => 'list',
        'type' => 'notice',
        'channel' => '#zofbot',
        'list' => 1,
        'message' => 'AlarmClockBot, alarm list'
    };

    $VAR1 = {
        'out' => 'Deleted alarm 1 [] which would have rang in 9 minute(s) and 5 second(s)',
        'who' => 'Zoffix!Zoffix@i.love.debian.org',
        'what' => 'del 1',
        'type' => 'notice',
        'channel' => '#zofbot',
        'del' => 1,
        'message' => 'AlarmClockBot, alarm del 1'
    };

    $VAR1 = {
          'out' => 'Zoffix, alarm rang ',
          'who' => 'Zoffix!Zoffix@i.love.debian.org',
          'rang' => 1,
          'channel' => '#zofbot',
          'type' => 'public'
    };

    $VAR1 = {
        'out' => 'Invalid command in alarm plugin',
        'who' => 'Zoffix!Zoffix@i.love.debian.org',
        'what' => 'blah',
        'type' => 'public',
        'channel' => '#zofbot',
        'invalid' => 1,
        'message' => 'AlarmClockBot, alarm blah'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_alarm_clock>) will receive input
every time alarm rings, new alarms is set, user asks to list active alarms,
user deletes the alarm or user uses an invalid command for the alarm plugin.
The input will come in C<$_[ARG0]> in
a form of a hashref. The above Dumper output shows possible variations
of keys. The keys/values are as follows:

=head3 C<out>

    { 'out' => 'Deleted alarm 1 [] which would have rang in 9 minute(s) and 5 second(s)', }

The C<out> key will contain the message which was (would have been) sent
to IRC.

=head3 C<who>

    { 'who' => 'Zoffix!Zoffix@i.love.debian.org', }

The C<who> key will contain the user mask of the user who sent the request
or in case of "alarm rang" type of event - the user to whom the alarm
belongs.

=head3 C<what>

    { 'what' => 'set 1h', }

The C<what> key will contain user's message after stripping the C<trigger>
(see CONSTRUCTOR).

=head3 C<message>

    { 'message' => 'AlarmClockBot, alarm set 1h' }

The C<message> key will contain the actual message which the user sent; that
is before the trigger is stripped.

=head3 C<type>

    { 'type' => 'public', }

The C<type> key will contain the "type" of the message the user have sent.
This will be either C<public>, C<privmsg> or C<notice>. In case of the
"alarm rang" type of event the C<type> key will contain the type of message
which was used to set this alarm.

=head3 C<channel>

    { 'channel' => '#zofbot', }

The C<channel> key will contain the name of the channel where the message
originated. This will only make sense if C<type> key contains C<public>.

=head3 C<set>, C<list>, C<del>, C<rang> and C<invalid>

The C<set>, C<list>, C<del>, C<rang> and C<invalid> keys indicate the
type of the event. That is if this event was generated by the user
setting the alarm, the C<set> key will be present. If user used an invalid
command the C<invalid> key will be present. If this even was generated by
alarm ringing then C<rang> key will be present. The C<list> and C<del>
keys will be present for user listing alarms and deleting them respectively.
The value of these keys will always be C<1>.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-Toys>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-Toys/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-PluginBundle-Toys at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
