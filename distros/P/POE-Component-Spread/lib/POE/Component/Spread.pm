package POE::Component::Spread;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;

$VERSION = "0.02";
@ISA = qw(Exporter);
@EXPORT = qw(REGULAR_MESS);

use Data::Dumper;
use POE::Driver::Spread;
use POE::Filter::Spread;
use Spread qw(:MESS);
use POE qw( Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW Filter::Line Filter::Stream );

sub new {
    my( $package, $alias ) = splice @_, 0, 2;

    return POE::Session->create(
        package_states => [
            $package => [ qw(_get_spread _error _start publish subscribe connect disconnect) ]
        ],
        args => [ $alias, @_ ]
    );
}

sub _start {
    my ($kernel, $session, $heap, $alias) = @_[KERNEL, SESSION, HEAP, ARG0];
    $kernel->alias_set($alias);
}

sub connect {
    my $k_heap = $_[HEAP];   # kernel's heap
    my $sender = $_[SENDER];
    my $s_name = $_[ARG0];
    my $p_name = $_[ARG1];
    my $heap = $sender->get_heap();

    # Spread doesn't like hostnames without ports
    unless ($s_name =~ /^\d+$/ or $s_name =~ /@/) {
        $s_name = '4803@' . $s_name
    }

    my ($m, $pg) = Spread::connect( { private_name => $p_name, spread_name => $s_name } );
    print "m is $m, pg=$pg\n";

    if (!defined($m)) {
        $poe_kernel->post( $sender => '_error' => 'connect' );
    }

    $k_heap->{groups}->{$pg}->{$sender} = 'self';
    $heap->{private_name} = $pg;

    # create a filehandle from the fileno we get back from Spread::connect
    open $heap->{filehandle}, "<&=$m";

    $heap->{wheel} = POE::Wheel::ReadWrite->new(
            Handle => $heap->{filehandle},
            Driver => POE::Driver::Spread->new(mbox => $m),
            Filter => POE::Filter::Spread->new(),

            InputEvent => '_get_spread',
            ErrorEvent => '_error'
    );
    $heap->{spread} = $m;
}

sub disconnect {
    my $sender = $_[SENDER];
    my $heap = $sender->get_heap();

    $heap->{wheel}->shutdown_input();
    undef $heap->{wheel};
}

sub _error {
    my ($kernel, $session, $heap, $data, $sender, $id) = @_[KERNEL, SESSION, HEAP, ARG0, SENDER, ARG3];
    my $r_heap = $sender->get_heap();
#    print "ERROR: ID=$id session:[$session, $heap], sender:[$sender, $r_heap], kernel:$poe_kernel\n";
    # BLEH
}

sub _get_spread {
    my ($kernel, $session, $heap, $data) = @_[KERNEL, SESSION, HEAP, ARG0];
    my @moo = @$data;
    my ($type, $sender, $groups, $mess, $endian, $message) = @{$moo[0]};

    if (!defined($type)) {
        $kernel->post( $session => '_error' => 'null packet' );
        return undef;
    }

    foreach my $g (@$groups) {
        foreach my $r (keys %{$heap->{groups}->{$g}}) {
            my $event = $heap->{groups}->{$g}->{$r};
            $event .= ($type & REGULAR_MESS) ? "_regular" : "_admin";
            $kernel->post( $r => $event => [$sender, $message, $type, $groups] );
        }
    }
}

sub publish {
    my $groups = $_[ARG0];
    my $message = $_[ARG1];
    my $heap = $_[HEAP];
    my $sender = $_[SENDER];
    my $r_heap = $sender->get_heap();

    Spread::multicast($r_heap->{spread}, RELIABLE_MESS, $groups, 0, $message);
}

sub subscribe {
    my $groups = $_[ARG0];
    my $heap = $_[HEAP];
    my $session = $_[SESSION];
    my $sender = $_[SENDER];
    my $event = $_[ARG1] || $groups;
    my $r_heap = $sender->get_heap();

    $heap->{groups}->{$groups}->{$sender} = $event;

    Spread::join($r_heap->{spread}, $groups);
}

$VERSION;

__END__

=head1 NAME

POE::Component::Spread - handle Spread communications in POE

=head1 SYNOPSIS

    POE::Component::Spread->new( 'spread' );
    
    POE::Session->create(
        inline_states => {
            _start => \&_start,
            chatroom_regular => \&do_something,
        }
    );
    
    sub _start {
        $poe_kernel->alias_set('displayer');
        $poe_kernel->post( spread => connect => 'localhost' );
        $poe_kernel->post( spread => subscribe => 'chatroom' );
        $poe_kernel->post( spread => publish => 'chatroom', 'A/S/L?' );
    }

    sub do_something { 
        my $args = $_[ARG0];
        my ($sender, $message, $type, $groups) = @$args;

        # ...
    }

=head1 DESCRIPTION

POE::Component::Spread is a POE component for talking to Spread servers.

=head1 METHODS

=head2 new

    POE::Component::Spread->new( 'spread' );

=head1 EVENTS

=head2 connect

    $poe_kernel->post( spread => connect => '4444@localhost' );

Connect this POE session to the Spread server on port 4444 on localhost.

=head2 subscribe

    $poe_kernel->post( spread => subscribe => 'chatroom' );

Subscribe to a Spread messaging group.  Admin messages will be sent to 
your C<groupname_admin> event and regular messages to C<groupname_regular>.

=head2 publish

    $poe_kernel->post( spread => publish => 'chatroom', 'A/S/L?' );

Send a simple message to a Spread group.

=head1 BUGS

Error handling is non-existent (like most of the API).

=head1 CREDITS

Theo Schlossnagle wrote Spread.pm without which this wouldn't work.
Michael Stevens provided inspiration with his unreleased PoCo::Spread.

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2004, Rob Partington <perl-pcs@frottage.org>

=cut
