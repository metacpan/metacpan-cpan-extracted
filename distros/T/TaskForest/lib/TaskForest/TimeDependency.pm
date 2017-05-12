################################################################################
#
# $Id: TimeDependency.pm 211 2009-05-25 06:05:50Z aijaz $
#
################################################################################

=head1 NAME

TaskForest::TimeDependency - A time constraint on a job

=head1 SYNOPSIS

 use TaskForest::TimeDependency;

 # Assume it is now 20:55 (8:55 pm) in Chicago

 $td = TaskForest::TimeDependency->new(
    start => '21:00',
    tz => 'America/Chicago',
    );

 $a = $td->check();  # $a == 0, $a->{status} eq 'Waiting'

 # 5 minutes go by

 # $a->{status} is still 'Waiting', but after

 $a = $td->check();  # now $a == 1 and $a->{status} is now 'Success'

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

A TimeDependency is an object that a job depends on.  It has a time
(and time zone) associated with it.  Just as a job can depend on
another job, a job can also depend on a TimeDependency.  The check()
function is used to determine whether or not a time dependency has
been met.

=head1 METHODS

=cut

package TaskForest::TimeDependency;

use strict;
use warnings;
use Data::Dumper;
use DateTime;
use Carp;
use TaskForest::LocalTime;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item new()

 Usage     : my $td = TaskForest::TimeDependency->new();
 Purpose   : The TimeDependency constructor creates a simple
             TimeDependency data structure.  Other classes will set
             and examine status and return code. 
 Returns   : Self
 Argument  : Attributes as a hash.  If a single scalar is provided,
             then that is considered to be a DateTime object -
             essentially a copy constructor. 
 Throws    : "TimeDependency does not have a start/end time" 

=back

=cut

# ------------------------------------------------------------------------------
sub new {
    my $arg = shift;
    my $class = (ref $arg) || $arg;

    # initialize object with default atttributes
    my $self = {
        start  => '',
        tz  => '',                      
        rc  => '',                      # exit code
        status => 'Waiting',
    };

    my $dt;
    if (scalar(@_) == 1) {
        # assume it's a DateTime object.  We really should die
        # here if ref($dt) ne 'DateTime'
        #
        $dt = shift;
        if (ref($dt) ne 'DateTime') {
            croak "Non-DateTime object passed to TaskForest::TimeDependency::new(): ", ref($dt);
        }
        $self->{start} = sprintf("%02d:%02d", $dt->hour, $dt->minute);
    }
    else {
        my %args = @_;

        # Set the attributes passed in
        #
        foreach my $key (keys %args) {
            $self->{$key} = $args{$key};
        }

        croak "TimeDependency does not have a start time" unless $self->{start};
        croak "TimeDependency does not have a time zone" unless $self->{tz};

        # create a DateTime object
        #
        $dt = DateTime->from_epoch(epoch => &TaskForest::LocalTime::epoch());
        $dt->set_time_zone($self->{tz});
        my ($hour, $min) = split(/:/, $self->{start});
        $dt->set(hour => $hour);
        $dt->set(minute => $min);
        #$dt->set_time_zone($self->{tz});
    }

    # set the ep attribute to the epoch value of the DateTime object.
    $self->{ep} = $dt->epoch;

    bless $self, $class;
    return $self;
}

# ------------------------------------------------------------------------------
=pod

=over 4

=item check()

 Usage     : $td->check();
 Purpose   : Checks to see whether the time dependency has been met
             or not. 
 Returns   : 1 if it has been met.  0 otherwise.
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub check {
    my $self = shift;
    my $now = &TaskForest::LocalTime::epoch();

    # If it's already marked as having been met, we just return 1;
    #
    if ($self->{status} eq 'Success') {
        return 1;
    }

    # If it has been met, set status variables and return 1 or 0
    #
    if ($now >= $self->{ep}) {
        $self->{rc} = 0;
        $self->{status} = 'Success';
        return 1;
    }
    else {
        $self->{rc} = 1;
        $self->{status} = 'Waiting';
        return 0;
    }
}
    

1;
