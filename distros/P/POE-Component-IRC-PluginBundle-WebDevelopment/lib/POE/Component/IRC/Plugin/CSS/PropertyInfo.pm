package POE::Component::IRC::Plugin::CSS::PropertyInfo;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use base 'POE::Component::IRC::Plugin::BaseWrap';
use POE qw(Component::IRC::Plugin::CSS::PropertyInfo::Data);

my %Properties
= POE::Component::IRC::Plugin::CSS::PropertyInfo::Data->_make_property_data;

my %Value_Types
= POE::Component::IRC::Plugin::CSS::PropertyInfo::Data->_make_vt_data;

my %Make_Output_For_Command = (
    initial     => \&_command_initial,
    values      => \&_command_values,
    inherited   => \&_command_inherited,
    percentages => \&_command_percentages,
    applies_to  => \&_command_applies_to,
    media       => \&_command_media,
    value_type  => \&_command_value_type,
);

sub _make_default_args {
    return (
        trigger          => qr/^css\s+(?=\S+\s+\S+)/i,
        command_triggers => {
            exists      => qr/^ e (?:xist s?)?                    \s+/xi,
            initial     => qr/^ i (?:nitial)?                     \s+/xi,
            values      => qr/^ v (?:alue s?)?                    \s+/xi,
            inherited   => qr/^ in (?:herit (?:ed)? )?            \s+/xi,
            percentages => qr/^ p (?:ercent (?:age s? )? )?       \s+/xi,
            applies_to  => qr/^ a (?: ppl (?:y|ies))? \s* (?:to)? \s+/xi,
            media       => qr/^ m (?: edia)? \s* (?:type)?        \s+/xi,
            value_type  => qr/^ v (?: alue )? \s* t (?: ypes?)?  \s+/xi,
        },
        response_event   => 'irc_css_property_info',
    );
}

sub _do_response {
    my ( $self, $in_ref ) = @_;

    my $response_message = $self->_make_response_message( $in_ref );

    $in_ref->{out} = $response_message;
    $self->{irc}->_send_event(
        $self->{response_event} => $in_ref,
    );

    if ( $self->{auto} ) {
        my $response_type = $in_ref->{type} eq 'public'
                        ? 'privmsg'
                        : $in_ref->{type};

        my $where = $in_ref->{type} eq 'public'
                ? $in_ref->{channel}
                : (split /!/, $in_ref->{who})[0];

        $poe_kernel->post( $self->{irc} =>
                $response_type =>
                $where =>
                $response_message
        );
    }

    undef;
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;

    my $in = $in_ref->{what};

    my $trigs_ref = $self->{command_triggers};

    for my $command ( sort keys %$trigs_ref ) {
        my $trigger = $trigs_ref->{ $command };
        if ( $in =~ s/$trigger// ) {
            $in =~ s/^\s+|\s+$//g;
            $in = lc $in;

            if ( $command ne 'value_type' and !exists $Properties{$in} ) {
                return "Property '$in' does not seem to exist";
            }
            if ( $command eq 'exists' ) {
                return "Yes, property '$in' does exist";
            }

            return $Make_Output_For_Command{ $command }->( $in );
        }
    }

    return 'Invalid command in CSS Property Info plugin';
}

sub _command_initial {
    my $in = shift;
    return "Initial value for '$in' is $Properties{ $in }{initial}";
}

sub _command_values {
    my $in = shift;
    return "Property '$in' accepts: $Properties{ $in }{values}";
}

sub _command_inherited {
    my $in = shift;
    return $Properties{ $in }{inherited} eq 'yes'
            ? "Yes, '$in' is inherited"
            : "No, '$in' is not inherited";
}

sub _command_percentages {
    my $in = shift;
    return $Properties{ $in }{percentages} eq 'N/A'
            ? "Percetages do not apply to '$in'"
            : "Percentages for '$in' refer to "
                . $Properties{ $in }{percentages};
}

sub _command_applies_to {
    my $in = shift;
    return "Property '$in' applies to: $Properties{ $in }{applies_to}";
}

