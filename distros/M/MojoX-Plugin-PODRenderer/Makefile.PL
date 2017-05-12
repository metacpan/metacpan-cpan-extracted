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
    'NAME'          => 'MojoX::Plugin::PODRenderer',
    'VERSION_FROM'  => 'lib/MojoX/Plugin/PODRenderer.pm',
    'ABSTRACT_FROM' => 'lib/MojoX/Plugin/PODRenderer.pm',
    'LICENSE'       => 'perl',
    'AUTHOR'        => 'Companies House <chgovuk@cpan.org>',
    'PREREQ_PM'     => {
                           'Mojolicious' => '4.68',
                           'Pod::Simple' => '3.20',
                           'boolean'     => '0.30',
                           'Class::MOP'  => '2.0603',
                           'File::Find'  => '1.20'
                       },
    'dist'          => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
       ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
               ('CAPI'         => 'TRUE') : ()),
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    repository => 'https://github.com/companieshouse/MojoX-Plugin-PODRenderer',
                },
                no_index => { directory => [ qw/t/ ] },
            },
        )
    ),
);

__END__
