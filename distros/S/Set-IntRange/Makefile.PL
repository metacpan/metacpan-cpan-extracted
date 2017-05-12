#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;

use ExtUtils::MakeMaker;

WriteMakefile
(
    'NAME'		=> 'Set::IntRange',
    'VERSION_FROM'	=> 'IntRange.pm', # finds $VERSION
    'PREREQ_PM'         => { 'Bit::Vector' => 7.1 },
#   ($] >= 5.005 ?
#       ('ABSTRACT'     => 'Easy manipulation of sets of integers (arbitrary intervals)',
#        'AUTHOR'       => 'Steffen Beyer (STBEY@cpan.org)') : ()),
    'dist'		=> { COMPRESS=>"gzip -9", SUFFIX=>"gz" }
);

__END__

