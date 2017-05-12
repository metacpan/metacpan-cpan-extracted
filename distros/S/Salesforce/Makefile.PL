#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

my $SFDC_CONFIG_FILE = "t/sfdc.cfg";

use vars qw($user $pass);
eval "require $SFDC_CONFIG_FILE;";

print <<END;
Several tests need to be run in order to test the Salesforce Perl module.
You MUST supply a Saleforce username and password in order to proceed.

END

$user = ExtUtils::MakeMaker::prompt('Enter user name:', $user);
$pass = ExtUtils::MakeMaker::prompt('Enter password:', $pass);
$user = '' unless defined $user;
$pass = '' unless defined $pass;
open(CFGFILE, ">$SFDC_CONFIG_FILE") || die "$SFDC_CONFIG_FILE: $!\n";
print CFGFILE <<EOF;
\$user = '$user';
\$pass = '$pass';
1;
EOF
close(CFGFILE);

WriteMakefile(
    VERSION => '0.57',
    NAME    => 'Salesforce',
    PREREQ_PM    => { 'SOAP::Lite' => 0.55 },
);
