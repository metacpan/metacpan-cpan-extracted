package Schedule::Poll;

use 5.006;
use strict;
use warnings FATAL => 'all';

use List::Util 'max';
use POSIX qw/ floor /;
use Carp;

=head1 NAME

Schedule::Poll - Evenly schedule recurring events with various intervals


=cut

our $VERSION = '0.02';


=head1 SYNOPSIS


    use Schedule::Poll;

    # Let's run a few things every 3 seconds,
    # and some things every 6 seconds

    my $config = {
        foo => 3,
        bar => 3,
        baz => 3,
        zip => 6,
        zoo => 6,
        zat => 6
    };

    my $poll = Schedule::Poll->new( $config );

    while(1) {

        if (my $aref =  $poll->which  ) {

            for my $each (@$aref) {

                print "$each fired!\n";
            }
        }
        sleep 1;
    }


=head1 METHODS

=head2 new

Constructor. Accepts a hashref with the values being an interval in seconds. Each interval used should be a divisor of 86400.


    my $poll = Schedule::Poll->new({
    
        foo => 300 # 5 minutes
        bar => 600 # 10 minutes
        baz => 5   # 5 seconds
    
    });

=cut

sub new {
    my $class = shift;
    my $self = { };
    $self->{config} = $_[0];
    croak "Missing data" unless exists $self->{config};
    croak "data is not a hashref" unless ref $self->{config} eq 'HASH';

    my $config = $self->{config};
    my @intervals;

    for my $interval (keys %{$config}) {
        croak "$config->{$interval} is not an even divisor of 86400" if (86400 % $config->{$interval} != 0);
        push (@intervals,$config->{$interval});
    }
    my $max = max(@intervals);
    $self->{max} = $max;

    my %groups = ( );
    for my $each (keys %{$config}) {
        push ( @{$groups{ $config->{$each} } }, $each);
    }
    my %schedule;
    undef @intervals;
    undef $config;
    undef $self->{config};


    for my $interval (keys %groups) {
        # Count of members in each group:
        my $members = scalar @{$groups{$interval}};

        my $iter = 1;

        if ($members/$interval >= 1) {

            #       > 1 req per second. Loop
            #       through the members and assign
            #       them to slots in the interval
            #
            #       Ex: 
            #           members  = 7
            #           interval = 5
            #
            #       1 2 3 4 5
            #       ---------
            #       | | | | |
            #       | |
            #
            #   With the above example, the 1st and 2nd second slots in that interval
            #   will contain 2 requests, the remaining slots will have 1


            #   First, We need to determine how many times this
            #   interval group will repeat given a max interval.

            my $sets = $max/$interval;

            while ($members >= 1) {
                $iter = 1 if $iter > $interval;
                                
                my $set = 0;

                while ($set < $sets) {

                    my $slot;
                    if ($set == 0) {
                        $slot = $iter;
                    }
                    else {
                        $slot = ($set * $interval) + $iter;
                    }
                    push ( @{$schedule{$slot}}, $groups{$interval}[$members -1]);
                    $set++;
               }

               $iter++;
               $members--;
           }
       }
       else {

           #    < 1 requests per sec. We can spread
           #    the reqests out over multiple seconds
           #
           #    Ex:      
           #        requests: 3
           #        interval: 9
           #
           #   1 2 3 4 5 6 7 8 9
           #   -----------------
           #   |     |     |
           #
           #   .. so 1 request for every 3 seconds.

            my $rate = floor 1/($members/$interval);


            my $sets = $max/$interval;
            while ($members >=1) {
                $iter = 1 if $iter >= $interval;
                my $set = 0;
                while ($set < $sets) {
                    my $slot;
                    if ($set == 0) {
                        $slot = $iter + ($rate -1);

                    }
                    else {
                        $slot = ($set * $interval) + ($iter + ($rate-1));
                    }
                    push ( @{$schedule{$slot}}, $groups{$interval}[$members -1]);
                    $set++;
                }
                $iter += $rate;
                $members--;
            }

        }
    }
    $self->{schedule} =  \%schedule;
    bless $self,$class;
};


sub current {
    my $self = shift;

    my $max = $self->{max};
    my @time = localtime();
    my $second = ($time[2] * 3600) + ($time[1] * 60) + $time[0];
    my $y=0;
    if ($second > $max) {
        while ($y < $second) {
            $y += $max;
        }
        return $second - ($y - $max);
    } else {
       return $second;
    }

}

=head2 which

Returns an arrary reference containing the items for that current tick interval.

    $poll->which;


=cut

sub which {
    my $self = shift;
    my $current = $self->current;
    my @who;
    if (exists $self->{schedule}{$current}) {
        for my $each (@{$self->{schedule}{$current}}) {
            push(@who,$each);
        }
        return \@who;
    }
    return 0;
}

=head2 Examples

    $href = {
        a => 3,
        b => 3,
        c => 3
    };

    Timeline:
        interval | 1  2  3  4  5  6  
        ---------+------------------
        key      | a  b  c  a  b  c


    $href = {
        a => 3,
        b => 3,
        c => 3,
        d => 6,
        e => 6,
        f => 6
    };

    Timeline:
        interval | 1  2  3  4  5  6  7  8  9  10  11  12 
        ---------+--------------------------------------
        key      | b  a  c  b  a  c  b  a  c  b   a   c
                 | d     e     f     d     e      f


=head1 AUTHOR

Michael Kroher, C<< <michael at kroher.net> >>

=cut
1; # End of Schedule::Poll
