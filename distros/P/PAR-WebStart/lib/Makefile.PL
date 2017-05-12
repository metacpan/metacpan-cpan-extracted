use strict;
use ExtUtils::MakeMaker;
my %opts = (
            NAME => 'PAR::WebStart',
            VERSION_FROM => 'PAR/WebStart.pm',
            PMLIBDIRS => [qw(PAR)],
            dist   => {
                         SUFFIX   => 'gz',
                         COMPRESS => 'gzip -9f',
                        },
            PM => {'PAR/WebStart.pm' => 
                   '$(INST_LIBDIR)/WebStart.pm',
                  'PAR/WebStart/PNLP.pm' => 
                  '$(INST_LIBDIR)/WebStart/PNLP.pm',
                  'PAR/WebStart/Util.pm' => 
                  '$(INST_LIBDIR)/WebStart/Util.pm',
                 },
           );

WriteMakefile( %opts);
