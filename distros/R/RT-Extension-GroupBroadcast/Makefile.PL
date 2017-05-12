use inc::Module::Install;

name        'RT-Extension-GroupBroadcast';
all_from    'lib/RT/Extension/GroupBroadcast.pm';
readme_from 'lib/RT/Extension/GroupBroadcast.pm';
include     'Module::Install::RTx';

# Allow build of a distribution without having an RT install
RTx 'RT-Extension-GroupBroadcast' unless $ENV{DIST_BUILD};

WriteAll;

=head1  BUILD

    git clean -xfd
    DIST_BUILD=1 perl Makefile.PL
    make manifest
    make dist

=cut
