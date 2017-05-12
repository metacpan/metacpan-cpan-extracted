use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Socket::NonBlock',
    'VERSION_FROM'	=> 'NonBlock.pm', # finds $VERSION
    'PREREQ_PM'		=> {'IO::Select' => 0.01, 'IO::Socket' => 0.01, 'POSIX' => 0.01, 'Carp' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'NonBlock.pm', # retrieve abstract from module
       AUTHOR     => 'Daniel Podolsky, <tpaba@cpan.org>') : ()),
);
