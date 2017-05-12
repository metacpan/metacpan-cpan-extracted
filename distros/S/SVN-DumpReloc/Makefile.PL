
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'SVN::DumpReloc',
               VERSION_FROM => 'lib/SVN/DumpReloc.pm',
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
               EXE_FILES => [ 'bin/svn-dump-reloc' ],
               MAN1PODS => { 'bin/svn-dump-reloc' => '$(INST_MAN1DIR)/svn-dump-reloc.1' }
             );
