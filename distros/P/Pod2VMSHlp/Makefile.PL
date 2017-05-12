#
# Makefile.PL for Pod2VMSHlp package - Peter Prymmer
#
# For compatability we simply test for PREREQ modules
# and alter the installation package if necessary (rather than
# failing to install with older Perl installations).
#

use Config;
use ExtUtils::MakeMaker;
use File::Copy;
my $dsr_test_ack = 0;
print "Testing for presence of the Pod::Parser module...";
eval "use Pod::Parser;";
if ($@) { 
    print "  Not found.\n\n";
    print << "EOPODPARSERMESS0";
The Pod::Dsr module and related utilites such as pod2rno cannot 
work without having the Pod::Parser module already installed.

EOPODPARSERMESS0
    print "Do you still wish to continue with this installation? [n] ";
    chomp($response = <STDIN>);
    print "\n\n";
    if ($response !~ /^y/i) {
        print << "EOPODPARSERMESS1";
You could install Pod::Parser from CPAN then return to the 
installiation of this package.

EOPODPARSERMESS1
        if ($] < 5.006) {
            print << "EOPODPARSERMESS2";

Your Perl version, $], seems a bit dated.  Note that Pod::Parser
comes packaged with later versions of Perl.

EOPODPARSERMESS2
    
        }
    print "Quitting installation at your request.\n";
    exit;
    }
    else {
        print "Do you understand that the dsr tests will probably fail? [y] ";
        chomp($response = <STDIN>);
        print "\n\n";
        if ($response !~ /^n/i) {
            $dsr_test_ack = 1;
        }
    }
}
else {
    print "ok\n\n";
}

my $exe_type = '';
if ($^O eq 'VMS') { $exe_type = '.com'; }

WriteMakefile(
    'NAME'     => 'Pod2VMSHlp',
    'PL_FILES' => {'pod2rno.PL' => "pod2rno$exe_type"},
    'EXE_FILES' => [('pod2hlp', 'pod2hlb', "pod2rno$exe_type")],
    'PMLIBDIRS'   => [qw(Pod)],
    'linkext' => { LINKTYPE => ''},
    'dist'     => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
    'VERSION_FROM' => 'Pod/Hlp.pm',
);

my $make = $Config{'make'} || 'mms';
my $make_test = "$make test";

print << "EOMAKEMESSAGE";

In order to build, test, and install the modules and utilities run:

    $make
    $make_test
    $make install

EOMAKEMESSAGE
if ($^O eq 'VMS') {

    print << "EOSYMBMESSAGE";
To set up foreign symbols for the utilities add:

    \$ pod2hlp == \@PERL_ROOT:[utils]pod2hlp
    \$ pod2hlb == \@PERL_ROOT:[utils]pod2hlb
    \$ pod2rno == \@PERL_ROOT:[utils]pod2rno.com

to your LOGIN.COM or your PERL_SETUP.COM.
EOSYMBMESSAGE

}

