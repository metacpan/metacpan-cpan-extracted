#*********************************************************************
#*** Makefile.PL
#*** Copyright (c) 2004 by Texas A&M University <jsmith@cpan.org>
#*** Based on Makefile.PL
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Makefile.PL,v 1.1 2004/04/15 20:43:59 jgsmith Exp $
#*********************************************************************

use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Data::Dumper;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts;

$opts{NAME}      = 'ResourcePool::Resource::Alzabo',
$opts{VERSION}   = '1.0100';
$opts{PREREQ_PM} = {'ResourcePool' => '1.0100'
                   ,'ResourcePool::Resource::DBI' => '1.0100'
                   ,'Alzabo'};

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT} = 'Alzabo bindings for ResourcePool';
    $opts{AUTHOR} = 'James Smith <jsmith@cpan.org>';
}

WriteMakefile(%opts);

