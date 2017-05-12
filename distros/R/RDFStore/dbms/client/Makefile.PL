# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# *
# *     $Id: Makefile.PL,v 1.13 2006/06/19 10:10:22 areggiori Exp $

use strict;
use ExtUtils::MakeMaker 5.16 qw(WriteMakefile prompt);
use Config;

die "RDFStore needs Perl 5.004_05 or better. This is $]
"
    if $] <= 5.00404;

$| = 1;

# this makefile will be used *just* for perl based dbmsd(8) testing (see ../README)
WriteMakefile(
        # any idea how to just make the bloody Makefile.PL to see ../../lib/DBMS.pm dyna linked to ../blib/arch/auto/RDFStore/RDFStore.so ???
        # just now copy all the modules of the main dir locally to while makeing test - the DBMS.pm module is installed with the main dist anyway!
        #PM => {'../../blib/lib/DBMS.pm' => '$(INST_LIBDIR)/DBMS.pm'}
        #PM => { '../../blib/lib/RDFStore.pm' => '$(INST_LIBDIR)/RDFStore.pm', '../../blib/lib/DBMS.pm' => '$(INST_LIBDIR)/DBMS.pm' }
        # this is the only one making sense and kinda working....
        PMLIBDIRS => [ '../../blib/lib', '../../blib/arch/' ]
        );

# XXXX -- perhaps overwrite the DBMS.pm and
# add:
#	eval("sub DBMS_XSMODE_DEFAULT () { 0; }") unless defined(&DBMS_XSMODE_DEFAULT);
#	eval("sub DBMS_XSMODE_RDONLY () { 1; }") unless defined(&DBMS_XSMODE_RDONLY);
#	eval("sub DBMS_XSMODE_RDWR () { 2; }") unless defined(&DBMS_XSMODE_RDWR);
#	eval("sub DBMS_XSMODE_CREAT () { 3; }") unless defined(&DBMS_XSMODE_CREAT);
#	eval("sub DBMS_XSMODE_DROP () { 4; }") unless defined(&DBMS_XSMODE_DROP);
