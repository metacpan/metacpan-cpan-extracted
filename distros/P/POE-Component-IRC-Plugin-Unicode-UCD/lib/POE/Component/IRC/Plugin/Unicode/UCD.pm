package POE::Component::IRC::Plugin::Unicode::UCD;

use warnings;
use strict;

our $VERSION = '0.004';

use base 'POE::Component::IRC::Plugin::BaseWrap';

use Carp;
use Encode qw/decode encode_utf8/;
use Unicode::UCD 'charinfo';

sub _make_default_args {
    return (
        response_event  => 'irc_unicode_ucd',
        trigger         => qr/^utf8?\s+(?=\S)/i,
    );
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;
    return [ $self->_unip( $in_ref->{what} ) ];
}

sub _make_response_event {
    my ( $self, $in_ref ) = @_;
    $in_ref->{result} = $self->_unip( $in_ref->{what} );
    return $in_ref;
}

sub _unip {
    ( my $self, $_ ) = @_;

    $_ = "0x$_"
        if !s/^[Uu]\+/0x/
            and /[A-Fa-f]/
            and /^[[:xdigit:]]{2,}\z/;

    $_ = oct if /^0/;

    unless ( /^\d+\z/ ) {
        eval {
            my $tmp = decode(
                length > 1 ? 'utf8' : 'iso-8859-1',
                "$_",
                1
            );

            die "'$_' is not numeric, conversion to unicode failed"
                unless length ($tmp) == 1;

            $_ = ord $tmp;
        };
        if ( $@ ) {
            ( my $err = $@ ) =~ s/ at .* line \d+.*\z//s;
            return $err;
        }
    }
    my $utf8r = encode_utf8( chr );
    my $utf8 = join ' ', map "0x$_", unpack '(H2)*', $utf8r;
    my $x;

    return sprintf "U+%X (%s): no match found", $_, $utf8
        unless $x = charinfo $_;

    return "U+$x->{code} ($utf8): $x->{name} [$utf8r]";
}

1;

__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::Unicode::UCD - lookup unicode chars/codes from IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::Unicode::UCD);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'UnicodeBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'Unicode BOT',
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
            'UnicodeUCD' =>
                POE::Component::IRC::Plugin::Unicode::UCD->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix> UnicodeBot, utf ☺
    <UnicodeBot> U+263A (0xe2 0x98 0xba): WHITE SMILING FACE [☺]
    <Zoffix> UnicodeBot, utf u+263a
    <UnicodeBot> U+263A (0xe2 0x98 0xba): WHITE SMILING FACE [☺]
    <Zoffix> UnicodeBot, utf 0x263a
    <UnicodeBot> U+263A (0xe2 0x98 0xba): WHITE SMILING FACE [☺]
    <Zoffix> UnicodeBot, utf 263a
    <UnicodeBot> U+263A (0xe2 0x98 0xba): WHITE SMILING FACE [☺]
    <Zoffix> UnicodeBot, utf WHITE SMILING FACE
    <UnicodeBot> 'WHITE SMILING FACE' is not numeric, conversion to unicode failed

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
look up Unicode chars/code points from IRC.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'UnicodeUCD' => POE::Component::IRC::Plugin::Unicode::UCD->new
    );

    # juicy flavor
    $irc->plugin_add(
        'UnicodeUCD' =>
            POE::Component::IRC::Plugin::Unicode::UCD->new(
                auto             => 1,
                response_event   => 'irc_unicode_ucd',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                trigger          => qr/^utf8?\s+(?=\S)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::Unicode::UCD> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. B<Note:>
arguments can be changed on the fly, just assign to
$plugin_object->{some_argument}.
The possible arguments/values are as follows:

=head3 auto

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emited by the plugin to retrieve the results (see
EMITED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 response_event

    ->new( response_event => 'event_name_to_recieve_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITED EVENTS
section for more information. B<Defaults to:> C<irc_unicode_ucd>

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

    ->new( trigger => qr/^utf8?\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
The possible argument to the plugin (from IRC that is, after stripping the
trigger) can be a unicode character, or code base either in a form of
C<U+263a> (case insensitive) or C<0x263a>.
B<Defaults to:> C<qr/^utf8?\s+(?=\S)/i>

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
        'what' => '☺',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'UnicodeBot, utf ☺',
        'result' => 'U+263A (0xe2 0x98 0xba): WHITE SMILING FACE [☺]',
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_unicode_ucd>) will recieve input
every time request is completed. The input will come in C<$_[ARG0]> in
a form of a hashref. The keys/values of that hashref are as follows:

=head2 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The usermask of the person who made the request.

=head2 what

    { 'what' => '☺' }

The user's message after stripping the trigger.

=head2 type

    { 'type' => 'public' }

The type of the request. This will be either C<public>, C<notice> or
C<privmsg>

=head2 channel

    { 'channel' => '#zofbot' }

The channel where the message came from (this will only make sense when the request came from a public channel as opposed to /notice or /msg)

=head2 message

    { 'message' => 'UnicodeBot, utf ☺' }

The full message that the user has sent.

=head2 result

    { 'result' => 'U+263A (0xe2 0x98 0xba): WHITE SMILING FACE [☺]' }

The result of the request.

=head1 AUTHOR

Thanks to L<Lukas (mauke) Mai|https://metacpan.org/author/MAUKE> for providing the unicode lookup code.

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-unicode-ucd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-Unicode-UCD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::Unicode::UCD

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-Unicode-UCD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-Unicode-UCD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-Unicode-UCD>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-Unicode-UCD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

