package POE::Component::IRC::Plugin::HTML::AttributeInfo;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use Carp;
use POE;
use base qw(
    POE::Component::IRC::Plugin::BaseWrap
    POE::Component::IRC::Plugin::HTML::AttributeInfo::Data
);

my @Attrs = __PACKAGE__->_data();
my %Valid_Attrs = __PACKAGE__->_valid_attrs();


sub _make_default_args {
    return (
        trigger          => qr/^attr\s+(?=\S+)/i,
        response_event   => 'irc_html_attribute',
        line_length      => 350,
        cmdtriggers      => {
            list_attr =>
            qr/^ l (?:ist)? \s* a (?:ttr (?:ibute s? )? )? \s+ (?=\S+) /xi,

            list_el =>
            qr/^ l (?:ist)? \s* e (?:l (?:ement s?)? )? \s+ (?=\S+) /xi,

            type    => qr/^ t (?: ype )? \s+ (?=\S+) /xi,

            default
            => qr/^ d (?: efault )? (?: \s+ value s? )? \s+ (?=\S+) /xi,

            deprecated => qr/^ de (?: precated )? \s+ (?=\S+) /xi,

            dtd => qr/^ dtd \s+ (?=\S+) /xi,

            comment => qr/^ c (?:omment s?)? \s+ (?=\S+) /xi,

            total   => qr/^ to (?:tal)? /xi,
        },
    );
}

sub _message_into_response_event { 'out' }

sub _make_response_message {
    my ( $self, $in_ref ) = @_;

    my $in = lc $in_ref->{what};

    $self->{debug}
        and carp "AttrInfo: input: `$in`";

    my $trig_ref = $self->{cmdtriggers};

    if ( $in =~ s/$trig_ref->{list_attr}// ) {
        $self->{debug}
            and carp "Attr LIST ATTRIBUTES ($in)";

        return $self->_prepare_output(
            $self->_command_get_attrs_for_el( uc $in )
        );
    }
    elsif ( $in =~ s/$trig_ref->{list_el}// ) {
        $self->{debug}
            and carp "Attr LIST ELEMENTS ($in)";

        return $self->_prepare_output(
            $self->_command_get_elements_for_attr( $in )
        );
    }
    elsif ( $in =~ s/$trig_ref->{type}// ) {
        $self->{debug}
            and carp "Attr TYPE ($in)";

        return $self->_prepare_output( $self->_command_attr_type( $in ) );
    }
    elsif ( $in =~ s/$trig_ref->{default}// ) {
        $self->{debug}
            and carp "Attr DEFAULT VALUE ($in)";

        return $self->_prepare_output(
            $self->_command_default_value( $in )
        );
    }
    elsif ( $in =~ s/$trig_ref->{deprecated}// ) {
        $self->{debug}
            and carp "Attr DEPRECATED ($in)";

        return $self->_prepare_output(
            $self->_command_is_deprecated( $in )
        );
    }
    elsif ( $in =~ s/$trig_ref->{comment}// ) {
        $self->{debug}
            and carp "Attr COMMENT ($in)";

        return $self->_prepare_output( $self->_command_comment( $in ) );
    }
    elsif ( $in =~ s/$trig_ref->{dtd}// ) {
        $self->{debug}
            and carp "Attr DTD ($in)";

        return $self->_prepare_output( $self->_command_dtd( $in ) );
    }
    elsif ( $in =~ s/$trig_ref->{total}// ) {
        $self->{debug}
            and carp "Attr TOTAL ($in)";

        return $self->_prepare_output( $self->_command_total );
    }

    return [ "Invalid command in HTML Attributes plugin" ];
}

sub _command_total {
    return "I know of " . keys( %Valid_Attrs ) . " attributes in total";
}

sub _command_comment {
    my ( $self, $attr ) = @_;

    return "Attribute $attr is not in my database"
        unless exists $Valid_Attrs{ $attr };

    my %comments;
    for ( @Attrs ) {
        if ( $_->{name} eq $attr ) {
            push @{ $comments{ $_->{comment} } },
                    @{ $_->{related_elements} };
        }
    }

    keys %comments
        or return "I don't have any comments regarding $attr attribute";

    if ( keys %comments == 1 ) {
        return "Comment for $attr is: " . (keys %comments)[0];
    }
    else {
        return "Attribute $attr has the following comments: "
            . join q|; |,
               map { "$_: [ " . join( q|, |, @{ $comments{ $_ } } ) . " ]" }
                sort keys %comments;
    }
}

