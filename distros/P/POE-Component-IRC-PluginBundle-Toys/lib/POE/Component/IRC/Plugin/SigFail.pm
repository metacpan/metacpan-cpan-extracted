package POE::Component::IRC::Plugin::SigFail;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Carp;
use Devel::TakeHashArgs;
use POE::Component::IRC::Plugin qw(:ALL);

sub new {
    my $class = shift;

    get_args_as_hash( \@_, \ my %args, {
            tag         => qr/<irc_sigfail:([^>]+)>/,
            messages    => __make_sigfail_messages(),
            extra       => [],
            sigfail     => 1,
        },
        [], # no mandatory args
        [ qw(tag  extra  messages  sigfail) ],
    ) or croak $@;

    push @{ $args{messages} }, @{ $args{extra} };

    return bless \%args, $class;
}

sub PCI_register {
    my ( $self, $irc ) = @_;
    $self->{irc} = $irc;
    $irc->plugin_register( $self, 'USER', qw(privmsg notice) );
    return 1;
}

sub PCI_unregister {
    my $self = shift;
    delete $self->{irc};
    return 1;
}

sub U_privmsg {
    my ( $self, undef, $out ) = @_;
    $self->_process( $out );
    return PCI_EAT_NONE;
}

sub U_notice {
    my ( $self, undef, $out ) = @_;
    $self->_process( $out );
    return PCI_EAT_NONE;
}

sub _process {
    my ( $self, $out ) = @_;
    if ( my ( $message ) = $$out =~ /$self->{tag}/ ) {
        $message = $self->{messages}[ rand @{ $self->{messages} } ]
            if $self->{sigfail};

        $$out =~ s/$self->{tag}/$message/g;
    }
}

sub __make_sigfail_messages {
    return [
        q|No idea|,
        q|No clue|,
        q|Wtf is that?|,
        q|Umm.. Google it|,
        q|Come again?|,
        q|Trying to be funny?|,
        q|Umm, I gotta run, talk to you later!|,
        q|Leave me alone|,
        q|Do I have to know that?|,
        q|My dum-dum wants gum-gum|,
        q|Pay me!|,
        q|Hold on a sec... just wait...umm I'll be right back!!|,
        q|$SIG{FAIL}|,
        q|Mooooooo-o-o|,
        q|Huh?|,
        q|Waddayawant?!|,
        q|Yeah, right!! Keep on waiting!|,
        q|*yawn*|,
        q|Don't leave! I'm coming!|,
        q|Where is my sugar?|,
        q|I'm not that smart :(|,
        q|lalalala-lala-lala|,
        q|me iz teh suck, ask some1 else|,
        q|must.... eat... batteries..|,
        q|Something tells me you are trying to fool me...|,
        q|NO! I will NOT tell you that!|,
        q|Stop picking on bots, you racist!!|,
        q|Do you have to bug me so much just because I am a bot?|,
        q|01001011101111010000110101100011! Read that!|,
        q|Not enough megahurts :(|,
        q|Can't tell you, it's a secret!|,
        q|Hrooop, something's broke!|,
        q|If you don't know, why should I? >:O|,
    ];
}

1;
__END__

=for stopwords bot sigfail

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::SigFail - make witty error/no result messages

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::SigFail);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'FailBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'FAIL BOT',
        plugin_debug => 1,
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start  irc_001  irc_public  _default) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'SigFail' =>
                POE::Component::IRC::Plugin::SigFail->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_public {
        $irc->yield( privmsg => '#zofbot' => '<irc_sigfail:FAIL>' );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }

=head1 DESCRIPTION

This is a silly little module which allows you to spice up your "error"
or "no result" messages with a little wit. It is to be used as a plugin
for L<POE::Component::IRC>.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain
    $irc->plugin_add(
        'SigFail' => POE::Component::IRC::Plugin::SigFail->new
    );

    # strawberry-vanilla
    $irc->plugin_add(
        'SigFail' => POE::Component::IRC::Plugin::SigFail->new(
            tag         => qr/<irc_sigfail:([^>]+)>/,
            messages    => [
                q|No idea|,
                q|No clue|,
            ],
            extra       => [
                q|Wtf is that?|,
                q|Umm.. Google it|,
            ],
            sigfail     => 1,
        )
    );

Constructs and returns a new POE::Component::IRC::Plugin::SigFail object
which is suitable to be fed into C<plugin_add> method of
L<POE::Component::IRC> object.

