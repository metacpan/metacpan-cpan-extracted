package POE::Component::IRC::Plugin::WWW::Lipsum;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
use POE::Component::WWW::Lipsum;

sub _make_default_args {
    return (
        response_event   => 'irc_lipsum',
        trigger          => qr/^lipsum\s*/i,
        line_lengths     => {
            public  => 350,
            notice  => 350,
            privmsg => 350,
        },
        max_lines        => {
            public  => 1,
            notice  => 5,
            privmsg => 5,
        },
    );
}

sub _make_poco {
    my $self = shift;

    if ( not ref $self->{max_lines} ) {
        $self->{max_lines} = {
            public  => $self->{max_lines},
            notice  => $self->{max_lines},
            privmsg => $self->{max_lines},
        };
    }
    else {
        $self->{max_lines} = {
            public  => 1,
            notice  => 5,
            privmsg => 5,
            %{ $self->{max_lines} },
        };
    }

    if ( not ref $self->{line_lengths} ) {
        $self->{line_lengths} = {
            public  => $self->{line_lengths},
            notice  => $self->{line_lengths},
            privmsg => $self->{line_lengths},
        };
    }
    else {
        $self->{line_lengths} = {
            public  => 350,
            notice  => 350,
            privmsg => 350,
            %{ $self->{line_lengths} },
        };
    }


    return POE::Component::WWW::Lipsum->spawn(
        debug => $self->{debug},
    );
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;

    if ( $in_ref->{error} ) {
        return [ $in_ref->{error} ];
    }

    my $text = join ' ', @{ $in_ref->{lipsum} };

    $text =~ s/\s+/ /g;

    my $line_max_length = $self->{line_lengths}{ $in_ref->{_type} } || 350;

    while ( length( $text ) > $line_max_length ) {
        push @{ $in_ref->{out} }, substr $text, 0, $line_max_length;
        $text = substr $text, $line_max_length;
    }
    push @{ $in_ref->{out} }, $text;

    my $line_num_max = $self->{max_lines}{ $in_ref->{_type} };
    unless ( defined $line_num_max ) {
        if ( $in_ref->{_type} eq 'public' ) {
            $line_num_max = 1;
        }
        else {
            $line_num_max = 5;
        }
    }

    @{ $in_ref->{out} } = splice @{ $in_ref->{out} }, 0, $line_num_max;

    return $in_ref->{out};
}

sub _make_response_event {
    my $self = shift;
    my $in_ref = shift;

    return {
        lipsum => $in_ref->{lipsum},

        ( exists $in_ref->{error}
            ? ( error => $in_ref->{error} )
            : ( out   => $in_ref->{out},  )
        ),

        map { $_ => $in_ref->{"_$_"} }
            qw( who channel  message  type what ),
    }
}

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    my %args;
    @args{ qw/amount what start html/ }
    = map lc, split m|[/\s,]+|, $data_ref->{what};

    $args{what} ||= 'words';
    $args{amount} ||= '15';

    if ( defined $args{html} and $args{html} =~ /yes/ ) {
        $args{html} = 1
    }
    else {
        delete $args{html};
    }

    my %max_amount_for = (
        words   => 7000,
        paras   => 100,
        lists   => 100,
        bytes   => 56000,
    );

    if ( $args{amount} > $max_amount_for{ $args{what} } ) {
        $args{amount} = $max_amount_for{ $args{what} };
    }

    $self->{poco}->generate( {
            event       => '_poco_done',
            args        => \%args,
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}


1;
__END__

=encoding utf8

=for stopwords Ipsum Lorem amet bot dolor ipsum privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::WWW::Lipsum - plugin to generate Lorem Ipsum text in IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::WWW::Lipsum);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'LipsumBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'Lorem Ipsum Bot',
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
            'lipsum' =>
                POE::Component::IRC::Plugin::WWW::Lipsum->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }


    <Zoffix> LipsumBot, lipsum
    <LipsumBot> Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut velit lectus, ullamcorper non, sagittis id.
    <Zoffix> LipsumBot, lipsum 10
    <LipsumBot> Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Mauris volutpat.
    <Zoffix> LipsumBot, lipsum 10/paras
    <LipsumBot> Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Curabitur sodales justo in nibh. Aenean placerat pretium nisl. Nulla enim arcu, porta in, molestie nec, consequat sed, nisi. Quisque eu urna. In hac habitasse platea dictumst. Sed sed augue. Pellentesque pellentesque fringilla pede. Nulla pharetra mattis dui. Donec diam ligula, imperdiet et,
    <Zoffix> LipsumBot, lipsum 10/paras/no
    <LipsumBot> Fusce dignissim, urna quis posuere cursus, erat est elementum dolor, non sollicitudin ligula nisl sed enim. Vivamus magna mi, pretium in, blandit non, ultrices ac, velit. Morbi nisl. Aenean quam massa, faucibus a, adipiscing at, sollicitudin nec, eros. Morbi pellentesque, erat ac porttitor ultricies, lacus arcu congue dolor, at malesuada urna nunc
    <Zoffix> LipsumBot, lipsum 10/paras/no/1
    <LipsumBot> <p> Aliquam quis est eget nulla ornare volutpat. Mauris a sapien. Nullam interdum justo quis metus. Quisque ultricies est eget dolor. Suspendisse nec neque nec diam semper gravida. In in odio in purus scelerisque sagittis. Nam suscipit quam vel lorem. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Praesent i
    <Zoffix> LipsumBot, lipsum 10 paras no 1
    <LipsumBot> <p> Suspendisse potenti. Ut ligula libero, posuere ac, euismod sit amet, dignissim eu, quam. Donec massa. Cras mollis pulvinar risus. Aenean porta porttitor nulla. Suspendisse potenti. Etiam nulla nisi, scelerisque vel, consequat vitae, ultrices aliquam, mauris. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
