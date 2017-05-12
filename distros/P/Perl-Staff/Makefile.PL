use inc::Module::Install;

name     'Perl-Staff';
all_from 'lib/Perl/Staff.pm';
author   'Perl event staff <sewi@cpan.org>';
license  'perl';

#build_requires 'Test::More';

# List the modules that we have shown
# let's not require every release of Perl::Staff the installation of these:
#requires 'perl'                     => '5.010001';
#requires 'Moose'                    => 0;
#requires 'Padre'                    => 0;
#requires 'Padre::Plugin::Perl6'     => 0;
#requires 'Padre::Plugin::PerlTidy'  => 0;
#requires 'Perl::Critic'             => 0;

# and some other things that are not on CPAN
# requires 'OTRS'                 => 0;
# requires 'Foswiki'              => 0;

auto_install;

WriteAll;

