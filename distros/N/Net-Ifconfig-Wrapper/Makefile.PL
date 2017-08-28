use 5.008004;

use warnings;
use strict;

# TODO: convert to Module::Install
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %supported = ('freebsd' => 1,
                 'solaris' => 1,
                 'linux'   => 1,
                 'openbsd' => 1,
                 'MSWin32' => 1,
                 'darwin'  => 1,
                 'cygwin'  => 1,
                );

$supported{$^O}
	or warn "\nWARNING! Your system '$^O' is not supported\b\n\n";

my $preReq = {'POSIX' => 0,};

if ( $^O eq 'MSWin32' )
	{
	Win32::IsWinNT()
		or warn "\nWARNING! Only WinNT (from Win2K) is supported\b\n\n";
	$preReq->{'Win32::API'}      = 0;
	$preReq->{'Win32::WinError'} = 0;
	};

if ( $^O eq 'cygwin' )
	{
	$preReq->{'Win32::API'}      = 0;
	$preReq->{'Win32::WinError'} = 0;
	};

WriteMakefile(
    NAME              => 'Net::Ifconfig::Wrapper',
    VERSION_FROM      => 'lib/Net/Ifconfig/Wrapper.pm', # finds $VERSION
    PREREQ_PM         => $preReq, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Ifconfig/Wrapper.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Podolsky <tpaba@cpan.org>') : ()),
);

__END__
