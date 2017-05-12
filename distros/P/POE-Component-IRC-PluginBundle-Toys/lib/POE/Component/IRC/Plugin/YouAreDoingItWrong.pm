package POE::Component::IRC::Plugin::YouAreDoingItWrong;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use POE qw(Component::WWW::DoingItWrongCom::RandImage);
use POE::Component::IRC::Plugin qw(:ALL);

sub new {
    my $package = shift;
    my %args = @_;
    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    # fill in the defaults
    %args = (
        debug          => 0,
        auto           => 1,
        trigger        => qr/^doing it wrong/i,
        banned         => [],
        response_event => 'irc_you_are_doing_it_wrong_response',

        %args,
    );

    return bless \%args, $package;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{_session_id} = $_[SESSION]->ID();
    $kernel->refcount_increment( $self->{_session_id}, __PACKAGE__ );

    $self->{poco} = POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        debug => $self->{debug},
    );

    undef;
}

sub PCI_register {
    my ( $self, $irc ) = splice @_, 0, 2;

    $self->{irc} = $irc;

    $irc->plugin_register( $self, 'SERVER', qw(public) );

    $self->{_session_id} = POE::Session->create(
        object_states => [
            $self => [
                qw(
                    _start
                    _shutdown
                    _pic
                    _get_pic
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

    foreach my $ban_re ( @{ $self->{banned} || [] } ) {
        return PCI_EAT_NONE
            if $who =~ /$ban_re/;
    }

    my $my_nick = $irc->nick_name();
    my ($what) = $message =~ m/^\s*\Q$my_nick\E[\:\,\;\.]?\s*(.*)$/i;

    return PCI_EAT_NONE
         if !defined $what or !($what =~ s/$self->{trigger}//);

    my ( $nick_to_address ) = $what =~ /(\S+)\s*$/;

    warn "Got PUBLIC input: [ who => $who, channel => $channel, "
            . "what => $what ]"
        if $self->{debug};
    $poe_kernel->post( $self->{_session_id} => _get_pic => {
            _what            => $message,
            _who             => $who,
            _channel         => $channel,
            _nick_to_address => $nick_to_address,
        }
    );

    return $self->{eat} ? PCI_EAT_ALL : PCI_EAT_NONE;
}

sub _get_pic {
    $_[OBJECT]->{poco}->fetch( {
            event            => '_pic',
            %{ $_[ARG0] },
        },
    );
}

sub _pic {
    my ( $kernel, $self, $result ) = @_[ KERNEL, OBJECT, ARG0 ];
    my $message;
    if ( $result->{error} ) {
        $message = "Error: $result->{error}";
    }
    else {
        $message = "You are doing it wrong: $result->{out}";
    }

    $self->{irc}->send_event(
        $self->{response_event} => {
            pic   => $result->{out},
            error => $result->{error},
            map { $_ => $result->{"_$_"} }
                qw(who what channel nick_to_address)
        }
    );

    if ( $self->{auto} ) {
        if ( defined $result->{_nick_to_address} ) {
            $message = "$result->{_nick_to_address}, \l$message";
        }

        $kernel->post(
            $self->{irc} => privmsg => $result->{_channel} => $message
        );
    }

    undef;
}

1;

__END__

=for stopwords bot pic

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::YouAreDoingItWrong - show people what they
are doing wrong by giving links to http://doingitwrong.com images.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC Component::IRC::Plugin::YouAreDoingItWrong);

    my $irc = POE::Component::IRC->spawn(
            nick    => 'WrongBot',
            server  => 'irc.freenode.net',
            port    => 6667,
            ircname => 'You Are Doing It Wrong Bot',
    ) or die "Oh noes :( $!";

    POE::Session->create(
        package_states => [
            main => [ qw( _start  irc_001 ) ],
        ],
    );

    $poe_kernel->run();

    sub _start {
        $irc->yield( register => 'all' );

        # register our plugin
        $irc->plugin_add(
            'Wrong' => POE::Component::IRC::Plugin::YouAreDoingItWrong->new
        );

        $irc->yield( connect => { } );
        undef;
    }

    sub irc_001 {
        my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
        $kernel->post( $sender => join => '#zofbot' );

        undef;
    }

    --

    [13:00:27] <Zoffix> WrongBot, doing it wrong Zoffix
    [13:00:27] <WrongBot> Zoffix, you are doing it wrong: http://www.doingitwrong.com/wrong/20070527-113353.jpg
    [13:00:41] <Zoffix> WrongBot, doing it wrong
    [13:00:42] <WrongBot> You are doing it wrong: http://www.doingitwrong.com/wrong/1487_kolo.jpg

=head1 DESCRIPTION

The module is a L<POE::Component::IRC> plugin which, when triggered,
fetches links to images from L<http://doingitwrong.com> and posts them
into the channel, optionally addressing a specific person.

=head1 CONSTRUCTOR

=head2 new

    $irc->plugin_add(
        'Wrong' => POE::Component::IRC::Plugin::YouAreDoingItWrong->new
    );

    $irc->plugin_add(
        'Wrong' => POE::Component::IRC::Plugin::YouAreDoingItWrong->new(
            auto           => 0,                 # do not auto respond
            trigger        => qr/^wrong/i,       # trigger
            banned         => [ qr/aol\.com$/ ], # ignore AOL users
            response_event => 'diw_event',       # event to send response to
            debug          => 1,                 # enable some debug output
        )
    );

Returns a L<POE::Component::IRC::Plugin> object suitable to be fed to
L<POE::Component::IRC> C<plugin_add()> method. Takes a few arguments,
I<all of which are optional>. The arguments may be as follows:

=head3 auto

    ->new( auto => 1 );

B<Optional>. The C<auto> argument specifies whether or not the plugin
should auto respond with C<privmsg> to the channel when triggered. If
C<auto> is set to a true value the plugin will automatically respond
when triggered, when C<auto> is set to a false value the plugin will
not send any messages to the server and you'll have to listen to the
event emitted by the plugin (see below). In
other words, if you are unhappy with the default behaviour you may
turn C<auto> off (by setting it to a false value) and set up a handler
on the plugin event to do exactly what you want. B<Defaults to:> C<1>


=head3 trigger

    ->new( trigger => qr/^doing it wrong/i );

B<Optional>. Takes a regex as an argument which specifies the
trigger for the plugin. B<Defaults to:> C<qr/^doing it wrong/i>
B<Note:> plugin responds to I<addressed> messages,
In other words, if you set the trigger to C<qr/^diw/i> and your
bot's nick name is C<WrongBot> the plugin will be triggered by saying
C<WrongBot, diw>. B<Note 2:> if after removing bot's nickname and the
trigger the left over will match C<m/(\S+)\s*$/> the capture will be
prepended to the output, this is so you could address a specific person:

    [13:00:27] <Zoffix> WrongBot, doing it wrong Zoffix
    [13:00:27] <WrongBot> Zoffix, you are doing it wrong: http://www.doingitwrong.com/wrong/20070527-113353.jpg
    [13:00:41] <Zoffix> WrongBot, doing it wrong
    [13:00:42] <WrongBot> You are doing it wrong: http://www.doingitwrong.com/wrong/1487_kolo.jpg

=head3 banned

    ->new( banned => [ qr/aol\.com$/ ] );

B<Optional>. Takes an arrayref of regexes as an argument. If the user mask
of the person who triggered the plugin matches any of the regexes in
the C<banned> arrayref the plugin will ignore that person. B<Defaults to:>
C<[]> (no bans are set)

=head3 response_event

    ->new( response_event => 'diw_event' );

B<Optional>. Specifies the name of the event to emit when plugin is
triggered. See EMITTED EVENTS section for details. B<Defaults to:>
C<irc_you_are_doing_it_wrong_response>

=head3 debug

    ->new( debug => 1 );

B<Optional>. When set to a true value plugin will print out a bit of
debug information. B<Defaults to:> C<0> (no debug info is printed out)

=head3 eat

    ->new( eat => 0 );

If set to a false value plugin will return a C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to:>
C<1>

=head1 EMITTED EVENTS

=head2 response_event

    $VAR1 = {
        'what' => 'WrongBot, doing it wrong',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'channel' => '#zofbot',
        'nick_to_address' => undef,
        'error' => undef,
        'pic' => bless( do{\(my $o = 'http://www.doingitwrong.com/wrong/20070929-012129.jpg')}, 'URI::http' )
    };

The event handler set up to handle the event, name of which you
can specify in the C<response_event> of the constructor (it defaults to
C<irc_you_are_doing_it_wrong_response>) will receive input from the
plugin every time it's triggered. The input will come in the form
of a hashref in C<ARG0>. The keys of that hashref are as follows:

=head3 what

    { 'what' => 'WrongBot, doing it wrong' }

The C<what> key will contain the message which triggered the plugin.

=head3 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The C<who> key will contain the mask of the user who triggered the plugin.

=head3 nick_to_address

    { 'nick_to_address' => undef }

The C<nick_to_address> key will contain the nick of the person to address
if the plugin was triggered in the "address someone" mode
(see description of the C<trigger> argument to the constructor) or C<undef>
if plugin was triggered in normal mode.

=head3 error

    { error => undef }

If an error occurred during while fetching the link to a random image
on L<http://doingitwrong.com> the C<error> key will contain the error
message, otherwise it will be C<undef>.

=head3 pic

    { 'pic' => bless( do{\(my $o = 'http://www.doingitwrong.com/wrong/20070929-012129.jpg')}, 'URI::http' ) }

If no errors occurred (see C<error> above), the C<pic> key will contain
a L<URI> object pointing to one of the images on
L<http://www.doingitwrong.com>.

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
