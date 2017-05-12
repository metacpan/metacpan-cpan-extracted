#! /usr/bin/perl -w
#*********************************************************************
#*** t/30SOAP.t
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 40CallCmd.t,v 1.5 2009-11-25 10:33:35 mws Exp $
#*********************************************************************
use strict;
use Test;

use SOAP::Lite;
use ResourcePool;
use ResourcePool::Factory::SOAP::Lite;
use ResourcePool::Command::SOAP::Lite::Call;

BEGIN { plan tests => 9;};

# there shall be silence
$SIG{'__WARN__'} = sub {};

# Well, originally, back in 2003 I have hosted a actual cgi based SOAP service to support these tests.
# many years later (2009) cgi hosting is not so easly possible anymore for my site.
# So, I used a very-very-strange trick:
# i have just captuerd the output of my original SOAP service and stored the SOAP XML's in plain files.
# since there are three different cases i want to test, i created three different files with different responeses.
# I use now three different urls as "service" point to access. However, those are just static files which hold the responses captured before
# Since i want to test the CLIENT and not the service, this is perfectly legal, very secure and has better availability.
# however, the POST content which is pushed by the client to the service is actually ignored, so don't expect this to work if you add/change the testcases

sub getPoolForSpecificTestcase($) {
	my ($testid) = @_;
	my $urlpattern = "http://www.fatalmind.com/software/ResourcePool/perl/soap.test.%d.xml";
	
	my $f = ResourcePool::Factory::SOAP::Lite->new(sprintf($urlpattern, $testid));
	return ResourcePool->new($f, MaxExecTry => 2);
}

my $cmd = ResourcePool::Command::SOAP::Lite::Call->new('RPSLTEST');
ok (getPoolForSpecificTestcase(1)->execute($cmd, 'test_return') eq "hirsch");

eval {
	getPoolForSpecificTestcase(3)->execute($cmd, 'test_die');
};
my $ex = $@;
ok ($ex);
ok ($ex->isa('ResourcePool::Command::Exception'));
ok ($ex->rootException()->{faultstring} =~ /a dead deer/);
ok ($ex->getExecutions() == 2); # Server fault -> no NoFailoverException

eval {
	getPoolForSpecificTestcase(4)->execute($cmd, 'test_client_fault');
};
$ex = $@;
ok ($ex);
ok ($ex->isa('ResourcePool::Command::Exception'));
ok ($ex->rootException()->{faultstring} =~ /a deer has been shot/);
ok ($ex->getExecutions() == 1); # Client fault -> NoFailoverException

