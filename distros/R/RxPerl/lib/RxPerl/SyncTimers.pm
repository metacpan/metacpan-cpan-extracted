package RxPerl::SyncTimers;

use strict;
use warnings;

use RxPerl ':all';

use Sub::Util 'set_subname';

use Exporter 'import';
our @EXPORT_OK = (@RxPerl::EXPORT_OK);
our %EXPORT_TAGS = (%RxPerl::EXPORT_TAGS);

foreach my $func_name (@EXPORT_OK) {
    set_subname __PACKAGE__."::$func_name", \&{$func_name};
}

our $DEBUG = 0;

my $_id_cursor = 0;
my %_timed_events;
my %_timeline;

our $time = 0;

sub reset {
    my ($class) = @_;

    $_id_cursor = 0;
    undef %_timed_events;
    undef %_timeline;
    $time = 0;
}

sub start {
    my ($class) = @_;

    while (%_timeline) {
        my @times = sort {$a <=> $b} keys %_timeline;
        $time = $times[0];
        print "** Time jump to: $time **\n" if $DEBUG;
        while (my $item = shift @{ $_timeline{$time} }) {
            delete $_timed_events{$item->{id}};
            $item->{sub}->();
        }
        delete $_timeline{$time};
    }
}

sub _round_number { 0 + sprintf("%.1f", $_[0]) }

sub _timer {
    my ($after, $sub, %opts) = @_;

    # opts can be: id

    my $id = $opts{id} // $_id_cursor++;
    my $target_time = _round_number($time + $after);
    $_timed_events{$id} = {
        time => $target_time,
        sub => $sub,
    };
    push @{ $_timeline{$target_time} }, {
        id => $id,
        sub => $sub,
    };

    return $id;
}

sub _cancel_timer {
    my ($id) = @_;

    return if !defined $id;

    my $event = delete $_timed_events{$id} or return;

    exists $_timeline{$event->{time}} or return;

    @{ $_timeline{$event->{time}} } = grep {$_->{id} ne $id} @{ $_timeline{$event->{time}} };

    if (! @{ $_timeline{$event->{time}} }) {
        delete $_timeline{$event->{time}};
    }
}

sub _add_recursive_timer {
    my ($after, $sub, $id) = @_;

    _timer($after, sub {
        _add_recursive_timer($after, $sub, $id);
        $sub->();
    }, id => $id);
}

sub _interval {
    my ($after, $sub) = @_;

    my $id = $_id_cursor++;

    _add_recursive_timer($after, $sub, $id);

    return $id;
}

sub _cancel_interval {
    my ($id) = @_;

    _cancel_timer($id);
}

1;