sub _command_media {
    my $in = shift;
    return "Property '$in' belongs to $Properties{ $in }{media} "
                . "media type(s)";
}

sub _command_value_type {
    my $in = shift;
    return exists $Value_Types{ $in }
            ? "Value type '$in' is described on $Value_Types{$in}"
            : "I am not aware of value type '$in'";
}

1;
__END__

=encoding utf8

=for stopwords bot privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::CSS::PropertyInfo - lookup CSS property information from IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::CSS::PropertyInfo);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'CSSInfoBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'CSS Property Info bot',
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
            'CSSInfo' =>
                POE::Component::IRC::Plugin::CSS::PropertyInfo->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }


    <Zoffix> CSSInfoBot, css exists foo
    <CSSInfoBot> Property 'foo' does not seem to exist
    <Zoffix> CSSInfoBot, css exists float
    <CSSInfoBot> Yes, property 'float' does exist

    <Zoffix> CSSInfoBot, css initial bar
    <CSSInfoBot> Property 'bar' does not seem to exist
    <Zoffix> CSSInfoBot, css initial float
    <CSSInfoBot> Initial value for 'float' is none

    <Zoffix> CSSInfoBot, css values position
    <CSSInfoBot> Property 'position' accepts: static | relative | absolute | fixed | inherit

    <Zoffix> CSSInfoBot, css inherited color
    <CSSInfoBot> Yes, 'color' is inherited
    <Zoffix> CSSInfoBot, css inherited display
    <CSSInfoBot> No, 'display' is not inherited

    <Zoffix> CSSInfoBot, css percentages width
    <CSSInfoBot> Percentages for 'width' refer to refer to width of containing block
    <Zoffix> CSSInfoBot, css percentages display
    <CSSInfoBot> Percetages do not apply to 'display'

    <Zoffix> CSSInfoBot, css applies to display
    <CSSInfoBot> Property 'display' applies to: all elements
    <Zoffix> CSSInfoBot, css applies to width
    <CSSInfoBot> Property 'width' applies to: all elements but non-replaced inline elements, table rows, and row groups

    <Zoffix> CSSInfoBot, css media color
    <CSSInfoBot> Property 'color' belongs to visual media type(s)
    <Zoffix> CSSInfoBot, css media azimut
    <CSSInfoBot> Property 'azimut' belongs to aural media type(s)

    <Zoffix> CSSInfoBot, css value type margin-width
    <CSSInfoBot> Value type 'margin-width' is described on http://www.w3.org/TR/CSS21/box.html#value-def-margin-width
    <Zoffix> CSSInfoBot, css value type counter
    <CSSInfoBot> Value type 'counter' is described on http://www.w3.org/TR/CSS21/syndata.html#value-def-counter

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides means to lookup
information pertaining to CSS properties (see log snippet in 'SYNOPSIS'
above)

