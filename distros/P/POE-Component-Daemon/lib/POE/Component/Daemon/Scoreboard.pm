#$Id: Scoreboard.pm 760 2011-05-18 18:14:30Z fil $
########################################################
package POE::Component::Daemon::Scoreboard;

use 5.00405;
use strict;

use vars qw($VERSION $UNIQUE);

use IPC::SysV qw(IPC_PRIVATE S_IRWXU IPC_CREAT SEM_UNDO);
use Carp;

$VERSION = '0.1300';

sub DEBUG () { 0 }

########################################################
sub new
{
    my($package, $N)=@_;
    if($UNIQUE) {
        warn "This should be only one $package.  Reusing previous one.";
        return $UNIQUE;
    }

    my $self=bless {N=>$N}, $package;

    # On linux, 2.6 kernels (at least), the first call after a reboot will
    # fail, second and subsequent will succeed.
    $self->{mem} = shmget(IPC_PRIVATE, $N, S_IRWXU) 
                        || 
                   shmget(IPC_PRIVATE, $N, S_IRWXU);
    die "$$: Unable to create shared memory: $!\n" unless $self->{mem};

    $self->{slots}=[reverse 0..($N-1)];

    my $blank=' ' x $N;
    shmwrite($self->{mem}, $blank, 0, $N);

    $UNIQUE=$self;

    return $self;
}

########################################################
sub read_all
{
    my($self)=@_;

    my $str=" " x $self->{N};
    shmread($self->{mem}, $str, 0, $self->{N})
        or die "Unable to read shared memory: $!\n";

    my $ret=[split //, $str];
    return $ret;
}

########################################################
sub add
{
    my($self, $value)=@_;
    return unless @{$self->{slots}};
    my $slot=pop @{$self->{slots}};
    DEBUG and warn "Adding slot $slot";
    $self->write($slot, $value);
    return $slot;
}

########################################################
sub drop
{
    my($self, $slot)=@_;
    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }
    $self->write($slot, '.');
    DEBUG and warn "Dropped slot $slot";
    push @{$self->{slots}}, $slot;
    return;
}

########################################################
sub write
{
    my($self, $slot, $value)=@_;
    croak "$$: Missing slot" unless defined $slot;
    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }

    $value=substr($value, 0, 1);
    DEBUG and warn "Setting slot $slot to $value";

    shmwrite($self->{mem}, $value, $slot, 1)
        or warn "Writing shared memory slot $slot: $!";

    return;
}

########################################################
sub read
{
    my($self, $slot)=@_;
    return unless defined $slot;

    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }
    DEBUG and warn "Reading value $slot";

    my $value=" ";
    shmread($self->{mem}, $value, $slot, 1)
        or warn "Reading shared memory slot $slot: $!";
    return $value;
}

########################################################
sub status
{
    my($self)=@_;
    my @ret;

    my $n=$self->read_all();
    push @ret, ref($self);
    push @ret, "$self->{N} slots in the scoreboard";
    push @ret, join '', "Slots [", @$n, "]";
    push @ret, (0+@{$self->{slots}})." slots free";

    return join "\n    ", @ret;
}

1;

__DATA__

