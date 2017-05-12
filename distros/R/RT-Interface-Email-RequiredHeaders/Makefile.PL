use inc::Module::Install;

name        'RT-Interface-Email-RequiredHeaders';
all_from    'lib/RT/Interface/Email/RequiredHeaders.pm';
readme_from 'lib/RT/Interface/Email/RequiredHeaders.pm';
include     'Module::Install::RTx';

# Allow build of a distribution without having an RT install
RTx 'RT-Interface-Email-RequiredHeaders' unless $ENV{DIST_BUILD};

WriteAll;

=head1  BUILD

    git clean -xfd
    DIST_BUILD=1 perl Makefile.PL
    make manifest
    make dist

=cut
