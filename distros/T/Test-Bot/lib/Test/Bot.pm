package Test::Bot;

use Any::Moose 'Role';
use AnyEvent;
use Class::MOP;
use Carp qw/croak/;

our $VERSION = '0.09';

=head1 NAME

Test::Bot - Continuous integration bot for automatically running unit tests and notifying developers of failed tests

=head1 SYNOPSIS

See README

=head1 AUTHOR

Mischa Spiegelmock, C<< <revmischa at cpan.org> >>

=cut

#use Any::Moose 'X::Getopt'; # why the heck does this not work?
with 'MouseX::Getopt';

# local source repo checkout
has 'source_dir' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    traits => [ 'Getopt' ],
    cmd_flag => 'source-dir',
    cmd_aliases => 's',
);

# forcibly check out the current commit we are testing?
# warning: will overwrite local changes
has 'force' => ( is => 'rw', isa => 'Bool' );

has 'tests_dir' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    traits => [ 'Getopt' ],
    cmd_flag => 'tests-dir',
    cmd_aliases => 't',
);

has 'notification_modules' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    required => 0,
    traits => [ 'Getopt' ],
    cmd_flag => 'notifs',
    cmd_aliases => 'n',
    default => sub { ['Print'] },
);

has 'preload_modules' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    required => 0,
    traits => [ 'Getopt' ],
    cmd_flag => 'preload',
    cmd_aliases => 'p',
    default => sub { ['Test::More'] },
);

has 'test_harness_module' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    traits => [ 'Getopt' ],
    cmd_flag => 'test_harness',
    cmd_aliases => 't',
    default => 'Aggregate',
);

has '_notify_instances' => (
    is => 'rw',
    isa => 'ArrayRef',
    traits => [ 'Array' ],
    handles => {
        add_notify_module_instance => 'push',
        notify_instances => 'elements',
    },
    default => sub { [] },
);

has '_configured_test_harness'  => ( is => 'rw', isa => 'Bool' );
has '_configured_notifications' => ( is => 'rw', isa => 'Bool' );

requires 'install';
requires 'watch';

sub load_test_harness {
    my ($self) = @_;

    my $harness = $self->test_harness_module;
    my $harness_class = "Test::Bot::TestHarness::$harness";
    Class::MOP::load_class($harness_class);
    $harness_class->meta->apply($self);
    print "+Loaded $harness test harness\n";
    
    requires 'run_tests_for_commit';
}

sub load_notify_modules {
    my ($self) = @_;

    foreach my $module (@{ $self->notification_modules }) {
        my $notif_class = "Test::Bot::Notify::$module";
        Class::MOP::load_class($notif_class);
        my $i = $notif_class->new(
            bot => $self,
        );
        $self->add_notify_module_instance($i);

        print "+Loaded $module notification module\n";
    }
}

sub notify {
    my ($self, @commits) = @_;

    $_->notify(@commits) for $self->notify_instances;
}

sub configure_test_harness {
    my ($self, %config) = @_;

    return if $self->_configured_test_harness;
    
    $self->load_test_harness;

    while (my ($k, $v) = each %config) {
        my $setter = $self->can($k) or croak "Unknown test harness setting $k";
        $setter->($self, $v);
    }

    $self->_configured_test_harness(1);
}

sub configure_notifications {
    my ($self, %config) = @_;

    return if $self->_configured_notifications;

    $self->load_notify_modules;

    # prepare notify instances
    foreach my $ni ($self->notify_instances) {
        while (my ($k, $v) = each %config) {
            my $setter = $ni->can($k) or next;
            $setter->($ni, $v);
        }
        
        $ni->setup;
    }

    $self->_configured_notifications(1);
}

# preload libraries shared by tests
sub load_preload_modules {
    my ($self) = @_;

    foreach my $module (@{ $self->preload_modules }) {
        local $| = 1;
        print "+Loading $module... ";
        Class::MOP::load_class($module);
        print "loaded.\n";
    }
}

sub run {
    my ($self) = @_;

    $self->load_preload_modules;
    
    $self->configure_test_harness;
    $self->configure_notifications;

    # listen...
    $self->install;

    # ...and wait
    $self->watch;

    # run forever.
    AE::cv->recv;
}

1;
