package POE::Devel::Top;

use strict;
use warnings;

use Carp;
use POE qw< API::Peek Session >;
use Term::ANSIColor qw< :constants >;


our $VERSION = "0.100";


#
# import()
# ------
sub import {
    my ($class, @args) = @_;

    # if caller line is zero, it means the module was loaded from the
    # command line, in which case we automatically spawn the session
    my ($package, undef, $line) = caller;
    $class->spawn(render => "console", @args)
        if $line == 0 or $package eq __PACKAGE__;
}


#
# spawn()
# -----
sub spawn {
    my ($class, @args) = @_;

    croak "Odd number of argument" if @args % 2 == 1;

    POE::Session->create(
        heap => {
            interval => 2,
            @args
        },

        inline_states => {
            _start => sub {
                $_[KERNEL]->alias_set("[$class]");
                $_[KERNEL]->delay(poe_devel_top_collect => $_[HEAP]->{interval});
            },
            poe_devel_top_collect   => \&collect,
            poe_devel_top_render    => \&render,
            poe_devel_top_store     => \&store,
        },
    );
}


#
# collect()
# -------
sub collect {
    my ($kernel, $heap) = @_[ KERNEL, HEAP ];
    my $poe_api = POE::API::Peek->new;
    my $now = time;

    # collect general data about the current process
    my @times = times;
    my @pwent = getpwuid(int $>);
    my $egid  = (split / /, $))[0];
    my @grent = getgrgid(int $egid);

    my %general = (
        process => {
            pid     => $$,
            uid     => $>,
            gid     => $egid,
            user    => $pwent[0],
            group   => $grent[0],
        },
        resource => {
            utime_self  => $times[0],
            utime_chld  => $times[2],
            stime_self  => $times[1],
            stime_chld  => $times[3],
        },
        poe => {
            sessions    => $poe_api->session_count,
            handles     => $poe_api->handle_count,
            loop        => $poe_api->which_loop,
        },
    );

    # collect information about the sessions
    my $kernel_id = $kernel->ID;
    my @sessions;

    for my $session ($poe_api->session_list) {
        push @sessions, {
          $session->ID eq $kernel_id ? (
              id        => 0,
              aliases   => "[POE::Kernel] id=".$session->ID,
          ) : (
              id        => $session->ID,
              aliases   => join(",", $poe_api->session_alias_list($session)),
          ),
          memory_size   => $poe_api->session_memory_size($session),
          refcount      => $poe_api->get_session_refcount($session),
          events_to     => $poe_api->event_count_to($session),
          events_from   => $poe_api->event_count_from($session),
        };
    }

    @sessions = sort { $a->{id} <=> $b->{id} } @sessions;

    # collect information about the events
    my @events;

    for my $event ($poe_api->event_queue_dump) {
        push @events, {
            id          => $event->{ID},
            name        => $event->{event},
            type        => $event->{type},
            priority    => $event->{priority} > $now ?
                $event->{priority} - $now : $event->{priority},
            source      => $event->{source}->ID,
            destination => $event->{destination}->ID,
        }
    }

    # create the final hash
    my %stats = (
        general     => \%general,
        sessions    => \@sessions,
        events      => \@events,
    );

    # call myself
    $kernel->delay(poe_devel_top_collect => $heap->{interval});

    # call the dumper event
    $kernel->yield(poe_devel_top_store => \%stats)
        if $heap->{dump_as} and $heap->{dump_as} ne "none";

    # call the renderer event
    $kernel->yield(poe_devel_top_render => \%stats)
        if $heap->{render} eq "console";

    return \%stats
}