get Lorem Ipsum text generated by L<http://lipsum.com/>.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 PLUGIN IRC COMMAND SYNTAX

    LipsumBot, lipsum [AMOUNT] [WHAT] [START WITH LOREM] [MAKE HTML]

All arguments are optional. Plugin can be triggered without any arguments,
if that's the case then plugin will output 15 words of Lorem Ipsum text.

Arguments can be separated either by whitespace, the C</> character or
C<,> character.

You cannot skip arguments, if you want to generate 15 paragraphs you
B<CANNOT> use C<LipsumBot, lipsum paras> even though 15 is the default
for C<AMOUNT>. (proper use is C<LipsumBot, lipsum 15 paras>)

=head2 C<AMOUNT> argument

    LipsumBot, lipsum 20

The C<AMOUNT> argument takes a positive integer which represents how
many of C<WHAT> (see below) to generate. B<Defaults to:> C<15>

To prevent extremely creative people lagging out the plugin the following
maximum values for the C<AMOUNT> argument are imposed depending on the
kind of C<WHAT> argument (see below) used:

    words   => 7000,
    paras   => 100,
    lists   => 100,
    bytes   => 56000,

Currently these limits are not configurable. Let me know if you need them
to be so.

=head2 C<WHAT> argument

    LipsumBot, lipsum 20 paras

The C<WHAT> argument specifies what kind of entity to generate, possible
values are:

    paras    - generate paragraphs
    words    - generate words
    bytes    - generate bytes
    lists    - generate lists

With C<paras> and C<lists> the C<MAKE HTML> argument (see below) plays a
role. B<Defaults to:> C<words>

=head2 C<START WITH LOREM> argument

    LipsumBot, lipsum 20 words no

Specifies whether or not the generated text should start with
"Lorem ipsum dolor sit amet". There are only two possible values: C<yes>
and C<no>. B<Defaults to:> C<yes>

=head2 C<MAKE HTML> argument

    LipsumBot, lipsum 20 paras no yes