sub _command_dtd {
    my ( $self, $attr ) = @_;
    $attr =~ s/\s+//g;

    return "Attribute $attr is not in my database"
        unless exists $Valid_Attrs{ $attr };

    my %dtds;
    for ( @Attrs ) {
        if ( $_->{name} eq $attr ) {
            $dtds{ $_->{dtd} } = 1;
        }
    }

    return "Attribute $attr appears in DTD: "
            . join q|, |, sort keys %dtds;
}

sub _command_is_deprecated {
    my ( $self, $attr ) = @_;
    $attr =~ s/\s+//g;

    return "Attribute $attr is not in my database"
        unless exists $Valid_Attrs{ $attr };

    my ( %deprecated_els, %not_deprecated_els );
    for ( @Attrs ) {
        next
            unless $_->{name} eq $attr;

        if ( $_->{deprecated} eq 'deprecated' ) {
            $deprecated_els{ $_ } = 1
                for @{ $_->{related_elements} };
        }
        else {
            $not_deprecated_els{ $_ } = 1
                for @{ $_->{related_elements} };
        }
    }

    if ( keys %not_deprecated_els and not keys %deprecated_els ) {
        return "Attribute $attr is NOT deprecated";
    }
    elsif ( keys %deprecated_els and not keys %not_deprecated_els ) {
        return "Attribute $attr is deprecated";
    }
    else {
        return "Attribute $attr is deprecated on element(s): "
            . join( q|, |, sort keys %deprecated_els )
            . " and NOT deprecated on element(s): "
            . join q|, |, sort keys %not_deprecated_els;
    }
}

sub _command_default_value {
    my ( $self, $attr ) = @_;
    $attr =~ s/\s+//g;

    return "Attribute $attr is not in my database"
        unless exists $Valid_Attrs{ $attr };

    my %vals;
    for ( @Attrs ) {
        if ( $_->{name} eq $attr ) {
            push @{ $vals{ $_->{default_value} } },
                    @{ $_->{related_elements} };
        }
    }

    if ( keys %vals == 1 ) {
        return "Attribute $attr\'s default value is " . (%vals)[0];
    }
    else {
        return "Attribute $attr\'s default values are: " .
                join q|; |,
                    map { "$_ [ " . join( q|, |, @{ $vals{ $_ } } ) . " ]" }
                        sort keys %vals;
    }
}

sub _command_attr_type {
    my ( $self, $attr ) = @_;
    $attr =~ s/\s+//g;

    return "Attribute $attr is not in my database"
        unless exists $Valid_Attrs{ $attr };


    my %types;
    for ( @Attrs ) {
        if ( $_->{name} eq $attr ) {
            $types{ $_->{type} } = 1;
        }
    }

    return "Attribute $attr\'s value is of type: "
            . join q|, |, sort keys %types;
}

sub _command_get_elements_for_attr {
    my ( $self, $attr ) = @_;
    $attr =~ s/\s+//g;

    return "Attribute $attr is not in my database"
        unless exists $Valid_Attrs{ $attr };

    my %els;
    for ( @Attrs ) {
        next
            unless $_->{name} eq $attr;

        my @attr_els = @{ $_->{related_elements} };
        @els{ @attr_els } = (1) x @attr_els;
    }

    return "Attribute $attr does not seem to apply to any elements"
        unless keys %els;

    return "Attribute $attr applies to elements: "
            . join q|, |, sort keys %els;
}

sub _command_get_attrs_for_el {
    my ( $self, $el ) = @_;
    $el =~ s/\s+//g;

    my %attrs;
    for my $bit ( @Attrs ) {
        for ( @{ $bit->{related_elements} } ) {
            $attrs{ $bit->{name} } = 1
                if $_ eq $el;
        }
    }

    return "Element $el does not have any attributes"
        unless keys %attrs;

    return "Element $el has the following attributes: "
            . join q|, |, sort keys %attrs;
}

sub _prepare_output {
    my ( $self, $out ) = @_;
    return
        unless defined $out;

    my @out;
    my $length = $self->{line_length};
    while ( length $out > $length ) {
        push @out, substr $out, 0, $length;
        $out = substr $out, $length;
    }
    return [ @out, $out ];
}

1;
__END__

=encoding utf8

