#!/usr/bin/perl -w
use strict;

#########################

BEGIN { $| = 1; print "1..45\n"; }
use POE::Component::Daemon::Scoreboard;
use POSIX qw(SIGUSR1 SIGKILL);
# use Religion::Package qw(1 1);

my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";


#########################
my $SB=POE::Component::Daemon::Scoreboard->new(10);
die "Unable to create scoreboard!\n" unless $SB;

print "ok 2\n";

my $Q=3;

#########################
my(%slots, $slot);
foreach my $q (0..10) {

    $slot=$SB->add('FORK');
    if($q==10) {
        print "not " if defined $slot;
        print "ok $Q\n";
        $Q++;
        next;
    }
    print "not " unless defined $slot;
    print "ok $Q\n";
    $Q++;

    my $pid=fork;
    die "Can't fork: $!" unless defined $pid;
    if($pid) {
        $slots{$slot}=$pid;
    }
    else {
        child($slot);
    }
}

#########################
my $q=$SB->read(9);
print "not " unless $q;
print "ok $Q\n";
$Q++; 

#########################
## wait for all the children to set their slot
unless(wait_for(\%slots)) {
    skip(20);
}

#########################
# make sure the all have the right value.  then tell 'em to go to the 
# next step
foreach my $sl (keys %slots) {
    my $q=$SB->read($sl);
    print "not " unless $q eq 'h';
    print "ok $Q\n";
    $Q++;
    kill SIGUSR1, $slots{$sl} or warn $!;
}

#########################
unless(wait_for(\%slots, 'r')) {
    foreach my $pid (values %slots) {
        kill SIGKILL, $pid;
    }
}

#########################
foreach my $sl (keys %slots) {
    $SB->drop($sl);
}
print "ok $Q\n";




##########################################################################
sub wait_for
{
    my($slots, $V)=@_;
    my %todo=%$slots;
    my $now=time;
    do {
        sleep 1;
        my $values=$SB->read_all;

        foreach my $sl (keys %todo) {
            if($V) {
                next unless ($values->[$sl]||'') eq $V;
            }
            else {
                next if ($values->[$sl]||'') eq 'F';
            }
            print "ok $Q\n";
            $Q++;
            delete $todo{$sl};
        }
        if(time - $now > 120) {      # 2 minute timeout
            warn "Timed out!";
            foreach (keys %todo) {
                print "not ok $Q\n";
                $Q++;
            }
            return;
        }
    } while(keys %todo);
    return 1;
}


##########################################################################
sub child
{
    my($slot)=@_;
    $SIG{USR1}=sub {
        $SB->write($slot, 'ribit!');
        exit 0;
    };
    $SB->write($slot, 'honk');
    sleep 1000;
    die "$$: Woah!  Why did I get here?\n";
    exit;
}
