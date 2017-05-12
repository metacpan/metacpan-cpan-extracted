package POE::Component::IRC::Plugin::Thanks;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Carp;
use POE::Component::IRC::Plugin qw( :ALL );

sub new {
    my $package = shift;
    croak "Must have even number of arguments to constructor"
        if @_ & 1;

    my %args = @_;

    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    # fill in defaults
    %args = (
        trigger => qr/ ^ (?:thank s? (?: \s* you )? | th?a?nx | thx | tyvm )/xi,
        respond => 1,
        thanks_event => 'thanks_response',

        %args,
    );
    my $self = bless \%args, $package;

    unless ( $self->{messages} ) {
        $self->{messages} = $self->_make_default_messages;
    }

    push @{ $self->{messages} }, @{ $self->{extra_messages} || [] };

    return $self;
}

sub PCI_register {
    my ( $self, $irc ) = splice @_, 0, 2;

    $irc->plugin_register( $self, 'SERVER', qw(public) );
    return 1;
}

sub PCI_unregister {
    return 1;
}

sub S_public {
    my ( $self, $irc ) = splice @_, 0, 2;
    my $who = ${ $_[0] };
    my $nick = ( split /!/, $who )[0];
    my $channel = ${ $_[1] }->[0];
    my $what = ${ $_[2] };
    my $mynick = $irc->nick_name();

    foreach my $ban_re ( @{ $self->{bans} || [] } ) {
        return PCI_EAT_NONE
            if $who =~ /$ban_re/;
    }

    my ( $message ) = $what =~ /^\s*\Q$mynick\E[:,;.~]?\s*(.*)$/i;
    return PCI_EAT_NONE
        unless defined $message and $message =~ $self->{trigger};

    my $thanks_response = $self->_make_thanks_response;
    $irc->yield( privmsg => $channel => "$nick, $thanks_response" )
        if $self->{respond};

    $irc->_send_event( $self->{thanks_event} => {
            who      => $who,
            channel  => $channel,
            what     => $what,
            response => $thanks_response,
        }
    );

    return $self->{eat} ? PCI_EAT_ALL : PCI_EAT_NONE;
}

sub _make_thanks_response {
    my $self = shift;
    my @messages = @{ $self->{messages} || [] };
    return $messages[ rand @messages ];
}

sub _make_default_messages {
    return  [
         q|You are welcome!|,
         q|That will be $50... CASH!|,
         q|yeah, yeah, that's what you all say...|,
         q|No problema :)|,
         q|can you help _me_ now?|,
         q|FYI, thanking the bot says a lot about your mental state!|,
         q|It's ok, I'm just a bot, no need for "thank you"s.|,
         q|No, no, thank YOU|,
     ],
}

1;

__END__

=for stopwords bot

=encoding utf8

=pod

=head1 NAME

POE::Component::IRC::Plugin::Thanks - make witty responses to "thank you"s

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::Thanks);

    my $irc = POE::Component::IRC->spawn(
            nick    => 'ThankBot',
            server  => 'irc.freenode.net',
            port    => 6667,
            ircname => 'Silly Thankie bot',
    ) or die "Oh noes :( $!";

    POE::Session->create(
        package_states => [
            main => [ qw( _start irc_001 ) ],
        ],
    );

    $poe_kernel->run();

    sub _start {
        $irc->yield( register => 'all' );

        # register our plugin
        $irc->plugin_add( 'Thanks' => POE::Component::IRC::Plugin::Thanks->new );

        $irc->yield( connect => { } );
        undef;
    }

    sub irc_001 {
        my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
        $kernel->post( $sender => join => '#zofbot' )
        undef;
    }

=head1 CONSTRUCTOR

    # vanilla plugin
    $irc->plugin_add( 'Thanks' => POE::Component::IRC::Plugin::Thanks->new );

    # juicy flavor
    $irc->plugin_add(
        'Thanks' => POE::Component::IRC::Plugin::Thanks->new(
            trigger => qr/^\s*(?:thanks|thank you)/i,
            respond => 1,
            thanks_event => 'thanks_response',
            messages => [       # discard default messages and use these
                'response 1',
                'response 2',
            ],
            extra_messages => [ # add these to the default messages
                'response 1',
                'response 2',
            ],
            bans => [ qr/^Spammer/i, qr/spam[.]net$/i ],
        )
    );

