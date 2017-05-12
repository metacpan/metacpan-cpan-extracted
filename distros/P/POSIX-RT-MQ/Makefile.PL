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
       AUTHOR     => 'Ilja Tabachnik <billy@arnis-bsl.com>') : ()),
    'DEFINE'      => '', # e.g., '-DHAVE_SOMETHING'
    'INC'         => '', # e.g., '-I/usr/include/other'
);

OS_SPECIFIC:
{
    SOLARIS:
    {
        $^O =~ /solaris/i  or last SOLARIS;
        my $rev = `uname -r`;
        $? == 0  or die "cannot execute 'uname -r'\n";
        if ($rev > 5.6) { $make_opts{LIBS} = ['-lrt'] }
        else            { $make_opts{LIBS} = ['-lposix4'] } 
        last OS_SPECIFIC;
    }
    
    AIX:
    {
        $^O =~ /aix/i  or last AIX;
        warn "\nPOSIX message queues are not supported in $^O.\n".
             "You are likely to be able to compile this module but any\n".
             "calls will fail with 'Function not implemented' error.\n".
             "However you may try ...\n\n";
        $make_opts{LIBS} = [];
        last OS_SPECIFIC;
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
