use strict;

print <<__EOF;

*********************************************************
This package contains a number of scripts that use Wx.
If you want to use these scripts, please install it.
*********************************************************

__EOF

my $pmfile = 'Kamelon/lib/Syntax/Kamelon.pm';

use ExtUtils::MakeMaker;
WriteMakefile(
   NAME              => 'Syntax::Kamelon',
   VERSION_FROM      => $pmfile, # finds $VERSION, requires EU::MM from perl >= 5.5
   LICENSE           => 'gpl_3',
   PREREQ_PM         => {
      'Data::Dumper' => 0,
      'Module::Load::Conditional' => 0,
      'Template' => 0,
      'Term::ANSIColor' => 0,
      'Test::More' => 0,
      'XML::TokeParser' => 0.05,
      'Time::HiRes' => 0,
   },
   ABSTRACT_FROM     => 'lib/Syntax/Kamelon.pod', # retrieve abstract from module
   (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
          resources => {
              repository => {
                 type => 'git',
		 url  => 'git://github.com/haje61/Kamelon.git',
                 web  => 'https://github.com/haje61/Kamelon',
              },
          }})
      : ()
    ),
);
