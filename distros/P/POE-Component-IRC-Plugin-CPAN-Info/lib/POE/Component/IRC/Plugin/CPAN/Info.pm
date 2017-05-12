package POE::Component::IRC::Plugin::CPAN::Info;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use Carp;
use POE;
use POE::Component::IRC::Plugin (qw( :ALL ));
use POE::Component::CPAN::SQLite::Info;

sub new {
    my $package = shift;
    my %args = @_;
    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    # load defaults and override with user args if any
    %args = (
        mirror              => 'http://cpan.perl.org/',
        path                => 'cpan_sqlite_info',
        debug               => 0,
        freshen_interval    => 43200,
        got_info_event      => 'cpaninfo_got_info',
        no_result_event     => 'cpaninfo_no_result',
        response_event      => 'cpaninfo_response',
        respond_no_result   => 1,
        send_events         => 1,
        show_help           => 1,
        eat                 => 0,
        listen_for_help     => [ qw(public notice privmsg) ],
        listen_for_input    => [ qw(public notice privmsg) ],
        no_result_responses => [ 'No clue', 'No idea' ],
        max_modules_limit   => 5,
        max_modules_length  => 300,
        max_output_length   => 600,
        max_output_length_pub => 400,
        output_line_length  => 300,
        banned              => [],
        %args,
    );

    for my $listen_type (qw( listen_for_help  listen_for_input )) {
        $args{ $listen_type } = {
            map { lc $_ => 1 }
                @{ $args{ $listen_type } }
        };
    }

    unless ( exists $args{ua_args}{timeout} ) {
        $args{ua_args}{timeout}  = 30;
    }

    if ( exists $args{channels} and ref $args{channels} ne 'ARRAY' ) {
        carp "Argument `channels` must contain an arrayref..";
        return;
    }

    # assign default triggers to anything not specified by user.
    my $default_triggers_ref = _make_default_triggers();
    if ( exists $args{triggers} ) {

        foreach my $trigger_category (qw( mod dist auth )) {
            my $cat_triggers = $default_triggers_ref->{ $trigger_category};

            $args{triggers}{ $trigger_category } = {
                %$cat_triggers,
                %{ $args{triggers}{ $trigger_category } || {} },
            };

            my $cat_trigger = "${trigger_category}_cat";
            unless ( exists $args{triggers}{ $cat_trigger } ) {
                $args{trigger}{ $cat_trigger }
                    = $default_triggers_ref->{ $cat_trigger};
            }
        }
    }
    else {
        $args{triggers} = $default_triggers_ref;
    }

    # assign default help triggers for anything not specified by user
    my $default_help_ref     = _make_default_help_triggers();
    if ( exists $args{help} ) {
        foreach my $category (qw(mod dist auth)) {
            my $cat_help = $default_help_ref->{ $category };

            $args{help}{ $category } = {
                %$cat_help,
                %{ $args{help}{ $category } || {} },
            };

            my $cat_trigger = "${category}_cat";
            unless ( exists $args{help}{ $cat_trigger } ) {
                $args{help}{ $cat_trigger }
                    = $default_help_ref->{help}{ $cat_trigger };
            }
        }
    }
    else {
        $args{help} = $default_help_ref;
    }

    unless ( exists $args{help}{help_re} ) {
        $args{help}{help_re} = $default_help_ref->{help_re};
    }

    return bless \%args, $package;
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
                    _fetched
                    _freshen
                    _got_info
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

    $self->{poco} = POE::Component::CPAN::SQLite::Info->spawn(
        map { $_, $self->{$_} }
            qw(mirror debug path)
    );

    warn "Sending `freshen` request to PoCo::CPAN::SQLite::Info"
        if $self->{debug};

    $self->{poco}->freshen( {
            event  => '_fetched',
            ua_args => $self->{ua_args},
        }
    );
    $self->{_freshen_alarm} = $kernel->delay(
        '_freshen' => $self->{freshen_interval}
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


sub _freshen {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    $self->{poco}->freshen( {
                event  => '_fetched',
                ua_args => $self->{ua_args},
            }
    );

    $self->{_freshen_alarm} = $kernel->delay(
        '_freshen' => $self->{freshen_delay}
    );
}

sub _fetched {
    my ( $kernel, $self, $input ) = @_[ KERNEL, OBJECT, ARG0 ];

    if ( $input->{freshen_error} ) {
        if ( $self->{debug} ) {
            if ( $input->{freshen_error} eq 'fetch' ) {
                warn "Could not fetch file(s)\n";
                foreach my $file ( keys %{ $input->{freshen_errors} } ) {
                    print "\t$file  => $input->{freshen_errors}{ $file }\n";
                }
            }
            else {
                warn "Failed to create storage dir:"
                     . " $input->{freshen_error}\n";
            }
        }
        $self->{_freshen_alarm} = $kernel->delay(
            '_freshen' => $self->{freshen_interval} < 30
                        ?  $self->{freshen_interval} : 30,
        );
    }
    else {
        warn "`freshen` success sending `fetch_info` request"
            if $self->{debug};

        $self->{poco}->fetch_info( { event   => '_got_info' } );
    }
}

sub _got_info {
    my ( $self, $input ) = @_[ OBJECT, ARG0 ];

    warn "_got_info success"
        if $self->{debug};

    delete $input->{path};

    $self->{_data} = $input;

    $self->{irc}->send_event( $self->{got_info_event} => time() )
        if $self->{send_events};
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

    return PCI_EAT_NONE
        if !exists $self->{listen_for_input}{ $type }
            and !$self->{send_events};

    foreach my $ban_re ( @{ $self->{banned} || [] } ) {
        return PCI_EAT_NONE
            if $who =~ /$ban_re/;
    }

    my $my_nick = $irc->nick_name();
    my $what;
    if ( $type eq 'public' ) {
        ($what) = $message =~ m/^\s*\Q$my_nick\E[\:\,\;\.]?\s*(.*)$/i;
    }
    else {
        $what = $message;
    }

    return PCI_EAT_NONE
        unless defined $what;

    warn "Got PUBLIC input: [ who => $who, channel => $channel, "
            . "what => $what ]"
        if $self->{debug};

    my $response;

    eval { $response = $self->_parse_commands( $what ); };
    # if $@ => did not match trigger,
    # if undef $response => no data available for this request
    if ( $@ ) {
        $response = $self->_parse_help( $what )
            if $self->{help}
                and exists $self->{listen_for_help}{ $type };

        warn "_parse_command( $what ) did not match anything"
            if $self->{debug} and not defined $response;

        return PCI_EAT_NONE
            unless defined $response;
    }


    my ( $nick ) = split /!/, $who;
    unless ( defined $response ) {
        if ( $self->{respond_no_result} ) {
            my $responses_ref = $self->{no_result_responses};

            if ( $type eq 'public' ) {
                $poe_kernel->post( $irc => privmsg => $channel =>
                    "$nick, " . $responses_ref->[ rand @$responses_ref ]
                );
            }
            else {
                $poe_kernel->post( $irc => $type => $nick =>
                    $responses_ref->[ rand @$responses_ref ]
                );
            }
        }
        $self->{irc}->send_event(
            $self->{no_result_event} => {
                'time'  => time(),
                who     => $who,
                channel => $channel,
                what    => $message,
                type    => $type,
            }
        ) if $self->{send_events};

        return PCI_EAT_NONE;
    }

    warn "Got response `$response`"
        if $self->{debug};

    my $max_length = $type eq 'public'
                   ? $self->{max_output_length_pub}
                   : $self->{max_output_length    };

    if ( length $response > $max_length ) {
        $response = substr $response, 0, $max_length - 3;
        $response .= '...';
    }

    # break long output into several lines to prefed "Excess Flood" drops
    my @responses;
    while ( length $response > $self->{output_line_length} ) {
        push @responses, substr $response, 0, $self->{output_line_length};
        $response = substr $response, $self->{output_line_length};
    }
    push @responses, $response;

    if ( exists $self->{ listen_for_input }{ $type } ) {
        if ( $type eq 'public' ) {
            $poe_kernel->post( $irc => privmsg => $channel =>
                "$nick, $_"
            ) for @responses;
        }
        else {
            $poe_kernel->post( $irc => $type => $nick => $_ )
                for @responses;
        }
    }

    if ( $self->{send_events} ) {
        for ( @responses ) {
            $self->{irc}->send_event(
                $self->{response_event} => {
                    'time'   => time(),
                    who      => $who,
                    channel  => $channel,
                    what     => $message,
                    type     => $type,
                    response => $_
                }
            );
        }
    }

    return $self->{eat} ? PCI_EAT_ALL : PCI_EAT_NONE;
}

sub _parse_help {
    my ( $self, $what ) = @_;
    my $trigs = _make_default_help_triggers();

    return
        unless defined $what and $what =~ s/$trigs->{help_re}//;

    return $self->_make_help_list
        unless length $what;


    my $help_data_ref = _make_help_data();
    $what =~ s/^\s+|\s+$//g;
    $what = lc $what;
    if ( $what =~ s/^$trigs->{mod_cat}//i ) {
        return $help_data_ref->{mod}{ $what };
    }
    elsif ( $what =~ s/^$trigs->{auth_cat}//i ) {
        return $help_data_ref->{auth}{ $what };

    }
    elsif ( $what =~ s/^$trigs->{dist_cat}//i ) {
        return $help_data_ref->{dist}{ $what };
    }
    return;
}

sub _parse_commands {
    my ( $self, $what ) = @_;

    my $response;
    if ( $what =~ s/$self->{triggers}{mod_cat}// ) {
        my $triggers = $self->{triggers}{mod};

        if ( $what =~ s/$triggers->{distname}// ) {
            $response = $self->_make_info( mods => $what => 'dist_name' );
        }
        elsif ( $what =~ s/$triggers->{version}// ) {
            $response = $self->_make_info( mods => $what => 'mod_vers' );
        }
        elsif ( $what =~ s/$triggers->{desc}// ) {
            $response = $self->_make_info( mods => $what => 'mod_abs' );
        }
        elsif ( $what =~ s/$triggers->{chapter}// ) {
            $response = $self->_make_info( mods => $what => 'chapterid' );
        }
        elsif ( $what =~ s/$triggers->{dslip}// ) {
            $response = $self->_make_info( mods => $what => 'dslip' );
        }
        else {
            die;
        }
    }
    elsif ( $what =~ s/$self->{triggers}{auth_cat}// ) {
        my $triggers = $self->{triggers}{auth};

        if ( $what =~ s/$triggers->{email}// ) {
            $response = $self->_make_info(auths => uc $what => 'email' );
        }
        elsif ( $what =~ s/$triggers->{name}// ) {
            $response
                = $self->_make_info( auths => uc $what => 'fullname' );
        }
        else {
            die
        }
    }
    elsif ( $what =~ s/$self->{triggers}{dist_cat}// ) {
        my $triggers = $self->{triggers}{dist};
        if ( $what =~ s/$triggers->{version}// ) {
            $response = $self->_make_info( dists => $what => 'dist_vers');
        }
        elsif ( $what =~ s/$triggers->{file}// ) {
            $response = $self->_make_info( dists => $what => 'dist_file');
        }
        elsif ( $what =~ s/$triggers->{auth}// ) {
            $response = $self->_make_info( dists => $what => 'cpanid' );
        }
        elsif ( $what =~ s/$triggers->{desc}// ) {
            $response = $self->_make_info( dists => $what => 'dist_abs' );
        }
        elsif ( $what =~ s/$triggers->{mods}// ) {
            $response = $self->_make_info( dists => $what => 'modules' );
        }
        elsif ( $what =~ s/$triggers->{chapter}// ) {
            $response = $self->_make_info( dists => $what => 'chapterid' );
        }
        else {
            die;
        }
    }
    else {
        die;
    }
    return $response;
}

sub _make_help_list {
    my $self = shift;

    my $help_data_ref = _make_default_help_triggers();
    my @help_list;
    foreach my $category (qw( dist mod auth )) {
        my $cat_prefix = $help_data_ref->{ $category . '_cat' };
        push @help_list, join q|, |,
                        map { $cat_prefix . $_ }
                            sort keys %{ $help_data_ref->{ $category } };
    }
    return join q|, |, @help_list;
}

sub _make_info {
    my ( $self, $category, $item, $section ) = @_;
    return
        unless defined $section;

    $item =~ s/^\s+|\s+$//g;
    return
        unless length $item;

    unless ( exists $self->{_data}{ $category }{ $item } ) {
        warn "Did not find {_data}{ $category }{ $item }"
            if $self->{debug};

        return;
    }

    my $data = $self->{_data}{ $category }{ $item };


    if ( exists $data->{ $section } ) {
        if ( $category eq 'dists' ) {
            if ( $section eq 'modules' ) {
                return $self->_prepare_dist_modules( $data->{ $section } );
            }
            elsif ( $section eq 'chapterid' ) {
                return $self->_prepare_dist_chapterid($data->{ $section });
            }
        }
        return $data->{ $section };
    }
    else {
        return;
    }
}

sub _prepare_dist_modules {
    my ( $self, $modules_ref ) = @_;
    return
        unless ref $modules_ref eq 'HASH';

    my @modules = keys %$modules_ref;

    if ( @modules > $self->{max_modules_limit} ) {
        return "Uses " . @modules . " modules...";
    }
    else {
        my $mods = join ' | ', @modules;
        if ( length $mods > $self->{max_modules_length} ) {
            $mods = "(total: " . @modules . " ) $mods";
            $mods = substr $mods, 0, $self->{max_modules_length} - 3;
            $mods .= '...';
        }
        return $mods;
    }
}

sub _make_default_help_triggers {
    return {
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
}

sub _make_help_data {
    return {
        mod => {
            distname    => q|Which distribution the module is in|,
            version     => q|Module's version|,
            desc        => q|Module's description|,
            chapter     => q|Module's chapter|,
            dslip       => q|Module's DSLIP code|,
        },
        auth => {
            email       => q|Author's e-mail address|,
            name        => q|Author's full name|,
        },
        dist => {
            version     => q|Distribution's version|,
            file        => q|Distribution's CPAN filename|,
            auth        => q|Distribution's author|,
            desc        => q|Distribution's description|,
            mods        => q|List modules included in the distribution|,
            chapter     => q|Chapter and subchapter of the distribution|,
        },
    };
}

sub _make_default_triggers {
    return {
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
}

1;
__END__

=encoding utf8

=for Pod::Coverage PCI_register PCI_unregister S_msg S_notice S_public new

=for stopwords  FYI addon bot desc dists hasref privmsg

=head1 NAME

POE::Component::IRC::Plugin::CPAN::Info - PoCo::IRC plugin for accessing
information about CPAN modules, distributions and authors.

=head1 SYNOPSIS

=for test_synopsis BEGIN { die "SKIP: "; }

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

=head1 FYI

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

After years of hiatus, I returned to this module and see that "freshen"
(update of info) doesn't always succeed in the example code. This means
that if the database was never created yet, the bot will be saying
I<No idea> for all queries, until the database is updated.

I haven't much interest in making a sane fix for this at the moment, so
I'm just going to put this note here :) Turn on C<<debug => 1 >> on the
plugin and if you don't see C<got_info> success, then just restart
the bot, for the database to be built (it might take a couple of minutes).

=for html  </div></div>

=head1 DESCRIPTION

The module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for easy addon of the module.

The module provides interface for querying information about CPAN authors,
(e.g. full name and email address), modules (e.g. version and
description) and distributions (e.g. list of modules the distribution
contains and author of the distribution).

=head1 DEFAULT COMMANDS

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
their names in particular. Every command is in the form C<foo_bar> where
C<foo> is the "category" of the command and C<bar> is the command name,
of course nothing is stopping you from making the trigger to be C<foobar>
but the reason I am telling you this is because the commands above also
indicate the "category" (the part before C<_>) and the command (the
part after C<_>) in
the C<trigers> hashref.
Thus to change trigger for C<mod_desc> command to C<mod_description>
you would specify

    ->new( triggers => { mod => { desc => qr/^description\s+/i } } );

But I am getting ahead of myself.. more on this later.

=head1 CONSTRUCTOR

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
L<POE::Component::IRC>'s C<plugin_add()> method. It may take a lot of
arguments, luckily all of them are optional with sensible defaults. The
possible options are as follows:

=head2 mirror

    POE::Component::CPAN::SQLite::Info->spawn( mirror => 'http://cpan.org' );

The component needs three files from CPAN mirrors, and
it fetches those automatically, namely those are

    $CPAN/modules/03modlist.data.gz
    $CPAN/modules/02packages.details.txt.gz
    $CPAN/authors/01mailrc.txt.gz.

The C<mirror> argument specifies what CPAN mirror to get those files
from. B<Defaults to:> C<http://cpan.perl.org>

=head2 path

    ->new( path => '/tmp' );

When component fetches the needed files it
will mirror them locally. By specifying the C<path> argument you can
tell the component where to store those. The component will create
two directories inside the one you've specified, namely 'authors' and
'modules'. This argument B<defaults to> C<'cpan_sqlite_info'> directory
inside the current directory.

=head2 freshen_interval

    ->new( freshen_interval    => 43200 );

The C<freshen_interval> specifies (in seconds) how often should the
component retrieve a fresh copy of CPAN files (described in C<mirror>
option above). If an error occurred during fetching of the files, the
component will I<retry> in C<freshen_interval> or 30 seconds, whichever
is sooner.
B<Defaults to:> C<43200> (half a day)

=head2 send_events

    ->new( send_events => 1 );

Specifies whether or not the component should emit any events which
are described below. When set to a true value the plugin will
emit the events, otherwise won't. Technically, it is possible to disable any
native plugin output (see C<listen_for_input> argument below) and respond
only by listening to the events it sends. B<Defaults to:> C<1>

=head2 got_info_event

    ->new( got_info_event      => 'cpaninfo_got_info' );

Upon successful retrieval of the files and successful processing of those
the component will emit the event specified by C<got_info_event> argument.
The handler will receive the output of Perl's C<time()> function as
the only argument of C<ARG0> which will indicate the time at which
the event was sent. Generally, on slow boxes the processing of the files
can take some time (it's all non-blocking, don't worry) thus if you
are just starting the component, it won't have data readily available
until you receive the first C<got_info_event>. B<Defaults to:>
C<cpaninfo_got_info>

=head2 no_result_event

    ->new( no_result_event     => 'cpaninfo_no_result' );

When plugin will see a matching command, but doesn't have any data
available for the request (e.g. calling C<mod_desc> on non-existent
module) the plugin will send the event specified by C<no_result_event>
argument. B<Defaults to:> C<cpaninfo_no_result>

=head2 response_event

    ->new( response_event      => 'cpaninfo_response' );

When plugin will have a response ready (e.g. response to the request
about some module's author), the event specified by C<response_event>
will be sent out. B<Defaults to:> C<cpaninfo_response>

=head2 respond_no_result

    ->new( respond_no_result => 0 );

If a trigger for a particular command matched (see C<triggers> below)
but there wasn't any information available for the request the component
may respond with a predefined "no clue" response (see
C<no_result_responses> below) or be quiet. When C<respond_no_result>
is set to a false value, the component will not respond when the
requested information is missing, otherwise it will randomly choose one
of the C<no_result_responses> (see below) and reply with that. I<Note:>
this doesn't affect the cases when triggers (see C<triggers> below)
don't match, it only affects the cases when a particular command matched
but data is not available such as asking for a version of a non-existent
module. B<Defaults to:> C<1>

=head2 no_result_responses

    ->new( no_result_responses => [ 'No clue', 'No idea', 'Waddayawant?' ] );

If the trigger for a command matched (see C<triggers> below) but the
data is not available (e.g. asking for a version of a non-existent module)
and C<respond_no_result> option (see above) is set to a I<true value>.
The component will respond with one of the randomly chosen responses.
Those responses are defined by the C<no_result_responses> argument
which takes an arrayref of possible responses. B<Defaults to:>
C<[ 'No clue', 'No idea' ]>

=head2 show_help

    ->new( show_help => 1 )

The plugin has a built in "help system" to refresh the memory about
available commands (no, you don't actually have to keep this doc open
all the time :) ). The details are explained in HELP MESSAGES section.
The C<show_help> key to the constructor enables or disables the help
system. When C<show_help> argument is set to a true value, plugin
will respond to help inquiries, otherwise the help system will be off.
B<Defaults to:> C<1>

=head2 listen_for_help

    ->new( listen_for_help     => [ qw(public notice privmsg) ] );

Plugin listens for three types of messages: public messages that appear
in the channel (although it makes sure that those messages prefixed with
your bot's nick), /notice messages and /msg (C<privmsg>) messages.
The details are explained in HELP MESSAGES section.
The C<listen_for_help> argument I<takes an arrayref> which tell it
which of those three types of messages to return the help for (if asked).
The message types are as follows:

=over 10

=item public

Public messages from channels with bot's nick prepended:

    <Zoffix> CPANInfoBot, auth_name Zoffix
    <CPANInfoBot> Zoffix, Zoffix Znet

=item notice

Messages sent via /notice

=item privmsg

Messages set via private messages ( /msg )

=back

In other words, if you want your users to use help only via /notice'ing
and /msg'ing you'd specify:

    ->new( listen_for_help     => [ qw(notice privmsg) ] );

=head2 listen_for_input

    ->new( listen_for_input    => [ qw(public notice privmsg) ] );

Same as C<listen_for_help> (see right above). Except this one controls
global "listening". In other words if you did something along the lines of:

    ->new(
        listen_for_input => [ qw(public)         ],
        listen_for_help  => [ qw(notice privmsg) ],
    );

Your users would be able to use plugin's commands in the channel but
would B<NOT> be able to use help at all, because the plugin
would ignore C<qw(notice privmsg)> messages sent to it because
C<listen_for_input> doesn't contain those elements.

On the contrary:

    ->new(
        listen_for_input => [ qw(public notice privmsg) ],
        listen_for_help  => [ qw(notice privmsg)        ],
    );

Would allow the users to use the bot in the channel, via /notice and /msg
but the help would be available only via /notice and /msg.

=head2 max_modules_limit

    ->new( max_modules_limit   => 5 );

The C<dist_mods> command lists all the modules included in the
distribution. As you can probably imagine, some dists contain enough
modules to spam the channel any day with this command. The two
arguments, C<max_modules_limit> and C<max_modules_length> (see below)
can help you deal with that. The C<max_modules_limit> takes a scalar
as an argument and acts in the following
way: if the distribution contains more than C<max_modules_limit>,
I<do NOT> list them, but instead respond with C<Uses $that_many modules...>.
If the distribution contains less than C<max_modules_limit> modules
in it, respond with list of their names. Yes, you may set
C<max_modules_limit> to C<0> and have the component always respond
with the quantity. Alternatively, you may set it to a large value
and set C<max_modules_length> (see below) to chop the long lists
B<Defaults to:> C<5>

=head2 max_modules_length

    ->new( max_modules_length  => 300 );

Along with C<max_modules_limit> (see above) you can specify the maximum
length of the C<dist_mods> output. If the output exceeds
C<max_modules_length> characters in length it will be chopped off and
the total number of modules in the distribution will be prepended.
B<Defaults to:> C<300>

=head2 max_output_length

    ->new( max_output_length => 600 );

This argument controls the maximum length of the output, but see
also C<max_output_length_pub> argument below. If any output
is longer than C<max_output_length> characters it will be chopped off
with C<...> appended. I<Note:> if this argument is set
to a lower value than C<max_modules_length> (see above), then output from
C<dist_mods> will be chopped up to C<max_output_length> (kind of an
"override"). B<Defaults to:> C<600>

=head2 max_output_length_pub

    ->new( max_output_length_pub => 400 );

This argument is the same as C<max_output_length> (see right above)
with the exception that it applies I<only to public messages> (i.e.
the output to public channels). Thus, you might want to set lower
output length for channel output as there are more people and flooding
the channel is not nice, but allow longer messages to /notice and /msg
requests with C<max_output_length> argument. B<Defaults to:> C<400>

=head2 output_line_length

    ->new( output_line_length  => 300 );

The C<output_line_length> argument controls the number of characters
per line of the output, in other words, if you the plugin about to
output 500 character message, but C<output_line_length> is set to C<300>
the plugin will break the output up into two messages and send one
300 character message followed by a 200 character message. This argument
ensures your bot will not be dropped from the network for C<"Excess Flood">.
B<Defaults to:> C<300>

=head2 banned

    ->new( banned => [ qr/\Q*!*\@spammer.com/, qr/^Spammer/i ] );

Takes an arrayref of regex references. Any user who's mask matches
any of the regexes specified in C<banned> argument will be ignored
by the plugin.

=head2 debug

    ->new( debug => 1 );

When C<debug> argument is set to a true value plugin will print out
a bit of debugging information. B<Defaults to:> C<0>

=head2 triggers

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

=head2 help

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

=head2 ua_args

    ->new(
        ua_args => {
            timeout => 50,
            agent   => 'CpanInfoPoco',
        },
    );

Takes a hashref of arguments, those will be passed to L<LWP::UserAgent>'s
constructor. B<Defaults to:> whatever L<LWP::UserAgent>'s constructor
defaults are, B<except> C<timeout> which defaults to C<30>.

=head1 TRIGGERS

The output of the plugin is triggered. Even though all those triggers
have defaults you can change each and everyone you like (or don't like
in this case :) ).

Triggers are broken down into three categories:
C<dist>, C<mod> and C<auth> which are for distribution related commands,
module related commands and author related commands respectively.
When the category trigger is matched, it is B<removed from the input>
and attempt to match command trigger is made. This means that if
you want your trigger for C<dist_mods> command to be C<dist_modules>
You'd set the I<command trigger> to be C<qr/^modules/;> because
by default the category trigger is C<qr/^dist_/i>, which will be removed.
The idea of category triggers is to save some typing if you are setting
up a lot of triggers yourself. In case you want each I<command> trigger
to differ that much you should set I<category> trigger to C<qr/(?=.)/>
which will match all the time (proving we have input). Why not an
empty C<qr//>? Read L<perlop>

When changing triggers, keep in mind that there is a built in help
system (see HELP MESSAGES section below) which you will need to change
as well because it will tell the users about default triggers
not the ones you've set up.

The following hashref is what the constructor's C<triggers> argument takes,
it represents default triggers set up on the plugin. If you want
to change only one trigger just specify it as
C<-E<gt>new( triggers => { mod => { desc => qr/^description\s+/i } } );
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

=head1 HELP MESSAGES

The component has a built in help system (which is can be disabled).
The hashref presented below is what the constructor's C<help>
argument takes,
it represents default triggers set up on the plugin. If you want
to change only one trigger just specify it as
C<-E<gt>new( triggers => { mod => { desc => 'description' } } );
no need to repeat every trigger, the rest will be left at the defaults.
B<Note:> as opposed to C<triggers> hashref, the C<help> hashref
contains a bunch of strings, B<NOT> regex references.

The only key that takes a C<qr//> is a C<help_re>, this key determines the
help system trigger, as with other triggers (see TRIGGERS section above)
the trigger will be removed before matching against help system commands.
The commands are matched in the following fashion: if it starts
with a category prefix, remove it and see if it contains the command now.
In other words, with the default settings, message containing
C<help mod_distname> would return help for plugin's C<mod_distname> command
because C<qr/^help\s*/i> would remove the C<help > from the beginning,
remove category prefix (C<mod_cat>) which is C<mod_> and match C<distname>
value set for the C<mod =E<gt> { distname }> key. The match is performed
case I<insensitively>.

If when C<help_re> trigger matched and removed the input is empty
plugin will list all available commands, with will be in the form
C<$mod_cat>C<$command>

As with triggers, C<mod_cat>, C<dist_cat> and
C<auth_cat> values represent the category prefix to save you typing
while defining category commands. If you wish, you may set category
prefixes to an empty string and define commands with full command values.
In other words, both of these will give help for C<mod_distname> command:

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

Here is a hashref with the possible constructor's C<help> argument's
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

=head1 EMITTED EVENTS

The plugin emits three different events (if enabled, and by default it is).
The names of the events may be configured with: C<got_info_event>
C<no_result_event> and C<response_event> arguments to the constructor.

=head2 output from got_info_event

The C<got_info_event> event will be sent out each time the plugin
successfully parses CPAN data files. On a slow box this process may
take a while (though it's non-blocking), therefore you won't be
able to inquire the plugin about any data until you receive at least
one C<got_info_event> event. The event handler will receive the output
of Perl's C<time()> function in it's C<ARG0> argument which will
be the time at which the event was sent.

=head2 output from C<no_result_event>

    $VAR1 = {
        'what' => 'CPAN2_, mod_version Fake',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'time' => 1202211629,
        'type' => 'public',
        'channel' => '#zofbot'
    };

The the handler for the event specified by C<no_result_event>
will receive events
whenever the a particular command matches but there is no data available.
For example, when request for C<mod_version> is made asking for the
version of a non-existent module.

=head2 output from response_event

    $VAR1 = {
        'what' => 'CPAN2_, mod_version Carp',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'response' => '1.08',
        'time' => 1202210405,
        'type' => 'public',
        'channel' => '#zofbot'
    };

The handler set up for the event specified by C<respose_event> will
receive event whenever a command request was made which produced useful
output.

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-Plugin-CPAN-Info>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-Plugin-CPAN-Info/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-Plugin-CPAN-Info at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut