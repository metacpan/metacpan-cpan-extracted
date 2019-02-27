# $Id: Makefile.PL,v 1.7 2003/01/23 09:01:22 ilja Exp $

require 5.006;
use ExtUtils::MakeMaker;

%make_opts =
(
    'NAME'         => 'POSIX::RT::MQ',
    'VERSION_FROM' => 'MQ.pm', 
    'PREREQ_PM'	   => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'MQ.pm', 
       #AUTHOR     => 'Ilja Tabachnik <billy@arnis-bsl.com>') : ()),
       AUTHOR     => 'Wieger Opmeer <wiegerop@cpan.org>') : ()),
    'DEFINE'      => '', # e.g., '-DHAVE_SOMETHING'
    'INC'         => '', # e.g., '-I/usr/include/other'
    'LICENSE'  => 'perl',
    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/a6502/POSIX-RT-MQ/issues',
	    },
            homepage => 'https://github.com/a6502/POSIX-RT-MQ',
            repository => {
                type => 'git',
                url  => 'https://github.com/a6502/POSIX-RT-MQ.git',
                web  => 'https://github.com/a6502/POSIX-RT-MQ',
            },
        },
    },
);

OS_SPECIFIC:
{
    DEFAULT:
    {
        $^O =~ /^(linux|freebsd|netbsd)$/ or last DEFAULT;
	$make_opts{LIBS} = ['-lrt'];
        last OS_SPECIFIC;
    }

    SOLARIS:
    {
        $^O eq 'solaris' or last SOLARIS;
        my $rev = `uname -r`;
        $? == 0  or die "cannot execute 'uname -r'\n";
        if ($rev > 5.6) { $make_opts{LIBS} = ['-lrt'] }
        else            { $make_opts{LIBS} = ['-lposix4'] } 
        last OS_SPECIFIC;
    }
    
    # fixme: is this still true?
    AIX:
    {
        $^O eq 'aix' or last AIX;
        warn "\nPOSIX message queues are not supported in $^O.\n".
             "You are likely to be able to compile this module but any\n".
             "calls will fail with 'Function not implemented' error.\n".
             "However you may try ...\n\n";
        $make_opts{LIBS} = [];
        last OS_SPECIFIC;
    }

    WINDOWS:
    {
        $^O eq 'MSWin32' or last WINDOWS;
        warn "\nPOSIX message queues are not supported in $^O.\n";
	die "OS unsupported";
    }
    
    UNKNOWN:
    {
        warn "\nThis version of $make_opts{NAME} has not beed tested on '$^O' platform.\n".
             "If you are lucky enough to get it working please drop me a note.\n".
             "If not (and you know POSIX message queues are supported on this platform)\n".
             "please inform me anyway - maybe we'll be able to do a port.\n\n";
             
        $make_opts{LIBS} = ['-lrt'];   # just a guess ...
    }
}

WriteMakefile(%make_opts);
