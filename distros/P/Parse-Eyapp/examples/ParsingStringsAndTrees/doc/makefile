dvi:addressassign.tex codegeneration.tex introduction.tex lexicalanalysis.tex machineindependentoptimizations.tex output.tex peephole.tex phases.tex syntacticanalysis.tex theperlreview.tex
	latex theperlreview.tex
	bibtex theperlreview
	latex theperlreview.tex
	
ps: addressassign.tex codegeneration.tex introduction.tex lexicalanalysis.tex machineindependentoptimizations.tex output.tex peephole.tex phases.tex syntacticanalysis.tex theperlreview.tex
	dvips theperlreview

pdf: addressassign.tex codegeneration.tex introduction.tex lexicalanalysis.tex machineindependentoptimizations.tex output.tex peephole.tex phases.tex syntacticanalysis.tex theperlreview.tex
	dvipdf theperlreview

html: dvi
	latex2html theperlreview

public: html ps pdf tar
	cp theperlreview/* /home/pl/public_html/eyapsimple/
	cp theperlreview.dvi /home/pl/public_html/eyapsimple/eyapsimple.dvi
	cp theperlreview.ps /home/pl/public_html/eyapsimple/eyapsimple.ps
	cp theperlreview.pdf /home/pl/public_html/eyapsimple/eyapsimple.pdf
	cp theperlreview.pdf /home/pl/public_html/perlexamples/eyapptut.pdf
	cp /tmp/source.tgz  /home/pl/public_html/eyapsimple/
	chmod a+r /home/pl/public_html/eyapsimple/*

clean:
	rm -f *.log *.dvi *.aux *.bbl *.blg *~
	
cleanall:
	rm -f *.log *.dvi *.aux *.bbl *.blg *~ *.pdf *.ps

tar:
	cd ..; make tar

link:
	ln -s ${HOME}/Lbook/perlbib/perl.bib

images:
	cp images/* theperlreview/
