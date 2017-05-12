#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2013 Ian Kent                                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;
use ExtUtils::MakeMaker;

BEGIN
{
    eval { require Config_m; }; # ExtUtils::FakeConfig (+ ActivePerl)
    eval { require Config;   } # Everyone else
    if ($@);
}

WriteMakefile(
    'NAME'          => 'MongoDB::Simple',
    'VERSION_FROM'  => 'lib/MongoDB/Simple.pm',
    'ABSTRACT_FROM' => 'lib/MongoDB/Simple.pm',
    'LICENSE'       => 'perl',
    'AUTHOR'        => 'Ian Kent <iankent@cpan.org>',
    'PREREQ_PM'     => {
                           'Exporter'                 => 5.6403,
                           'MongoDB'                  => 0.700,
                           'Switch'                   => 2.16,
                           'DateTime'                 => 1.03,
                           'DateTime::Format::W3CDTF' => 0.06,
                           'Tie::Array'               => 1.04,
                       },
    'dist'          => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
       ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
               ('CAPI'         => 'TRUE') : ())
);

__END__
