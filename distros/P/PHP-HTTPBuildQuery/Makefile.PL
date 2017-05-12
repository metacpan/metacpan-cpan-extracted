######################################################################
# Makefile.PL for PHP::HTTPBuildQuery
# Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  The
# copyrights to the contents of this file are licensed under the Perl
# Artistic License (ver. 15 Aug 1997)
######################################################################
  # 5.6 has broken utf8 support, requiring 5.8
use 5.008;
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/php-httpbuildquery-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'PHP::HTTPBuildQuery',
    'VERSION_FROM' => 'HTTPBuildQuery.pm', # finds $VERSION
    'PREREQ_PM'    => {
         "URI::Escape" => 0,
    }, # e.g., Module::Name => 1.1
    'LICENSE' => 'artistic',
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'HTTPBuildQuery.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
