package POE::Component::IRC::Plugin::WWW::XKCD::AsText;

use warnings;
use strict;

our $VERSION = '0.003';

use Carp;
use POE qw(Component::WWW::XKCD::AsText);
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
        response_event   => 'irc_xkcd',
        banned           => [],
        addressed        => 1,
        eat              => 1,
        trigger          => qr/^xkcd\s+(?=\S)/i,
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

    $self->{poco} = POE::Component::WWW::XKCD::AsText->spawn(
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
                    _xkcd_done
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
            unless length $what and $what !~ /\D/;

    warn "Matched trigger: [ who => $who, channel => $channel, "
            . "what => $what ]"
        if $self->{debug};

    foreach my $ban_re ( @{ $self->{banned} || [] } ) {
        return PCI_EAT_NONE
            if $who =~ /$ban_re/;
    }

    $self->{poco}->retrieve( {
            session     => $self->{_session_id},
            event       => '_xkcd_done',
            id          => $what,
            _who        => $who,
            _channel    => $channel,
            _message    => $message,
            _type       => $type,
        }
    );

    return $self->{eat} ? PCI_EAT_ALL : PCI_EAT_NONE;
}

sub _xkcd_done {
    my ( $kernel, $self, $in_ref ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $response_message;

    if ( exists $in_ref->{error} ) {
        $response_message = [ $in_ref->{error} ];
    }
    else {
        $response_message = $in_ref->{text};
        $response_message =~ s/\n\s*\n/\n \n/g;
        $response_message = [ split /\n/, $response_message ];
    }

    $self->{irc}->send_event( $self->{response_event} => {
            text => $in_ref->{text},
            id   => $in_ref->{id},
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

        for ( @$response_message ) {
            $kernel->post( $self->{irc} =>
                $response_type =>
                $where =>
                $_
            );
        }
    }

    undef;
}

1;

__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::WWW::XKCD::AsText - read http://xkcd.com comics on IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::WWW::XKCD::AsText);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'XKCD',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'XKCD Bot',
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
            'XKCD' =>
                POE::Component::IRC::Plugin::WWW::XKCD::AsText->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix_> XKCDBot, xkcd 1
    <XKCDBot> [[A boy sits in a barrel which is floating in an ocean.]]
    <XKCDBot>
    <XKCDBot> Boy: I wonder where I'll float next?
    <XKCDBot>
    <XKCDBot> [[The barrel drifts into the distance. Nothing else can be seen.]]
    <XKCDBot>
    <XKCDBot> {{Alt: Don't we all.}}

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
read L<http://xkcd.com> comics' transcriptions on IRC.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'XKCD' => POE::Component::IRC::Plugin::WWW::XKCD::AsText->new
    );

    # juicy flavor
    $irc->plugin_add(
        'XKCD' =>
            POE::Component::IRC::Plugin::WWW::XKCD::AsText->new(
                auto             => 1,
                response_event   => 'irc_xkcd',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                trigger          => qr/^xkcd\s+(?=\S)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::WWW::XKCD::AsText> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. The possible
arguments/values are as follows:

=head3 auto

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the person requesting
a comic with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emited by the plugin to retrieve the results (see
EMITED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 response_event

    ->new( response_event => 'event_name_to_recieve_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the comic's text is retrieved. See EMITED EVENTS
section for more information. B<Defaults to:> C<irc_xkcd>

=head3 banned

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) requesting the comic matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 trigger

    ->new( trigger => qr/^xkcd\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests for a comic. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data which is ment to be a comic ID number.
B<Defaults to:> C<qr/^xkcd\s+(?=\S)/i>

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<XKCDBot> and your trigger is C<qr/^xkcd\s+/>
you would request the comic by saying C<XKCDBot, xkcd 222>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to request the comic. Note: this argument has no effect on
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
will enable comics only via C</notice> and C</msg> messages.
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

=head1 EMITED EVENTS

=head2 response_event

    $VAR1 = {
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'XKCDBot, xkcd 333',
        'id' => '333',
        'text' => q|comic's text here|,
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_xkcd>) will recieve input
every time comic request is completed. The input will come in the form
of a hashref in C<ARG0>. The keys/values of that hashref are as follows:

=head3 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The C<who> key will contain the usermask of the user who requested the
comic.

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

    { 'message' => 'XKCDBot, kxcd 333', }

The C<message> key will contain the message which the user has
sent to request the comic.

=head3 id

    { 'id' => '333' }

The C<term> key will contain the ID of the comic being retrieved.

=head3 text

    { 'text' => 'comic text goes here' }

The C<text> key will contain the text of the comic or an error message.
You can differentiate the errors by checking if C<error> key is set to
a true value.

=head3 error

    { 'error' => '1' }

When C<error> key is present it is an indication that an error occured
during the retrieval of the comic (including non-existant comic IDs). The
actual error message will be present in C<text> key.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-www-xkcd-astext at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-WWW-XKCD-AsText>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::WWW::XKCD::AsText

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-WWW-XKCD-AsText>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-WWW-XKCD-AsText>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-WWW-XKCD-AsText>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-WWW-XKCD-AsText>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

