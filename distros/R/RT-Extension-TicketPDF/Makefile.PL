use inc::Module::Install;

name        'RT-Extension-TicketPDF';
all_from    'lib/RT/Extension/TicketPDF.pm';
readme_from 'lib/RT/Extension/TicketPDF.pm';
include     'Module::Install::RTx';

# Allow build of a distribution without having an RT install
RTx 'RT-Extension-TicketPDF' unless $ENV{DIST_BUILD};

WriteAll;

=head1  BUILD

    git clean -xfd
    DIST_BUILD=1 perl Makefile.PL
    make manifest
    make dist

=cut
