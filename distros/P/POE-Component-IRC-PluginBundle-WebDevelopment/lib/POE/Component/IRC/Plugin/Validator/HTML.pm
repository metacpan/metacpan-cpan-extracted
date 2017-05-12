package POE::Component::IRC::Plugin::Validator::HTML;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use POE::Component::WebService::Validator::HTML::W3C;
use base 'POE::Component::IRC::Plugin::BasePoCoWrap';

sub _make_default_args {
    return (
        response_event   => 'irc_validator_html',
        trigger          => qr/^validate\s+(?=\S)/i,
    );
}

sub _make_poco {
    return POE::Component::WebService::Validator::HTML::W3C->spawn(
        debug => shift->{debug},
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;
    return [ $self->_construct_response($in_ref) ];
}

sub _make_response_event {
    my $self = shift;
    my $in_ref = { %{ shift || {} } };

    $in_ref->{uri_to_results}
    = $self->_construct_response( $in_ref, 'just_uri_kplz_and_thank_you' );

    $in_ref->{ $_ } = delete $in_ref->{"_$_"}
        for qw( who channel  message  type );

    return $in_ref;
}

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    $self->{poco}->validate( {
            event       => '_poco_done',
            in          => delete $data_ref->{what},
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}

sub _construct_response {
    my ( $self, $in_ref, $is_only_uri ) = @_;

    my $uri = URI->new( $in_ref->{validator_uri} );
    $uri->query_form(
        uri => $in_ref->{in},
        doctype => 'Inline',
        group   => '0',
        No200   => 1,
        verbose => 1,
    );

    if ( $is_only_uri ) {
        return $uri;
    }
    elsif ( not $in_ref->{num_errors} ) {
        return "Valid ( $uri )";
    }
    else {
        return "Invalid ($in_ref->{num_errors} errors) See: $uri";
    }
}

1;

__END__

=encoding utf8

=for stopwords bot privmsg regexen requestor usermask usermasks validator

=head1 NAME

POE::Component::IRC::Plugin::Validator::HTML - access HTML validator
from IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::Validator::HTML);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'ValidatorBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'Validator Bot',
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
            'ValidatorHTML' =>
                POE::Component::IRC::Plugin::Validator::HTML->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix> ValidatorBot, validate http://zoffix.com
    <ValidatorBot> Valid ( http://validator.w3.org/check?uri=http%3A%2F%2Fzoffix.com&doctype=Inline&group=0&No200=1&verbose=1 )
    <Zoffix> ValidatorBot, validate http://google.ca
    <ValidatorBot> Invalid (49 errors) See: http://validator.w3.org/check?uri=http%3A%2F%2Fgoogle.ca&doctype=Inline&group=0&No200=1&verbose=1

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
W3C HTML validator.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'ValidatorHTML' => POE::Component::IRC::Plugin::Validator::HTML->new
    );

    # juicy flavor
    $irc->plugin_add(
        'ValidatorHTML' =>
            POE::Component::IRC::Plugin::Validator::HTML->new(
                auto             => 1,
                response_event   => 'irc_validator_html',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                trigger          => qr/^validate\s+(?=\S)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::Validator::HTML> object suitable to be
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
section for more information. B<Defaults to:> C<irc_validator_html>

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

    ->new( trigger => qr/^validate\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^validate\s+(?=\S)/i>

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying
C<Nick, trig validate http://zoffix.com>.
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
          'errors' => [
                        {
                                 'msg' => 'no document type declaration; implying "<!DOCTYPE HTML SYSTEM>"',
                                 'col' => '0',
                                 'line' => '1'
                          },
                        # and more and more of these
          ],
          'in' => 'http://google.ca',
          'num_errors' => '46',
          'validator_uri' => 'http://validator.w3.org/check',
          'type' => 'uri',
          'is_valid' => 0,
          'uri_to_results' => bless( do{\(my $o = 'http://validator.w3.org/check?uri=http%3A%2F%2Fgoogle.ca&doctype=Inline&group=0&No200=1&verbose=1')}, 'URI::http' ),
          'channel' => '#zofbot',
          'type' => 'public',
          'who' => 'Zoffix__!n=Zoffix@unaffiliated/zoffix',
          'message' => 'ValidatorBot, validate http://zoffix.com',
        };


    $VAR1 = {
          'options' => {
                         'http_timeout' => 2,
                         'validator_uri' => 'http://somewhereesle.com'
                       },
          '_user_defined' => 'something',
          'in' => 'http://zoffix.com',
          'validator_error' => 'Could not contact validator',
          'type' => 'uri',
          'validator_uri' => 'http://somewhereesle.com'
          'uri_to_results' => bless( do{\(my $o = 'http://http://somewhereesle.com/?uri=http%3A%2F%2Fgoogle.ca&doctype=Inline&group=0&No200=1&verbose=1')}, 'URI::http' ),
          'channel' => '#zofbot',
          'type' => 'public',
          'who' => 'Zoffix__!n=Zoffix@unaffiliated/zoffix',
          'message' => 'ValidatorBot, validate http://zoffix.com',
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_validator_html>) will receive input
every time validation request is completed. The input will come in
in C<$_[ARG0]> in a form of a hashref.
The the keys are the B<same as the return of>
L<POE::Component::WebService::Validator::HTML::W3C> C<validate()>
method/event B<with additional> keys which are as follows:

=head3 uri_to_results

'uri_to_results' => bless( do{\(my $o = 'http://validator.w3.org/check?uri=http%3A%2F%2Fgoogle.ca&doctype=Inline&group=0&No200=1&verbose=1')}, 'URI::http' ),

Will contain a L<URI> object pointing to the results of validation.

=head3 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The C<who> key will contain the usermask of the user who requested
validation.

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

    { 'message' => 'ValidatorBot, validate http://zoffix.com' }

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

