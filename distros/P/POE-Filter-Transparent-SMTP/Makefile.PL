# 	($rcs) = (' $Id: Makefile.PL,v 1.5 2009/01/28 12:51:50 george Exp $ ' =~ /(\d+(\.\d+)+)/);
# Copyright (c) 2008-2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => q{POE::Filter::Transparent::SMTP},
    AUTHOR        => 'George Nistorica <ultradm@cpan.org>',
    LICENSE       => q{perl},
    VERSION_FROM  => q{lib/POE/Filter/Transparent/SMTP.pm},
    ABSTRACT_FROM => q{lib/POE/Filter/Transparent/SMTP.pm},
    PL_FILES      => {},
    PREREQ_PM     => {
        q{Test::More}        => 0,
        q{POE::Filter::Line} => 0,
        q{Data::Dumper}      => 0,
        q{Carp}              => 0,
    },
    dist => { COMPRESS => q{gzip -9f}, SUFFIX => q{gz}, },
    clean => { FILES => q{POE-Filter-Transparent-SMTP-*} },
);
