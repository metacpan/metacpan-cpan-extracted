package POE::Component::IRC::Plugin::Validator::CSS;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use Carp;
use POE qw(Component::WebService::Validator::CSS::W3C);
use POE::Component::IRC::Plugin qw(:ALL);
use LWP::UserAgent;

sub new {
    my $class = shift;

    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    # fill in the defaults.
    %args = (
        auto                => 1,
        eat                 => 1,
        trigger             => qr/^cssval\s+(?=\S)/i,
        addressed           => 1,
        listen_for_input    => [ qw(public  notice  privmsg) ],
        response_event      => 'irc_css_validator_response',
        valid_format        => '([:[uri_short]:]) Valid '
                                . '( [:[refer_to_uri]:] )',

        invalid_format      => '([:[uri_short]:]) Invalid, '
                                . '[:[num_errors]:] error(s), see: '
                                . '[:[refer_to_uri]:]',

        banned              => [],

        %args,
    );

    unless ( exists $args{poco_args}{ua} ) {
        $args{poco_args}{ua} = LWP::UserAgent->new( timeout => 15 );
    }

    $args{listen_for_input} = {
        map { $_ => 1 } @{ $args{listen_for_input} || [] }
    };

    return bless \%args, $class;
}

sub PCI_register {
    my ( $self, $irc ) = splice @_, 0, 2;

    $self->{irc} = $irc;

    $irc->plugin_register( $self, 'SERVER', qw(notice public msg) );

    $self->{_session_id} = POE::Session->create(
        object_states => [
            $self => [
                qw(
                    _start
                    _shutdown
                    _start_val
                    _validated
                )
            ]
        ],
    )->ID;

    return 1;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{_session_id} = $_[SESSION]->ID();
    $kernel->refcount_increment( $self->{_session_id}, __PACKAGE__ );

    $self->{poco} = POE::Component::WebService::Validator::CSS::W3C->spawn(
        %{ $self->{poco_args} || {} }
    );
    undef;
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

    $poe_kernel->post( $self->{_session_id} => _start_val => {
            _who        => $who,
            _what       => $what,
            _channel    => $channel,
            _message    => $message,
            _type       => $type,
        }
    );

    return $self->{eat} ? PCI_EAT_ALL : PCI_EAT_NONE;
}

sub _start_val {
    my ( $self, $args ) = @_[ OBJECT, ARG0 ];
    $self->{poco}->validate( {
            event => '_validated',
            uri   => $args->{_what},

            %$args,
        }
    );
}

