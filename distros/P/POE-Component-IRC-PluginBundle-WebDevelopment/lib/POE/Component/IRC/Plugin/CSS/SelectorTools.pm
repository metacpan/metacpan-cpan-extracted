package POE::Component::IRC::Plugin::CSS::SelectorTools;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use Carp;
use POE;
use base 'POE::Component::IRC::Plugin::BaseWrap';

sub _make_default_args {
    return (
        trigger         => qr/^sel(?:ector)?\s+(?=\S+)/i,
        ztriggers        => {
            link    => qr/^link\s+(?=\S+)/i,
            multi   => qr/^multi\s+(?=\S+)/i,
        },
        response_event  => 'irc_css_selector_tools',
        line_length     => 350,
        max_length      => 695,
    );
}

sub _message_into_response_event { 'out' };

sub _make_response_message {
    my ( $self, $in_ref ) = @_;

    my $in = $in_ref->{what};
    $self->{debug}
        and carp "CSS SelectorTools: ($in)";

    my $trig_ref = $self->{ztriggers};
    if ( $in =~ s/$trig_ref->{link}// ) {
        $self->{debug}
            and carp "CSS SelectorTools [LINK]: ($in)";

        return $self->_prepare_output( $self->_command_link( $in ) );
    }
    elsif ( $in =~ s/$trig_ref->{multi}// ) {
        $self->{debug}
            and carp "CSS SelectorTools [MULTI]: ($in)";

        return $self->_prepare_output( $self->_command_multi( $in ) );
    }
    else {
        return [ "Invalid command in CSS::SelectorTools plugin" ];
    }
}

sub _command_multi {
    my ( $self, $in ) = @_;
    $in =~ s/^\s+|\s+$//g;

    if ( my ( $dup, $selectors ) = $in =~ /^\[ ([^\]]+) ] \s+ (.+)/x ) {
        $selectors =~ s/(^|,\s*)/$1$dup /g;
        return $selectors;
    }
    else {
        return "Input must be in the form:"
                . " [part_to_duplicate] sel1, sel2 .. selN";
    }
}

sub _command_link {
    my ( $self, $in ) = @_;
    my $out = 'a:link, a:visited, a:hover, a:active';
    $out =~ s/a(?=:)/$in/g;
    return $out;
}

sub _prepare_output {
    my ( $self, $out ) = @_;
    my @out;
    my ( $max, $len ) = @$self{ qw(max_length  line_length) };

    $out = substr( $out, 0, $max  ) . q|...|
        if length $out >= $max;

    while ( length $out > $len ) {
        push @out, substr $out, 0, $len;
        $out = substr $out, $len;
    }
    return [ @out, $out ];
}

1;
__END__

=encoding utf8

