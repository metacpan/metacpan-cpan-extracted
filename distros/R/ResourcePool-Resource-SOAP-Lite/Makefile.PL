#*********************************************************************
#*** Makefile.PL
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Makefile.PL,v 1.5 2011-01-31 13:49:38 mws Exp $
#*********************************************************************

use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Data::Dumper;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts;

$opts{NAME}      = 'ResourcePool::Resource::SOAP::Lite',
$opts{VERSION}   = '1.0103';
$opts{PREREQ_PM} = {'ResourcePool' => '1.0100'
                   ,'SOAP::Lite'};

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT} = 'SOAP::Lite bindings for ResourcePool';
    $opts{AUTHOR} = 'Markus Winand <mws@fatalmind.com>';
}

my $onlinetests = ExtUtils::MakeMaker::prompt('
During "make test" phase we may run tests against a SOAP server located
at the authors website.

Do you want to perform these tests in addition to core tests?', 'yes') =~ /^\s*(y)/i;

$opts{test} = {TESTS => join(' ', glob($onlinetests ? 't/*.t' : 't/[0-3]*.t'))};
WriteMakefile(%opts);
