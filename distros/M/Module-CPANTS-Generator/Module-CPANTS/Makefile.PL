use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'	=> 'Module::CPANTS',
  'VERSION_FROM' => 'lib/Module/CPANTS.pm',
  'PREREQ_PM' => {'Test::More' => '0.01'},
  'PL_FILES' => {},
);

sub MY::libscan {
    my $path = $_[1];
    return '' if $path =~ /\B\.svn\b/;
    return $path;
}
