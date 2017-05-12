package POE::Component::IRC::Plugin::WWW::HTMLTagAttributeCounter;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
use POE::Component::WWW::HTMLTagAttributeCounter;

sub _make_default_args {
    return (
        response_event   => 'irc_html_counter',
        trigger          => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
    );
}

sub _make_poco {
    my $self = shift;
    return POE::Component::WWW::HTMLTagAttributeCounter->spawn(
        $self->{ua} ? $self->{ua} : ()
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;

    my $prefix = '';
    if ( $in_ref->{_type} eq 'public' ) {
        $prefix = (split /!/, $in_ref->{_who})[0] . ', ';
    }

    if ( ref $in_ref->{where} ) {
        return $prefix . 'invalid arguments. Usage: [attr|tag] http://example.com/ div span a';
    }

    return "$prefix$in_ref->{error}"
        if $in_ref->{error};

    my $what = $in_ref->{type} eq 'attr' ? 'attributes' : 'tags';

    return "${prefix}I counted $in_ref->{result_readable} $what";
}

sub _message_into_response_event { 'out' }

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    my ( $type, $where, @what ) = split ' ', $data_ref->{what};

    $type = 'tag'
        unless $type eq 'attr'
            or $type eq 'tag';

    $where = \'ERROR'
        unless @what;

    $self->{poco}->count( {
            event       => '_poco_done',
            where       => $where,
            type        => $type,
            what        => \@what,
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}

1;
__END__

=encoding utf8

=for stopwords bot html privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::WWW::HTMLTagAttributeCounter - html tag and attribute counter for IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC Component::IRC::Plugin::WWW::HTMLTagAttributeCounter);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'CounterBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'CounterBot',
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
            'HTMLCounter' =>
                POE::Component::IRC::Plugin::WWW::HTMLTagAttributeCounter->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix> CounterBot, count tag http://zoffix.com/ div a span
    <CounterBot> Zoffix, I counted 15 a, 6 div and 8 span tags

    <Zoffix> CounterBot, count attr http://zoffix.com/ href class id
    <CounterBot> Zoffix, I counted 9 class, 17 href and 15 id attributes

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
count HTML tags and attributes in the web page given. The plugin is non-blocking and
it accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 IRC USAGE

With all the default arguments you'd trigger the plugin with the following request:

    <Zoffix> CounterBot, count tag http://zoffix.com/ div a span

Where C<count> is the trigger, C<tag> is the type of count that can be either C<tag> or
C<attr>, following that is the URI on which to perform the count and after the URI is a
whitespace separated list of tags to count.

Note that C<tag http://zoffix.com/ div a span> line is all whitespace separated, you cannot
change that, really.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'HTMLCounter' => POE::Component::IRC::Plugin::WWW::HTMLTagAttributeCounter->new
    );

    # juicy flavor
    $irc->plugin_add(
        'HTMLCounter' =>
            POE::Component::IRC::Plugin::WWW::HTMLTagAttributeCounter->new(
                auto             => 1,
                ua               => LWP::UserAgent->new( timeout => 10 ),
                response_event   => 'irc_html_counter',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
                triggers         => {
                    public  => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
                    notice  => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
                    privmsg => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::WWW::HTMLTagAttributeCounter> object suitable to be
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
listen to the events emitted by the plugin to retrieve the results (see
EMITTED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 C<response_event>

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_html_counter>

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

    ->new( trigger => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex, irrelevant of the type of the message, will be considered as requests. See also
B<addressed> option below which is enabled by default as well as
B<triggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
See C<IRC USAGE> section below to understand how you need to format your trigger.
B<Defaults to:> C<qr/^count\s+(?=\S+\s+\S+\s+\S+)/i>

=head3 C<triggers>

    ->new( triggers => {
            public  => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
            notice  => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
            privmsg => qr/^count\s+(?=\S+\s+\S+\s+\S+)/i,
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
B<triggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^count\s+(?=\S+\s+\S+\s+\S+)/i>

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

=head1 EMITTED EVENTS

=head2 C<response_event>

    $VAR1 = {
        'result_readable' => '9 class, 17 href and 15 id',
        'where' => 'http://zoffix.com/',
        'type' => 'attr',
        'result' => {
            'href' => '17',
            'id' => '15',
            'class' => '9'
        },
        'what' => [
            'href',
            'class',
            'id'
        ],
        'out' => 'Zoffix, I counted 9 class, 17 href and 15 id attributes',
        '_what' => 'attr http://zoffix.com/ href class id',
        '_channel' => '#zofbot',
        '_type' => 'public',
        '_who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        '_message' => 'CounterBot, count attr http://zoffix.com/ href class id',
    };


The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_html_counter>) will receive input
every time request is completed. The input will come in C<$_[ARG0]>
on a form of a hashref.
The possible keys/values of that hashrefs are as follows:

=head3 C<result_readable>

    { 'result_readable' => '15 a, 6 div and 8 span', }

The C<result_readable> key will contain the return value of C<result_readable> method
of L<WWW::HTMLTagAttributeCounter>.

=head3 C<result>

    {
        'result' => {
            'href' => '17',
            'id' => '15',
            'class' => '9'
        },
    }

The C<result> key will contain the same hashref as L<WWW::HTMLTagAttributeCounter>'s
C<count()> method would return. See L<WWW::HTMLTagAttributeCounter> for details.

=head3 C<where>

    'where' => 'http://zoffix.com/',

The C<where> key will contain the URI of the page on which the count is performed.

=head3 C<type>

    'type' => 'tag',

The C<type> key will contain the type of the count, this will be either C<attr> or
C<tag>.

=head3 C<result>

    'result' => 'Zoffix, I counted 15 a, 6 div and 8 span tags',

The C<result> key will contain the message that would be spoken on IRC when constructor's
C<auto> argument is set to a true value.

=head3 C<what>

    'what' => [
        'div',
        'a',
        'span'
    ],

The C<what> key will contain an arrayref of tags or attributes that were counted.

=head3 C<_who>

    { '_who' => 'Zoffix!Zoffix@i.love.debian.org', }

The C<_who> key will contain the user mask of the user who sent the request.

=head3 C<_what>

    { '_what' => 'EXAMPLE', }

The C<_what> key will contain user's message after stripping the C<trigger>
(see CONSTRUCTOR).

=head3 C<_message>

    { '_message' => 'CounterBot, count attr http://zoffix.com/ href class id', }

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

=head1 SEE ALSO

L<POE>, L<WWW::HTMLTagAttributeCounter>

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
