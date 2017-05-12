package POE::Component::IRC::Plugin::BasePoCoWrap;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Carp;
use POE;
use POE::Component::IRC::Plugin qw(:ALL);

sub new {
    my $package = shift;
    croak "Even number of arguments must be specified"
        if @_ & 1;
    my %args = @_;
    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    # fill in the defaults
    my $self = bless {}, $package;
    %args = (
        debug            => 0,
        auto             => 1,
        response_event   => 'irc_poco_wrap_response',
        banned           => [],
        addressed        => 1,
        eat              => 1,
        trigger          => qr/^poco_wrap\s+(?=\S)/i,
        listen_for_input => [ qw(public notice privmsg) ],
        response_types   => {
            public      => 'public',
            privmsg     => 'privmsg',
            notice      => 'notice',
        },

        $self->_make_default_args(),

        %args,
    );

    $args{listen_for_input} = {
        map { $_ => 1 } @{ $args{listen_for_input} || [] }
    };

    $self->{ $_ } = delete $args{ $_ } for keys %args;

    return $self;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{_session_id} = $_[SESSION]->ID();
    $kernel->refcount_increment( $self->{_session_id}, __PACKAGE__ );

    $self->{poco} = $self->_make_poco;

    undef;
}

sub PCI_register {
    my ( $self, $irc ) = splice @_, 0, 2;

    $self->{irc} = $irc;

    $irc->plugin_register( $self, 'SERVER', qw(public notice msg) );

    $self->{_session_id} = POE::Session->create(
        object_states => [
            $self => [
                qw(
                    _start
                    _shutdown
                    _poco_done
                    _poco_begin
                )
            ],
        ],
    )->ID;

    return 1;
}

sub _shutdown {
    my ($kernel, $self) = @_[ KERNEL, OBJECT ];
    $self->{poco}->shutdown;
    $kernel->alarm_remove_all();
    $kernel->refcount_decrement( $self->{_session_id}, __PACKAGE__ );
    undef;
}

sub PCI_unregister {
    my $self = shift;

    # Plugin is dying make sure our POE session does as well.
    $poe_kernel->call( $self->{_session_id} => '_shutdown' );

    delete $self->{irc};

    return 1;
}

sub S_public {
    my ( $self, $irc ) = splice @_, 0, 2;
    my $who     = ${ $_[0] };
    my $channel = ${ $_[1] }->[0];
    my $message = ${ $_[2] };
    return $self->_parse_input( $irc, $who, $channel, $message, 'public' );
}

sub S_notice {
    my ( $self, $irc ) = splice @_, 0, 2;
    my $who     = ${ $_[0] };
    my $channel = ${ $_[1] }->[0];
    my $message = ${ $_[2] };
    return $self->_parse_input( $irc, $who, $channel, $message, 'notice' );
}

sub S_msg {
    my ( $self, $irc ) = splice @_, 0, 2;
    my $who     = ${ $_[0] };
    my $channel = ${ $_[1] }->[0];
    my $message = ${ $_[2] };
    return $self->_parse_input( $irc, $who, $channel, $message, 'privmsg' );
}

