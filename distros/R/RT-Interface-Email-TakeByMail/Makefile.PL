use inc::Module::Install;

name                 'RT-Interface-Email-TakeByMail';
all_from             'lib/RT/Interface/Email/TakeByMail.pm';
readme_from          'lib/RT/Interface/Email/TakeByMail.pm'; # README CPAN
readme_markdown_from 'lib/RT/Interface/Email/TakeByMail.pm'; # README.mkdn GitHub
include              'Module::Install::RTx';

# Allow build of a distribution without having an RT install
RTx 'RT-Interface-Email-TakeByMail' unless $ENV{DIST_BUILD};

WriteAll;

=head1  BUILD

    git clean -xfd
    DIST_BUILD=1 perl Makefile.PL
    make manifest
    make dist

=cut
