# $Id: constants.t,v 1.2 2003/01/27 10:47:02 ilja Exp $

use warnings;
use strict;

use Test;
BEGIN 
{     
    use vars qw(@tests);
    @tests = ( \&test_mq_open_max, 
               \&test_mq_prio_max );

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



sub test_mq_open_max
{
    my $val = POSIX::RT::MQ::MQ_OPEN_MAX;
#    warn "\nPOSIX::RT::MQ::MQ_OPEN_MAX=$val\n";
    if ($^O =~ /^(linux|freebsd)$/) {
        defined($val) && $val== -1
           or die "expecting MQ_OPEN_MAX to be -1 on $^O";
    } else {
        defined($val) && $val>=0  
            or die "strange value of MQ_OPEN_MAX: ", (defined $val ? $val : '"undef"'), "\n";
    }
}

sub test_mq_prio_max
{
    my $val = POSIX::RT::MQ::MQ_PRIO_MAX;
#    warn "\nPOSIX::RT::MQ::MQ_PRIO_MAX=$val\n";
    defined($val) && $val>=0  
        or die "strange value of MQ_OPEN_MAX: ", (defined $val ? $val : '"undef"'), "\n";
}

