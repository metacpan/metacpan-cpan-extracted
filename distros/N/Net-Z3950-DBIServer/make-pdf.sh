#!/bin/sh

rm -rf PDF
mkdir PDF
for i in \
	bin/zSQLgate \
	lib/Net/Z3950/DBIServer/Config.pm \
	lib/Net/Z3950/DBIServer/Exception.pm \
	lib/Net/Z3950/DBIServer/GRS1.pm \
	lib/Net/Z3950/DBIServer/Install.pm \
	lib/Net/Z3950/DBIServer/Intro.pm \
	lib/Net/Z3950/DBIServer/LICENCE.pm \
	lib/Net/Z3950/DBIServer/MARC.pm \
	lib/Net/Z3950/DBIServer/ResultSet.pm \
	lib/Net/Z3950/DBIServer/Run.pm \
	lib/Net/Z3950/DBIServer/SUTRS.pm \
	lib/Net/Z3950/DBIServer/Spec.pm \
	lib/Net/Z3950/DBIServer/Tutorial.pm \
	lib/Net/Z3950/DBIServer/XML.pm \
	lib/Net/Z3950/DBIServer.pm \
; do
	base=`echo $i | sed 's/\//-/g; s/\.pm//'`
	echo === $base ===
	pod2man $i > PDF/$base.man
	(
	    cd PDF
	    groff -man $base.man > $base.ps
	    ps2pdf $base.ps
	)
done

rm -f pod2htmd.tmp pod2htmi.tmp
concatenate-pdfs \
	PDF/bin-zSQLgate.pdf \
	PDF/lib-Net-Z3950-DBIServer-LICENCE.pdf \
	PDF/lib-Net-Z3950-DBIServer-Intro.pdf \
	PDF/lib-Net-Z3950-DBIServer-Install.pdf \
	PDF/lib-Net-Z3950-DBIServer-Tutorial.pdf \
	PDF/lib-Net-Z3950-DBIServer-Run.pdf \
	PDF/lib-Net-Z3950-DBIServer-Spec.pdf \
	PDF/lib-Net-Z3950-DBIServer.pdf \
	PDF/lib-Net-Z3950-DBIServer-Config.pdf \
	PDF/lib-Net-Z3950-DBIServer-ResultSet.pdf \
	PDF/lib-Net-Z3950-DBIServer-GRS1.pdf \
	PDF/lib-Net-Z3950-DBIServer-XML.pdf \
	PDF/lib-Net-Z3950-DBIServer-MARC.pdf \
	PDF/lib-Net-Z3950-DBIServer-SUTRS.pdf \
	PDF/lib-Net-Z3950-DBIServer-Exception.pdf \
		> zSQLgate-manual.pdf
