require 5.006; # lower versions of perl not supported

use Config;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

{
   local $ENV{CC} = "$Config{cc} $Config{cppflags} $Config{ccflags} $Config{cccdlflags}";
   print "$ENV{CC}\n";
   system "cd sndlib && ./configure";
}

@pack = ["audio.pd",Audio,PDL::Audio];
%hash = pdlpp_stdargs(@pack);

$hash{depend}{'Audio.o'} = 'xlib.h remez.h';
$hash{depend}{'xlib.o'} = 'xlib.h remez.h';
$hash{OBJECT} = "Audio.o xlib.o remez.o";

do "./config.pl";

$hash{PM}{'Scales.pm'} = '$(INST_LIBDIR)/Audio/Scales.pm';
$hash{PM}{'Pitches.pm'} = '$(INST_LIBDIR)/Audio/Pitches.pm';
                       
push @{$hash{DIR}}, "sndlib";

WriteMakefile(%hash,
   'dist'	=> {
                   PREOP	=> 'pod2text Audio.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
                   COMPRESS	=> 'gzip -9v',
                   SUFFIX	=> '.gz',
                  },
   MYEXTLIB	=> "sndlib/sndlib.a",
   VERSION_FROM => 'audio.pd',
   DIR	=> [],
   EXE_FILES => ["bin/pdlaudio-demo", "bin/pdlaudio-birds"],
   XS	=> { "Audio.xs" => "Audio.c" },
);

sub MY::postamble {
   my $self=shift;
   pdlpp_postamble(@pack)."

.EXPORT_ALL_VARIABLES:

force:

\$(MYEXTLIB): force
	cd sndlib && \$(MAKE)

clean::
	cd sndlib && \$(MAKE) clean

";
}
