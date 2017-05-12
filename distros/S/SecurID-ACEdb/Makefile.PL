# $Id: Makefile.PL,v 1.5 1999/01/07 19:21:37 carrigad Exp $

# Copyright (C), 1998, 1999 Enbridge Inc.

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'SecurID::ACEdb',
	      'CCFLAGS'   => '-g -Wall',
	      'VERSION_FROM' => 'ACEdb.pm',
	      'LIBS'	=> ['-L/opt/SecurID/ace/examples -lm -lc -lw -lsocket -lnsl -ldl -ladmin_c'],
	      'INC'	=> '-I/opt/SecurID/ace/examples',
	      'OBJECT'    => '$(BASEEXT)$(OBJ_EXT) $(PROOBJ)',
	      'macro'     => {'DLC' => '/opt/SecurID/ace/rdbms',
			      'PROLOAD' => '$(DLC)/probuild',
			      'PROOBJ' => '$(PROLOAD)/4gl/bklk.o \
	$(PROLOAD)/4gl/bkset.o \\
	$(PROLOAD)/4gl/dblg.o \\
	$(PROLOAD)/4gl/drargs.o \\
	$(PROLOAD)/4gl/drcon.o \\
	$(PROLOAD)/4gl/drdb.o \\
	$(PROLOAD)/4gl/drdbctl.o \\
	$(PROLOAD)/4gl/drdbset.o \\
	$(PROLOAD)/4gl/drmsg.o \\
	$(PROLOAD)/4gl/drmsgw.o \\
	$(PROLOAD)/4gl/drpfile.o \\
	$(PROLOAD)/4gl/drppath.o \\
	$(PROLOAD)/4gl/drsetup.o \\
	$(PROLOAD)/4gl/drsig.o \\
	$(PROLOAD)/4gl/fd.o \\
	$(PROLOAD)/4gl/fdlist.o \\
	$(PROLOAD)/4gl/fmeval.o \\
	$(PROLOAD)/4gl/hl.o \\
	$(PROLOAD)/4gl/hlidynlx.o \\
	$(PROLOAD)/4gl/hlinocpp.o \\
	$(PROLOAD)/4gl/n1noora.o \\
	$(PROLOAD)/4gl/n1norms.o \\
	$(PROLOAD)/4gl/n1nosilk.o \\
	$(PROLOAD)/4gl/nca.o \\
	$(PROLOAD)/4gl/ncs.o \\
	$(PROLOAD)/4gl/ncslist.o \\
	$(PROLOAD)/4gl/nsutil.o \\
	$(PROLOAD)/4gl/profcomp.o \\
	$(PROLOAD)/4gl/profldls.o \\
	$(PROLOAD)/4gl/rlset.o \\
	$(PROLOAD)/4gl/rntmpio.o \\
	$(PROLOAD)/4gl/rtfullp.o \\
	$(PROLOAD)/4gl/sldb.o \\
	$(PROLOAD)/4gl/snlkup.o \\
	$(PROLOAD)/4gl/sqlsmlpi.o \\
	$(PROLOAD)/4gl/sqlsmscv.o \\
	$(PROLOAD)/4gl/svtstlk.o \\
	$(PROLOAD)/4gl/tstset.o \\
	$(PROLOAD)/4gl/hliclang.o \\
	$(PROLOAD)/4gl/dblp.o \\
	$(PROLOAD)/4gl/dbmanb.o \\
	$(PROLOAD)/4gl/fmsrt.o \\
	$(PROLOAD)/4gl/bfx.o \\
	$(PROLOAD)/4gl/ncsbsd.o \\
	$(LDESQLC_N1NOTLI) \\
	$(PROLOAD)/4gl/n2fulhli.o \\
	$(PROLOAD)/4gl/ncsplain.o \\
	$(PROLOAD)/4gl/hlidyn.o \\
	$(PROLOAD)/4gl/dbusr.o \\
	$(PROLOAD)/4gl/dblang.o \\
	$(PROLOAD)/4gl/dblksch.o \\
	$(PROLOAD)/4gl/dbflushm.o \\
	$(PROLOAD)/4gl/n1nordb.o \\
	$(PROLOAD)/4gl/n1nocis.o \\
	$(PROLOAD)/4gl/n1nonis.o \\
	$(PROLOAD)/4gl/n1nowi.o \\
	$(PROLOAD)/4gl/n1udsf.o \\
	$(PROLOAD)/4gl/n1nosyb.o \\
	$(PROLOAD)/4gl/n1nobti.o \\
	$(PROLOAD)/4gl/n1noserv.o \\
	$(PROLOAD)/4gl/n1vv.o \\
	$(PROLOAD)/4gl/n1nopip.o \\
	$(PROLOAD)/4gl/n1noas4.o \\
	$(PROLOAD)/4gl/sysglb.o \\
	$(PROLOAD)/4gl/drdbctrn.o \\
	$(PROLOAD)/4gl/ncstrn.o \\
	$(PROLOAD)/4gl/nsutltrn.o \\
	$(PROLOAD)/4gl/upprodbb.o \\
	$(PROLOAD)/4gl/hlsmpat.o \\
	$(PROLOAD)/4gl/n1nodde.o \\
	$(PROLOAD)/4gl/n1nodt.o \\
	$(PROLOAD)/4gl/ccread.o \\
	$(PROLOAD)/4gl/ccxlate.o \\
	$(PROLOAD)/4gl/fmebase.o \\
	$(PROLOAD)/4gl/n1nosyt.o \\
	$(PROLOAD)/4gl/n1noodbc.o \\
	$(PROLOAD)/4gl/dbsys.o \\
	$(PROLOAD)/4gl/mtsys.o \\
	$(PROLOAD)/4gl/musys.o \\
	$(PROLOAD)/4gl/prsys.o \\
	$(PROLOAD)/4gl/sfsys.o \\
	$(PROLOAD)/4gl/ncasys.o \\
	$(PROLOAD)/4gl/qrsys.o \\
	$(PROLOAD)/4gl/runtime.o \\
	$(PROLOAD)/4gl/dbmgr.o \\
	$(PROLOAD)/4gl/compiler.o \\
	$(PROLOAD)/4gl/hlilib.o \\
	$(PROLOAD)/4gl/stlib.o \\
	$(PROLOAD)/4gl/ut.o'},
);