=for stopwords bot cmdtriggers privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::HTML::AttributeInfo - HTML attribute info lookup from IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::HTML::AttributeInfo);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'HTMLAttrBot',
        server      => '127.0.0.1',
        port        => 6667,
        ircname     => 'HTML Attributes Lookup Bot',
        plugin_debug => 1,
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start  irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'HTMLAttributeInfo' =>
                POE::Component::IRC::Plugin::HTML::AttributeInfo->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }


    <Zoffix> HTMLAttrBot, attr list attributes table
    <HTMLAttrBot> Element TABLE has the following attributes: align,
                  bgcolor, border, cellpadding, cellspacing, class, dir,
                  frame, id, lang, onclick, ondblclick, onkeydown,
                  onkeypress, onkeyup, onmousedown, onmousemove,
                  onmouseout, onmouseover, onmouseup, rules, style,
                  summary, title, width

    <Zoffix> HTMLAttrBot, attr list elements cellspacing
    <HTMLAttrBot> Attribute cellspacing applies to elements: TABLE

    <Zoffix> HTMLAttrBot, attr type class
    <HTMLAttrBot> Attribute class's value is of type: CDATA

    <Zoffix> HTMLAttrBot, attr default width
    <HTMLAttrBot> Attribute width's default values are: #IMPLIED [ HR,
                  IFRAME, IMG, OBJECT, TABLE, TD, TH, COL, COLGROUP, PRE ];
                  #REQUIRED [ APPLET ]

    <Zoffix> HTMLAttrBot, attr deprecated width
    <HTMLAttrBot> Attribute width is deprecated on element(s): APPLET, HR,
                  PRE, TD, TH and NOT deprecated on element(s): COL,
                  COLGROUP, IFRAME, IMG, OBJECT, TABLE

    <Zoffix> HTMLAttrBot, attr dtd style
    <HTMLAttrBot> Attribute style appears in DTD: HTML 4.01 Strict

    <Zoffix> HTMLAttrBot, attr comment style
    <HTMLAttrBot> Comment for style is: associated style info

    <Zoffix> HTMLAttrBot, attr comment name
    <HTMLAttrBot> Attribute name has the following comments: N/A: [ BUTTON,
                  TEXTAREA ]; allows applets to find each other: [ APPLET
                  ]; field name: [ SELECT ]; for reference by usemap: [ MAP
                  ]; metainformation name: [ META ]; name of form for
                  scripting: [ FORM ]; name of frame for targetting: [
                  FRAME, IFRAME ]; name of image for scripting: [ IMG ];
                  named link end: [
    <HTMLAttrBot> A ]; property name: [ PARAM ]; submit as part of form: [
                  INPUT, OBJECT ]

    <Zoffix> HTMLAttrBot, attr total
    <HTMLAttrBot> I know of 119 attributes in total

    <Zoffix> HTMLAttrBot, attr blah
    <HTMLAttrBot> Invalid command in HTML Attributes plugin

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
to lookup information regarding HTML element attributes.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

