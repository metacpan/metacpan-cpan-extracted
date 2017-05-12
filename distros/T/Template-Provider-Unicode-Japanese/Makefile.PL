#
# $Id: Makefile.PL,v 1.4 2007/05/04 08:01:15 hironori.yoshida Exp $
#
package main;
use strict;
use warnings;
our $VERSION = eval { require version; version::qv('1.2.1') };

use inc::Module::Install;
eval {
    require ExtUtils::MakeMaker::Coverage;
    ExtUtils::MakeMaker::Coverage->import;
};

name 'Template-Provider-Unicode-Japanese';
version "$VERSION";
perl_version '5.006';
all_from 'lib/Template/Provider/Unicode/Japanese.pm';

requires 'version'           => 0;
requires 'Template::Config'  => 0;
requires 'Unicode::Japanese' => 0;

WriteAll;

1;
