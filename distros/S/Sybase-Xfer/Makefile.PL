#
# (c) 1999 Morgan Stanley Dean Witter and Co.
# See ..../src/LICENSE for terms of distribution.
#
# $Id$
#
use ExtUtils::MakeMaker;

print <<"LegalMumboJumbo";

This software is is licensed as open source code and is subject to the
terms and conditions of a license agreement that is set forth in the
included LICENSE file.  

If you have read the license agreement and accept its terms and
conditions, answer "yes" to continue with the installation.  If you
have not read the license agreement or do not accept its terms and
conditions, answer "no" and fire up your favorite text editor....

LegalMumboJumbo
    
print "Did you read the LICENSE file and agree to its terms and conditions? [y] ";
my $answer = <STDIN>;
exit 1 if $answer =~ /^n/i;

open(YES,">.LICENSE.ACCEPTED") || die "Unable to write .LICENSE.ACCEPTED: $!\n";
close(YES) || die "Unable to close .LICENSE.ACCEPTED: $!\n";

print "\n";

WriteMakefile(NAME           => 'Sybase::Xfer',
              VERSION_FROM   => 'Xfer.pm',
              EXE_FILES      => ['sybxfer'],
              PREREQ_PM      => { Sybase::DBlib => 0, 
                                  Tie::IxHash   => 0,
                                  Getopt::Long  => 0 },
             )          


