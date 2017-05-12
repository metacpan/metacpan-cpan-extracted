package Parallel::Prefork::SpareWorkers::Scoreboard;

use strict;
use warnings;

use Fcntl qw(:DEFAULT :flock);
use File::Temp qw();
use POSIX qw(SEEK_SET);
use Scope::Guard;
use Signal::Mask;

use Parallel::Prefork::SpareWorkers qw(:status);

# format of each slot: STATUS_CHAR PID(15bytes,left-aligned) "\n"
use constant SLOT_SIZE     => 16;
use constant EMPTY_SLOT    => STATUS_NEXIST . (' ' x (SLOT_SIZE - 2)) . "\n";
sub _format_slot {
    my ($state, $pid) = @_;
    substr($state, 0, 1) . sprintf "%-14d\n", $pid;
}

sub new {
    my ($klass, $filename, $max_workers) = @_;
    # create scoreboard file
    $filename ||= File::Temp::tempdir(CLEANUP => 1) . '/scoreboard';
    sysopen my $fh, $filename, O_RDWR | O_CREAT | O_EXCL
        or die "failed to create scoreboard file:$filename:$!";
    my $wlen = syswrite $fh, EMPTY_SLOT x $max_workers;
    die "failed to initialize scoreboad file:$filename:$!"
        unless $wlen == SLOT_SIZE * $max_workers;
    my $self = bless {
        filename    => $filename,
        fh          => $fh,
        max_workers => $max_workers,
        slot        => undef,
    }, $klass;
    $self;
}

sub get_statuses {
    local ($Signal::Mask{CHLD}, $Signal::Mask{TERM}, $Signal::Mask{INT}) = (1, 1, 1);

    my $self = shift;
    sysseek $self->{fh}, 0, SEEK_SET
        or die "seek failed:$!";
    sysread($self->{fh}, my $sb, $self->{max_workers} * SLOT_SIZE)
        == $self->{max_workers} * SLOT_SIZE
            or die "failed to read status:$!";
    my @s = map {
        $_ =~ /^(.)/ ? ($1) : ()
    } split /\n/, $sb;
}

sub clear_child {
    local ($Signal::Mask{CHLD}, $Signal::Mask{TERM}, $Signal::Mask{INT}) = (1, 1, 1);

    my ($self, $pid) = @_;
    my $lock = $self->_lock_file;
    sysseek $self->{fh}, 0, SEEK_SET
        or die "seek failed:$!";
    for (my $slot = 0; $slot < $self->{max_workers}; $slot++) {
        my $rlen = sysread($self->{fh}, my $data, SLOT_SIZE);
        die "unexpected eof while reading scoreboard file:$!"
            unless $rlen == SLOT_SIZE;
        if ($data =~ /^.$pid[ ]*\n$/) {
            # found
            sysseek $self->{fh}, SLOT_SIZE * $slot, SEEK_SET
                or die "seek failed:$!";
            my $wlen = syswrite $self->{fh}, EMPTY_SLOT;
            die "failed to clear scoreboard file:$self->{filename}:$!"
                unless $wlen == SLOT_SIZE;
            last;
        }
    }
}

sub child_start {
    local ($Signal::Mask{CHLD}, $Signal::Mask{TERM}, $Signal::Mask{INT}) = (1, 1, 1);

    my $self = shift;
    die "child_start cannot be called twite"
        if defined $self->{slot};
    close $self->{fh}
        or die "failed to close scoreboard file:$!";
    sysopen $self->{fh}, $self->{filename}, O_RDWR
        or die "failed to create scoreboard file:$self->{filename}:$!";
    my $lock = $self->_lock_file;
    for ($self->{slot} = 0;
         $self->{slot} < $self->{max_workers};
         $self->{slot}++) {
        my $rlen = sysread $self->{fh}, my $data, SLOT_SIZE;
        die "unexpected response from sysread:$rlen, expected @{[SLOT_SIZE]}:$!"
            if $rlen != SLOT_SIZE;
        if ($data =~ /^.[ ]+\n$/o) {
            last;
        }
    }
    die "no empty slot in scoreboard"
        if $self->{slot} >= $self->{max_workers};
    $self->set_status(STATUS_IDLE);
}

sub set_status {
    my ($self, $status) = @_;
    die "child_start not called?"
        unless defined $self->{slot};
    sysseek $self->{fh}, $self->{slot} * SLOT_SIZE, SEEK_SET
        or die "seek failed:$!";
    my $wlen = syswrite $self->{fh}, _format_slot($status, $$);
    die "failed to write status into scoreboard:$!"
        unless $wlen == SLOT_SIZE;
}

sub _lock_file {
    my $self = shift;
    my $fh = $self->{fh};
    flock $fh, LOCK_EX
        or die "failed to lock scoreboard file:$!";
    return Scope::Guard->new(
        sub {
            flock $fh, LOCK_UN
                or die "failed to unlock scoreboard file:$!";
        },
    );
}

1;
