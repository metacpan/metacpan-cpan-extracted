# Copyright (C) 2013 MaxiM Basunov <maxim.basunov@gmail.com>
# All rights reserved.
#
# This program is free software; you may redistribute it and/or
# modify it under the same terms as Perl itself.

# $Id$

use 5.010001;
use ExtUtils::MakeMaker;
use strict;

my $deflist = '';

foreach (@ARGV) {
    $deflist .= "${_} " if /^-D/;
}

WriteMakefile(
    NAME              => 'Net::MRT',
    VERSION_FROM      => 'lib/Net/MRT.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/MRT.pm', # retrieve abstract from module
       AUTHOR         => 'MaxiM Basunov <maxim.basunov@gmail.com>') : ()),
    LICENSE           => 'perl',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => $deflist, # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
        # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    TYPEMAPS          => ['type.map'],
    H                 => ['mrttypes.h',],
    TEST_REQUIRES     => {
        'Test::Deep'      => '0', # or a minimum working version
    }
);
