# This -*- perl -*- script writes the Makefile for LWP::Parallel
# $Id: Makefile.PL,v 1.14 2004/02/10 15:19:10 langhein Exp $
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'LWP::Parallel',
    'ABSTRACT' => 'Extension for LWP to allow parallel HTTP and FTP access',
    'DISTNAME'  => 'ParallelUserAgent',
    'VERSION_FROM' => 'lib/LWP/Parallel.pm', # finds $VERSION
    'LICENSE'      => 'perl',
    'AUTHOR'       => 'Marc Langheinrich <marclang@cpan.org>, Mike South (maintainer) <msouth@cpan.org>',
    #
    # Not 100% sure what is needed here--I'm stripping out 
    # the old http protocol ones though because a recent change should remove
    # the dependency.  Passes tests; if you have problems after this change,
    # please submit a failing test.
    #
    'PREREQ_PM' => {
        'LWP'                    => 5.64,
        'IO::Socket::SSL'        => 0,
    },
);

package MY;

sub test
{
    q(
test: all
	$(FULLPERL) t/TEST 

);
}


