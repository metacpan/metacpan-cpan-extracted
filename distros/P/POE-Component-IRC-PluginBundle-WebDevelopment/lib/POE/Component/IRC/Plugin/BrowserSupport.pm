package POE::Component::IRC::Plugin::BrowserSupport;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use POE::Component::WWW::WebDevout::BrowserSupportInfo;
use base 'POE::Component::IRC::Plugin::BasePoCoWrap';

sub _make_default_args {
    return (
        response_event   => 'irc_webdevout_support',
        trigger          => qr/^support\s+(?=\S)/i,
    );
}

sub _make_poco {
    my $self = shift;
    return POE::Component::WWW::WebDevout::BrowserSupportInfo->spawn(
        debug => $self->{debug},
        exists $self->{obj_args} ? ( obj_args => $self->{obj_args} ) : (),
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;
    my $what = substr $in_ref->{what}, 0, 10;
    if ( exists $in_ref->{error} ) {
        return [ "($what) Error: $in_ref->{error}" ];
    }
    else {
        my $results = join ' | ',
                        map { "$_: ${\(defined $in_ref->{results}{$_}
                                ? $in_ref->{results}{$_} : '')}"
                            } sort keys %{ $in_ref->{results} };

        return [ "($what) $in_ref->{uri_info}   $results" ];
    };
}

sub _make_response_event {
    my $self = shift;
    my $in_ref = shift;

    return {
        uri_info    => $in_ref->{uri_info},
        what        => $in_ref->{what},
        ( exists $in_ref->{error}
            ? ( error   => $in_ref->{error} )
            : ( results => $in_ref->{results} )
        ),
        map { $_ => $in_ref->{"_$_"} }
            qw( who channel  message  type ),
    }
}

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    $self->{poco}->fetch( {
            event       => '_poco_done',
            what        => delete $data_ref->{what},
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}

1;
__END__

=encoding utf8

=for stopwords bot privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::BrowserSupport - lookup browser support for
CSS/HTML/JS from IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::BrowserSupport);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'BrowserSupportBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'BrowserSupport Bot',
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
            'BrowserSupport' =>
                POE::Component::IRC::Plugin::BrowserSupport->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix__> BrowserSupportBot, support html
    <BrowserSupportBot> (html)     http://www.webdevout.net/browser-support-html#support-html401
    FX1_5: 91.741% | FX2: 91.741% | IE6: 80.211% | IE7: 80.802% | KN3_5: ? |
    OP8: 85.822% | OP9: 86.361% | SF2: ?

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
L<http://webdevout.net>'s browser support API.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'BrowserSupport' => POE::Component::IRC::Plugin::BrowserSupport->new
    );

    # juicy flavor
    $irc->plugin_add(
        'BrowserSupport' =>
            POE::Component::IRC::Plugin::BrowserSupport->new(
                auto             => 1,
                response_event   => 'irc_webdevout_browser_support',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^support\s+(?=\S)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
                obj_args         => { long => 1 },
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::BrowserSupport> object suitable to be
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
section for more information. B<Defaults to:> C<irc_webdevout_support>

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

    ->new( trigger => qr/^support\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^support\s+(?=\S)/i>

=head3 addressed

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

=head3 obj_args

    ->new( obj_args => { long => 1 } );

B<Optional>. Takes a hashref as an argument which contains
L<WWW::WebDevout::BrowserSupportInfo> constructor's arguments. See
L<WWW::WebDevout::BrowserSupportInfo> documentation for possible arguments.
B<Defaults to>: default L<WWW::WebDevout::BrowserSupportInfo> constructor.

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
        'who' => 'Zoffix__!n=Zoffix@unaffiliated/zoffix',
        'what' => 'html',
        'uri_info' => 'http://www.webdevout.net/browser-support-html#support-html401',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'SupportBot, support html',
        'results' => {
            'SF2' => '?',
            'FX1_5' => '91.741%',
            'FX2' => '91.741%',
            'IE6' => '80.211%',
            'IE7' => '80.802%',
            'OP8' => '85.822%',
            'OP9' => '86.361%',
            'KN3_5' => '?'
        }
    };


The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_webdevout_support>) will receive input
every time request is completed. The input will come in C<$_[ARG0]> in
a form of a hashref.
The keys/value of that hashref are as follows:

=head3 results

    'results' => {
        'SF2' => '?',
        'FX1_5' => '91.741%',
        'FX2' => '91.741%',
        'IE6' => '80.211%',
        'IE7' => '80.802%',
        'OP8' => '85.822%',
        'OP9' => '86.361%',
        'KN3_5' => '?'
    }

Unless an error occurred (including "No results" errors) the C<results>
key will be present. Its value will be a hashref with keys being the
browsers and values being the support information. By default, the names
of browsers will be short. If you want long ones pass
C<obj_args => { long => 1 }> into the constructor, see
L<WWW::WebDevout::BrowserSupportInfo> for more information.

=head3 error

    { 'error' => 'No results' }

If a network error occurred or no results were found the C<error> key
will be present and the value of it will be the description of the error.

=head3 uri_info

    { 'uri_info' => 'http://www.webdevout.net/browser-support-html#support-html401' }

The C<uri_info> key will contain the link pointing to
L<http://webdevout.net> to the location where more information about the
term being looked up can be found.

=head3 what

    { 'what' => 'html' }

The C<what> key will contain the term which was looked up.

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

    { 'message' => 'SupportBot, support html' }

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
