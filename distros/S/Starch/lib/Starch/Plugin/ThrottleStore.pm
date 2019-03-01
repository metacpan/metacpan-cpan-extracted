package Starch::Plugin::ThrottleStore;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

=head1 NAME

Starch::Plugin::ThrottleStore - Throttle misbehaving Starch stores.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::ThrottleStore'],
        store => {
            class => ...,
            throttle_threshold => 2,
            throttle_duration  => 20,
        },
    );

=head1 DESCRIPTION

This plugin detects stores which are throwing errors consistently
and disables them for a period of time.

When the L</throttle_threshold> number of consecutive errors
is reached all store operations will be disabled for
L</throttle_duration> seconds.

When the error threshold has been reached an erorr log message
will be produced stating that throttling is starting.  Each
store access for the duration of the throttling will then produce
a log message stating which state key is being throttled.

=cut

use Types::Common::Numeric -types;
use Try::Tiny;

use Moo::Role;
use namespace::clean;

with qw(
    Starch::Plugin::ForStore
);

=head1 OPTIONAL STORE ARGUMENTS

These arguments are added to classes which consume the
L<Starch::Store> role.

=head2 throttle_threshold

How many consecutive errors which will trigger throttling.
Defaults to C<1>, which means the first error detected will
begin throttling.

=cut

has throttle_threshold => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 1,
);

=head2 throttle_duration

How many seconds to throttle for once the L</throttle_threshold>
has been reached.  Default to C<60> (1 minute).

=cut

has throttle_duration => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 60,
);

=head1 STORE ATTRIBUTES

These attributes are added to classes which consume the
L<Starch::Store> role.

=head2 throttle_error_count

Contains the current number of consecutive errors.

=cut

has throttle_error_count => (
    is       => 'ro',
    init_Arg => undef,
    default  => 0,
    writer   => '_set_throttle_error_count',
);

=head2 throttle_start

Contains the epoch time of when the L</throttle_threshold> was
passed and throttling began.

=cut

has throttle_start => (
    is       => 'ro',
    init_arg => undef,
    writer   => '_set_throttle_start',
    clearer  => '_clear_throttle_start',
);

foreach my $method (qw( set get remove )) {
    around $method => sub{
        my $orig = shift;
        my $self = shift;

        my $error_count = $self->throttle_error_count();
        my $start = $self->throttle_start();

        if ($start) {
            my $duration = $self->throttle_duration();
            if ($start + $duration < time()) {
                $self->_clear_throttle_start();
                $error_count = 0;
            }
            else {
                my ($id, $namespace) = @_;
                my $manager = $self->manager();
                my $key = $self->stringify_key( $id, $namespace );
                $self->log->errorf(
                    'Throttling %s of state key %s on the %s store for the next %d seconds.',
                    $method, $key, $self->short_store_class_name(), ($start + $duration) - time(),
                );
                return {
                    $manager->no_store_state_key() => 1,
                } if $method eq 'get';
                return;
            }
        }

        my @args = @_;
        my ($ret, $error, $errored);
        try { $ret = $self->$orig( @args ) }
        catch { $error=$_; $errored=1 };

        if ($errored) { $error_count ++ }
        else { $error_count = 0 }
        $self->_set_throttle_error_count( $error_count );

        my $threshold = $self->throttle_threshold();
        if ($error_count >= $threshold) {
            $self->log->errorf(
                'Error threshold %d reached on the %s store, throttling for the next %d seconds.',
                $threshold, $self->short_store_class_name(), $self->throttle_duration(),
            );
            $self->_set_throttle_start( time() );
        }

        die $error if $errored;

        return $ret if $method eq 'get';
        return;
    };
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHORS> and L<Starch/LICENSE>.

=cut