The functionality and arguments for each of plugin's command is described
in section about C<cmdtriggers> constructor's argument.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'HTMLAttributeInfo' =>
            POE::Component::IRC::Plugin::HTML::AttributeInfo->new
    );

    # juicy flavor
    $irc->plugin_add(
        'HTMLAttributeInfo' =>
            POE::Component::IRC::Plugin::HTML::AttributeInfo->new(
                auto             => 1,
                response_event   => 'irc_html_attribute',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                line_length      => 350,
                trigger          => qr/^attr\s+(?=\S+)/i,
                cmdtriggers         => {
                    list_attr   => qr/^ l (?:ist)? \s* a (?:ttr (?:ibute s? )? )? \s+ (?=\S+) /xi,
                    list_el     => qr/^ l (?:ist)? \s* e (?:l (?:ements?)? )? \s+ (?=\S+) /xi,
                    type        => qr/^ t (?: ype )? \s+ (?=\S+) /xi,
                    default     => qr/^ d (?: efault )? (?: \s+ values? )? \s+ (?=\S+) /xi,
                    deprecated  => qr/^ de (?: precated )? \s+ (?=\S+) /xi,
                    dtd         => qr/^ dtd \s+ (?=\S+) /xi,
                    comment     => qr/^ c (?:omment s?)? \s+ (?=\S+) /xi,
                    total       => qr/^ to (?:tal)? /xi,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::HTML::AttributeInfo> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. B<Note:> you
can change all these arguments dynamically by accessing your plugin
object as a hashref; in other words, if you want to ban a user on
the fly you can do:
C<< push @{ $your_plugin_object->{banned} }, qr/\Quser!mask@foos.com/; >> .
The possible arguments/values are as follows:

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

=head3 C<response_event>

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_html_attribute>

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

=head3 C<line_length>

    ->new( line_length => 350, );

B<Optional>. Some commands emit quite a lot of output. The plugin will
split the output into several messages if the length of the output is
more than C<line_length> characters. B<Defaults to:> C<350>

=head3 C<trigger>

    ->new( trigger => qr/^attr\s+(?=\S+)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^attr\s+(?=\S+)/i>

=head3 C<cmdtriggers>

    cmdtriggers         => {
        list_attr   => qr/^ l (?:ist)? \s* a (?:ttr (?:ibute s? )? )? \s+ (?=\S+) /xi,
        list_el     => qr/^ l (?:ist)? \s* e (?:l (?:ement s?)? )? \s+ (?=\S+) /xi,
        type        => qr/^ t (?: ype )? \s+ (?=\S+) /xi,
        default     => qr/^ d (?: efault )? (?: \s+ value s? )? \s+ (?=\S+) /xi,
        deprecated  => qr/^ de (?: precated )? \s+ (?=\S+) /xi,
        dtd         => qr/^ dtd \s+ (?=\S+) /xi,
        comment     => qr/^ c (?:omment s?)? \s+ (?=\S+) /xi,
        total       => qr/^ to (?:tal)? /xi,
    },

B<Optional>. After the C<trigger> (see above) is stripped the plugin will
match the input on command regexes specified via C<cmdtriggers> (note the
plural form) argument; if none match the user will be informed about
using an invalid command to the plugin.
The C<cmdtriggers> argument takes a hashref as a value;
keys of that hashref are command names and values are regexes
(C<qr//>) which trigger the command.
B<Note:> anything matching the regex will be stripped from
the input so make sure it doesn't match actual data. B<Note 2:> if you are
redefining the cmdtriggers you must specify entire hashref. The possible
keys/values are as follows:

=head4 C<list_attr>

    { list_attr => qr/^ l (?:ist)? \s* a (?:ttr (?:ibute s? )? )? \s+ (?=\S+) /xi, }

    <Zoffix> HTMLAttrBot, attr list attributes table
    <HTMLAttrBot> Element TABLE has the following attributes: align,
                  bgcolor, border, cellpadding, cellspacing, class, dir,
                  frame, id, lang, onclick, ondblclick, onkeydown,
                  onkeypress, onkeyup, onmousedown, onmousemove,
                  onmouseout, onmouseover, onmouseup, rules, style,
                  summary, title, width

The C<list_attr> command lists all the attributes which the given element
may have.
B<Trigger defaults to:> C<< qr/^ l (?:ist)? \s* a (?:ttr (?:ibute s? )? )? \s+ (?=\S+) /xi >>

=head4 C<list_el>

    { list_el => qr/^ l (?:ist)? \s* e (?:l (?:ement s?)? )? \s+ (?=\S+) /xi, }

    <Zoffix> HTMLAttrBot, attr list elements cellspacing
    <HTMLAttrBot> Attribute cellspacing applies to elements: TABLE

The C<list_el> command lists all the elements to which given attribute
applies. B<Trigger defaults to:> C<< qr/^ l (?:ist)? \s* e (?:l (?:ement s?)? )? \s+ (?=\S+) /xi >>

=head4 C<type>

    { type => qr/^ t (?: ype )? \s+ (?=\S+) /xi, }

    <Zoffix> HTMLAttrBot, attr type class
    <HTMLAttrBot> Attribute class's value is of type: CDATA

The C<type> command lists the type of values the given attribute may have.
B<Trigger defaults to:> C<< qr/^ t (?: ype )? \s+ (?=\S+) /xi >>

=head4 C<default>

    { default => qr/^ d (?: efault )? (?: \s+ value s? )? \s+ (?=\S+) /xi, }

    <Zoffix> HTMLAttrBot, attr default width
    <HTMLAttrBot> Attribute width's default values are: #IMPLIED [ HR,
                  IFRAME, IMG, OBJECT, TABLE, TD, TH, COL, COLGROUP, PRE ];
                  #REQUIRED [ APPLET ]

The C<default> command list possible default values for the given attribute.
B<Trigger defaults to:> C<< qr/^ d (?: efault )? (?: \s+ value s? )? \s+ (?=\S+) /xi >>

=head4 C<deprecated>

    { deprecated => qr/^ de (?: precated )? \s+ (?=\S+) /xi, }

    <Zoffix> HTMLAttrBot, attr deprecated width
    <HTMLAttrBot> Attribute width is deprecated on element(s): APPLET, HR,
                  PRE, TD, TH and NOT deprecated on element(s): COL,
                  COLGROUP, IFRAME, IMG, OBJECT, TABLE

The C<deprecated> command tells whether or not the given attribute is
deprecated. B<Trigger defaults to:>
C<< qr/^ de (?: precated )? \s+ (?=\S+) /xi >>

=head4 C<dtd>

    { dtd => qr/^ dtd \s+ (?=\S+) /xi, }

    <Zoffix> HTMLAttrBot, attr dtd style
    <HTMLAttrBot> Attribute style appears in DTD: HTML 4.01 Strict

The C<dtd> command lists the DTDs (Document Type Definitions) under which
the given attribute is defined.
B<Trigger defaults to:> C<< qr/^ dtd \s+ (?=\S+) /xi >>

=head4 C<comment>

    { comment => qr/^ c (?:omment s?)? \s+ (?=\S+) /xi, }

    <Zoffix> HTMLAttrBot, attr comment style
    <HTMLAttrBot> Comment for style is: associated style info

    <Zoffix> HTMLAttrBot, attr comment name
    <HTMLAttrBot> Attribute name has the following comments: N/A: [ BUTTON,
                  TEXTAREA ]; allows applets to find each other: [ APPLET
                  ]; field name: [ SELECT ]; for reference by usemap: [ MAP
                  ]; metainformation name: [ META ]; name of form for
                  scripting: [ FORM ]; name of frame for targetting: [
                  FRAME, IFRAME ]; name of image for scripting: [ IMG ];
                  named link end: [
    <HTMLAttrBot> A ]; property name: [ PARAM ]; submit as part of form: [
                  INPUT, OBJECT ]

The C<comment> command lists the "comments" for the given attribute.
B<Trigger defaults to:> C<< qr/^ c (?:omment s?)? \s+ (?=\S+) /xi >>

=head4 C<total>

    { total => qr/^ to (?:tal)? /xi, }

    <Zoffix> HTMLAttrBot, attr total
    <HTMLAttrBot> I know of 119 attributes in total

The C<total> command doesn't do much; it does not take any input and only
lists the number of attributes which are known to the plugin.
B<Trigger defaults to:> C<< qr/^ to (?:tal)? /xi >>

=head3 C<addressed>

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig dtd title>.
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
            'Attribute width is deprecated on element(s): APPLET, HR, PRE,
            TD, TH and NOT deprecated on element(s): COL, COLGROUP, IFRAME,
            IMG, OBJECT, TABLE'
        ],
        'who' => 'Zoffix!Zoffix@irc.zoffix.com',
        'what' => 'de width',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'HTMLAttrBot, attr de width'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_html_attribute>) will receive input
every time request is completed. The input will come in C<$_[ARG0]> in
a form of a hashref. The possible keys/values of that hashref are as
follows:

=head3 C<out>

    {
        'out' => [
            'Attribute width is deprecated on element(s): APPLET, HR, PRE,
            TD, TH and NOT deprecated on element(s): COL, COLGROUP, IFRAME,
            IMG, OBJECT, TABLE'
        ],
    }

The C<out> key will contain an arrayref which represents plugin's response
(this is what you'd see as a message when C<auto> option in constructor is
on). This arrayref will contain several elements if the length of output
is longer than C<line_length> characters (see CONSTRUCTOR section).

=head3 C<who>

    { 'who' => 'Zoffix!Zoffix@irc.zoffix.com', }

The C<who> key will contain the usermask of the user who made the request.

=head3 C<what>

    { 'what' => 'de width', }

The C<what> key will contain user's message after C<trigger> was stripped
but before any of the C<cmdtriggers> are stripped (see CONSTRUCTOR for
description of C<trigger> and C<cmdtriggers> arguments)

=head3 C<message>

    { 'message' => 'HTMLAttrBot, attr de width' }

The C<message> key will contain user's full message (before any cmdtriggers
are stripped).

=head3 C<type>

    { 'type' => 'public', }

The C<type> key will contain the "type" of the message sent by the
requester. The possible values are: C<public>, C<notice> and C<privmsg>
indicating that request was requested in public channel, via C</notice>
and via C</msg> (private message) respectively.

=head3 C<channel>

    { 'channel' => '#zofbot', }

The C<channel> key will contain the name of the channel from which the
request
came. This will only make sense when C<type> key (see above) contains
C<public>.

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

