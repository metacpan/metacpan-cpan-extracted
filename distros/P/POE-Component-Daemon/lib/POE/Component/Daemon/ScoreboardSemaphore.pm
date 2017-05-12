#$Id: ScoreboardSemaphore.pm 760 2011-05-18 18:14:30Z fil $
########################################################
package POE::Component::Daemon::Scoreboard;

use 5.00405;
use strict;

use vars qw($VERSION $UNIQUE);

use IPC::SysV qw(IPC_PRIVATE S_IRWXU IPC_CREAT SEM_UNDO);
use IPC::Semaphore;
use Carp;

$VERSION = '0.1300';

sub DEBUG () { 1 }

sub FS () { "\x1c" }
sub EOT () { "\x03" }

########################################################
sub new
{
    my($package, $N)=@_;
    if($UNIQUE) {
        warn "This should be only one $package.  Reusing previous one.";
        return $UNIQUE;
    }

    my $self=bless {N=>$N}, $package;

    $self->{semaphore}=IPC::Semaphore->new(IPC_PRIVATE, 2, 
                                                S_IRWXU | IPC_CREAT);
    $self->{semaphore}->setall(1, 1);
    $self->{have}='';

    my $size = $N* 5 + 1;
    $self->{mem}=shmget(IPC_PRIVATE, $size, S_IRWXU);
    $self->{mem_size}=$size;
    $self->{slots}=[reverse 0..($N-1)];

    my $blank=EOT;
    shmwrite($self->{mem}, $blank, 1, $self->{mem});

    die "Unable to create shared memory: $!\n" unless $self->{mem};

    $UNIQUE=$self;

    return $self;
}

########################################################
sub grab_sem
{
    my($self)=@_;
    return if $self->{have};
    $self->{semaphore}->op(0, -1, SEM_UNDO) or die "Decrementing semaphore: $!\n";
    $self->{have}=1;
    return;
}

########################################################
sub release_sem
{
    my($self)=@_;
    return unless $self->{have};
    $self->{semaphore}->op(0, +1, SEM_UNDO) or die "Releasing semaphore: $!\n";
    $self->{have}=0;
    return;
}

########################################################
sub read_all
{
    my($self)=@_;
    $self->grab_sem();

    my $str;
    shmread($self->{mem}, $str, 0, $self->{mem_size})
        or die "Unable to read shared memory: $!\n";
    # truncate it
    substr($str, index($str, EOT))='';

    my $ret=[split FS, $str];

    $self->release_sem;
    return $ret;
}

########################################################
sub write_all
{
    my($self, $values)=@_;
    $self->grab_sem();

    my $str=join FS, @$values;
    $str.=EOT;
    my $length=length($str);

    die "Can't write more then $self->{size} bytes to shared memory!"
        unless $length < $self->{mem_size};

    # pad it
    # $str.=join '', $str, EOT x ($self->{mem_size} - $length);
    shmwrite($self->{mem}, $str, 0, length($str))
        or die "Unable to write shared memory: $!\n";

    $self->release_sem;
    return;
}

########################################################
sub add
{
    my($self, $value)=@_;
    return unless @{$self->{slots}};
    my $slot=pop @{$self->{slots}};
    $self->write($slot, $value);
    DEBUG and warn "Added slot $slot";
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
    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }

    $value=substr($value, 0, 4);
    DEBUG and warn "Setting slot $slot to $value";

    $self->grab_sem();
    my $values=$self->read_all();
    $values->[$slot]=$value;

    $self->write_all($values);

    $self->release_sem();
    return;
}

########################################################
sub read
{
    my($self, $slot)=@_;
    if($slot >= $self->{N}) {
        carp "$slot isn't a known slot\n";
        return;
    }
    DEBUG and warn "Reading value $slot";
    my $values=$self->read_all();
    return $values->[$slot];
}

########################################################
sub status
{
    my($self)=@_;
    my @ret;

    push @ret, "$self->{N} slots in the scoreboard";    
    push @ret, (0+@{$self->{slots}}), " slots free";
    my $state=$self->{semaphore}->getncnt(0);
    push @ret, "$state processes want the scoreboard";

    return join "\n", @ret;
}

1;

__DATA__