The constructor takes a few arguments I<all of which are optional> and
are passed as key/value pairs. All arguments can be changed dynamically
by assigning to them as hashref keys in your plugin's object. In other
words, if you want to change the value of C<sigfail> argument you can
simply do C<< $your_sigfail_plugin_object->{sigfail} = 0; >>.
The possible arguments are as follows:

=head3 C<tag>

    ->new( tag => qr/<irc_sigfail:([^>]+)>/, );

B<Optional>. The way the plugin works is it looks for special "tags"
in outgoing C<privmsg> and C<notice> messages. The "tag" is a regex
(C<qr//>) which is given as a value to constructor's C<tag> argument.
The regex must have one capturing group of parenthesis. When C<sigfail>
argument (see below) is set to a true value the plugin will replace the
entire "tag" with one of the "witty messages". If C<sigfail> argument
is set to a false value, the "tag" will be replaced with whatever was
captured by capturing ground of parentheses. This allows you to specify
"real" error/no result messages in your tags and dynamically change
values of C<sigfail> argument in case you need to know the actual message.
B<Defaults to:> C<< qr/<irc_sigfail:([^>]+)>/ >>.

=head3 C<messages>

    ->new( messages => [
                q|No idea|,
                q|No clue|,
            ],
    );

B<Optional>. The C<messages> argument is the heart of the plugin. It takes
an arrayref as a value elements of which are "witty messages" with which
the tag will be replaced. The default set of C<messages> is presented
in "MESSAGES" section below. If you want to just add a few more messages
see the C<extra> argument below. If you have some nice and funny messages
suitable for this plugin please tell me about them at C<zoffix@cpan.org>
and I will be more than happy to add them to the "core". B<Defaults to:>
an arrayref containing all the messages presented in "MESSAGES" section
below.

=head3 C<extra>

    ->new( extra => [
                q|Wtf is that?|,
                q|Umm.. Google it|,
            ],
    );

B<Optional>. If you simply to want to add a few C<messages> of your own
instead of completely replacing the C<messages> arrayref (see above) simply
assign them to C<extra> argument. The C<extra> argument takes an arrayref
as a value elements of which will be appended to C<messages> arrayref
(see description above). B<Defaults to:> C<[]> (empty arrayref).

=head3 C<sigfail>

    ->new( sigfail => 1, );

B<Optional>. This is the "controlling switch" of the plugin. It takes
either true or false values as a value. When set to a true value the
"tag" (see above) will be replaced with one of the witty messages given via
C<messages> argument. When set to a false value the "tag" will be replaced
with whatever was captured in the first group of capturing parenthesis
of the C<tag> argument's regex (see above). B<Defaults to:> C<1>

=head1 MESSAGES

The following are default "witty messages" with which you "tag" will
be replaced; i.e. the default elements of C<messages> argument arrayref.

    [
        q|No idea|,
        q|No clue|,
        q|Wtf is that?|,
        q|Umm.. Google it|,
        q|Come again?|,
        q|Trying to be funny?|,
        q|Umm, I gotta run, talk to you later!|,
        q|Leave me alone|,
        q|Do I have to know that?|,
        q|My dum-dum wants gum-gum|,
        q|Pay me!|,
        q|Hold on a sec... just wait...umm I'll be right back!!|,
        q|$SIG{FAIL}|,
        q|Mooooooo-o-o|,
        q|Huh?|,
        q|Waddayawant?!|,
        q|Yeah, right!! Keep on waiting!|,
        q|*yawn*|,
        q|Don't leave! I'm coming!|,
        q|Where is my sugar?|,
        q|I'm not that smart :(|,
        q|lalalala-lala-lala|,
        q|me iz teh suck, ask some1 else|,
        q|must.... eat... batteries..|,
        q|Something tells me you are trying to fool me...|,
        q|NO! I will NOT tell you that!|,
        q|Stop picking on bots, you racist!!|,
        q|Do you have to bug me so much just because I am a bot?|,
        q|01001011101111010000110101100011! Read that!|,
        q|Not enough megahurts :(|,
        q|Can't tell you, it's a secret!|,
        q|Hrooop, something's broke!|,
        q|If you don't know, why should I? >:O|,
    ];

=head1 EXAMPLES

The C<examples/> directory of this distribution contains a C<fail_bot.pl>
script which is an IRC bot which responds with a sigfail message every time
there is a public message in the channel.

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