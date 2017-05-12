package POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search;

use warnings;
use strict;

our $VERSION = '0.002';

use POE::Component::WWW::OhNoRobotCom::Search;
use base 'POE::Component::IRC::Plugin::BasePoCoWrap';

sub _make_default_args {
    return (
        response_event  => 'irc_ohnorobot_results',
        trigger         => qr/^comics?\s+(?=\S+)/i,
        obj_args        => { },
        max_results     => 3,
    );
}

sub _make_poco {
    my $self = shift;
    return POE::Component::WWW::OhNoRobotCom::Search->spawn(
        %{ $self->{obj_args} || {} }
    );
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;
    my @out = exists $in_ref->{error}
        ? $in_ref->{error}
        : sort keys %{ $in_ref->{results} };

    @out = splice @out, 0, $self->{max_results};

    return [ join ' ', @out ];
}

sub _make_response_event {
    my $self = shift;
    my $in_ref = shift;

    return {
        ( exists $in_ref->{error}
            ? ( error => $in_ref->{error} )
            : ( results => $in_ref->{results} )
        ),
        term    => $in_ref->{term},
        map { $_ => $in_ref->{"_$_"} }
            qw( who channel  message  type ),
    }
}

sub _make_poco_call {
    my ( $self, $data_ref ) = @_;

    $self->{poco}->search({
            event       => '_poco_done',
            term        => delete $data_ref->{what},
            map( +( exists $self->{$_} ? ( $_ => $self->{$_} ) : () ),
                    qw(max_results comic_id include lucky)
            ),
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search - search http://ohnorobot.com/ website from IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC Component::IRC::Plugin::WWW::OhNoRobotCom::Search);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'OhNoRobotComBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'Bot for searching ohnorobot.com',
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
            'OhNoRobot' =>
                POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search->new(
                    comic_id    => 56 # XKCD comics
                )
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix> OhNoRobotComBot, comic foo
    <OhNoRobotComBot> http://xkcd.com/233/ http://xkcd.com/240/ http://xkcd.com/261/
    <Zoffix> OhNoRobotComBot, comic bar
    <OhNoRobotComBot> http://xkcd.com/328/ http://xkcd.com/359/ http://xkcd.com/361/

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
search L<http://ohnorobot.com/> website from IRC.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'OhNoRobotCom' => POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search->new
    );

    # juicy flavor
    $irc->plugin_add(
        'OhNoRobotCom' =>
            POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search->new(
                auto             => 1,
                response_event   => 'irc_ohnorobot_results',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^comics?\s+(?=\S)/i,
                obj_args         => { debug => 1 },
                max_results      => 3,
                include          => [ qw(all_text meta) ],
                comic_id         => 56, # XKCD comics
                lucky            => 1,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search> object suitable
to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. B<Note:>
most of these arguments can be changed on the fly by changing them as keys
in your plugin's object, i.e. C<< $plug_obj->{banned} = [qr/.*/ ]; >>.
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
section for more information. B<Defaults to:> C<irc_ohnorobot_results>

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

    ->new( trigger => qr/^comics?\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^comics?\s+(?=\S)/i>

=head3 obj_args

    ->new( obj_args => { debug => 1 } );

B<Optional>. Takes a hashref as an argument which will be dereferenced
directly into L<POE::Component::WWW::OhNoRobotCom::Search>'s constructor.
See documentation for L<POE::Component::WWW::OhNoRobotCom::Search> for
possible arguments. B<Defaults to:> C<{}> ( default constructor )

=head3 comic_id

    ->( comic_id => 56 )

B<Optional>.
The C<comic_id> argument takes a scalar as a value which should be a
comic ID number or an empty string which indicates that search should be
done on all comics. To obtain the comic ID number go to
L<http://www.ohnorobot.com/index.pl?show=advanced>, "View Source" and search
for the name of the comic, when you'll find an <option> the C<value="">
attribute of that option will be the number you are looking for. Idealy,
it would make sense to make the C<comic_id> argument
accepts names instead
of those numbers, but there are just too many (500+) different comics sites
and new are being added, blah blah. B<Defaults to:>
empty string, meaning search through all the comics.

=head3 include

    ->( include => [ qw(all_text meta) ] )

B<Optional>.
Specifies what kind of "things" to include into consideration when
performing the search. Takes an arrayref as an argument. B<Defaults to:> all
possible elements included which are as follows:

=over 10

=item all_text

Include I<All comic text>.

=item scene

Include I<Scene descriptions>.

=item sound

Include I<Sound effects>.

=item speakers

Include I<Speakers' names>

=item link

Include I<Link text>.

=item meta

Include I<Meta information>

=back

=head3 max_results

    ->new( max_results => 3 )

B<Optional>.
The number of results displayed on L<http://www.ohnorobot.com> is 10, the
object will send out several requests if needed to obtain the
number of results specified in the C<max_results> argument. Don't use
extremely large values here, as the amount of requests will B<NOT> be
C<max_results / 10> because results are often repeating and the object
will count only unique URIs on the results page. B<Note:> values less than
10 for this argument will yield to C<max_results> results being presented
on IRC (when C<auto> is turned on) but the response event will likely to
recieve more than that.
B<Defaults to:> C<3>
(this does not necessarily mean that the object will send only one request).

=head3 lucky

    ->new( lucky => 1 );

ARE YOU FEELING LUCKY?!!? If so, the C<lucky> argument, when set to a
B<true> value, will "press" the I<Let the robot decide> button on
L<http://www.ohnorobot.com> and the C<search> method/event will fetch
a poiting to the comic which the *ahem* "robot" thinks is what you
want. B<Note:> when using the C<lucky> argument search
will error out (see "EMITED EVENTS" section below)
if nothing was found. B<Defaults to:> a false value (no feelin' lucky :( )

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig foo>.
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
        'type' => 'public',
        'channel' => '#zofbot',
        'term' => 'bar',
        'message' => 'OhNoRobotComBot, comic bar',
        'results' => {
            'http://scarygoround.com/index.php?date=20080311' => 'Scary Go Round :: Monday-Friday Comic by John Allison',
            'http://achewood.com/index.php?date=12312004' => 'Trashspotting',
            'http://suburbanjungle.com/d/20060315.html' => 'The Suburban Jungle, Starring Tiffany Tiger - Archives',
            'http://shd-wk.com/index.php?strip_id=99' => '#99',
            'http://www.goats.com/archive/991231.html' => 'Goats comic strip from December / 31 / 1999: tastes like chicken candy',
            'http://crfh.net/d/20080306.html' => 'College Roomies from Hell!!! for Thursday, March 6, 2008',
            'http://rocr.xepher.net/index.php?p=20051230' => 'Webcomic Rogues of Clwyd-Rhan: The Rogues find they have an unexpected ally.',
            'http://jesusandmo.net/thanks.html' => 'Jesus and Mo',
            'http://www.gpf-comics.com/mischief/d/20070622.html' => 'General Protection Fault--The Comic Strip',
            'http://questionablecontent.net/view.php?comic=99' => 'Almost Psychic'
        }
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_ohnorobot_results>) will recieve input
every time request is completed. The input will come in a form of a
hashref in C<$_[ARG0]>.
The possible keys/values of that hashref are as follows:

=head2 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The usermask of the person who made the request.

=head2 term

    { 'term' => 'bar' }

The search term which was used for searching. (this is C<message> key
with trigger stripped out)

=head2 type

    { 'type' => 'public' }

The type of the request. This will be either C<public>, C<notice> or
C<privmsg>

=head2 channel

    { 'channel' => '#zofbot' }

The channel where the message came from (this will only make sense when the request came from a public channel as opposed to /notice or /msg)

=head2 message

    { 'message' => 'OhNoRobotComBot, comic bar' }

The full message that the user has sent.

=head2 error

    { 'error' => 'Network error: 500 read timeout' }

If an error occured during the search the C<error> key will be present
and will contain explanation for the error.

=head2 results

    'results' => {
        'http://scarygoround.com/index.php?date=20080311' => 'Scary Go Round :: Monday-Friday Comic by John Allison',
        'http://achewood.com/index.php?date=12312004' => 'Trashspotting',
        'http://suburbanjungle.com/d/20060315.html' => 'The Suburban Jungle, Starring Tiffany Tiger - Archives',

        ....etc
    }

The C<results> key will contain a hashref with search results. The keys
will be links poiting to comics found and values will be the titles
of the comics. Note: if C<max_results> argument to the constructor
is set to a value less than 10 (it's 3 by default) then C<results> key
will likely to contain more results than C<max_results>.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-www-ohnorobotcom-search at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-WWW-OhNoRobotCom-Search>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::WWW::OhNoRobotCom::Search

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-WWW-OhNoRobotCom-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-WWW-OhNoRobotCom-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-WWW-OhNoRobotCom-Search>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-WWW-OhNoRobotCom-Search>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

