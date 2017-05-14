package TextProgressBar;

use strict;
use warnings;
use List::Util qw( min max );

$| = 1;

sub new {
    my ($class) = @_;
    my $self = {
        value => 0,
        maximum => -1,
        iteration => 0
    };
    return bless $self, $class;
}

sub clear
{
    my ($self) = @_;
    printf "\n";

    $self->{iteration} = 0;
    $self->{value} = 0;
    $self->{maximum} = -1;
    $self->{message} = undef;
}

sub update
{
    my ($self) = @_;
    ++$self->{iteration};

    if ($self->{maximum} > 0) {
        # we know the maximum
        # draw a progress bar
        my $percent = $self->{value} * 100 / $self->{maximum};
        my $hashes = $percent / 2;

        my $progressbar = '#' x $hashes;
        if ($percent % 2) {
            $progressbar .= '>';
        }

        printf "\r[%-50s] %3d%% %s     ",
               $progressbar,
               $percent,
               $self->{message};
    } else {
        # we don't know the maximum, so we can't draw a progress bar
        my $center = ($self->{iteration} % 48) + 1; # 50 spaces, minus 2
        my $before = ' ' x max($center - 2, 0);
        my $after = ' ' x min($center + 2, 50);

        printf "\r[%s###%s]      %s      ",
               $before, $after, $self->{message};
    }
}

sub setMessage
{
    my ($self, $m) = @_;
    $self->{message} = $m;
}

sub setStatus
{
    my ($self, $val, $max) = @_;
    $self->{value} = $val;
    $self->{maximum} = $max;
}

1;
