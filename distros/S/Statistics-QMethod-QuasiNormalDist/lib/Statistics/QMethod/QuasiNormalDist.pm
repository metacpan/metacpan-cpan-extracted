package Statistics::QMethod::QuasiNormalDist;

use warnings;
use strict;
use POSIX;
use base 'Exporter';
use Carp;
our @EXPORT = qw/get_q_dist/;
our $VERSION = '0.01';

# dispatch table for dealing with rounding errors theoretically this
# could all be memoised

my %difs = (
    0 => sub { return },
    -2 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)] + 2;
    },
    '-1' => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)] + 1;
    },
    1 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   + 1 ;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 2 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 2 ;

    },
    2 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 1 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 1 ;
    },
    3 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 2 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 2 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   + 1 ;
    },
    4 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 2 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 2 ;
    },
    5 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 2 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 2 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 1 ;
    },
    6 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 3 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 3 ;
    },
    7 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 3 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 3 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 1 ;
    },
    8 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 3 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 3 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 2 ;
    },
    9 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 4 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 4 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 1 ;
    },
    10 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 4 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 4 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 2 ;
    },
    11 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 4 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 4 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 3 ;
    },
    12 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 5 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 5 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 2 ;
    },
    13 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 5 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 5 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 3 ;
    },
    14 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 5 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 5 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 4 ;
    },
    15 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 6 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 6 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 3 ;
    },
    16 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 6 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 6 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 4 ;
    },
    17 => sub {
        my ($res, $N) = @_;
        $res->[floor($#$res/2)-1] = $res->[floor($#$res/2)] - 6 ;
        $res->[floor($#$res/2)+1] = $res->[floor($#$res/2)] - 6 ;
        $res->[floor($#$res/2)] = $res->[floor($#$res/2)]   - 5 ;
    },

);

sub get_q_dist {
    my $N = shift;
    die "do not support q samples of $N" if $N < 5 || $N > 500;
    my @weights = qw/0.0013 0.023 0.16  0.22 0.22 0.22 0.16 0.023 0.0013/;
    my @res = map { sprintf "%.0f", $_ * $N} @weights;
    @res = grep { $_ } @res; # strip the trailing and leading zeroes
    my $sum = _sum(\@res);
    my $dif = $sum-$N;
    eval  {
        $difs{$dif}->(\@res, $N);
    };
    if ($@) {
        warn"oops, dif was $dif\n"
    };
    _massage_tails(\@res,$N);
    _massage_centre(\@res, $N);
    _check_dist(\@res,$N);
    return \@res;
}

sub _sum {
    my $ary = shift;
    carp "needs an array referenc" if ref $ary ne 'ARRAY';
    my $sum = 0;
    map { $sum = $sum+$_} @$ary;
    return $sum;
}

sub _massage_centre {
    my ($res, $N) = @_;
    my $mid = floor($#$res/2);
    if ($res->[$mid-1] == $res->[$mid] && $res->[$mid] == $res->[$mid+1]) {
        $res->[$mid-1]--;
        $res->[$mid+1]--;
        $res->[$mid] +=2;
    if ($N == 5) { # special case
        shift @$res;
        pop @$res;
        $res->[0]=1;
        $res->[$#$res]=1;
    }
    }
    elsif ($res->[$mid] < $res->[$mid + 1 ]) {
        $res->[$mid-1]--;
        $res->[$mid+1]--;
        $res->[$mid] +=2;
    }
}

sub _massage_tails {
    my ($res, $N) = @_;
    if ($res->[0] !=1) {
        if ($res->[0] == 2) {
            $res->[0]--;
            $res->[1]++;
            $res->[$#$res]--;
            $res->[$#$res-1]++;

        }
        elsif ($res->[0] >= 3) {
            $res->[0]--;
            $res->[$#$res]--;
            push @$res,1;
            unshift @$res,1;
        }
    }
}

sub _check_dist {
    my ($res, $N) = @_;
    my $mid = floor($#$res/2);
    my @top = @$res[0 .. $mid];
    my @bottom = reverse @$res;
    @bottom = @$res[0 .. $mid];
    # check dist is symmetrical
    die "$N distrib is not symmetrical" if join ('', @top) != join ('',@bottom);
    my $n = $bottom[0];
    foreach (@bottom[1 .. $#bottom]) {
        # check that each half of the distribution is quasi-normal
        die "the distribution is not quasi normal for $N" if $_ < $n;
    }
}

=head1 Statistics::QMethod::QuasiNormalDist

=head1 SUMMARY

    use Statistics::QMethod::QuasiNormalDist;
    my @dist = get_q_dist(50); # quasi normalo distribution for a 50
                               # item Q sample

Q methodology requires the generation of a quasi normal distribution
in order to provide a ranking method for subjects in a Q sort.  This
module generates these for Q samples between 5 and 500 items long.

=head1 EXPORTS

    get_q_dist($N)

where N is the number of items in a q sample.


=head1 REFERENCES

Stephenson, W. (1953). The study of behaviour: q.technique and its
methodology. Chicago: University of Chicago Press.

=head1 Author

Kieren Diment <zarquon@cpan.org>

=head1 LICENSE

This software can be redistributed under the same conditions as perl itself.

=cut

1;
