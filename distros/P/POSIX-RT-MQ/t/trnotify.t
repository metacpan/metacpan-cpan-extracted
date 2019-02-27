# $Id: trnotify.t,v 1.3 2003/01/27 08:25:19 ilja Exp $

use warnings;
use strict;

use Test;

sub _mq_avail {
    # currently only for freebsd
    return 1 unless $^O =~ /^(freebsd)$/;
    my $mqfs = `mount | fgrep mqueuefs`;
    return 1 if $mqfs and $mqfs =~ 'mqueuefs';
    warn "skipping tests becasue mqueuefs is not mounted";
    return 0;
}

BEGIN 
{     
    use vars qw(@tests $testqueue $attr $msg $prio);
    @tests = ( \&test_sighash );
    $testqueue = '/testq_42';
    #$attr = { mq_maxmsg=>16, mq_msgsize=>256 };
    # linux has a default maxmsg of 10 for non-privileged users
    # so use some low suitable whacky numbers
    $attr = { mq_maxmsg=>9, mq_msgsize=>256 };
    ($msg, $prio) = ("A Sample Message!", 1);

    unless (_mq_avail()) {
        print "1..0 # Skip: mqueues not available\n";
        exit 0;
    }

    plan tests => scalar(@tests);
};

use Fcntl;
use POSIX;
use POSIX::RT::MQ;

for (@tests)
{ 
    eval {$_->()}; 
    if($@) { warn("\n$@"); ok(0) } 
    else   { ok(1) } 
} 

 

sub test_sighash
{
    POSIX::RT::MQ->unlink($testqueue);
    my $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT, 0600, $attr)  or die "cannot open($testqueue, O_RDWR|O_CREAT, 0600, ...): $!\n";
    
    # $mq->notify() and die "notify() OK while expected to fail\n";
    # WO: my reading of http://pubs.opengroup.org/onlinepubs/007904975/functions/mq_notify.html
    # WO: is that a null mq_notify on mq without notifications is not an error:
    $mq->notify() or die "notify() failed while expected to be OK\n";

    my $got_usr1 = 0;
    local $SIG{USR1} = sub { $got_usr1 = 1 };
    $mq->notify(SIGUSR1)  or die "cannot notify(SIGUSR1): $!\n";

    defined(my $pid = fork)  or die "cannot fork: $!\n";
    unless ($pid) #child...
    {
        undef $mq;
        $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_NONBLOCK)  or  exit(1);
        exit ($mq->send($msg, $prio) ? 0 : 2);
    }

    # wait until the child puts a message on the queue and terminates
    waitpid($pid, 0);
    # ok, if we still didn't get the notification let's give the system one more second
    $got_usr1  or  select(undef, undef, undef, 1);

    $got_usr1  or die "didn't get the SIGUSR1 :-(\n";
    # really got a message?
    defined $mq->blocking(0)        or  die "cannot blocking(0): $!\n";
    my ($m, $p) = $mq->receive()    or  die "cannot receive(): $!\n";
    ($m eq $msg  &&  $p == $prio)   or  die "unexpected message received\n";

    # now we should be alredy deregistered from notifications
    # $mq->notify()  and die "notify() OK while expected to fail\n";
    # WO: see note above
    $mq->notify() or die "notify() failed while expected to be OK\n";

    1;
}