The constructor returns a L<POE::Component::IRC::Plugin> object suitable
for consumption by L<POE::Component::IRC> C<plugin_add()> method.  It takes
a few arguments but I<all of them are optional>. The possible arguments are:

=head2 trigger

    ->new( trigger => qr/^\s*(?:thanks|thank you)/i );

Takes a regex as an argument. Specifies what messages to consider to be
"thank you" messages. In other words, messages that match C<trigger>
will generate a random "thank you" response from this plugin.
B<Defaults to:> C<qr/ ^ (?:thank s? (?: \s* you )? | th?a?nx | thx | tyvm )/xi>

=head2 respond

    ->new( respond => 0 );

The C<respond> argument controls whether or not the plugin should auto
respond to the person thanking us. If set to a I<false> value plugin
will not auto respond and only the C<thanks_event> (see below) will be sent out.
If set to a true value plugin will respond to the person I<and> send the event.

=head2 thanks_event

    ->new( thanks_event => 'thanks_response' );

Whenever the bot is addressed and the message matches the C<trigger> (see above)
the plugin will send out the event specified by C<thanks_event>. See
EMITTED EVENTS section below for more information.

=head2 messages

    ->new(
           messages => [
                'response 1',
                'response 2',
            ],
    );

Plugin has a set of predefined "thank you" responses which are listed in
the DEFAULT RESPONSES section below. If you wish, you can specify your
own set using the C<messages> argument which I<takes an arrayref> of messages.
B<Defaults to:> the responses listed in the DEFAULT RESPONSES section below.

=head2 extra_messages

    ->new(
            extra_messages => [ # add these to the default messages
                'response 1',
                'response 2',
            ],
    );

The same as C<messages> argument (see above) I<except> the messages listed
in C<extra_messages> will be I<appended> to messages listed in C<messages>
argument. In other words, if you want to add a few responses to the
default responses you don't have to redefine every default response in
C<messages> argument, but instead just list your extra messages in
C<extra_messages> argument. B<Default to:> nothing (obviously).

=head2 bans

    ->new( bans => [ qr/^Spammer/i, qr/spam[.]net$/i ] );

The C<bans> key I<takes an arrayref> as an argument with regex objects
as elements of that arrayref. If plugin receives input from a user who's
mask matches any of the regexes specified in C<bans> key, plugin will ignore
that user. B<Defaults to:> empty, no bans are set.

=head2 eat

    ->new( eat => 0 );

If set to a I<false> value plugin will return a C<PCI_EAT_NONE>
after responding
with a "thank you" message. If C<eat> is set to a I<true> value, plugin will
return a C<PCI_EAT_ALL> after responding with a "thank you" message.
See L<POE::Component::IRC::Plugin> documentation for more information if
you are interested.
B<Defaults to:> C<1>

=head1 DEFAULT RESPONSES

The plugin has a set of defined "thank you" responses, which are what is the
default of C<messages> argument of the constructor. See C<messages> and
C<extra_messages> arguments to the constructor if you wish to change the
default responses in any way. I am B<very> open to new additions
of messages to the default list, feel free to suggest some witty responses.
The following arrayref is the default value
of C<messages> argument if the constructor:

    [
         q|You are welcome!|,
         q|That will be $50... CASH!|,
         q|yeah, yeah, that's what you all say...|,
         q|No problema :)|,
         q|can you help _me_ now?|,
         q|FYI, thanking the bot says a lot about your mental state!|,
         q|It's ok, I'm just a bot, no need for "thank you"s.|,
         q|No, no, thank YOU|,
    ]

=head1 EMITTED EVENTS

Whenever the plugin responds with a "thank you" response. The plugin emits an
event, name of which is specified by the <thanks_event>
argument to the constructor.

By setting C<respond> in the constructor to a false value you may generate
responses yourself whenever you receive the C<thanks_event>.

The event handler which is handling this event
will receive a hashref in its C<ARG0> argument. The hashref will have the
following keys/values:

    {
        who => 'Zoffix!zoffix@unaffiliated/zoffix',
        channel => '#zofbot',
        what => '_ZofBot, thanks!',
        response => 'No, no, thank YOU'
    }

=head2 who

    { who => 'Zoffix!zoffix@unaffiliated/zoffix' }

The mask of the person who thanked us.

=head2 channel

    { channel => '#zofbot' }

The channel where the message originated.

=head2 what

    { what => '_ZofBot, thanks!' }

The content of the message.

=head2 response

    { response => 'No, no, thank YOU' }

The randomly generated "thank you" response.

=cut

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