#
# render()
# ------
sub render {
    my ($kernel, $stats) = @_[ KERNEL, ARG0 ];
    my $proc    = $stats->{general}{process};
    my $rsrc    = $stats->{general}{resource};

    local $Term::ANSIColor::AUTORESET = 1;

    my $session_head    = REVERSE(BOLD "%5s  %6s  %8s  %6s  %8s  %-40s").$/;
    my $session_row     = "%5d  %6s  %8d  %6d  %8d  %-40s\n";
    my @session_cols    = qw< ID Memory Refcount EvtsTo EvtsFrom Aliases >;

    my $event_head      = REVERSE(BOLD "%5s  %-17s %4s %5s %5s  %-40s").$/;
    my $event_row       = "%5d  %-17s %4d %5d %5d  %-40s\n";
    my @event_cols      = qw< ID Type Pri Src Dest Name >;

    print "\e[2J\e[f",
          "Process ID: $proc->{pid},  ",
          "UID: $proc->{uid} ($proc->{user}),  ",
          "GID: $proc->{gid} ($proc->{group})\n",
          "Resource usage:  ",
            "user: $rsrc->{utime_self} sec (+$rsrc->{utime_chld} sec),  ",
            "system: $rsrc->{stime_self} sec (+$rsrc->{stime_chld} sec)\n",
          "Sessions: $stats->{general}{poe}{sessions} total,  ",
          "Handles: $stats->{general}{poe}{handles} total,  ",
          "Loop: $stats->{general}{poe}{loop}\n\n";

    print BOLD " Sessions", $/;
    printf $session_head, @session_cols;
    printf $session_row,
        $_->{id}, human_size( $_->{memory_size} ), $_->{refcount},
        $_->{events_to}, $_->{events_from}, $_->{aliases}
        for @{$stats->{sessions}};

    print $/;

    print BOLD " Events", $/;
    printf $event_head, @event_cols;
    printf $event_row,
        $_->{id}, $_->{type}, $_->{priority},
        $_->{source}, $_->{destination}, $_->{name}
        for @{$stats->{events}};

    print $/;
}


#
# human_size()
# ----------
sub human_size {
    my ($size) = @_;

    return $size if $size < 100_000;

    my $unit;
    for (qw< K M G >) {
        $size = int($size / 1024);
        $unit = $_;
        last if $size < 1024;
    }

    return $size.$unit;
}


#
# store()
# -----
sub store {
    my ($kernel, $heap, $stats) = @_[ KERNEL, HEAP, ARG0 ];

    if ($heap->{dump_as} eq "yaml") {
        if (eval "require YAML; 1") {
            YAML::DumpFile($heap->{dump_to}, $stats);
            return
        }
        else {
            $heap->{dump_as} = "native";
            $heap->{dump_to} =~ s/\.ya?ml$/.dmp/;
            carp "warning: YAML not available. Defaulting to native format."
        }
    }

    if ($heap->{dump_as} eq "native") {
        if (eval "require Storable; 1") {
            Storable::nstore($stats, $heap->{dump_to});
            return
        }
        else {
            croak "fatal: Can't load Storable: $@"
        }
    }
}


__PACKAGE__

__END__

=head1 NAME

POE::Devel::Top - Display information about POE sessions and events

=head1 VERSION

Version 0.100

=head1 SYNOPSIS

Load the module as any other POE plugin:

    use POE qw< Devel::Top >;

    POE::Devel::Top->spawn;

Load the module from the command line:

    perl -MPOE::Devel::Top ...


=head1 DESCRIPTION

This module displays information about the sessions and events handled
by the current POE kernel, mimicking the well-known B<top(1)> system
utility.

In this early version, it only prints the information on C<STDOUT>.


=head1 METHODS

=head2 spawn()

Create the internal session that prints the information on screen.

B<Options>

=over

=item *

C<dump_as> - Specify the dumping format: C<"native"> for Storable,
C<"yaml"> for YAML.

=item *

C<dump_to> - Specify the dump file path.

=item *

C<interval> - Specify the delay in seconds between updates.

=item *

C<render> - Set to C<"none"> to disable any rendering. Set to C<"console">
to enable a rendering on the console, similar to the C<top(1)> command.

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni C<< <sebastien at aperghis.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-devel-top at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Devel-Top>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Devel::Top

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Dist=POE-Devel-Top>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Devel-Top>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Devel-Top>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Devel-Top>

=back


=head1 ACKNOWLEDGEMENTS

Rocco Caputo and the numerous people who contributed to POE.

Matt Cashner (sungo) for C<POE::API::Peek>.

Apocalypse and Chris Williams (BinGOs) for helping me on the C<#poe>
IRC channel.


=head1 COPYRIGHT & LICENSE

Copyright 2010 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
