# Usage:
# $ make -F xt/Makefile
PANDOC_BINDIR=~/.pandoc/bin

test:
	for P in ${PANDOC_BINDIR}/pandoc-*; do\
		prove -lv -Pandoc=$$P t;\
	done

index.html: ../lib/Pandoc/Elements.pm 
	pod2pandoc $< -s -S --toc -o $@
