use lib qw(lib);
use Package::Install;

my %mm_args = (
               'NAME'         => 'Package-Tools',
               'VERSION_FROM' => 'lib/Package/Base.pm',
               'PREREQ_PM'    => {
                                  Carp                => 0,
                                  Config::IniFiles    => 2.38,
                                  ExtUtils::MakeMaker => 0,
                                  File::Spec          => 0.87,
                                  Getopt::Long        => 2.26,
                                  Log::Log4perl       => 0.47,
                                  Term::ANSIColor     => 0,
                                  Text::ParseWords    => 3.2,
                                  Text::Wrap          => 2001.0131,
                                 },
               'ABSTRACT'     => 'Base and utility classes for package development and production',
               'AUTHOR'       => 'Allen Day <allenday@ucla.edu>',
              );

my $install = Package::Install->new(bootstrap=>1);
$install->write_makefile(%mm_args, bootstrap=>1);
