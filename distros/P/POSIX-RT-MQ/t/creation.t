# $Id: creation.t,v 1.6 2003/01/27 08:25:19 ilja Exp $

use warnings;
use strict;

use Test;
BEGIN 
{     
    use vars qw(@tests $testqueue);
    @tests = ( \&test_open, 
               \&test_unlink, 
               \&test_name, 
               \&test_attributes,
               \&test_blocking );
    $testqueue = '/testq_42';
    
    plan tests => scalar @tests;
};

use Fcntl;
use POSIX::RT::MQ;

for (@tests)
{ 
    eval {$_->()}; 
    if($@) { warn("\n$@"); ok(0) } 
    else   { ok(1) } 
} 



sub test_open
{
    POSIX::RT::MQ->unlink($testqueue);
    my $mq;
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR)            and die "should fail: open($testqueue, O_RDWR)\n";
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT)    or  die "cannot open($testqueue, O_RDWR|O_CREAT): $!\n";
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR)            or  die "cannot open($testqueue, O_RDWR): $!\n";
    $mq = POSIX::RT::MQ->open($testqueue, O_RDONLY)          or  die "cannot open($testqueue, O_RDONLY): $!\n";
    $mq = POSIX::RT::MQ->open($testqueue, O_WRONLY)          or  die "cannot open($testqueue, O_WRONLY): $!\n";
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_NONBLOCK) or  die "cannot open($testqueue, O_RDWR|O_NONBLOCK): $!\n";
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT|O_EXCL)  and die "should fail: open($testqueue, O_RDWR|O_CREAT|O_EXCL)\n";
}    

sub test_unlink
{
    POSIX::RT::MQ->unlink($testqueue);
    my $mq;
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT)    or  die "cannot open($testqueue, O_RDWR|O_CREAT): $!\n";
    $mq->unlink()                                            or  die "cannot unlink(): $!\n";
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT)    or  die "cannot open($testqueue, O_RDWR|O_CREAT): $!\n";
    POSIX::RT::MQ->unlink($testqueue)                        or  die "cannot unlink($testqueue): $!\n";
    $mq->unlink()                                            and die "should fail: unlink()\n";
    POSIX::RT::MQ->unlink($testqueue)                        and die "should fail: unlink($testqueue)\n";
}

sub test_name
{
    POSIX::RT::MQ->unlink($testqueue);
    my $mq;
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT)    or  die "cannot open($testqueue, O_RDWR|O_CREAT): $!\n";
    $mq->name eq $testqueue                                  or  die "unexpected value from name()\n";
    $mq->unlink()                                            or  die "cannot unlink(): $!\n";
    defined($mq->name())                                     and die "unexpected defined value from name()\n";
}
        
sub test_attributes
{
    POSIX::RT::MQ->unlink($testqueue);
    my ($mq, $a1, $a2);

    $a1 = { mq_maxmsg=>128, mq_msgsize=>256 };
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT, 0600, $a1)  or  die "cannot open($testqueue, O_RDWR|O_CREAT, ...): $!\n";
    $a2 = $mq->attr                                                   or  die "cannot attr(): $!\n";
    ($a2->{mq_maxmsg}  == $a1->{mq_maxmsg})                           or  die "mq_maxmsg didn't match\n";
    ($a2->{mq_msgsize} == $a1->{mq_msgsize})                          or  die "mq_msgsize didn't match\n";
    ($a2->{mq_curmsgs} == 0)                                          or  die "mq_curmsgs != 0\n";
    ($a2->{mq_flags} & O_NONBLOCK)                                    and die "mq_flags - unexpectedly in non-blocking mode\n";
    
    $a1->{mq_flags} = $a2->{mq_flags} | O_NONBLOCK;
    $mq->attr($a1)                                                    or  die "cannot attr(a1): $!\n";
    $a2 = $mq->attr                                                   or  die "cannot attr(): $!\n";
    ($a2->{mq_flags} & O_NONBLOCK)                                    or  die "mq_flags - unexpectedly in blocking mode\n";
}    

sub test_blocking
{
    POSIX::RT::MQ->unlink($testqueue);
    
    my ($mq, $a, $bl);
    
    $a = { mq_maxmsg=>128, mq_msgsize=>256 };
    $mq = POSIX::RT::MQ->open($testqueue, O_RDWR|O_CREAT, 0600, $a)   or  die "cannot open($testqueue, O_RDWR|O_CREAT, ...): $!\n";

    # blocking mode here ...

    defined($bl = $mq->blocking)                    or  die "cannot blocking(): $!\n";
    $a = $mq->attr                                  or  die "cannot attr(): $!\n";
    ($bl && !($a->{mq_flags} & O_NONBLOCK))         or  die "blocking mode didn't match\n";

    $bl == $mq->blocking(0)                         or  die "blocking mode didn't match\n";

    defined($bl = $mq->blocking)                    or  die "cannot blocking(): $!\n";
    $a = $mq->attr                                  or  die "cannot attr(): $!\n";
    (!$bl && $a->{mq_flags} & O_NONBLOCK)           or  die "blocking mode didn't match\n";

    $bl == $mq->blocking(1)                         or  die "blocking mode didn't match\n";

    defined($bl = $mq->blocking)                    or  die "cannot blocking(): $!\n";
    $a = $mq->attr                                  or  die "cannot attr(): $!\n";
    ($bl && !($a->{mq_flags} & O_NONBLOCK))         or  die "blocking mode didn't match\n";
}

