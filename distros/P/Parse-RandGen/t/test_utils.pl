# $Revision: #1 $$Date: 2005/04/28 $$Author: nautsw $
# DESCRIPTION: Perl ExtUtils: Common routines required by package tests
#
# Copyright 2000-2003 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use vars qw($PERL);

$PERL = "$^X -Iblib/arch -Iblib/lib -IPreproc/blib/arch -IPreproc/blib/lib";

mkdir 'test_dir',0777;

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib '..';
    use lib "blib/lib";
    use lib "blib/arch";
    use lib "Preproc/blib/lib";
    use lib "Preproc/blib/arch";
}

1;
