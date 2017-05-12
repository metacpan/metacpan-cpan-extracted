package POE::Component::IRC::Plugin::ColorNamer;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use App::ColorNamer;
use base 'POE::Component::IRC::Plugin::BaseWrap';

sub _make_default_args {
    return (
        trigger          => qr/^color\s*namer\s+(?=\S+$)/i,
        response_event   => 'irc_colornamer',
    );
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;

    my $is_sane_only = $in_ref->{what} =~ s/^://;

    my $app  = App::ColorNamer->new;

    $app->sane_colors( $self->{sane_colors} )
        if $self->{sane_colors};

    my $name = $app->get_name( $in_ref->{what}, $is_sane_only );

    my $out;
    if ( $name ) {
        $out = "$name->{name} (#$name->{hex}"
            . ( $name->{exact} ? ', exact match)' : ')' );
    }
    else {
        $out = 'Error: ' . $app->error;
    }

    return $out;
}

sub _message_into_response_event { 'result' }

1;
__END__

=encoding utf8

=for stopwords PoCo bot privmsg regexen requestor usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::ColorNamer - PoCo IRC plugin that tells the name of the color by its hex code

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::ColorNamer);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'ColorNamerBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'ColorNamerBot',
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
            'ColorNamer' =>
                POE::Component::IRC::Plugin::ColorNamer->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }


    <Zoffix> ColorNamerBot, colornamer :89043d
    <ColorNamerBot> Brick Red (#c62d42)
    <Zoffix> ColorNamerBot, colornamer 89043d
    <ColorNamerBot> Siren (#7a013a)
    <Zoffix> ColorNamerBot, colornamer fff
    <ColorNamerBot> White (#ffffff, exact match)

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin that uses
L<POE::Component::IRC::Plugin> for its base. It provides means to
get a name of a color, given its hex code. This functionality is
provided by L<App::ColorNamer> module.
The plugin accepts input from public channel events, C</notice> messages
as well as C</msg> (private messages).

=head1 PLUGIN FUNCTION USAGE

    <Zoffix> ColorNamerBot, colornamer :89043d
    <ColorNamerBot> Brick Red (#c62d42)
    <Zoffix> ColorNamerBot, colornamer 89043d
    <ColorNamerBot> Siren (#7a013a)
    <Zoffix> ColorNamerBot, colornamer fff
    <ColorNamerBot> White (#ffffff, exact match)

The plugin expects either a 3 or 6-digit hexadecimal color code as
input, optionally prefixed by a hash symbol. This input can be
prefixed by a colon character(:) to make the plugin use "sane colors"
only. See L<App::ColorNamer>'s C<sane_colors()> method's description
for more info.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'ColorNamer' => POE::Component::IRC::Plugin::ColorNamer->new
    );

    # juicy flavor
    $irc->plugin_add(
        'ColorNamer' =>
            POE::Component::IRC::Plugin::ColorNamer->new(
                auto             => 1,
                sane_colors      => [ qw/FFFAAA  AAAFFF/ ],
                response_event   => 'irc_colornamer',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                trigger          => qr/^color\s*namer\s+(?=\S+$)/i,
                triggers         => {
                    public  => qr/^color\s*namer\s+(?=\S+$)/i,
                    notice  => qr/^color\s*namer\s+(?=\S+$)/i,
                    privmsg => qr/^color\s*namer\s+(?=\S+$)/i,
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
C<POE::Component::IRC::Plugin::ColorNamer> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. B<Note:>
you can change the values of the arguments dynamically by accessing
them as hashref keys in your plugin's object; e.g. to ban some
user during runtime simply do
C<< push @{ $your_plugin_object->{banned} }, qr/user!mask/ >>
The possible arguments/values are as follows:

=head3 C<sane_colors>

    sane_colors => [ qw/FFFAAA  AAAFFF/ ],

B<Optional>. Takes an arrayref as a value. If specified, this
arrayref will be given to C<sane_colors()> L<App::ColorNamer>'s method.
See L<App::ColorNamer>'s C<sane_colors()> method's description
for more info.
B<By default> is not specified.

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

=head3 C<response_event>

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_colornamer>

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
B<By default:> it is not specified. B<Note:> as opposed to C<banned>,
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 C<trigger>

    ->new( trigger => qr/^color\s*namer\s+(?=\S+$)/i);

B<Optional>. Takes a regex as an argument. Messages matching this
regex, irrelevant of the type of the message, will be considered as
requests. See also B<addressed> option below which is enabled by default
as well as B<triggers> option, which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^color\s*namer\s+(?=\S+$)/i>

=head3 C<triggers>

    ->new( triggers => {
            public  => qr/^color\s*namer\s+(?=\S+$)/i,
            notice  => qr/^color\s*namer\s+(?=\S+$)/i,
            privmsg => qr/^color\s*namer\s+(?=\S+$)/i,
        }
    );

B<Optional>. Takes a hashref as an argument which may contain either
one or all of keys B<public>, B<notice> and B<privmsg> which indicates
the type of messages: channel messages, notices and private messages
respectively. The values of those keys are regexes of the same format and
meaning as for the C<trigger> argument (see above).
Messages matching this
regex will be considered as requests. The difference is that only
messages of type corresponding to the key of C<triggers> hashref
are checked for the trigger. B<Note:> the C<trigger> will be matched
irrelevant of the setting in C<triggers>, thus you can have one global
and specific "local" triggers. See also
B<addressed> option below which is enabled by default as well as
B<triggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^color\s*namer\s+(?=\S+$)/i> for all three triggers.

=head3 C<response_types>

    ->new(
        response_types   => {
            public      => 'public',
            privmsg     => 'privmsg',
            notice      => 'notice',
        },
    )

B<Optional>. Takes a hashref with one, two or three keys as a value.
Valid keys are C<public>, C<privmsg> and C<notice> that correspond to
messages sent from a channel, via a private message or via a notice
respectively. When plugin is set to auto-respond (it's the default)
using this hashref you can control the response type based on where the
message came from. The valid values of the keys are the same as the
names of the keys. The B<default> is presented above - messages are
sent the same way they came. If for example, you wish to respond to
private messages with notices instead, simply set C<privmsg> key to
value C<notice>:

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
you would make the request by saying C<Nick, trig #fff>.
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

    {
        'result' => 'Cod Gray (#0b0b0b)',
        'who' => 'Zoffix!sexy@i.love.debian.org',
        'what' => '080808',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'ColorNamerBot, colornamer 080808'
    }

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_colornamer>) will receive input
every time request is completed. The input will come in C<$_[ARG0]>
on a form of a hashref.
The possible keys/values of that hashrefs are as follows:

=head3 C<result>

    {
        'result' => 'Cod Gray (#0b0b0b)',
    ...

The C<result> key will contain the output of the plugin; this
is the string the plugin would output to the requestor if the
C<auto> option is turned on.

=head3 C<who>

    {
        'who' => 'Zoffix!Zoffix@i.love.debian.org',
    ...

The C<who> key will contain the user mask of the user who sent the request.

=head3 C<what>

    {
        'what' => '080808',
    ...

The C<what> key will contain user's message after stripping the C<trigger>
(see CONSTRUCTOR).

=head3 C<message>

    {
        'message' => 'ColorNamerBot, colornamer 080808'
    ...

The C<message> key will contain the actual message which the user sent; that
is before the trigger is stripped.

=head3 C<type>

    {
        'type' => 'public',
    ...

The C<type> key will contain the "type" of the message the user have sent.
This will be either C<public>, C<privmsg> or C<notice>.

=head3 C<channel>

    {
        'channel' => '#zofbot',
    ...

The C<channel> key will contain the name of the channel where the message
originated. This will only make sense if C<type> key contains C<public>.

=head1 EXAMPLE

The C<examples/> directory of this distribution contains a sample
color naming IRC bot.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-PluginBundle-WebDevelopment at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut