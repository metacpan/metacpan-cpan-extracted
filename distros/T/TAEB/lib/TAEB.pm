package TAEB;
use 5.008001;
use TAEB::Util qw/:colors tile_types item_menu/;

use TAEB::OO;

use Log::Dispatch::Null;

use TAEB::Config;
use TAEB::Display::Curses;
use TAEB::VT;
use TAEB::Logger;
use TAEB::ScreenScraper;
use TAEB::Spoilers;
use TAEB::World;
use TAEB::Senses;
use TAEB::Action;
use TAEB::Publisher;
use TAEB::Debug;

with 'TAEB::Role::Persistency';
with 'TAEB::Role::Initialize';

our $VERSION = '0.03';

class_has persistent_data => (
    is        => 'ro',
    isa       => 'HashRef',
    lazy      => 1,
    predicate => 'loaded_persistent_data',
    default   => sub {
        my $file = TAEB->persistent_file;
        return {} unless defined $file && -r $file;

        TAEB->log->main("Loading persistency data from $file.");
        return eval { Storable::retrieve($file) } || {};
    },
);

class_has interface => (
    is       => 'rw',
    isa      => 'TAEB::Interface',
    handles  => [qw/read write/],
    lazy     => 1,
    default  => sub {
        my $interface_config = TAEB->config->get_interface_config;
        TAEB->config->get_interface_class->new($interface_config);
    },
);

class_has ai => (
    is        => 'rw',
    isa       => 'TAEB::AI',
    handles   => [qw(want_item currently)],
    predicate => 'has_ai',
    lazy      => 1,
    default   => sub {
        my $ai = TAEB->config->get_ai_class->new;
        $ai->institute; # default doesn't fire triggers
        $ai;
    },
    trigger   => sub {
        my ($self, $ai) = @_;
        TAEB->log->main("Now using AI $ai.");
        $ai->institute;
    },
);

class_has scraper => (
    is       => 'ro',
    isa      => 'TAEB::ScreenScraper',
    lazy     => 1,
    default  => sub { TAEB::ScreenScraper->new },
    handles  => [qw(parsed_messages all_messages messages farlook)],
);

class_has config => (
    is       => 'ro',
    isa      => 'TAEB::Config',
    default  => sub { TAEB::Config->new },
);

class_has vt => (
    is       => 'ro',
    isa      => 'TAEB::VT',
    lazy     => 1,
    default  => sub {
        my $vt = TAEB::VT->new(cols => 80, rows => 24);
        $vt->option_set(LINEWRAP => 1);
        $vt->option_set(LFTOCRLF => 1);
        return $vt;
    },
    handles  => [qw(topline)],
);

class_has state => (
    is      => 'rw',
    isa     => 'TAEB::Type::PlayState',
    default => 'logging_in',
    trigger => sub {
        my (undef, $state) = @_;
        TAEB->log->main("Game state has changed to $state.");
    },
);

class_has log => (
    is      => 'ro',
    isa     => 'TAEB::Logger',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $log = TAEB::Logger->new;
        $log->add_as_default(Log::Dispatch::Null->new(
            name => 'taeb-warning',
            min_level => 'warning',
            max_level => 'warning',
            callbacks => sub {
                my %args = @_;
                if (!TAEB->display->to_screen) {
                    local $SIG{__WARN__};
                    warn $args{message};
                }
            },
        ));
        $log->add_as_default(Log::Dispatch::Null->new(
            name => 'taeb-error',
            min_level => 'error',
            callbacks => sub {
                my %args = @_;
                if (!TAEB->display->to_screen) {
                    local $SIG{__WARN_};
                    confess $args{message};
                }
                else {
                    TAEB->complain(Carp::shortmess($args{message}));
                }
            },
        ));
        TAEB->setup_handlers;
        return $log;
    },
);

class_has dungeon => (
    traits  => [qw/TAEB::Persistent/],
    is      => 'ro',
    isa     => 'TAEB::World::Dungeon',
    default => sub { TAEB::World::Dungeon->new },
    handles => sub {
        my ($attr, $dungeon) = @_;

        my %delegate = map { $_ => $_ }
                       qw{current_level current_tile
                          nearest_level_to nearest_level shallowest_level
                          farthest_level_from farthest_level deepest_level
                          map_like x y z fov};

        for ($dungeon->get_all_method_names) {
            $delegate{$_} = $_
                if m{
                    ^
                    (?: each | any | all | grep ) _
                    (?: orthogonal | diagonal | adjacent )
                    (?: _inclusive )?
                    $
                }x;
        }

        return %delegate;
    },
);

class_has senses => (
    traits    => [qw/TAEB::Persistent/],
    is        => 'ro',
    isa       => 'TAEB::Senses',
    default   => sub { TAEB::Senses->new },
    handles   => qr/^(?!_check_|msg_|update|initialize|config)/,
    predicate => 'has_senses',
);

class_has spells => (
    traits  => [qw/TAEB::Persistent/],
    is      => 'ro',
    isa     => 'TAEB::World::Spells',
    default => sub { TAEB::World::Spells->new },
    handles => {
        find_spell    => 'find',
        find_castable => 'find_castable',
        knows_spell   => 'knows_spell',
    },
);

class_has publisher => (
    is      => 'ro',
    isa     => 'TAEB::Publisher',
    lazy    => 1,
    default => sub { TAEB::Publisher->new },
    handles => [qw/enqueue_message get_exceptional_response get_response get_location_request remove_messages menu_select single_select/],
);

class_has action => (
    is        => 'rw',
    isa       => 'TAEB::Action',
    predicate => 'has_action',
);

class_has new_game => (
    is  => 'rw',
    isa => 'Bool',
    trigger => sub {
        my $self = shift;
        my $new = shift;

        # just in case we missed doing this last time we died
        # we might want some way to prevent all loading from the state file
        # before new_game is called to make this a bit more correct
        $self->destroy_saved_state if $new;

        # by the time we have called new_game, we know whether or not we want
        # to load the class from a state file or from defaults. so, do
        # initialization here that should be done each time the app starts.
        $self->log->main("calling initialize");
        $self->initialize;
    },
);

class_has debugger => (
    is      => 'ro',
    isa     => 'TAEB::Debug',
    default => sub { TAEB::Debug->new },
);

class_has display => (
    is      => 'ro',
    isa     => 'TAEB::Display',
    trigger => sub { shift->display->institute },
    lazy    => 1,
    default   => sub {
        my $display = TAEB->config->get_display_class->new;
        $display->institute; # default doesn't fire triggers
        $display;
    },
    handles => [qw/notify redraw display_topline get_key try_key place_cursor
                   display_menu/],
);

class_has item_pool => (
    traits  => [qw/TAEB::Persistent/],
    is      => 'ro',
    isa     => 'TAEB::World::ItemPool',
    default => sub { TAEB::World::ItemPool->new },
    handles => {
        get_artifact => 'get_artifact',
    },
);

around action => sub {
    my $orig = shift;
    my $self = shift;
    return $orig->($self) unless @_;
    TAEB->publisher->unsubscribe($self->action) if $self->action;
    my $ret = $orig->($self, @_);
    TAEB->publisher->subscribe($self->action);
    return $ret;
};

sub next_action {
    my $self = shift;

    my $action = $self->ai->next_action(@_)
        or confess $self->ai . " did not return a next_action!";

    if ($action->isa('TAEB::World::Path')) {
        return TAEB::Action::Move->new(path => $action);
    }

    return $action;
}

sub iterate {
    my $self = shift;

    eval {
        TAEB->log->main("Starting a new step.");

        $self->full_input(1);
        $self->human_input;

        my $method = "handle_" . $self->state;
        $self->$method;
    };

    if ($@) {
        TAEB->display->deinitialize;

        local $SIG{__DIE__};
        die $@ unless $@ =~ /^The\ game\ has\ ended\.
                             |The\ game\ has\ been\ saved\.
                             |The\ game\ could\ not\ start\./x;

        return TAEB->state eq 'unable_to_login'
             ? TAEB::Message::Report::CouldNotStart->new
             : TAEB->state eq 'dying'
             ? TAEB->death_report
             : TAEB::Message::Report::Saved->new;
    }

    return;
}

sub handle_playing {
    my $self = shift;

    if ($self->has_action && !$self->action->aborted) {
        $self->action->done;
        $self->publisher->send_messages;
    }

    $self->currently('?');
    $self->action($self->next_action);
    TAEB->log->main("Current action: " . $self->action);
    $self->write($self->action->run);
}

sub handle_logging_in {
    my $self = shift;

    if ($self->vt->contains("Hit space to continue: ") ||
	$self->vt->contains("Hit return to continue: ")) {
        # This message is sent by NetHack if it itself encounters an error
        # during the login process. If NetHack can't run, we can't play it,
        # so bail out.
        TAEB->log->main("NetHack itself has errored out, we can't continue.",
                        level => 'info');
        TAEB->state('unable_to_login');
        die "The game could not start.";
    }
    elsif ($self->vt->contains("Shall I pick a character's ")) {
        TAEB->log->main("We are now in NetHack, starting a new character.");
        $self->write('n');
    }
    elsif ($self->topline =~ qr/Choosing Character's Role/) {
        $self->write($self->config->get_role);
    }
    elsif ($self->topline =~ qr/Choosing Race/) {
        $self->write($self->config->get_race);
    }
    elsif ($self->topline =~ qr/Choosing Gender/) {
        $self->write($self->config->get_gender);
    }
    elsif ($self->topline =~ qr/Choosing Alignment/) {
        $self->write($self->config->get_align);
    }
    elsif ($self->topline =~ qr/Restoring save file\.\./) {
        $self->log->main("We are now in NetHack, restoring a save file.");
        $self->write(' ');
    }
    elsif ($self->topline =~ qr/, welcome( back)? to NetHack!/) {
        $self->new_game($1 ? 0 : 1);
        $self->enqueue_message('check');
        $self->enqueue_message('game_started');
        $self->state('playing');
    }
    elsif ($self->topline =~ /^\s*It is written in the Book of /) {
        TAEB->log->main("Using TAEB's nethackrc is MANDATORY. Use $0 --rc.",
                        level => 'error');
        $self->quit;
        die "Using TAEB's nethackrc is MANDATORY";
    }
}

sub full_input {
    my $self = shift;
    my $main_call = shift;

    $self->scraper->clear;

    $self->process_input;

    unless ($self->state eq 'logging_in') {
        $self->action->post_responses
            if $main_call && $self->has_action && !$self->action->aborted;

        $self->dungeon->update($main_call);
        $self->senses->update($main_call);
        $self->publisher->update($main_call);

        $self->redraw;
        $self->display_topline;
    }
}

sub process_input {
    my $self = shift;
    my $scrape = @_ ? shift : 1;

    my $input = $self->read;

    $self->vt->process($input);

    $self->scraper->scrape
        if $scrape && $self->state ne 'logging_in';

    return $input;
}

sub human_input {
    my $self = shift;

    my $c;
    $c = $self->try_key unless $self->ai->is_human_controlled;

    if (defined $c) {
        my $out = $self->keypress($c);
        if (defined $out) {
            $self->notify($out);
        }
    }
}

sub keypress {
    my $self = shift;
    my $c = shift;

    # pause for a key
    if ($c eq 'p') {
        TAEB->notify("Paused.", 0);
        TAEB->get_key;
        TAEB->redraw;
        return;
    }

    if ($c eq 'd') {
        $self->display->change_draw_mode;
        return;
    }

    if ($c eq 'i') {
        item_menu('Inventory (' . TAEB->inventory->weight . ' hzm)',
                  [TAEB->inventory]);
        return;
    }

    if ($c eq "\cP") {
        my $menu = TAEB::Display::Menu->new(
            description => "Old messages",
            items       => [ TAEB->scraper->old_messages ],
        );
        $self->display_menu($menu);

        return;
    }

    if ($c eq "\cX") {
        item_menu("Senses", TAEB->senses);
        return;
    }

    if ($c eq 'e') {
        my $eq = $self->equipment;
        my @eq = (
            map { "$_: " . ($eq->$_ ? $eq->$_->debug_line : "(none)") }
            sort { ($eq->$b ? 1 : 0) <=> ($eq->$a ? 1 : 0) }
            $eq->slots
        );

        item_menu("Equipment", \@eq);
        return;
    }

    if ($c eq 'I') {
        my $menu = TAEB::Display::Menu->new(
            description => "Item spoiler data",
            items       => [ NetHack::Item::Spoiler->all_identities ],
            select_type => 'single',
        );
        my $item = $self->display_menu($menu)
            or return;

        my $spoiler = NetHack::Item::Spoiler->spoiler_for($item);
        item_menu("Spoiler data for $item", $spoiler);

        return;
    }

    if ($c eq 't') {
        my @types = (
            grep { !TAEB->current_level->is_unregisterable($_) }
            sort { $a cmp $b }
            tile_types(),
        );

        my $type_menu = TAEB::Display::Menu->new(
            description => "Select a tile type",
            items       => \@types,
            select_type => 'single',
        );

        my $type = $self->display_menu($type_menu)
            or return;

        my @tiles = map { $_->level->debug_line . ': ' . $_->debug_line }
                    map { $_->tiles_of($type) }
                    map { @$_ }
                    @{ TAEB->dungeon->levels };

        item_menu("Tiles of type $type", \@tiles);

        return;
    }

    # user input (for emergencies only)
    if ($c eq "\e") {
        $self->write($self->get_key);
        return;
    }

    # refresh NetHack's screen
    if ($c eq 'r' || $c eq "\cr") {
        # back to normal
        TAEB->redraw(force_clear => 1);
        return;
    }

    if ($c eq 'q') {
        $self->save;
        return;
    }

    if ($c eq 'Q') {
        $self->quit;
        return;
    }

    # space is always a noncommand
    return if $c eq ' ';

    $self->enqueue_message('key' => $c);
    return;
}

around notify => sub {
    my $orig = shift;
    my $self = shift;
    my $msg  = shift;

    unshift @_, TAEB::Util::COLOR_CYAN if !@_;

    $orig->($self, $msg, @_);
};

sub complain {
    my $self = shift;
    my $msg  = shift;

    $self->notify($msg, TAEB::Util::COLOR_RED, @_);
}

around write => sub {
    my $orig = shift;
    my $self = shift;
    my $text = shift;

    return if length($text) == 0;

    $self->log->output("Sending '$text' to NetHack.");
    $orig->($self, $text);
};

# allow the user to say TAEB->ai("human") and have it DTRT
around ai => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {
        $self->ai->deinstitute
            if $self->has_ai;

        if ($_[0] =~ /^\w+$/) {
            my $name = shift;

            # guess the case unless they tell us what it is (because of
            # ScoreWhore)
            $name = "\L\u$name" if $name eq lc $name;

            $name = "TAEB::AI::$name";

            (my $file = "$name.pm") =~ s{::}{/}g;
            require $file;

            return $self->$orig($name->new);
        }
    }

    return $self->$orig(@_);
};

sub new_item {
    my $self = shift;
    my $item = $self->item_pool->new_item(@_);
    my $class = $item->meta->name;
    (my $taeb_class = $class) =~ s/^NetHack::Item/TAEB::World::Item/;
    $taeb_class->meta->rebless_instance($item);
    return $item;
}

sub inventory {
    my $self = shift;
    my $inventory = $self->item_pool->inventory;

    return $inventory->items if wantarray;
    return $inventory;
}

sub has_item {
    my $self = shift;
    $self->inventory->find(@_);
}

sub new_monster {
    my $self = shift;
    TAEB::World::Monster->new(@_);
}

sub equipment {
    my $self = shift;
    $self->inventory->equipment(@_);
}

sub quit {
    my $self = shift;
    $self->write("   \e   \e     #quit\n");
    # screenscraper handles the message sending and die call
}

sub save {
    my $self = shift;
    $self->write("   \e   \e     S");
    $self->enqueue_message('save');
}

sub persistent_file {
    my $self = shift;

    my $interface = $self->config->interface;
    my $state_file = $self->config->taebdir_file("$interface.state");
}

sub play {
    my $self = shift;

    while (1) {
        my $report = $self->iterate;
        return $report if $report;
    }
}

