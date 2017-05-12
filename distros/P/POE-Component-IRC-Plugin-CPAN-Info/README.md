# NAME

POE::Component::IRC::Plugin::CPAN::Info - PoCo::IRC plugin for accessing
information about CPAN modules, distributions and authors.

# SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC Component::IRC::Plugin::CPAN::Info);

    my @Channels = ( '#zofbot' );

    my $irc = POE::Component::IRC->spawn(
            nick    => 'CPANInfoBot',
            server  => 'irc.freenode.net',
            port    => 6667,
            ircname => 'CPAN module information bot',
    ) or die "Oh noes :( $!";

    POE::Session->create(
        package_states => [
            main => [ qw( _start irc_001 ) ],
        ],
    );

    $poe_kernel->run();

    sub _start {
        $irc->yield( register => 'all' );

        # register our plugin
        $irc->plugin_add(
            'CPANInfo' => POE::Component::IRC::Plugin::CPAN::Info->new
        );

        $irc->yield( connect => { } );
        undef;
    }

    sub irc_001 {
        my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
        $kernel->post( $sender => join => $_ )
            for @Channels;
        undef;
    }

# FYI

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

After years of hiatus, I returned to this module and see that "freshen"
(update of info) doesn't always succeed in the example code. This means
that if the database was never created yet, the bot will be saying
_No idea_ for all queries, until the database is updated.

I haven't much interest in making a sane fix for this at the moment, so
I'm just going to put this note here :) Turn on `<debug =` 1 >> on the
plugin and if you don't see `got_info` success, then just restart
the bot, for the database to be built (it might take a couple of minutes).

<div>
    </div></div>
</div>

# DESCRIPTION

