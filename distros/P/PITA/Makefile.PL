use inc::Module::Install::DSL 1.04;

all_from      lib/PITA.pm
requires_from lib/PITA/Guest/Server.pm
requires_from lib/PITA/Guest/Server/HTTP.pm
requires      Carp                       0
requires      version                    0.70
requires      File::Spec                 3.29
requires      File::Basename             0
requires      File::Temp                 0
requires      File::Path                 0
requires      File::Copy                 0
requires      File::Flock                104.111901 unless win32
requires      File::Remove               1.51
requires      Getopt::Long               0
requires      Storable                   2.14
requires      File::Find::Rule           0.30
requires      Data::GUID                 0.042
requires      Archive::Extract           0.18
requires      URI                        1.35
requires      Params::Util               1.00
requires      Probe::Perl                0.01
requires      Process                    0.16
requires      Process::YAML              0
requires      PITA::XML                  0.50
requires      PITA::Scheme               0.43
requires      PITA::Image                0.60
requires      POE::Declare               0.58
requires      POE::Declare::HTTP::Server 0.05
requires      POE::Wheel::Run            1.299
test_requires Test::More                 0.47
test_requires Test::Script               1.02
test_requires Test::POE::Stopping        1.07
test_requires POE::Declare::HTTP::Client 0.02
no_index      directory                  doc