It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'CSSPropertyInfo' =>
            POE::Component::IRC::Plugin::CSS::PropertyInfo->new
    );

    # juicy flavor
    $irc->plugin_add(
        'CSSPropertyInfo' =>
      POE::Component::IRC::Plugin::CSS::PropertyInfo->new(
        auto             => 1,
        banned           => [ qr/aol\.com$/i ],
        root             => [ qr/mah.net$/i ],
        addressed        => 1,
        trigger          => qr/^css\s+(?=\S+\s+\S+)/i,
        command_triggers => {
            exists      => qr/^ e (?:xist s?)?                    \s+/xi,
            initial     => qr/^ i (?:nitial)?                     \s+/xi,
            values      => qr/^ v (?:alue s?)?                    \s+/xi,
            inherited   => qr/^ in (?:herit (?:ed)? )?            \s+/xi,
            percentages => qr/^ p (?:ercent (?:age s? )? )?       \s+/xi,
            applies_to  => qr/^ a (?: ppl (?:y|ies))? \s* (?:to)? \s+/xi,
            media       => qr/^ m (?: edia)? \s* (?:type)?        \s+/xi,
            value_type  => qr/^ v (?: alue )? \s* t (?: ypes?)?  \s+/xi,
        },
        response_event   => 'irc_css_property_info',
        listen_for_input => [ qw(public notice privmsg) ],
        eat              => 1,
        debug            => 0,
      )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::CSS::PropertyInfo> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. The possible
arguments/values are as follows:

=head3 auto

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emitted by the plugin to retrieve the results (see
EMITTED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 response_event

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_css_property_info>

=head3 banned

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) making the request matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 root

    ->new( root => [ qr/\Qjust.me.and.my.friend.net\E$/i ] );

B<Optional>. As opposed to C<banned> argument, the C<root> argument
B<allows> access only to people whose usermasks match B<any> of
the regexen you specify in the arrayref the argument takes as a value.
B<By default:> it is not specified. B<Note:> as opposed to C<banned>
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 trigger

    ->new( trigger => qr/^css\s+(?=\S+\s+\S+)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed including
sub triggers which are set by C<command_triggers> argument (see below).
B<Defaults to:> C<qr/^css\s+(?=\S+\s+\S+)/i>

=head3 command_triggers

    command_triggers => {
        exists      => qr/^ e (?:xist s?)?                    \s+/xi,
        initial     => qr/^ i (?:nitial)?                     \s+/xi,
        values      => qr/^ v (?:alue s?)?                    \s+/xi,
        inherited   => qr/^ in (?:herit (?:ed)? )?            \s+/xi,
        percentages => qr/^ p (?:ercent (?:age s? )? )?       \s+/xi,
        applies_to  => qr/^ a (?: ppl (?:y|ies))? \s* (?:to)? \s+/xi,
        media       => qr/^ m (?: edia)? \s* (?:type)?        \s+/xi,
        value_type  => qr/^ v (?: alue )? \s* t (?: ypes?)?  \s+/xi,
    },

B<Optional>. After the C<trigger> (see above) is matched and B<removed>
a match for a particular "command" will be made. As the case is with
C<trigger> the C<command_triggers> will be B<removed> from the request
string before proceeding thus make sure they don't match the data needed
for the request. That data will be a name of the CSS property for all
the commands except for C<value_type> command for which the data are
CSS value types listed below. The C<command_triggers>
argument takes a hashref with keys being command names and values
being regexes. The B<default> settings are presented in the snippet above.
The commands (keys of the C<command_triggers> hashref) represent the
following commands:

=head4 exists

    exists      => qr/^ e (?:xist s?)?                    \s+/xi,

    <Zoffix> CSSInfoBot, css exists foo
    <CSSInfoBot> Property 'foo' does not seem to exist
    <Zoffix> CSSInfoBot, css exists float
    <CSSInfoBot> Yes, property 'float' does exist

The C<exists> command checks whether or not CSS property exists.

=head4 initial

    initial     => qr/^ i (?:nitial)?                     \s+/xi,

    <Zoffix> CSSInfoBot, css initial bar
    <CSSInfoBot> Property 'bar' does not seem to exist
    <Zoffix> CSSInfoBot, css initial float
    <CSSInfoBot> Initial value for 'float' is none

The C<initial> command lists property's initial values.

=head4 values

    values      => qr/^ v (?:alue s?)?                    \s+/xi,

    <Zoffix> CSSInfoBot, css values position
    <CSSInfoBot> Property 'position' accepts: static | relative | absolute | fixed | inherit

The C<values> command lists valid values accepted by CSS property. Those
will be either literal values or "value types". The link describing certain
value type can be obtained by inquiring the plugin's C<value_type> command
(see below).

=head4 inherited

    inherited   => qr/^ in (?:herit (?:ed)? )?            \s+/xi,

    <Zoffix> CSSInfoBot, css inherited color
    <CSSInfoBot> Yes, 'color' is inherited
    <Zoffix> CSSInfoBot, css inherited display
    <CSSInfoBot> No, 'display' is not inherited

The C<inherited> command tells one whether or not a certain CSS property's
values are inherited or not.

=head4 percentages

    percentages => qr/^ p (?:ercent (?:age s? )? )?       \s+/xi,

    <Zoffix> CSSInfoBot, css percentages width
    <CSSInfoBot> Percentages for 'width' refer to refer to width of containing block
    <Zoffix> CSSInfoBot, css percentages display
    <CSSInfoBot> Percetages do not apply to 'display'

The C<percentages> command tells one to what do the percentage values
for the property refer to.

=head4 applies_to

    applies_to  => qr/^ a (?: ppl (?:y|ies))? \s* (?:to)? \s+/xi,

    <Zoffix> CSSInfoBot, css applies to display
    <CSSInfoBot> Property 'display' applies to: all elements
    <Zoffix> CSSInfoBot, css applies to width
    <CSSInfoBot> Property 'width' applies to: all elements but non-replaced inline elements, table rows, and row groups

The C<applies_to> command tells one to which elements the specified property
applies.

=head4 media

    media       => qr/^ m (?: edia)? \s* (?:type)?        \s+/xi,

    <Zoffix> CSSInfoBot, css media color
    <CSSInfoBot> Property 'color' belongs to visual media type(s)
    <Zoffix> CSSInfoBot, css media azimut
    <CSSInfoBot> Property 'azimut' belongs to aural media type(s)

The C<media> command tells one to which media type a certain property
belongs.

=head4 value_type

    value_type  => qr/^ v (?: alue )? \s* t (?: ypes?)?  \s+/xi,

    <Zoffix> CSSInfoBot, css value type margin-width
    <CSSInfoBot> Value type 'margin-width' is described on http://www.w3.org/TR/CSS21/box.html#value-def-margin-width
    <Zoffix> CSSInfoBot, css value type counter
    <CSSInfoBot> Value type 'counter' is described on http://www.w3.org/TR/CSS21/syndata.html#value-def-counter

Lastly, the C<value_type> command. It takes "value types" as an argument
as opposed to CSS properties and simply returns a URI pointing to the
documentation describing the value type. Possible value types are these:

    margin-width
    absolute-size
    number
    time
    string
    border-width
    border-style
    frequency
    identifier
    color
    integer
    specific-voice
    relative-size
    generic-voice
    padding-width
    angle
    percentage
    family-name
    uri
    length
    generic-family
    shape
    counter

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig a float>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to make a request. Note: this argument has no effect on
C</notice> and C</msg> requests. B<Defaults to:> C<1>

=head3 listen_for_input

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

=head3 eat

    ->new( eat => 0 );

B<Optional>. If set to a false value plugin will return a
C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head3 debug

    ->new( debug => 1 );

B<Optional>. Takes either a true or false value. When C<debug> argument
is set to a true value some debugging information will be printed out.
When C<debug> argument is set to a false value no debug info will be
printed. B<Defaults to:> C<0>.

=head1 EMITTED EVENTS

=head2 response_event

    $VAR1 = {
        'out' => 'Property \'float\' applies to: all, but see http://www.w3.org/TR/CSS21/visuren.html#dis-pos-flo',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'what' => 'a float',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'CSSInfoBot_, css a float'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_css_property_info>) will receive input
every time request is completed. The input will come in a form of a
hashref in C<$_[ARG0]>. The keys/values of that hashref are as follows:

=head3 out

    { 'out' => 'Property \'float\' applies to: all, but see http://www.w3.org/TR/CSS21/visuren.html#dis-pos-flo', }

The C<out> key will contain the "information message", this will be
the response string containing the response to the particular command
and this will be what will be sent to IRC if C<auto> argument to constructor
is set to a true value.

=head3 what

    { 'what' => 'a float' }

The C<what> key will contain the command and the data associated with it.
In other words what the user requested after the C<trigger> was stripped
off, in the sample above the command is C<applies_to> and the property
is C<float>.

=head3 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

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

    { 'message' => 'CSSInfoBot_, css a float' }

The C<message> key will contain the message which the user has
sent to request.

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