=for stopwords bot bots privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::CSS::SelectorTools - couple of CSS selector tools for IRC bots

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::CSS::SelectorTools);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'CSSToolsBot',
        server      => '127.0.0.1',
        port        => 6667,
        ircname     => 'CSSToolsBot',
        plugin_debug => 1,
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start  irc_001 ) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'CSSSelectorTools' =>
                POE::Component::IRC::Plugin::CSS::SelectorTools->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }

    <Zoffix> CSSToolsBot, sel link #foo div #beer .bas a
    <CSSToolsBot> #foo div #beer .bas a:link, #foo div #beer .bas a:visited, #foo div #beer .bas a:hover, #foo div #beer .bas a:active

    <Zoffix> CSSToolsBot, sel multi [#foo] bar, beer, bez, p, div, a
    <CSSToolsBot> #foo bar, #foo beer, #foo bez, #foo p, #foo div, #foo a

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides basic CSS selector
making tools. So far there are only two tools, the "link rule maker" and
"multi-selector maker". If you have any suggestions for other tools feel
free to let me know.

It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

The "commands" and their functionality is described under C<triggers>
sub section of CONSTRUCTOR section.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'CSSSelectorTools' =>
            POE::Component::IRC::Plugin::CSS::SelectorTools->new
    );

    # juicy flavor
    $irc->plugin_add(
        'CSSSelectorTools' =>
            POE::Component::IRC::Plugin::CSS::SelectorTools->new(
                auto             => 1,
                response_event   => 'irc_css_selector_tools',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                line_length      => 350,
                max_length       => 695,
                trigger          => qr/^sel(?:ector)?\s+(?=\S+)/i,
                ztriggers        => {
                    link    => qr/^link\s+(?=\S+)/i,
                    multi   => qr/^multi\s+(?=\S+)/i,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::CSS::SelectorTools> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. B<Note:> you
can change all these arguments dynamically by accessing your plugin
object as a hashref; in other words, if you want to ban a user on
the fly you can do:
C<< push @{ $your_plugin_object->{banned} }, qr/\Quser!mask@foos.com/; >> .
The possible arguments/values are as follows:

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
section for more information. B<Defaults to:> C<irc_css_selector_tools>

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

=head3 C<line_length>

    { line_length => 350, }

B<Optional>. Depending on the input plugin's output may be quite verbose.
If the length of the output is longer than C<line_length> characters it
will be split into several messages (to avoid disconnects or content
cut offs). B<Defaults to:> C<350>

=head3 C<max_length>

    { max_length => 695, }

B<Optional>. Same as C<line_length> argument except C<max_length> specifies
the maximum length of the output plugin is allowed to emit. If length
of the output is longer than C<max_length> the excess will be cut off and
C<...> will be appended to indicate "overflow". B<Defaults to:> C<695>

=head3 C<trigger>

    ->new( trigger => qr/^sel(?:ector)?\s+(?=\S+)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^sel(?:ector)?\s+(?=\S+)/i>

=head3 C<ztriggers>

    ->new( triggers => {
                    link    => qr/^link\s+(?=\S+)/i,
                    multi   => qr/^multi\s+(?=\S+)/i,
        },
    );

B<Optional>. The C<ztriggers> (not the plural form with "z" at the front)
argument takes a
hashref as a value. The keys of that hashref are command names and values
are regex (C<qr//>) which represent the trigger for the corresponding
command. Same as with C<trigger>, the individual command C<ztriggers> will
be removed from input so make sure they don't match the actual data
to be processed. If none of C<ztriggers> regexes match plugin will inform
the user that the used command is invalid.
Currently plugin provides only two commands:

=head4 C<link>

    { link => qr/^link\s+(?=\S+)/i, }

    <Zoffix> CSSToolsBot, sel link #foo div #beer .bas a
    <CSSToolsBot> #foo div #beer .bas a:link, #foo div #beer .bas
                  a:visited, #foo div #beer .bas a:hover, #foo div #beer
                  .bas a:active

The C<link> command is a "link selector" maker. Say you want to style
C<#foo bar beer a> links but too lazy to type out the C<:hover> and the rest
(or what is more importantly - don't remember the correct order). Just give
the plugin the selector for your link and it will do everything itself.
B<Trigger defaults to:> C<< qr/^link\s+(?=\S+)/i >>

=head4 C<multi>

    { multi   => qr/^multi\s+(?=\S+)/i, }

    <Zoffix> CSSToolsBot, sel multi [#foo] bar, beer, bez, p, div, a
    <CSSToolsBot> #foo bar, #foo beer, #foo bez, #foo p, #foo div, #foo a

The C<multi> command is a "repeater"; as useless as it is it helps to use
this one when all those people ask whether or not selector
C<< #foo bar, beer, bez >> selects C<beer> and C<bez> under C<#foo>.
B<Trigger defaults to:> C<< qr/^multi\s+(?=\S+)/i >>

=head3 C<addressed>

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig link #foo>.
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
        'out' => [
            '#foo bar, #foo beer, #foo bez, #foo p, #foo div, #foo a'
        ],
        'who' => 'Zoffix!Zoffix@irc.zoffix.com',
        'what' => 'multi [#foo] bar, beer, bez, p, div, a',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'CSSToolsBot, sel multi [#foo] bar, beer, bez, p, div, a'
    };


The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_css_selector_tools>) will receive input
every time request is completed. The input will come in C<$_[ARG0]> in
a form of a hashref. The possible keys/values of that hashref are as
follows:

=head3 out

    {
        'out' => [
            '#foo bar, #foo beer, #foo bez, #foo p, #foo div, #foo a'
        ],
    }

The C<out> key will contain an arrayref of responses the plugin would send
to IRC if C<auto> argument to constructor is set to a true value.
If the length of output is more than C<line_length> (see CONSTRUCTOR) then
this arrayref will contain several elements.

=head3 what

    { 'what' => 'multi [#foo] bar, beer, bez, p, div, a', }

The C<what> key will contain the command and the data associated with it.
In other words what the user requested after the C<trigger> was stripped
off (note that C<triggers> are NOT stripped here yet)

=head3 who

    { 'who' => 'Zoffix!Zoffix@irc.zoffix.com', }

The C<who> key will contain the usermask of the user who sent the request.

=head3 type

    { 'type' => 'public' }

The C<type> key will contain the "type" of the message sent by the
requester. The possible values are: C<public>, C<notice> and C<privmsg>
indicating that request was requested in public channel, via C</notice>
and via C</msg> (private message) respectively.

=head3 channel

    { 'channel' => '#zofbot' }

The C<channel> key will contain the name of the channel from which the
request
came from. This will only make sense when C<type> key (see above) contains
C<public>.

=head3 message

    { 'message' => 'CSSToolsBot, sel multi [#foo] bar, beer, bez, p, div, a' }

The C<message> key will contain the message which the user has
sent as a request (i.e. without any triggers being stripped off).

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

