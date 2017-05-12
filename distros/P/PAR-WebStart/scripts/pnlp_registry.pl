use strict;
use warnings;
use File::Which;
use ExtUtils::MakeMaker;
my $Registry;
use Win32::TieRegistry 0.20 (
                             TiedRef => \$Registry,  
                             Delimiter => "/",
                            ); 

print <<"END";

This script will add the appropriate registry
settings necessary to use perlws of PAR::WebStart
to open PNLP files.

END

my $ans = prompt("Do you wish to continue?", 'yes');
die "script aborted" unless ($ans =~ /^y/i);

my $perlws = which('perlws');
die qq{Cannot find "perlws" in the PATH} unless $perlws;
my $perl = which('perl');
die qq{Cannot find "perl" in the PATH} unless $perl;

my $root = $Registry->{"HKEY_CLASSES_ROOT/"};
$root->{"PNLPFile/"} = {
                        "/" => "PNLPFile",
                        "DefaultIcon/" => {"/" => "$perl,0"},
                        "shell/" => {"/" => "open"},
                       } or die "$^E";
$root->{"PNLPFile/shell/"} = {
                             "/" => "open",
                             "open/" => {"/" => "command"},
                             } or die "$^E";
$root->{"PNLPFile/shell/open/"} = {
                                   "/" => "command",
                                   "command/" => {"/" => "$perlws \"%1\""},
                             } or die "$^E";

$root->{".pnlp/"} = {
                     "/" => "PNLPFile",
                     "/Content Type" => "application/x-perl-pnlp-file",
                    } or die "$^E";

print "\nRegistry entries successfully added\n";
