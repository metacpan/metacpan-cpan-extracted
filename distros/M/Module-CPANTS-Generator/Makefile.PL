use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'	=> 'Module::CPANTS::Generator',
  'VERSION_FROM' => 'lib/Module/CPANTS/Generator.pm',
  'PREREQ_PM' => {
    'CPANPLUS'    => '0.042',
    'DBD::SQLite' => '0.01',
    'File::Find::Rule' => '0.01',
    'LWP::Simple' => '0.01',
    'Pod::POM'  => '0.01',
    'Pod::Simple'  => '0.01',
    'String::Approx'  => '0.01',
    'Template'    => '2.08',
    'Test::More'  => '0.01',
  },
  'PL_FILES' => {},
  'DIR' => [],
);

sub MY::libscan {
    my $path = $_[1];
    return '' if $path =~ /\B\.svn\b/;
    return $path;
}
