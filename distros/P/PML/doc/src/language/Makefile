PML=	pml
SUB=	perl -e '$$_ = $$ARGV[0]; s/\.pml$$/.html/; print'
ORDER!=	perl -ne 'chomp; s/\s+//g; print "$${_}.html "' Order
DEST=	../../language.html

FILES != for i in *.pml ; do echo `${SUB} $$i`' '; done

all:	.depend ${FILES}
	cat ${ORDER} > ${DEST}

.depend: depend

depend:
	rm -f .depend
	for i in src/*.pml ; \
	do \
		echo `${SUB} $$i`: $$i  `ls include/*.pmlh` >> .depend; \
	done
	
clean:
	rm -f *.html .depend

realclean: clean
	rm ${DEST}
	
.SUFFIXES : .html .pml

.pml.html :
	${PML} $< > $@
