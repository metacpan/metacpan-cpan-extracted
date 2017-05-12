#!perl
use strict;
use warnings;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use ExtUtils::MakeMaker;
use English qw( -no_match_vars );

$OUTPUT_AUTOFLUSH++;

use lib "lib";

WriteMakefile(
        'NAME'           => 'RTG::Report',
        'VERSION_FROM'   => 'lib/RTG/Report.pm', # finds $VERSION
        'EXE_FILES'      => [ 
                              'bin/billing_report.pl', 
                              'bin/record_consolidator.pl',
                              'bin/uplink_summary.pl',
                            ],
        'INSTALLSCRIPT'  => '/usr/local/sbin',
        'MIN_PERL_VERSION' => 5.008001,
        'PREREQ_PM'      => { 
                        'Date::Calc'        => 5.4, 
                        'DBIx::Simple'      => 1.26, 
                        'MIME::Lite'        => 3,
                        'Net::SMTP'         => .5,
                        'Text::CSV'         => .5,
                        'Config::Std'       => '0.0.4',
                },
        AUTHOR            => 'Matt Simerson (msimerson@cpan.org)',
        ABSTRACT          => 'RTG Reporting and data processing',
        PL_FILES          => {},
        LICENSE           => 'perl',
        dist              => { COMPRESS => 'gzip -9f', },
        clean             => {
                               FILES => [  "tmp/*",
                                           "pod2htm*",
                                        ],
                             },
);

sub MY::postamble {
    '
deps:
	perl bin/install_deps.pl
';
}

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Layered Technologies, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