The module is a [POE::Component::IRC](https://metacpan.org/pod/POE::Component::IRC) plugin which uses
[POE::Component::IRC::Plugin](https://metacpan.org/pod/POE::Component::IRC::Plugin) for easy addon of the module.

The module provides interface for querying information about CPAN authors,
(e.g. full name and email address), modules (e.g. version and
description) and distributions (e.g. list of modules the distribution
contains and author of the distribution).

# DEFAULT COMMANDS

With default settings the plugin will respond to the following commands
which are either sent by addressing the "bot", /notice'ing the "bot"
or /msg'ing the "bot".

    auth_email      # Author's e-mail address
    auth_name       # Author's full name

    mod_distname    # Which distribution the module is in
    mod_version     # Module's version
    mod_desc        # Module's description
    mod_chapter     # Module's chapter
    mod_dslip       # Module's DSLIP code.

    dist_version    # Distribution's version
    dist_file       # Distribution's CPAN filename
    dist_auth       # Distribution's author
    dist_desc       # Distribution's description
    dist_mods       # List modules included in the distribution
    dist_chapter    # Chapter and subchapter of the distribution

    help            # lists available help system commands
                    # which can be triggered by using 'help $command'

    help auth_email
    help auth_name  # and so on with all of the above commands.

Example:

    <Zoffix> CPANInfoBot, dist_auth WWW-Search-Mininova
    <CPANInfoBot> Zoffix, ZOFFIX

Before I continue, if you are planing to reconfigure those commands
(which I call triggers) I want you to glance at the command list above, at
their names in particular. Every command is in the form `foo_bar` where
`foo` is the "category" of the command and `bar` is the command name,
of course nothing is stopping you from making the trigger to be `foobar`
but the reason I am telling you this is because the commands above also
indicate the "category" (the part before `_`) and the command (the
part after `_`) in
the `trigers` hashref.
Thus to change trigger for `mod_desc` command to `mod_description`
you would specify

    ->new( triggers => { mod => { desc => qr/^description\s+/i } } );

But I am getting ahead of myself.. more on this later.

# CONSTRUCTOR

    # "Vanilla" plugin
    $irc->plugin_add(
        'CPANInfo' => POE::Component::IRC::Plugin::CPAN::Info->new
    );

    # the "Juicy Options" flavor
    my $cpan_info_plugin = POE::Component::IRC::Plugin::CPAN::Info->new(
        mirror              => 'http://cpan.perl.org/',
        path                => 'cpan_sqlite_info',
        freshen_interval    => 43200,
        send_events         => 1,
        got_info_event      => 'cpaninfo_got_info',
        no_result_event     => 'cpaninfo_no_result',
        response_event      => 'cpaninfo_response',
        respond_no_result   => 1,
        no_result_responses => [ 'No clue', 'No idea' ],
        show_help           => 1,
        listen_for_help     => [ qw(public notice privmsg) ],
        listen_for_input    => [ qw(public notice privmsg) ],
        max_modules_limit   => 10,
        max_modules_length  => 300,
        max_output_length   => 600,
        output_line_length  => 300,
        debug       => 1,
        triggers    => {
            dist_cat => qr/(?=.)/, # no dist_cat regex
            dist => {
                auth => qr/^author\s+/i,
            },
            mod_cat => qr/^mod(?:|ule)?_?/i,
            auth_cat => qr/^auth(?:or)?_?/i,
            auth => {
                email => qr/^(?:e-|e)?mail\s+/i,
            },
        },
        help => {
            help_re => qr/^cpan_help\s+/i,
            dist_cat => 'd',
            dist => {
                auth => 'author',
            }
            mod_cat => 'm',
            auth_cat => '',
        },
        ua_args => {
            timeout => 50,
            agent   => 'CpanInfoPoco',
        },
    );
    $irc->plugin_add( 'CPANInfo' => $cpan_info_plugin );

The constructor returns an object suitable to be fed to
[POE::Component::IRC](https://metacpan.org/pod/POE::Component::IRC)'s `plugin_add()` method. It may take a lot of
arguments, luckily all of them are optional with sensible defaults. The
possible options are as follows:

## mirror

    POE::Component::CPAN::SQLite::Info->spawn( mirror => 'http://cpan.org' );

The component needs three files from CPAN mirrors, and
it fetches those automatically, namely those are

    $CPAN/modules/03modlist.data.gz
    $CPAN/modules/02packages.details.txt.gz
    $CPAN/authors/01mailrc.txt.gz.

The `mirror` argument specifies what CPAN mirror to get those files
from. __Defaults to:__ `http://cpan.perl.org`

## path

    ->new( path => '/tmp' );

When component fetches the needed files it
will mirror them locally. By specifying the `path` argument you can
tell the component where to store those. The component will create
two directories inside the one you've specified, namely 'authors' and
'modules'. This argument __defaults to__ `'cpan_sqlite_info'` directory
inside the current directory.

## freshen\_interval

    ->new( freshen_interval    => 43200 );

The `freshen_interval` specifies (in seconds) how often should the
component retrieve a fresh copy of CPAN files (described in `mirror`
option above). If an error occurred during fetching of the files, the
component will _retry_ in `freshen_interval` or 30 seconds, whichever
is sooner.
__Defaults to:__ `43200` (half a day)

## send\_events

    ->new( send_events => 1 );

Specifies whether or not the component should emit any events which
are described below. When set to a true value the plugin will
emit the events, otherwise won't. Technically, it is possible to disable any
native plugin output (see `listen_for_input` argument below) and respond
only by listening to the events it sends. __Defaults to:__ `1`

## got\_info\_event

    ->new( got_info_event      => 'cpaninfo_got_info' );

Upon successful retrieval of the files and successful processing of those
the component will emit the event specified by `got_info_event` argument.
The handler will receive the output of Perl's `time()` function as
the only argument of `ARG0` which will indicate the time at which
the event was sent. Generally, on slow boxes the processing of the files
can take some time (it's all non-blocking, don't worry) thus if you
are just starting the component, it won't have data readily available
until you receive the first `got_info_event`. __Defaults to:__
`cpaninfo_got_info`

## no\_result\_event

    ->new( no_result_event     => 'cpaninfo_no_result' );

When plugin will see a matching command, but doesn't have any data
available for the request (e.g. calling `mod_desc` on non-existent
module) the plugin will send the event specified by `no_result_event`
argument. __Defaults to:__ `cpaninfo_no_result`

## response\_event

    ->new( response_event      => 'cpaninfo_response' );

When plugin will have a response ready (e.g. response to the request
about some module's author), the event specified by `response_event`
will be sent out. __Defaults to:__ `cpaninfo_response`

## respond\_no\_result

    ->new( respond_no_result => 0 );

If a trigger for a particular command matched (see `triggers` below)
but there wasn't any information available for the request the component
may respond with a predefined "no clue" response (see
`no_result_responses` below) or be quiet. When `respond_no_result`
is set to a false value, the component will not respond when the
requested information is missing, otherwise it will randomly choose one
of the `no_result_responses` (see below) and reply with that. _Note:_
this doesn't affect the cases when triggers (see `triggers` below)
don't match, it only affects the cases when a particular command matched
but data is not available such as asking for a version of a non-existent
module. __Defaults to:__ `1`

## no\_result\_responses

    ->new( no_result_responses => [ 'No clue', 'No idea', 'Waddayawant?' ] );

If the trigger for a command matched (see `triggers` below) but the
data is not available (e.g. asking for a version of a non-existent module)
and `respond_no_result` option (see above) is set to a _true value_.
The component will respond with one of the randomly chosen responses.
Those responses are defined by the `no_result_responses` argument
which takes an arrayref of possible responses. __Defaults to:__
`[ 'No clue', 'No idea' ]`

## show\_help

    ->new( show_help => 1 )

The plugin has a built in "help system" to refresh the memory about
available commands (no, you don't actually have to keep this doc open
all the time :) ). The details are explained in HELP MESSAGES section.
The `show_help` key to the constructor enables or disables the help
system. When `show_help` argument is set to a true value, plugin
will respond to help inquiries, otherwise the help system will be off.
__Defaults to:__ `1`

## listen\_for\_help

    ->new( listen_for_help     => [ qw(public notice privmsg) ] );

Plugin listens for three types of messages: public messages that appear
in the channel (although it makes sure that those messages prefixed with
your bot's nick), /notice messages and /msg (`privmsg`) messages.
The details are explained in HELP MESSAGES section.
The `listen_for_help` argument _takes an arrayref_ which tell it
which of those three types of messages to return the help for (if asked).
The message types are as follows:

- public

    Public messages from channels with bot's nick prepended:

        <Zoffix> CPANInfoBot, auth_name Zoffix
        <CPANInfoBot> Zoffix, Zoffix Znet

- notice

    Messages sent via /notice

- privmsg

    Messages set via private messages ( /msg )

In other words, if you want your users to use help only via /notice'ing
and /msg'ing you'd specify:

    ->new( listen_for_help     => [ qw(notice privmsg) ] );

## listen\_for\_input

    ->new( listen_for_input    => [ qw(public notice privmsg) ] );

Same as `listen_for_help` (see right above). Except this one controls
global "listening". In other words if you did something along the lines of:

    ->new(
        listen_for_input => [ qw(public)         ],
        listen_for_help  => [ qw(notice privmsg) ],
    );

Your users would be able to use plugin's commands in the channel but
would __NOT__ be able to use help at all, because the plugin
would ignore `qw(notice privmsg)` messages sent to it because
`listen_for_input` doesn't contain those elements.

On the contrary:

    ->new(
        listen_for_input => [ qw(public notice privmsg) ],
        listen_for_help  => [ qw(notice privmsg)        ],
    );

Would allow the users to use the bot in the channel, via /notice and /msg
but the help would be available only via /notice and /msg.

## max\_modules\_limit

    ->new( max_modules_limit   => 5 );

The `dist_mods` command lists all the modules included in the
distribution. As you can probably imagine, some dists contain enough
modules to spam the channel any day with this command. The two
arguments, `max_modules_limit` and `max_modules_length` (see below)
can help you deal with that. The `max_modules_limit` takes a scalar
as an argument and acts in the following
way: if the distribution contains more than `max_modules_limit`,
_do NOT_ list them, but instead respond with `Uses $that_many modules...`.
If the distribution contains less than `max_modules_limit` modules
in it, respond with list of their names. Yes, you may set
`max_modules_limit` to `0` and have the component always respond
with the quantity. Alternatively, you may set it to a large value
and set `max_modules_length` (see below) to chop the long lists
__Defaults to:__ `5`

## max\_modules\_length

    ->new( max_modules_length  => 300 );

Along with `max_modules_limit` (see above) you can specify the maximum
length of the `dist_mods` output. If the output exceeds
`max_modules_length` characters in length it will be chopped off and
the total number of modules in the distribution will be prepended.
__Defaults to:__ `300`

## max\_output\_length

    ->new( max_output_length => 600 );

This argument controls the maximum length of the output, but see
also `max_output_length_pub` argument below. If any output
is longer than `max_output_length` characters it will be chopped off
with `...` appended. _Note:_ if this argument is set
to a lower value than `max_modules_length` (see above), then output from
`dist_mods` will be chopped up to `max_output_length` (kind of an
"override"). __Defaults to:__ `600`

## max\_output\_length\_pub

    ->new( max_output_length_pub => 400 );

This argument is the same as `max_output_length` (see right above)
with the exception that it applies _only to public messages_ (i.e.
the output to public channels). Thus, you might want to set lower
output length for channel output as there are more people and flooding
the channel is not nice, but allow longer messages to /notice and /msg
requests with `max_output_length` argument. __Defaults to:__ `400`

## output\_line\_length

    ->new( output_line_length  => 300 );

The `output_line_length` argument controls the number of characters
per line of the output, in other words, if you the plugin about to
output 500 character message, but `output_line_length` is set to `300`
the plugin will break the output up into two messages and send one
300 character message followed by a 200 character message. This argument
ensures your bot will not be dropped from the network for `"Excess Flood"`.
__Defaults to:__ `300`

## banned

    ->new( banned => [ qr/\Q*!*\@spammer.com/, qr/^Spammer/i ] );

Takes an arrayref of regex references. Any user who's mask matches
any of the regexes specified in `banned` argument will be ignored
by the plugin.

## debug

    ->new( debug => 1 );

When `debug` argument is set to a true value plugin will print out
a bit of debugging information. __Defaults to:__ `0`

## triggers

    ->new (
        triggers    => {
            dist_cat => qr/(?=.)/, # no dist_cat regex
            dist => {
                auth => qr/^author\s+/i,
            },
            mod_cat => qr/^mod(?:|ule)?_?/i,
            auth_cat => qr/^auth(?:or)?_?/i,
            auth => {
                email => qr/^(?:e-|e)?mail\s+/i,
            },
            help_re => qr/^cpan_help\s+/i,
        }
    );

Takes an hashref as an argument. See TRIGGERS section below for information.

## help

    ->new(
        help => {
            dist_cat => 'd',
            dist => {
                auth => 'author',
            }
            mod_cat => 'm',
            auth_cat => '',
        },
    );

Takes a hasref as an argument. See HELP MESSAGES section below for
information.

## ua\_args

    ->new(
        ua_args => {
            timeout => 50,
            agent   => 'CpanInfoPoco',
        },
    );

Takes a hashref of arguments, those will be passed to [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)'s
constructor. __Defaults to:__ whatever [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)'s constructor
defaults are, __except__ `timeout` which defaults to `30`.

# TRIGGERS

The output of the plugin is triggered. Even though all those triggers
have defaults you can change each and everyone you like (or don't like
in this case :) ).

Triggers are broken down into three categories:
`dist`, `mod` and `auth` which are for distribution related commands,
module related commands and author related commands respectively.
When the category trigger is matched, it is __removed from the input__
and attempt to match command trigger is made. This means that if
you want your trigger for `dist_mods` command to be `dist_modules`
You'd set the _command trigger_ to be `qr/^modules/;` because
by default the category trigger is `qr/^dist_/i`, which will be removed.
The idea of category triggers is to save some typing if you are setting
up a lot of triggers yourself. In case you want each _command_ trigger
to differ that much you should set _category_ trigger to `qr/(?=.)/`
which will match all the time (proving we have input). Why not an
empty `qr//`? Read [perlop](https://metacpan.org/pod/perlop)

When changing triggers, keep in mind that there is a built in help
system (see HELP MESSAGES section below) which you will need to change
as well because it will tell the users about default triggers
not the ones you've set up.

The following hashref is what the constructor's `triggers` argument takes,
it represents default triggers set up on the plugin. If you want
to change only one trigger just specify it as
`->new( triggers =` { mod => { desc => qr/^description\\s+/i } } );
no need to repeat every trigger, the rest will be left at the defaults.

    {
        mod_cat  => qr/ ^ mod_ /xi,
        mod      => {
            distname    => qr/ ^ distname \s+ /xi,
            version     => qr/ ^ version  \s+ /xi,
            desc        => qr/ ^ desc     \s+ /xi,
            chapter     => qr/ ^ chapter  \s+ /xi,
            dslip       => qr/ ^ dslip    \s+ /xi,
        },

        auth_cat  => qr/ ^auth_ /xi,
        auth     => {
            email       => qr/ ^ email    \s+ /xi,
            name        => qr/ ^ name     \s+ /xi,
        },

        dist_cat => qr/ ^ dist_ /xi,
        dist     => {
            version     => qr/ ^ version  \s+ /xi,
            file        => qr/ ^ file     \s+ /xi,
            auth        => qr/ ^ auth     \s+ /xi,
            desc        => qr/ ^ desc     \s+ /xi,
            mods        => qr/ ^ mods     \s+ /xi,
            chapter     => qr/ ^ chapter  \s+ /xi,
        },
    };

# HELP MESSAGES

The component has a built in help system (which is can be disabled).
The hashref presented below is what the constructor's `help`
argument takes,
it represents default triggers set up on the plugin. If you want
to change only one trigger just specify it as
`->new( triggers =` { mod => { desc => 'description' } } );
no need to repeat every trigger, the rest will be left at the defaults.
__Note:__ as opposed to `triggers` hashref, the `help` hashref
contains a bunch of strings, __NOT__ regex references.

The only key that takes a `qr//` is a `help_re`, this key determines the
help system trigger, as with other triggers (see TRIGGERS section above)
the trigger will be removed before matching against help system commands.
The commands are matched in the following fashion: if it starts
with a category prefix, remove it and see if it contains the command now.
In other words, with the default settings, message containing
`help mod_distname` would return help for plugin's `mod_distname` command
because `qr/^help\s*/i` would remove the `help ` from the beginning,
remove category prefix (`mod_cat`) which is `mod_` and match `distname`
value set for the `mod => { distname }` key. The match is performed
case _insensitively_.

If when `help_re` trigger matched and removed the input is empty
plugin will list all available commands, with will be in the form
`$mod_cat``$command`

As with triggers, `mod_cat`, `dist_cat` and
`auth_cat` values represent the category prefix to save you typing
while defining category commands. If you wish, you may set category
prefixes to an empty string and define commands with full command values.
In other words, both of these will give help for `mod_distname` command:

    ->new( help => {
            mod_cat => '',
            mod => { distname => 'mod_distname' },
        },
    );

    # these two are the same, but different effect on other help commands

    ->new( help => {
            mod_cat => 'mod_',
            mod => { distname => 'distname' },
        },
    );

Here is a hashref with the possible constructor's `help` argument's
keys and their default values.

    {
        help_re => qr/^help\s*/i,
        mod_cat => 'mod_',
        mod     => {
            distname    => 'distname',
            version     => 'version',
            desc        => 'desc',
            chapter     => 'chapter',
            dslip       => 'dslip',
        },
        auth_cat  => 'auth_',
        auth     => {
            email       => 'email',
            name        => 'name',
        },

        dist_cat => 'dist_',
        dist     => {
            version     => 'version',
            file        => 'file',
            auth        => 'auth',
            desc        => 'desc',
            mods        => 'mods',
            chapter     => 'chapter',
        },
    };

# EMITTED EVENTS

The plugin emits three different events (if enabled, and by default it is).
The names of the events may be configured with: `got_info_event`
`no_result_event` and `response_event` arguments to the constructor.

## output from got\_info\_event

The `got_info_event` event will be sent out each time the plugin
successfully parses CPAN data files. On a slow box this process may
take a while (though it's non-blocking), therefore you won't be
able to inquire the plugin about any data until you receive at least
one `got_info_event` event. The event handler will receive the output
of Perl's `time()` function in it's `ARG0` argument which will
be the time at which the event was sent.

## output from `no_result_event`

    $VAR1 = {
        'what' => 'CPAN2_, mod_version Fake',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'time' => 1202211629,
        'type' => 'public',
        'channel' => '#zofbot'
    };

The the handler for the event specified by `no_result_event`
will receive events
whenever the a particular command matches but there is no data available.
For example, when request for `mod_version` is made asking for the
version of a non-existent module.

## output from response\_event

    $VAR1 = {
        'what' => 'CPAN2_, mod_version Carp',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'response' => '1.08',
        'time' => 1202210405,
        'type' => 'public',
        'channel' => '#zofbot'
    };

The handler set up for the event specified by `respose_event` will
receive event whenever a command request was made which produced useful
output.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/POE-Component-IRC-Plugin-CPAN-Info](https://github.com/zoffixznet/POE-Component-IRC-Plugin-CPAN-Info)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/POE-Component-IRC-Plugin-CPAN-Info/issues](https://github.com/zoffixznet/POE-Component-IRC-Plugin-CPAN-Info/issues)

If you can't access GitHub, you can email your request
to `bug-POE-Component-IRC-Plugin-CPAN-Info at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
