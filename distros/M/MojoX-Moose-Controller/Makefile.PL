#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2014 Companies House                                     ##
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

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    'NAME'          => 'MojoX::Moose::Controller',
    'VERSION_FROM'  => 'lib/MojoX/Moose/Controller.pm',
    'ABSTRACT_FROM' => 'lib/MojoX/Moose/Controller.pm',
    'LICENSE'       => 'perl',
    'AUTHOR'        => 'Companies House <iankent@cpan.org>',
    'PREREQ_PM'     => {
                           'Moose' => '2.0603',
                           'MooseX::NonMoose' => '0.24',
                           'Mojolicious' => '4.58',
                       },
    'dist'          => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
       ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
               ('CAPI'         => 'TRUE') : ()),
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    repository => 'https://github.com/companies-house/MojoX-Moose-Controller',
                },
                no_index => { directory => [ qw/t/ ] },
            },
        )
    ),
);

__END__