sub reset_state {
    my $self = shift;
    my $meta = $self->meta;

    TAEB->remove_handlers;
    for my $attr ($meta->get_all_class_attributes) {
        $attr->clear_value($meta);
        $attr->set_value($meta, $attr->default($meta))
            if !$attr->is_lazy && $attr->has_default;
    }
}

sub setup_handlers {
    $SIG{__WARN__} = sub {
        my $method = $_[0] =~ /^Use of uninitialized / ? 'undef' : 'perl';
        TAEB->log->$method($_[0], level => 'warning');
    };

    $SIG{__DIE__} = sub {
        my $message = shift;

        if ($message =~ /^(The game has ended\.|The game has been saved\.)/) {
            TAEB->log->main($1, level => 'info');

            if ($1 =~ /ended/) {
                TAEB->destroy_saved_state;
            }
            else {
                TAEB->save_state;
            }
        }
        else {
            TAEB->save_state;

            my $level = $message =~ /^Interrupted\./
                      ? 'info'
                      : 'error';
            TAEB->log->perl($message, level => $level);

            TAEB->save;
        }

        die $message;
    };
}

sub remove_handlers {
    $SIG{__WARN__} = 'DEFAULT';
    $SIG{__DIE__}  = 'DEFAULT';
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

__END__

=head1 NAME

TAEB - the Tactical Amulet Extraction Bot (for NetHack)

=head1 DESCRIPTION

TAEB is a framework for programmatically playing NetHack
(L<http://nethack.org>). This framework is useful for, among other things,
writing autonomous NetHack bots, or providing unconventional interfaces to
NetHack for humans.

Once installed, run the F<taeb> script to run L<TAEB::AI::Demo>. This
simplistic AI is provided so that TAEB does something out of the box, and for
didactic purposes. You should select a more robust TAEB AI (such as
L<TAEB::AI::Behavioral>) to run.

=head1 ATTRIBUTES

=over 4

=item interface

An interface for communicating with NetHack

=item ai

An agent that decides what to do each turn

=item scraper

A screen scraper to give meaning to the characters on the virtual terminal

=item config

The user's configuration for each component

=item vt

A virtual terminal that gives us an addressable screen for NetHack's output

=item state

A string representing TAEB's current state (logging_in, playing, or dying)

=item log

A message bus for tracking history for debugging and informational purposes

=item dungeon

The state of the NetHack world; levels and tiles are some of the dungeon's
domain

=item senses

The state of TAEB's character; HP, in_beartrap, and fire_resistant are some
statuses about TAEB's character that senses tracks.

=item spells

The spells that TAEB currently knows

=item publisher

A message bus for communicating information across all of TAEB's components

=item action

The L<TAEB::Action> that was taken or is about to be taken

=item new_game

A boolean indicating whether the current session started a new game or
continued a previously saved game

=item debugger

An object holding a collection of debugging tools such as
L<TAEB::Debug::Console> and L<TAEB::Debug::IRC::Bot>

=item display

An interface to communicate with the human user

=item item_pool

A pool (universe) of NetHack items; the item pool tracks inventory, artifacts,
possibilities for each appearance, and so on.

=back

=head1 CODE

TAEB is versioned using C<darcs>. You can get a checkout of the code with:

    darcs get --partial http://sartak.org/code/TAEB

=head1 BLOG

The TAEB authors maintain something resembling a blog of ideas, difficulties,
and progress at:

    http://taeb-nethack.blogspot.com

=head1 AUTHORS

The primary authors of TAEB are:

=over 4

=item Shawn M Moore C<sartak@gmail.com>

=item Jesse Luehrs C<doy@tozt.net>

=item Stefan O'Rear C<stefanor@cox.net>

=back

TAEB has also had features, fixes, and improvements from:

=over 4

=item Sebbe

=item arcanehl

=item sawtooth

=item Jerub

=item ais523

=item dho

=item futilius

=item bd

=item Zaba

=item toft

=item HanClinto

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 TAEB DevTeam.

This program is free software; you can redistribute it and/or modify it
under terms of the GNU public license version 2.

=cut

