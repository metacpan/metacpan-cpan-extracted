package POE::Component::IRC::Plugin::Google::PageRank;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use Carp;
use POE qw(Component::WWW::Google::PageRank);
use POE::Component::IRC::Plugin qw(:ALL);

sub new {
    my $package = shift;
    croak "Even number of arguments must be specified"
        if @_ & 1;
    my %args = @_;
    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    # fill in the defaults
    %args = (
        debug            => 0,
        auto             => 1,
        response_event   => 'irc_google_pagerank',
        banned           => [],
        addressed        => 1,
        eat              => 1,
        trigger          => qr/^rank\s+(?=\S)/i,
        listen_for_input => [ qw(public notice privmsg) ],

        %args,
    );

    $args{listen_for_input} = {
        map { $_ => 1 } @{ $args{listen_for_input} || [] }
    };

    return bless \%args, $package;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{_session_id} = $_[SESSION]->ID();
    $kernel->refcount_increment( $self->{_session_id}, __PACKAGE__ );

    $self->{poco} = POE::Component::WWW::Google::PageRank->spawn(
        debug => $self->{debug},
    );

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
                    _rank_done
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
        unless defined $what and $what =~ s/$self->{trigger}//;

    $what =~ s/^\s+|\s+$//;

    return PCI_EAT_NONE
            unless defined $message;

    warn "Matched trigger: [ who => $who, channel => $channel, "
            . "what => $what ]"
        if $self->{debug};

    foreach my $ban_re ( @{ $self->{banned} || [] } ) {
        return PCI_EAT_NONE
            if $who =~ /$ban_re/;
    }

    $self->{poco}->rank( {
            session     => $self->{_session_id},
            event       => '_rank_done',
            page        => $what,
            _who        => $who,
            _channel    => $channel,
            _message    => $message,
            _type       => $type,
        }
    );

    return $self->{eat} ? PCI_EAT_ALL : PCI_EAT_NONE;
}

sub _rank_done {
    my ( $kernel, $self, $in_ref ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $response_message;

    if ( exists $in_ref->{error} ) {
        $response_message = defined $in_ref->{error}
                          ? "Error: $in_ref->{error}"
                          : "Error: unknown";
    }
    else {
        $in_ref->{rank} ||= 'not available';
        $response_message = "Rank is $in_ref->{rank}";
    }

    $self->{irc}->send_event( $self->{response_event} => {
            result => $response_message,
            page   => $in_ref->{page},
            map { $_ => $in_ref->{"_$_"} }
                qw( who channel  message  type ),
        }
    );

    if ( $self->{auto} ) {
        my $response_type = $in_ref->{_type} eq 'public'
                        ? 'privmsg'
                        : $in_ref->{_type};

        my $where = $in_ref->{_type} eq 'public'
                ? $in_ref->{_channel}
                : (split /!/, $in_ref->{_who})[0];

        $kernel->post( $self->{irc} =>
            $response_type =>
            $where =>
            $response_message
        );
    }

    undef;
}

1;

__END__

=encoding utf8

=for stopwords bot  pagerank privmsg requestor usermask

=head1 NAME

POE::Component::IRC::Plugin::Google::PageRank - non-blocking access
to Google's PageRank via IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::Google::PageRank);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'RankBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'Google PageRank Bot',
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
            'GoogleRank' =>
                POE::Component::IRC::Plugin::Google::PageRank->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }


    [22:37:04] <Zoffix> RankBot, rank zoffix.com
    [22:37:05] <RankBot> Rank is 4
    [22:37:09] <Zoffix> RankBot, rank google.com
    [22:37:10] <RankBot> Rank is 10

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides access to
Google PageRank
from IRC.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'GoogleRank' => POE::Component::IRC::Plugin::Google::PageRank->new
    );

    # juicy flavor
    $irc->plugin_add(
        'GoogleRank' =>
            POE::Component::IRC::Plugin::Google::PageRank->new(
                auto             => 1,
                response_event   => 'irc_google_pagerank',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                trigger          => qr/^rank\s+(?=\S)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::Google::PageRank> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. The possible
arguments/values are as follows:

=head3 auto

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to pagerank requests. When the C<auto>
argument is set to a true value plugin will respond to the person requesting
pagerank with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emitted by the plugin to retrieve the results (see
EMITTED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 response_event

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of pagerank are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_google_pagerank>

=head3 banned

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) requesting the pagerank matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 trigger

    ->new( trigger => qr/^rank\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests for pagerank. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the URI of the page for which pagerank is needed.
B<Defaults to:> C<qr/^rank\s+(?=\S)/i>

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<RankBot> and your trigger is C<qr/^rank/>
you would request the pagerank by saying
C<RankBot, rank http://zoffix.com>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to request pagerank. Note: this argument has no effect on
C</notice> and C</msg> pagerank requests. B<Defaults to:> C<1>

=head3 listen_for_input

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to pagerank
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to pagerank requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable pagerank requests only via C</notice> and C</msg> messages.
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
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'page' => 'http://haslayout.net',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'RankBot, rank haslayout.net',
        'result' => 'Rank is 4'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_google_pagerank>) will receive input
every time pagerank request is completed. The input will come in the form
of a hashref in C<ARG0>. The keys/values of that hashref are as follows:

=head3 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The C<who> key will contain the usermask of the user who requested the
pagerank.

=head3

    { 'type' => 'public' }

The C<type> key will contain the "type" of the message sent by the
requestor. The possible values are: C<public>, C<notice> and C<privmsg>
indicating that request was requested in public channel, via C</notice>
and via C</msg> (private message) respectively.

=head3 channel

    { 'channel' => '#zofbot' }

The C<channel> key will contain the name of the channel from which the
request
came from. This will only make sense when C<type> key (see above) contains
C<public>.

=head3 message

    { 'message' => 'RankBot, rank haslayout.net' }

The C<message> key will contain the message which the user has
sent to request the pagerank.

=head3 page

    { 'page' => 'http://haslayout.net', }

The C<page> key will contain the page for which the pagerank was
requested.

=head3 result

    { 'result' => 'Rank is 4' }

The C<result> key will contain the pagerank of the specified page, in other
words what you'd see the plugin say when C<auto> (see constructor arguments)
is turned on (that's the default). Note: the successful results will
begin with C<Rank is> and if an error occurred during the request, or
no result was returned the C<result>'s value will begin with C<Error:>.

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