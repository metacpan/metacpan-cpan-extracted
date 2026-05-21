package Qpsmtpd::Constants;
use strict;
use warnings;
use Exporter 'import';

# Stubbed values, distinct so a test can tell them apart.
use constant DECLINED => 909;
use constant DENY     => 911;
use constant LOGWARN  => 1;
use constant LOGINFO  => 2;
use constant LOGDEBUG => 3;

our @EXPORT = qw(DECLINED DENY LOGWARN LOGINFO LOGDEBUG);
1;
