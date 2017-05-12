use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $PreReq = {};

if ( "\L$^O" =~ m/win32/ )
	{
	$PreReq->{'Term::Screen::Win32'} = 0.01;
	}
else
	{
	$PreReq->{'Term::Screen'} = 1.09;
	};

$PreReq->{'Carp'}      = 0;
$PreReq->{'Tie::Hash'} = 0;

WriteMakefile(
    NAME              => 'Term::Screen::Uni',
    VERSION_FROM      => 'lib/Term/Screen/Uni.pm', # finds $VERSION
    PREREQ_PM         => $PreReq, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Term/Screen/Uni.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Podolsky <tpaba@cpan.org>') : ()),
);
