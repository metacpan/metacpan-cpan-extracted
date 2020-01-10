use strict;
use warnings;
use lib 'lib';
use Test::More 'no_plan';
use File::Spec;

BEGIN {
    use_ok("Net::SyslogNg");
}

can_ok("Net::SyslogNg", "new");

my $syslog = Net::SyslogNg->new(
    -debug      => 1,
);


$syslog->send();


