#*********************************************************************
#*** Makefile.PL
#*** Copyright (c) 2020 by Markus Winand <mws@fatalmind.com>
#*** $Id$
#*********************************************************************

use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Data::Dumper;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts;

$opts{NAME}      = 'ResourcePool::Resource::Net::LDAP',
$opts{VERSION}   = '1.0003';
$opts{PREREQ_PM} = {'ResourcePool' => '1.0000'
                   ,'Net::LDAP'};

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ABSTRACT} = 'Net::LDAP bindings for ResourcePool';
    $opts{AUTHOR} = 'Markus Winand <mws@fatalmind.com>';
}

WriteMakefile(%opts);
