package POE::Component::IRC::Plugin::WWW::GetPageTitle;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
use POE::Component::WWW::GetPageTitle;
use URI::Find::Schemeless;
use URI;

sub _make_default_args {
    return (
        response_event   => 'irc_get_page_title',
        trigger          => qr/^title\s+(?=\S)/i,
    );
}

sub _make_poco {
    my $self = shift;
    return POE::Component::WWW::GetPageTitle->spawn(
        $self->{ua} ? ( ua => $self->{ua} ) : ()
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;
    defined $in_ref->{title}
        and $in_ref->{title} =~ s/\s/ /g;

    return [
        exists $in_ref->{error}
        ? $in_ref->{error}
        : '[' . URI->new(
            $in_ref->{page} =~ m|^https?://|i ? $in_ref->{page} : "http://$in_ref->{page}"
        )->authority . '] ' . $in_ref->{title}
    ];
}

sub _make_response_event {
    my $self = shift;
    my $in_ref = shift;

    return {
        ( exists $in_ref->{error}
            ? ( error => $in_ref->{error} )
            : (
                title => '[' . URI->new(
                    $in_ref->{page} =~ m|^https?://|i ? $in_ref->{page}
                    : "http://$in_ref->{page}"
                )->authority . '] ' . $in_ref->{title}
            )
        ),

        map { $_ => $in_ref->{"_$_"} }
            qw( who channel  message  type  what ),
    }
}

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    if ( $self->{find_uris} ) {
        $self->{finder} = [];
        my $finder = URI::Find::Schemeless->new( sub { $self->_uri_callback(shift) } );
        $finder->find( \ $data_ref->{what} );
    }
    else {
        $self->{finder} = [ $data_ref->{what} ];
    }

    if ( $self->{max_uris} ) {
        @{ $self->{finder} } = splice @{ $self->{finder} }, 0, $self->{max_uris};
    }

    if ( $self->{debug} ) {
        print "Going to fetch titles for the following URIs:\n",
            join "\n", @{ $self->{finder} }, '';
    }

    @{ $self->{finder} } = grep !/^ftp/i, @{ $self->{finder} };

    for ( @{ $self->{finder} } ) {
        $self->{poco}->get_title( {
                event       => '_poco_done',
                page        => $_,
                map +( "_$_" => $data_ref->{$_} ),
                    keys %$data_ref,
            }
        );
    }
}

sub _uri_callback {
    my ( $self, $uri ) = @_;
    push @{ $self->{finder} }, $uri;
    $uri;
}

1;
__END__

=encoding utf8

=for stopwords bot dumbasses privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::WWW::GetPageTitle - web page title fetching IRC plugin

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::WWW::GetPageTitle);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'TitleBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'TitleBot',
        plugin_debug => 1,
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
            'get_page_title' =>
                POE::Component::IRC::Plugin::WWW::GetPageTitle->new(
                    max_uris  => 2,
                    find_uris => 1,
                    addressed => 0,
                    trigger   => qr/^/,
                ),
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix> TitleBot, title google.ca
    <TitleBot> [google.ca] Google

    <Zoffix> google.ca zoffix.com
    <TitleBot> [google.ca] Google
    <TitleBot> [zoffix.com] Home - Zoffix Znet Portal

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
to fetch titles of the URIs that are either given to the bot directly or (upon configuration)
simply appear in the channel.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'get_page_title' => POE::Component::IRC::Plugin::WWW::GetPageTitle->new
    );

    # juicy flavor
    $irc->plugin_add(
        'get_page_title' =>
            POE::Component::IRC::Plugin::WWW::GetPageTitle->new(
                auto             => 1,
                response_event   => 'irc_get_page_title',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^title\s+(?=\S)/i,
                triggers         => {
                    public  => qr/^title\s+(?=\S)/i,
                    notice  => qr/^title\s+(?=\S)/i,
                    privmsg => qr/^title\s+(?=\S)/i,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::WWW::GetPageTitle> object suitable to be
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
B<Note:> this option does not make the plugin automatically fetch titles for every URI that
appears in the channel, see C<find_uris> argument below.
B<Defaults to:> C<1>.

=head3 C<find_uris>

    ->new( find_uris => 1 );

B<Optional>. When set to a true value will make the plugin automatically find all the URIs in
the given text. B<By default> set to a false value.
If you wish the plugin to fetch titles for all the URIs that appear in the
channel use the following options:

    ->new(
        find_uris => 1,
        addressed => 0,
        trigger   => qr/^/,
    );

Note: regex C<qr//> is special and won't cut it for "anything" as a trigger.

=head3 C<max_uris>

    ->new( max_uris => 2 );

B<Optional>. Generally you'll use this one along with C<find_uris> argument. Specifies how
many URIs from a single given input it should fetch. Use this option to avoid dumbasses abusing
the bot. Setting this argument to zero means "no limit".
B<By default> is not specified (no limit).

=head3 C<response_event>

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_get_page_title>

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

    ->new( trigger => qr/^title\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex, irrelevant of the type of the message, will be considered as requests. See also
B<addressed> option below which is enabled by default as well as
B<triggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^title\s+(?=\S)/i>

=head3 C<triggers>

    ->new( triggers => {
            public  => qr/^title\s+(?=\S)/i,
            notice  => qr/^title\s+(?=\S)/i,
            privmsg => qr/^title\s+(?=\S)/i,
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
B<Defaults to:> C<qr/^title\s+(?=\S)/i>

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
        'title' => '[google.ca] Google',
        'what' => 'http://zoffix.com/css/center http://google.ca/ http://microsoft.com/',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'http://zoffix.com/css/center google.ca microsoft.com'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_get_page_title>) will receive input
every time request is completed. Note that when C<find_uris> option is turned on there
may be several events generated (one for each URI found).
The input will come in C<$_[ARG0]> on a form of a hashref.
The possible keys/values of that hashrefs are as follows:

=head3 C<title>

    { 'title' => '[google.ca] Google', }

The C<title> key will contain the "authority" section of the original URI and the title
of the page, this is what the plugin reports to the channel/person when C<auto> argument
is turned on. B<Note:> anything in the title of that page that matches C<\s> will be replaced
by a space character.

=head3 C<who>

    { 'who' => 'Zoffix!Zoffix@i.love.debian.org', }

The C<who> key will contain the user mask of the user who sent the request.

=head3 C<what>

    { 'what' => 'http://zoffix.com/css/center http://google.ca/ http://microsoft.com/', }

The C<what> key will contain user's message after stripping the C<trigger> except when
C<find_uris> is turned on; in that case the URIs in original message will also be properly
reformed.
(see CONSTRUCTOR).

=head3 C<message>

    { 'message' => 'http://zoffix.com/css/center google.ca microsoft.com' }

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

=head1 EXAMPLES

The C<examples/> directory of this distribution contains an example IRC bot that reports titles
for all the URIs that appear in the channel.

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