Applies only when C<WHAT> is set to either C<paras> or C<lists>.
Indicates whether or not the plugin should wrap paragraphs into C<< <p> >>
or C<< <li> >> HTML elements. There are only two possible values: C<yes>
and C<no>. B<Defaults to:> C<no>

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'WWW::Lipsum' => POE::Component::IRC::Plugin::WWW::Lipsum->new
    );

    # juicy flavor
    $irc->plugin_add(
        'WWW::Lipsum' =>
            POE::Component::IRC::Plugin::WWW::Lipsum->new(
                auto             => 1,
                response_event   => 'irc_lipsum',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                line_lengths     => 350,
                max_lines        => 5,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^lipsum\s*/i,
                triggers         => {
                    public  => qr/^EXAMPLE\s*/i,
                    notice  => qr/^EXAMPLE\s*/i,
                    privmsg => qr/^EXAMPLE\s*/i,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::WWW::Lipsum> object suitable to be
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

=head3 C<line_lengths>

    line_lengths => 350,

    line_lengths => {
        public  => 100,
        notice  => 200,
        privmsg => 350,
    }

B<Optional>. Specifies the length of one "line" the plugin will output,
but line is meant one message sent to IRC. The value can be either a hashref
or a scalar. When the value is a hashref, possible keys of it are
C<public>, C<notice> and C<privmsg> which correspond to appropriate
type of IRC messages, where C<public> is the message which came from the
channel. If you omit a certain key, it will take on its default value. Thus
the following two are equivalent:

    line_lengths => { public => 300 }

    line_lengths => {
        public  => 300,
        notice  => 350,
        privmsg => 350,
    }

You can also specify a scalar value to C<line_lengths> key, in this case
all of the keys (C<public>, C<notice> and C<privmsg>) will be set to
that value. B<Defaults to:> C<350> for all message types.

=head3 C<max_lines>

    max_lines => 5,

    max_lines => {
        public  => 1,
        notice  => 8,
        privmsg => 8,
    },

B<Optional>. Specifies the maximum number of "lines" (see the
C<line_lengths> argument for definition of "lines" in this context) which
plugin will output. As a value takes either a scalar or a hashref, the
same principles as for C<line_lengths> argument apply to C<max_lines> as
well. B<Defaults to:> C<1> for C<public> messages and C<5> for C<notice>
and C<privmsg> messages.

=head3 C<response_event>

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_lipsum>

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

    ->new( trigger => qr/^lipsum\s*/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex, irrelevant of the type of the message, will be considered as requests. See also
B<addressed> option below which is enabled by default as well as
B<triggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^lipsum\s*/i>

=head3 C<triggers>

    ->new( triggers => {
            public  => qr/^EXAMPLE\s+(?=\S)/i,
            notice  => qr/^EXAMPLE\s+(?=\S)/i,
            privmsg => qr/^EXAMPLE\s+(?=\S)/i,
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
B<By default> not specified (i.e. everything is triggered by C<trigger>)

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
        'out' => [
                    'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Pellentesque placerat pede non metus. Vivamus tellus. '
                ],
        'what' => '',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'type' => 'public',
        'channel' => '#zofbot',
        'lipsum' => [
                    'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Pellentesque placerat pede non metus. Vivamus tellus. '
                    ],
        'message' => 'LipsumBot, lipsum'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_lipsum>) will receive input
every time request is completed. The input will come in C<$_[ARG0]>
on a form of a hashref.
The possible keys/values of that hashrefs are as follows:

=head3 C<out>

        'out' => [
                    'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Pellentesque placerat pede non metus. Vivamus tellus. '
                ],

The C<out> key will contain an arrayref of the messages (or "lines") sent
to IRC. The content here is affected by C<line_lengths> and C<max_lines>
constructor arguments.

=head3 C<lipsum>

        'lipsum' => [
                    'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Pellentesque placerat pede non metus. Vivamus tellus. '
                    ],

The C<lipsum> key will contain Lorem Ipsum text B<before> it was chopped
up and limited by C<line_lengths> and C<max_lines> constructor arguments.

=head3 C<who>

    { 'who' => 'Zoffix!Zoffix@i.love.debian.org', }

The C<who> key will contain the user mask of the user who sent the request.

=head3 C<what>

    { 'what' => '20 paras yes no', }

The C<what> key will contain user's message after stripping the C<trigger>
(see CONSTRUCTOR).

=head3 C<message>

    { 'message' => 'LipsumBot, lipsum 20 paras yes no' }

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

=head1 SEE ALSO

L<POE>, L<POE::Component::IRC>, L<WWW::Lipsum>

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