sub _parse_input {
    my ( $self, $irc, $who, $channel, $message, $type ) = @_;

    warn "Got input: [ who => $who, channel => $channel, "
            . "mesage => $message ]"
        if $self->{debug};

    return PCI_EAT_NONE
        unless exists $self->{listen_for_input}{ $type };

    my $what;
    if ( $self->{addressed} and $type eq 'public' ) {
        my $my_nick = $irc->nick_name();
        ($what) = $message =~ m/^\s*\Q$my_nick\E[\:\,\;\.]?\s*(.*)$/i;
    }
    else {
        $what = $message;
    }

    return PCI_EAT_NONE
        unless defined $what;

    return PCI_EAT_NONE
        unless (
            ( exists $self->{triggers}{ $type }
                and $what =~ s/$self->{triggers}{$type}//
            )
            or
            ( exists $self->{trigger} and $what =~ s/$self->{trigger}// )
    );

    $what =~ s/^\s+|\s+$//g;

    warn "Matched trigger: [ who => $who, channel => $channel, "
            . "what => $what ]"
        if $self->{debug};

    foreach my $ban_re ( @{ $self->{banned} || [] } ) {
        return PCI_EAT_NONE
            if $who =~ /$ban_re/;
    }

    $poe_kernel->post( $self->{_session_id} => _poco_begin => {
                what    => $what,
                who     => $who,
                channel => $channel,
                message => $message,
                type    => $type,
            }
    );

    return $self->{eat} ? PCI_EAT_ALL : PCI_EAT_NONE;
}

sub _poco_begin {
    my ( $self, $args_ref ) = @_[OBJECT, ARG0];
    $self->_make_poco_call( $args_ref );
}

sub _poco_done {
    my ( $kernel, $self, $in_ref ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $response_message
    = $self->_make_response_message( @_[ARG0 .. $#_] );

    my $event_response;
    if ( my $key = $self->_message_into_response_event( $in_ref ) ) {
        if ( ref $key eq 'ARRAY' ) {
            $in_ref->{ $key->[0] } = $response_message;
            %$in_ref = (
                %$in_ref,
                %{ $key->[1] },
            );
        }
        else {
            $in_ref->{ $key } = $response_message;
        }
        $event_response = $in_ref;
    }
    else {
        $event_response = $self->_make_response_event( $in_ref );
    }

    $response_message = [ $response_message ]
        unless ref $response_message eq 'ARRAY';

    $self->{irc}->send_event(
        $self->{response_event} => $event_response,
    );

    if ( $self->{auto} ) {
        $in_ref->{_type} = $self->{response_types}{ $in_ref->{_type} };

        my $response_type = $in_ref->{_type} eq 'public'
                        ? 'privmsg'
                        : $in_ref->{_type};

        my $where = $in_ref->{_type} eq 'public'
                ? $in_ref->{_channel}
                : (split /!/, $in_ref->{_who})[0];

        for ( @$response_message ) {
            $kernel->post( $self->{irc} =>
                $response_type =>
                $where =>
                $_
            );
        }
    }

    undef;
}

sub _message_into_response_event { undef; }

1;
__END__

=encoding utf8

=for stopwords PoCo RTFS bot usermask

=head1 NAME

POE::Component::IRC::Plugin::BasePoCoWrap - base talking/ban/trigger
functionality for plugins using POE::Component::*

=head1 SYNOPSIS

    package POE::Component::IRC::Plugin::WrapExample;

    use strict;
    use warnings;

    use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
    use POE::Component::WWW::Google::Calculator;

    sub _make_default_args {
        return (
            response_event   => 'irc_google_calc',
            trigger          => qr/^calc\s+(?=\S)/i,
        );
    }

    sub _make_poco {
        return POE::Component::WWW::Google::Calculator->spawn(
            debug => shift->{debug},
        );
    }

    sub _make_response_message {
        my $self   = shift;
        my $in_ref = shift;
        return [ exists $in_ref->{error} ? $in_ref->{error} : $in_ref->{out} ];
    }

    sub _make_response_event {
        my $self = shift;
        my $in_ref = shift;

        return +{
            ( exists $in_ref->{error}
                ? ( error => $in_ref->{error} )
                : ( result => $in_ref->{out} )
            ),

            map +( $_ => $in_ref->{"_$_"} ),
                qw( who channel  message  type )
        }
    }

    sub _make_poco_call {
        my $self = shift;
        my $data_ref = shift;

        $self->{poco}->calc( {
                event       => '_poco_done',
                term        => delete $data_ref->{what},
                map +( "_$_" => $data_ref->{$_} ),
                    keys %$data_ref,
            }
        );
    }

    1;
    __END__

=head1 NON PoCo FLAVOR

This distribution also contains L<POE::Component::IRC::Plugin::BaseWrap>
module, for wrapping non-PoCo stuff.

=head1 DESCRIPTION

The module is a base class to use for plugins which use a
POE::Component::* object internally.
It provides: triggering with a trigger, listening for requests in
public channels, /notice and /msg (with ability to configure which exactly)
as well as auto-responding to those requests.
It provides "banned" feature which allows you to ignore certain people
if their usermask matches a regex.

I am not sure how flexible this base wrapper can get, just give it a try.
Suggestions for improvements/whishlists are more than welcome.

=head1 FORMAT OF THIS DOCUMENT

This document uses word "plugin" to refer to the plugin which uses this
base class.

Of course, by providing more functionality you need to document it.
At the end of this document you will find a POD snippet which you can
simply copy/paste into your plugin's docs. B<I recommend> that you read
that snippet first as to understand what functionality this base class
provides.

=head1 SUBS YOU NEED TO OVERRIDE

=head2 C<_make_default_args>

    sub _make_default_args {
        return (
            response_event   => 'irc_google_calc',
            trigger          => qr/^calc\s+(?=\S)/i,
        );
    }

This sub must return a list of key/value arguments which you need to
override. What you specify here will be possible to override by the user
from the C<new()> method of the plugin.

A (sane) plugin would return a C<response_event> and C<trigger> arguments
from this sub. There are some mandatory, or I shall rather say "reserved"
arguments (they have defaults) which you can return from this sub which
are as follows. On the left are the argument name, on the right is the
default value it will take if you don't return it from the
C<_make_default_args> sub:

        debug            => 0,
        auto             => 1,
        response_event   => 'irc_poco_wrap_response',
        banned           => [],
        addressed        => 1,
        eat              => 1,
        trigger          => qr/^poco_wrap\s+(?=\S)/i,
        listen_for_input => [ qw(public notice privmsg) ],

Read the L<PLUGIN DOCUMENTATION> section to understand what each of
these do.

=head2 C<_make_poco>

    sub _make_poco {
        return POE::Component::WWW::Google::Calculator->spawn(
            debug => shift->{debug},
        );
    }

This sub must return your POE::Component::* object. The arguments which
are available to the user in the C<new()> method of the plugin
(i.e. the ones which you returned from C<_make_default_args> and the
default ones) will be available as hash keys in the first element of C<@_>
which is also your plugin's object.

=head2 C<_make_poco_call>

    sub _make_poco_call {
        my $self = shift;
        my $data_ref = shift;

        $self->{poco}->calc( {
                event       => '_poco_done',
                term        => delete $data_ref->{what},
                map +( "_$_" => $data_ref->{$_} ),
                    keys %$data_ref,
            }
        );
    }

In this sub you would make a call to your POE::Component::* object
asking for some data. After the plugin returns the calls to
C<_make_response_message> and C<_make_response_event> will be made
and C<@_[ARG0 .. $#_ ]> will contain whatever your PoCo returns.

B<NOTE:> your PoCo must send the response to an event named C<_poco_done>
otherwise you'll have to override more methods which is left as an exercise.
(RTFS! :) )

The first element of C<@_> in C<_make_poco_call> sub will contain plugin's
object, the second element will contain a hashref with the following
keys/values:

    $VAR1 = {
        'who' => 'Zoffix__!n=Zoffix@unaffiliated/zoffix',
        'what' => 'http://zoffix.com',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'CalcBot, rank http://zoffix.com'
    };

=over 10

=item C<who>

The mask of the other who triggered the request

=item C<what>

The input after stripping the trigger (note, leading/trailing white-space
is stripped as well)

=item C<type>

This will be either C<public>, C<privmsg> or C<notice> and will indicate
where the message came from.

=item C<channel>

This will be the channel name if the request came from a public channel

=item C<message>

This will be the full message of the user who triggered the request.

=back

=head2 C<_make_response_message>

    sub _make_response_message {
        my $self   = shift;
        my $in_ref = shift;
        return [ exists $in_ref->{error} ? $in_ref->{error} : $in_ref->{out} ];
    }

This sub must return an arrayref or a single string. If a string is returned then it
is almost the same as returning an arrayref with just that string in it; by "almost" I mean
that the difference is also there if you are using C<_message_into_response_event()> thus
either a string or an arrayref will be present in the response event.
Each element of the returned arrayref will be "spoken" in the
channel/notice/msg (depending on the type of the request). The <@_> array
will contain plugin's object as the first element and C<@_[ARG0 .. $#_]>
will be the rest of the elements.

=head2 C<_make_response_event>

    sub _make_response_event {
        my $self = shift;
        my $in_ref = shift;

        return {
            ( exists $in_ref->{error}
                ? ( error => $in_ref->{error} )
                : ( result => $in_ref->{out} )
            ),

            map { $_ => $in_ref->{"_$_"} }
                qw( who channel  message  type ),
        }
    }

This sub will be called internally like this:

    $self->{irc}->send_event(
        $self->{response_event} =>
        $self->_make_response_event( @_[ARG0 .. $#_] )
    );

Therefore it must return something that you would like to see in the
even handler set up to handle C<response_even>. The C<@_> will contain
plugin's object as the first element and C<@_[ARG0 .. $#_]>

=head2 C<_message_into_response_event>

    sub _message_into_response_event { 'name_of_key'; }

While using previous version of this module I often found myself wishing
to put the return value of C<_make_response_message()> as a certain key
in C<$in_ref> of C<_make_response_event()> sub.. and didn't want to do
whatever the plugin would be doing twice. Now this can be easily done.

The C<_message_into_response_event> sub must return a true value which
will be the name of the key which will contain the return value of
C<_make_response_message()> sub and stuffed into C<$in_ref> hashref of
the C<_make_response_event()> sub. Basically, if you are defining
C<_message_into_response_event()> sub you should not define
C<_make_response_message()> sub as it will never be called.

If along with the return value of C<_make_response_message()> you also
want to add some extra keys into the C<$in_ref> you can return an
I<arrayref> from C<_message_into_response_event()> sub with two elements.
The first element of that arrayref would be the name of the key into
which to stick the return value of C<_make_response_message()>. The second
element must be a I<hashref> with extra keys/values which will be
set in the C<$in_ref>; note that you can override original keys from here.

The C<@_> will contain your plugin's object as the first element and
C<$in_ref> as a second element ( see C<_make_response_event()> )

As an example, the following two snippets are equivalent:

    sub _make_response_message {
        return "Right now it is " . localtime;
    }

    sub _make_response_event {
        my ( $self, $in_ref ) = @_;
        $in_ref->{time} = "Right now it is " . localtime;
        return $in_ref;
    }

    # is the same as:

    sub _make_response_message {
        return "Right now it is " . localtime;
    }

    sub _message_into_response_event { 'time' }

=head1 PREREQUISITES

This base class likes to play with the following modules under the hood:

    Carp
    POE
    POE::Component::IRC::Plugin

=head1 EXAMPLES

The C<examples/> directory of this distribution contains an example
plugin written using POE::Component::IRC::Plugin::BasePoCoWrap as well as
a google page rank bot which uses that plugin.

=head1 PLUGIN DOCUMENTATION

This section lists a "default" plugin's documentation which you can
copy/paste (and EDIT!) into your brand new plugin to describe the
functionality this base class offers. B<Make sure to proof read> ;)

    =head1 SYNOPSIS

        use strict;
        use warnings;

        use POE qw(Component::IRC  Component::IRC::Plugin::EXAMPLE);

        my $irc = POE::Component::IRC->spawn(
            nick        => 'EXAMPLE',
            server      => 'irc.freenode.net',
            port        => 6667,
            ircname     => 'EXAMPLE',
        );

        POE::Session->create(
            package_states => [
                main => [ qw(_start irc_001) ],
            ],
        );

        $poe_kernel->run;

        sub _start {
            $irc->yield( register => 'all' );

            $irc->plugin_add(
                'EXAMPLE' =>
                    POE::Component::IRC::Plugin::EXAMPLE->new
            );

            $irc->yield( connect => {} );
        }

        sub irc_001 {
            $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
        }

        <Zoffix_> EXAMPLE, example example
        <EXAMPLE> HUH?!?!! This is just an example?!?! :(

    =head1 DESCRIPTION

    This module is a L<POE::Component::IRC> plugin which uses
    L<POE::Component::IRC::Plugin> for its base. It provides interface to
    EXAMPLE EXAMPLE EXAMPLE EXAMPLE EXAMPLE.
    It accepts input from public channel events, C</notice> messages as well
    as C</msg> (private messages); although that can be configured at will.

    =head1 CONSTRUCTOR

    =head2 C<new>

        # plain and simple
        $irc->plugin_add(
            'EXAMPLE' => POE::Component::IRC::Plugin::EXAMPLE->new
        );

        # juicy flavor
        $irc->plugin_add(
            'EXAMPLE' =>
                POE::Component::IRC::Plugin::EXAMPLE->new(
                    auto             => 1,
                    response_event   => 'irc_EXAMPLE',
                    banned           => [ qr/aol\.com$/i ],
                    addressed        => 1,
                    root             => [ qr/mah.net$/i ],
                    trigger          => qr/^EXAMPLE\s+(?=\S)/i,
                    triggers         => {
                        public  => qr/^EXAMPLE\s+(?=\S)/i,
                        notice  => qr/^EXAMPLE\s+(?=\S)/i,
                        privmsg => qr/^EXAMPLE\s+(?=\S)/i,
                    },
                    response_types   => {
                        public      => 'public',
                        privmsg     => 'privmsg',
                        notice      => 'notice',
                    },
                    listen_for_input => [ qw(public notice privmsg) ],
                    eat              => 1,
                    debug            => 0,
                )
        );

    The C<new()> method constructs and returns a new
    C<POE::Component::IRC::Plugin::EXAMPLE> object suitable to be
    fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
    takes a few arguments, but I<all of them are optional>. The possible
    arguments/values are as follows:

    =head3 C<auto>

        ->new( auto => 0 );

    B<Optional>. Takes either true or false values, specifies whether or not
    the plugin should auto respond to requests. When the C<auto>
    argument is set to a true value plugin will respond to the requesting
    person with the results automatically. When the C<auto> argument
    is set to a false value plugin will not respond and you will have to
    listen to the events emited by the plugin to retrieve the results (see
    EMITED EVENTS section and C<response_event> argument for details).
    B<Defaults to:> C<1>.

    =head3 C<response_event>

        ->new( response_event => 'event_name_to_recieve_results' );

    B<Optional>. Takes a scalar string specifying the name of the event
    to emit when the results of the request are ready. See EMITED EVENTS
    section for more information. B<Defaults to:> C<irc_EXAMPLE>

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

        ->new( trigger => qr/^EXAMPLE\s+(?=\S)/i );

    B<Optional>. Takes a regex as an argument. Messages matching this
    regex, irrelevant of the type of the message, will be considered as requests. See also
    B<addressed> option below which is enabled by default as well as
    B<trigggers> option which is more specific. B<Note:> the
    trigger will be B<removed> from the message, therefore make sure your
    trigger doesn't match the actual data that needs to be processed.
    B<Defaults to:> C<qr/^EXAMPLE\s+(?=\S)/i>

    =head3 C<triggers>

        ->new( triggers => {
                public  => qr/^EXAMPLE\s+(?=\S)/i,
                notice  => qr/^EXAMPLE\s+(?=\S)/i,
                privmsg => qr/^EXAMPLE\s+(?=\S)/i,
            }
        );

    B<Optional>. Takes a hashref as an argument which may contain either
    one or all of keys B<public>, B<notice> and B<privmsg> which indicates
    the type of messages: channel messages, notices and private messages
    respectively. The values of those keys are regexes of the same format and
    meaning as for the C<trigger> argument (see above).
    Messages matching this
    regex will be considered as requests. The difference is that only messages of type corresponding to the key of C<triggers> hashref
    are checked for the trigger. B<Note:> the C<trigger> will be matched
    irrelevant of the setting in C<triggers>, thus you can have one global and specific "local" triggers. See also
    B<addressed> option below which is enabled by default as well as
    B<trigggers> option which is more specific. B<Note:> the
    trigger will be B<removed> from the message, therefore make sure your
    trigger doesn't match the actual data that needs to be processed.
    B<Defaults to:> C<qr/^EXAMPLE\s+(?=\S)/i>

    =head3 C<response_types>

        ->new(
            response_types   => {
                public      => 'public',
                privmsg     => 'privmsg',
                notice      => 'notice',
            },
        )

    B<Optional>. Takes a hashref with one, two or three keys as a value. Valid keys are C<public>,
    C<privmsg> and C<notice> that correspond to messages sent from a channel, via a private message or
    via a notice respectively. When plugin is set to auto-respond (it's the default) using this hashref
    you can control the response type based on where the message came from. The valid values of the
    keys are the same as the names of the keys. The B<default> is presented above - messages are sent the same way they came. If for example, you wish to respond to private messages with notices instead,
    simply set C<privmsg> key to value C<notice>:

        ->new(
            response_types   => {
                privmsg     => 'notice',
            },
        )

    =head3 C<addressed>

        ->new( addressed => 1 );

    B<Optional>. Takes either true or false values. When set to a true value
    all the public messages must be I<addressed to the bot>. In other words,
    if your bot's nickname is C<Nick> and your trigger is
    C<qr/^trig\s+/>
    you would make the request by saying C<Nick, trig EXAMPLE>.
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

    =head1 EMITED EVENTS

    =head2 C<response_event>

       EXAMPLE

    The event handler set up to handle the event, name of which you've
    specified in the C<response_event> argument to the constructor
    (it defaults to C<irc_EXAMPLE>) will recieve input
    every time request is completed. The input will come in C<$_[ARG0]>
    on a form of a hashref.
    The possible keys/values of that hashrefs are as follows:

    =head3 C<EXAMPLE>

    =head3 C<_who>

        { '_who' => 'Zoffix!Zoffix@i.love.debian.org', }

    The C<_who> key will contain the user mask of the user who sent the request.

    =head3 C<_what>

        { '_what' => 'EXAMPLE', }

    The C<_what> key will contain user's message after stripping the C<trigger>
    (see CONSTRUCTOR).

    =head3 C<_message>

        { '_message' => 'EXAMPLE' }

    The C<_message> key will contain the actual message which the user sent; that
    is before the trigger is stripped.

    =head3 C<_type>

        { '_type' => 'public', }

    The C<_type> key will contain the "type" of the message the user have sent.
    This will be either C<public>, C<privmsg> or C<notice>.

    =head3 C<_channel>

        { '_channel' => '#zofbot', }

    The C<_channel> key will contain the name of the channel where the message
    originated. This will only make sense if C<_type> key contains C<public>.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-Plugin-BaseWrap>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-Plugin-BaseWrap/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-Plugin-BaseWrap at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut