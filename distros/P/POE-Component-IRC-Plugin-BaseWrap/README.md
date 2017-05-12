# NAME

POE::Component::IRC::Plugin::BaseWrap - base class for IRC plugins which need triggers/ban/root control

# SYNOPSIS

    package POE::Component::IRC::Plugin::Example;

    use strict;
    use warnings;

    use base 'POE::Component::IRC::Plugin::BaseWrap';

    sub _make_default_args {
        return (
            trigger          => qr/^(?=time$)/i,
            response_event   => 'irc_time_response',
        );
    }

    sub _make_response_message {
        my ( $self, $in_ref ) = @_;
        my $nick = (split /!/, $in_ref->{who})[0];
        return [ "$nick, time over here is: " . scalar localtime ];
    }

    sub _make_response_event {
        my ( $self, $in_ref ) = @_;
        $in_ref->{time} = localtime;
        return $in_ref;
    }

    1;
    __END__



    <Zoffix> TimeBot, time
    <TimeBot> Zoffix, time over here is: Mon Mar 10 18:12:15 2008

# PoCo FLAVOR

This distribution also contains [POE::Component::IRC::Plugin::BasePoCoWrap](https://metacpan.org/pod/POE::Component::IRC::Plugin::BasePoCoWrap)
module, for wrapping [POE::Component](https://metacpan.org/pod/POE::Component) stuff.

# DESCRIPTION

The module is a base class which provides features such as limiting user
access to the plugin (banned/root), triggering on matching trigger. The
module provides listening to requests in public channels as well as /notice
and /msg messages.

# FORMAT OF THIS DOCUMENT

This document contains a section at the end titled "PLUGIN DOCUMENTATION"
which you can copy/paste into your module when using this base class
to describe any functionality that this plugin offers. It is __recommended__
that you read that documentation __first__ as to know in details the
functionality of this base class.

In this document a word "plugin" refers to the POE::Component::IRC::Plugin
which is to be using this base class.

# SUBS YOU NEED TO/CAN OVERRIDE

## `_make_default_args`

    sub _make_default_args {
        return (
            trigger          => qr/^(?=time$)/i,
            response_event   => 'irc_time_response',
        );
    }

The `_make_default_args` sub must return a list of key/value pairs which
represent the default arguments of the plugin's constructor (`new()`
method). Whatever you specify here may be overridden by giving
plugin's constructor same-named arguments. Whatever you specify here
will be available in `_make_response_message` and `_make_response_event`
as a key in plugin's object. In other words, the trigger is available
as `$self->{trigger}` (`$self` being passed in `$_[0]`). Refer
to ["PLUGIN DOCUMENTATION"](#plugin-documentation) section for information on which arguments
are provided by default (as well as their default values). Exception
being the `response_event` argument default is `irc_basewrap` and
`trigger` argument's default is `qr/^basewrap\s+(?=\S)/i`

__Note:__ user is able to change this arguments on the fly by accessing
them as hashref keys in plugin's object.

## `_make_response_message`

    sub _make_response_message {
        my ( $self, $in_ref ) = @_;
        my $nick = (split /!/, $in_ref->{who})[0];
        return "$nick, time over here is: " . scalar localtime;
    }

The `_make_response_message` sub must return either a scalar or an
arrayref. If an arrayref is returned each element
of that arrayref will be "spoken" by the plugin if `auto` argument to
the constructor is set to a true value. Returning is scalar is equivalent
to returning an arrayref with only one element.
The `@_` will contain plugin's
object as the first element (constructor's arguments, anyone?) and the
second element will contain a hashref, keys/values of which are as follows:

    $VAR1 = {
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'what' => 'time',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'TimeBot, time'
    };

### who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The usermask of the person who made the request.

### what

    { 'what' => 'time' }

The user's message after stripping the trigger.

### type

    { 'type' => 'public' }

The type of the request. This will be either `public`, `notice` or
`privmsg`

### channel

    { 'channel' => '#zofbot' }

The channel where the message came from (this will only make sense when
the request came from a public channel as opposed to /notice or /msg)

### message

    { 'message' => 'TimeBot, time' }

The full message that the user has sent.

## `_make_response_event`

    sub _make_response_event {
        my ( $self, $in_ref ) = @_;
        $in_ref->{time} = localtime;
        return $in_ref;
    }

The `_make_response_event` sub is similar to `_make_response_message` sub
except this one defines what the event handler listening to
`response_event` (see constructor's documentation in PLUGIN DOCUMENTATION
section) event will receive, but see also `_message_into_response_event()`
below. The call to this sub looks like this basically:

    $self->{irc}->send_event(
        $self->{response_event} => $self->_make_response_event( $in_ref ),
    );

The first element of `@_` will be the plugin's object and the second
element will be the same hashref as `_make_response_message` sub receives.
See `_make_response_message` sub above for more information.

## `_message_into_response_event`

    sub _message_into_response_event { 'name_of_key'; }

While using previous version of this module I often found myself wishing
to put the return value of `_make_response_message()` as a certain key
in `$in_ref` of `_make_response_event()` sub.. and didn't want to do
whatever the plugin would be doing twice. Now this can be easily done.

The `_message_into_response_event` sub must return a true value which
will be the name of the key which will contain the return value of
`_make_response_message()` sub and stuffed into `$in_ref` hashref of
the `_make_response_event()` sub. Basically, if you are defining
`_message_into_response_event()` sub you should not define
`_make_response_message()` sub as it will never be called.

If along with the return value of `_make_response_message()` you also
want to add some extra keys into the `$in_ref` you can return an
_arrayref_ from `_message_into_response_event()` sub with two elements.
The first element of that arrayref would be the name of the key into
which to stick the return value of `_make_response_message()`. The second
element must be a _hashref_ with extra keys/values which will be
set in the `$in_ref`; note that you can override original keys from here.

The `@_` will contain your plugin's object as the first element and
`$in_ref` as a second element ( see `_make_response_event()` )

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

# PLUGIN DOCUMENTATION

Below is the copy/paste friendly documentation for your plugin (lazy++)
which describes functionality offered by this base class. The text uses
word `EXAMPLE` in the places you need to fill in, but make sure to
proof read it in full ('cause it's JUST MIGHT HAPPEN that I left a
nasty surprise for those who are just WAY TOO LAZY ;) )

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
            $irc->yield( join => '#zofbot' );
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
                    root             => [ qr/mah.net$/i ],
                    addressed        => 1,
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
    takes a few arguments, but I<all of them are optional>. B<Note:>
    you can change the values of the arguments dynamically by accessing
    them as hashref keys in your plugin's object; e.g. to ban some
    user during runtime simply do
    C<< push @{ $your_plugin_object->{banned} }, qr/user!mask/ >>
    The possible arguments/values are as follows:

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

        ->new( response_event => 'event_name_to_receive_results' );

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
    (it defaults to C<irc_EXAMPLE>) will receive input
    every time request is completed. The input will come in C<$_[ARG0]>
    on a form of a hashref.
    The possible keys/values of that hashrefs are as follows:

    =head3 C<EXAMPLE>

    =head3 C<who>

        { 'who' => 'Zoffix!Zoffix@i.love.debian.org', }

    The C<who> key will contain the user mask of the user who sent the request.

    =head3 C<what>

        { 'what' => 'EXAMPLE', }

    The C<what> key will contain user's message after stripping the C<trigger>
    (see CONSTRUCTOR).

    =head3 C<message>

        { 'message' => 'EXAMPLE' }

    The C<message> key will contain the actual message which the user sent; that
    is before the trigger is stripped.

    =head3 C<type>

        { 'type' => 'public', }

    The C<type> key will contain the "type" of the message the user have sent.
    This will be either C<public>, C<privmsg> or C<notice>.

    =head3 C<channel>

        { 'channel' => '#zofbot', }

    The C<channel> key will contain the name of the channel where the message
    originated. This will only make sense if C<type> key contains C<public>.

# EXAMPLES

The `examples/` directory of this distribution contains an example plugin
which uses this base class as well as the bot that uses the plugin.

# SEE ALSO

[POE::Component::IRC::Plugin::BasePoCoWrap](https://metacpan.org/pod/POE::Component::IRC::Plugin::BasePoCoWrap), [POE::Component::IRC::Plugin](https://metacpan.org/pod/POE::Component::IRC::Plugin),

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/POE-Component-IRC-Plugin-BaseWrap](https://github.com/zoffixznet/POE-Component-IRC-Plugin-BaseWrap)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/POE-Component-IRC-Plugin-BaseWrap/issues](https://github.com/zoffixznet/POE-Component-IRC-Plugin-BaseWrap/issues)

If you can't access GitHub, you can email your request
to `bug-POE-Component-IRC-Plugin-BaseWrap at rt.cpan.org`

# AUTHOR

Zoffix Znet <zoffix at cpan.org>
([http://zoffix.com/](http://zoffix.com/), [http://haslayout.net/](http://haslayout.net/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
