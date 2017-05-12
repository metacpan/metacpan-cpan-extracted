# Makefile.PL for OpenThought::XML2Hash                 http://openthought.net
# -------------------------------------                 eric at openthought.net

use lib ".";
use ExtUtils::MakeMaker qw(prompt);

# ExtUtils::AutoInstall Bootstrap Code, version 7.
BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.45;$p->VERSION||0>=$v
or+eval"use $p $v;1"or+do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};
(!defined($e)||$e!~m/--(?:default|skip|testonly)/and-t STDIN or
eval"use ExtUtils::MakeMaker;WriteMakefile(PREREQ_PM=>{'$p',$v}
);1"and exit)and print"==> $p $v required. Install it from CP".
"AN? [Y/n] "and<STDIN>!~/^n/i and print"*** Installing $p\n"and
do{if (eval '$>' and lc(`sudo -V`) =~ /version/){system('sudo',
$^X,"-MCPANPLUS","-e","CPANPLUS::install $p");eval"use $p $v;1"
||system('sudo', $^X, "-MCPAN", "-e", "CPAN::install $p")}eval{
require CPANPLUS;CPANPLUS::install$p};eval"use $p $v;1"or eval{
require CPAN;CPAN::install$p};eval"use $p $v;1"||die"*** Please
manually install $p $v from cpan.org first...\n"}}}

# The XML Parser problems seem to be better in newer Linux distributions.
# XML::Parser 2.30 works fine on several system I've tested.  I'm commenting
# out the below code, let's see how this works.

# XML::Parser Code
#my $p='XML::Parser'; eval"use $p 2.29;1" or(print
#       "*** Fetching $p.\n"), require CPAN,
#       CPAN::Shell->install("C/CO/COOPERCL/XML-Parser-2.29.tar.gz");
#       eval "use $p 2.29;1" or die "*** Please install $p manually.\n";

use ExtUtils::AutoInstall (
   -version             => '0.26',
   -core                => [
        XML::Parser     => '2.29',
   ],
);

WriteMakefile(
    AUTHOR        => 'Eric Andreychek (eric at openthought.net)',
    ABSTRACT      => 'Convert XML Data to a Hash',
    NAME          => 'OpenThought::XML2Hash',
    DISTNAME      => 'OpenThought-XML2Hash',
    VERSION_FROM  => 'lib/OpenThought/XML2Hash.pm',
);