sub _validated {
    my ( $kernel, $self, $in_ref ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $response_message;
    if ( $in_ref->{result} ) {
        $response_message = $self->_make_response( $in_ref );
    }
    else {
        $response_message = "Validator error: $in_ref->{request_error}";
    }

    $self->{irc}->_send_event( $self->{response_event} => {
            result => $response_message,

            map { $_ => $in_ref->{"_$_"} }
                qw( who  what  channel  message  type ),
        }
    );

    my $response_type = $in_ref->{_type} eq 'public'
                      ? 'privmsg'
                      : $in_ref->{_type};

    my $where = $in_ref->{_type} eq 'public'
              ? $in_ref->{_channel}
              : (split /!/, $in_ref->{_who})[0];

    if ( $self->{auto} ) {
        $kernel->post( $self->{irc} =>
            $response_type =>
            $where =>
            $response_message
        );
    }

    undef;
}

sub _make_response {
    my ( $self, $in_ref ) = @_;

    my $response = $in_ref->{is_valid}
                 ? $self->{valid_format}
                 : $self->{invalid_format};

    my %replacement_for = (
        uri_short   => $self->_shorten_uri_length( $in_ref->{uri} ),
        map { $_ => $in_ref->{ $_ } }
            qw( uri num_errors refer_to_uri num_warnings )
    );

    %replacement_for
    = map { $_ => $replacement_for{ $_ } }
        grep { defined $replacement_for{ $_ } }
            keys %replacement_for;

    my $replacement_re = join '|', keys %replacement_for;

    $response
    =~ s/ \Q[:[\E ($replacement_re) \Q]:]\E /$replacement_for{ $1 }/gix;

    return $response;
}

sub _shorten_uri_length {
    my $self = shift;
    my $uri  = shift;
    $uri =~ s{ ^ (?: (?: ht | f )tps?:// (www\.)? | www\. )}{}xi;
    $uri =~ s{ \. (?: s?html? | php | pl | asp | jsp | css | js ) $ }{}xi;
    if ( length $uri > 16 ) {
        $uri = substr( $uri, 0, 8) . "..." . substr $uri, -5 ;
    }
    return $uri;
}

1;

__END__

=encoding utf8

=for stopwords autoresponds bot bots privmsg usermask validator

=head1 NAME

POE::Component::IRC::Plugin::Validator::CSS - non-blocking CSS validator
for IRC bots.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::Validator::CSS);

    my $irc = POE::Component::IRC->spawn(
        nick    => 'CSSValidator',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'CSS Validator Bot',
    ) or die "Oh noes :( $!";

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        # register our plugin
        $irc->plugin_add(
            'CSSValidator' =>
                POE::Component::IRC::Plugin::Validator::CSS->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
        $kernel->post( $sender => join => '#zofbot' );
    }


    [18:05:00] <Zoffix> CSSValidator, cssval http://zoffix.com
    [18:05:01] <CSSValidator> (zoffix.com) Valid  ( http://jigsaw.w3.org/css-validator/validator?uri=http%3A%2F%2Fzoffix.com )

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides access to
W3C CSS Validator (L<http://jigsaw.w3.org/css-validator/>) from IRC.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    $irc->plugin_add(
            'CSSValidator' =>
                POE::Component::IRC::Plugin::Validator::CSS->new
    );

    $irc->plugin_add(
            'CSSValidatorJuicy' =>
                POE::Component::IRC::Plugin::Validator::CSS->new(
                    auto                => 1,
                    trigger             => qr/^cssval\s*/i,
                    addressed           => 1,
                    listen_for_input    => [ qw(public  notice  privmsg) ],
                    response_event      => 'irc_css_validator_response',
                    valid_format        => '([:[uri_short]:]) Valid '
                                            . '( [:[refer_to_uri]:] )',

                    invalid_format      => '([:[uri_short]:]) Invalid, '
                                            . '[:[num_errors]:] error(s), see: '
                                            . '[:[refer_to_uri]:]',

                    banned              => [ qr/Zoffix!/, qr/aol[.]com$/i ],
                    poco_args => {
                        val_uri => 'http://local.validator',
                        ua    => LWP::UserAgent->new( timeout => 15 ),
                        debug => 1,
                    },
                )
    );

The C<new> method constructs and returns a new
POE::Component::IRC::Plugin::Validator::CSS object which is suitable
for consumption by the L<POE::Component::IRC> C<plugin_add()> method.
It may take quite a few arguments, although I<all of them are optional>.
Possible arguments are as follows:

=head3 auto

    ->new( auto => 1 )

B<Optional>. Takes either true or false values. By default the plugin
autoresponds the results of validation to wherever
the request came from (see C<listen_for_input> argument below). You
may wish to disable that feature by setting C<auto> argument to a
I<false value> and listen to the event plugin emits (see C<response_event>
argument below). B<Defaults to:> C<1>

=head3 trigger

    ->new( trigger => qr/^cssval\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests for validation. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual URI which needs to be validated.
B<Defaults to:> C<qr/^cssval\s+(?=\S)/i>

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<CSSBot> and your trigger is C<qr/^val/>
you would request the validation by saying C<CSSBot, val some_site.com>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to request validation. Note: this argument has no effect on
C</notice> and C</msg> validation requests. B<Defaults to:> C<1>

=head3 listen_for_input

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to validation
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to validation requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable validation only via C</notice> and C</msg> messages.
B<Defaults to:> C<[ qw(public  notice  privmsg) ]>

=head3 response_event

    ->new( response_event => 'irc_css_validator_response' );

B<Optional>. Whenever validation results are ready plugin emits an
event (see EMITTED EVENTS for details). The value of C<response_event>
will specify the name of the event to emit. B<Defaults to:>
C<irc_css_validator_response>

=head3 valid_format

    ->new( valid_format => '([:[uri_short]:]) Valid ( [:[refer_to_uri]:] )' );

B<Optional>. It is possible to configure the message which the plugin
sends when validation completes. The C<valid_format> takes a scalar
string which specifies
the format of messages sent when the URI being validated is valid (see
also C<invalid_format> below). The C<valid_format>'s value may contain
several special character sequences which will be replaced by specific
data bits. B<Defaults to:>
C<([:[uri_short]:]) Valid ( [:[refer_to_uri]:] )>.
The special character sequences are as follows:

=over 10

=item [:[uri]:]

Any occurrences of C<[:[uri]:]> in the C<valid_format> string will
be replaced by the URI which was validated.

=item [:[uri_short]:]

Since it's common that people will be validating pretty long URIs which
will clutter the output you may wish to use C<[:[uri_short]:]> instead of
C<[:[uri]:]> (see above). The C<[:[uri_short]:]> will contain a specially
chopped up version of the URI being validated, just to make it obvious
which URI it was (in case of multiple validations done at the same time).

=item [:[num_errors]:]

Any occurrences of C<[:[num_errors]:]> will be replaced with the number
representing the number of errors... and for C<valid_format> it will
(should :) ) always be C<0>. However, the same code makes the replacement
for C<invalid_format> (see below), thus this C<0> is at your disposal in
C<valid_format> as well ;)

=item [:[refer_to_uri]:]

Any occurrences of C<[:[refer_to_uri]:]> will be replaced with the
URI pointing to the validator's page with the results of validation.

=item [:[num_warnings]:]

Any occurrences of C<[:[num_warnings]:]> will be replaced with the number
of warnings occurred on the page.

=back

=head3 invalid_format

    ->new( invalid_format => '([:[uri_short]:]) Invalid, [:[num_errors]:] error(s), see: [:[refer_to_uri]:]' );

B<Optional>. Exactly the same as C<valid_format> argument (see above)
and it takes exactly the same special character sequences, B<except>
the C<invalid_format> specifies the format of the output when the URI
being validated is invalid (contains some CSS errors). B<Defaults to:>
C<([:[uri_short]:]) Invalid, [:[num_errors]:] error(s), see: [:[refer_to_uri]:]>

=head3 banned

    ->new( banned => [ qr/Zoffix!/, qr/aol[.]com$/i ] );

B<Optional>. Takes an arrayref as a value. The elements must be regexes.
If the usermask of the person requesting the validation matches any of
the regexes specified in C<banned>, the plugin will ignore that user.
B<Defaults to:> C<[]> (no bans are set).

=head3 poco_args

    ->new( poco_args => {
            ua      => LWP::UserAgent->new( timeout => 10 ),
            val_uri => 'http://local.validator/',
            debug   => 1,
        }
    );

B<Optional>. Takes a hashref as a value which will be passed to
L<POE::Component::WebService::Validator::CSS::W3C> C<spawn()> method.
Read L<POE::Component::WebService::Validator::CSS::W3C>'s documentation for
possible values. The plugin will use all the defaults, however
unless you specify the C<ua> argument which takes an L<LWP::UserAgent>
object, the L<LWP::UserAgent> object with its default parameters will be
used with I<exception of the> C<timeout> argument, which plugin sets
to C<15> seconds.

=head3 eat

    ->new( eat => 0 );

If set to a false value plugin will return a C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head1 EMITTED EVENTS

=head2 response_event

    $VAR1 = {
        'what' => 'zoffix.com',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'CSSValidator, cssval zoffix.com',
        'result' => '(zoffix.com) Valid ( http://jigsaw.w3.org/css-validator/validator?uri=zoffix.com )'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_css_validator_response>) will receive input
every time validation request is completed. The input will come in the form
of a hashref in C<ARG0>. The keys/values of that hashref are as follows:

=head3 what

    { 'what' => 'zoffix.com' }

The C<what> key will contain the URI being validated (semantics: B<what>
was being validated).

=head3 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The C<who> key will contain the usermask of the user who requested the
validation.

=head3

    { 'type' => 'public' }

The C<type> key will contain the "type" of the message sent be the
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

    { 'message' => 'CSSValidator, cssval zoffix.com' }

The C<message> key will contain the message which the user has
sent to request the validation.

=head3 result

    { 'result' => '(zoffix.com) Valid ( http://jigsaw.w3.org/css-validator/validator?uri=zoffix.com )' }

The C<result> key will contain the result of the validation, or more
specifically either C<valid_format> or C<invalid_format> strings
(see constructor's description) with data bits replaced, in other
words what you'd see the plugin say when C<auto> (see constructor arguments)
is turned on (that's the default).

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
