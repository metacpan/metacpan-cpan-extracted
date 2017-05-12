#
# $Id: Makefile.PL,v 1.6 2007/05/04 08:02:57 hironori.yoshida Exp $
#
package main;
use strict;
use warnings;
our $VERSION = eval { require version; version::qv('1.3.1') };

use inc::Module::Install;
eval {
    require ExtUtils::MakeMaker::Coverage;
    ExtUtils::MakeMaker::Coverage->import;
};

name 'Template-Stash-HTML-Entities';
version "$VERSION";
perl_version '5.006';
all_from 'lib/Template/Stash/HTML/Entities.pm';

requires 'version'          => 0;
requires 'HTML::Entities'   => 0;
requires 'Template::Config' => 0;

WriteAll;

1;
