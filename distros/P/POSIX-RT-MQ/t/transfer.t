# $Id: transfer.t,v 1.5 2003/01/27 08:25:19 ilja Exp $

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
    use vars qw(@tests $testqueue @q_len @msg_len);
    @tests = ( \&test_integrity,
               \&test_nonblocking,
               \&test_blocking );
    # linux has a default maxmsg of 10 for non-privileged users
    # so use some low suitable whacky numbers
    #@q_len    = (1, 10, 128);
    @q_len    = (1, 5, 10);
    @msg_len  = (1, 128, 1024, 4096);
    $testqueue = '/testq_42';

    unless (_mq_avail()) {
        print "1..0 # Skip: mqueues not available\n";
        exit 0;
    }
    
    plan tests => scalar(@tests);
};

use Fcntl;
use POSIX::RT::MQ;

for (@tests)
{ 
    eval {$_->()}; 
    if($@) { warn("\n$@"); ok(0) } 
    else   { ok(1) } 
} 
 


sub test_integrity
{
    for my $q_len (@q_len)
    {
        for my $msg_len (@msg_len)
        {
            #print STDERR "test_integrity { mq_maxmsg=>$q_len, mq_msgsize=>$msg_len }\n";
            my $attr = { mq_maxmsg=>$q_len, mq_msgsize=>$msg_len };

            POSIX::RT::MQ->unlink($testqueue);
            my $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT, 0600, $attr) or die "cannot open($testqueue, O_RDWR|O_CREAT, 0600, ...): $!\n";

            my @messages = ();
            for (my $m=0; $m<$q_len; $m++)
            {
                my ($msg, $prio) = construct_message($msg_len, $m);
                push @messages, [$msg, $prio, $m];
                $mq->send($msg, $prio)  or die "cannot send(...): $!\n";
            }
            @messages = sort { ($b->[1]<=>$a->[1]) || ($a->[2]<=>$b->[2]) } @messages;
            for (my $m=0; $m<$q_len; $m++)
            {
                my ($msg,  $prio)  = $mq->receive  or die "cannot receive(): $!\n";
                my $saved = shift @messages;
                $msg eq $saved->[0] && $prio == $saved->[1]  or die "unexpected message and (or) priority\n";
            }
       }
    }       
    1;
}    

sub test_nonblocking
{
    my $q_len   = $q_len[-1];
    my $msg_len = $msg_len[-1];
    #print STDERR "test_nonblocking { mq_maxmsg=>$q_len, mq_msgsize=>$msg_len }\n";
    my $attr = { mq_maxmsg=>$q_len, mq_msgsize=>$msg_len };
    
    POSIX::RT::MQ->unlink($testqueue);
    my $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT|O_NONBLOCK, 0600, $attr)  or die "cannot open($testqueue, O_RDWR|O_CREAT, 0600, ...): $!\n";
    
    # receive from empty queue
    $mq->receive  and die "receive() OK from empty queue\n";
    
    # fill the queue        
    for (my $m=0; $m<$q_len; $m++)
    {
        my ($msg, undef) = construct_message($msg_len, $m);
        $mq->send($msg)  or die "cannot send(...): $!\n";
    }
    
    # send to full queue
    my ($msg, undef) = construct_message($msg_len, 0);
    $mq->send($msg)  and die "send() OK to full queue\n";
    
    1;      
}

sub test_blocking
{
    my $q_len   = $q_len[-1];
    my $msg_len = $msg_len[-1];
    #print STDERR "test_blocking { mq_maxmsg=>$q_len, mq_msgsize=>$msg_len }\n";
    my $attr    = { mq_maxmsg=>$q_len, mq_msgsize=>$msg_len };
    
    POSIX::RT::MQ->unlink($testqueue);
    my $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT, 0600, $attr)  or die "cannot open($testqueue, O_RDWR|O_CREAT, 0600, ...): $!\n";
    
    # receive from empty queue
    {
        my $timeout = '';
        local $SIG{ALRM} = sub { $timeout = 'TIMEOUT' };
        alarm(3);
        $mq->receive;
        $timeout eq 'TIMEOUT'  or die "receive() didn't block\n";
    }

    # fill the queue    
    for (my $m=0; $m<$q_len; $m++)
    {
        my ($msg, undef) = construct_message($msg_len, $m);
        $mq->send($msg)  or die "cannot send(...): $!\n";
    }
    
    # send to full queue
    {
        my $timeout = '';
        local $SIG{ALRM} = sub { $timeout = 'TIMEOUT' };
        my ($msg, undef) = construct_message($msg_len, 0);
        alarm(3);
        $mq->send($msg);
        $timeout eq 'TIMEOUT'  or die "send() didn't block\n";
    }
    
    1;      
}

sub construct_message
{
    my $msg_len = shift;
    my $msg_num = shift;
    my $all_chars = join '' => map { chr } (0..255);

    my $msg = "$msg_num ";
    $msg .= $all_chars  while length($msg) < $msg_len;
    substr($msg, $msg_len) = '';
    ($msg, $msg_num%8); # calculate prio
}
