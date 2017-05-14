dirs=vi-subst compile-tcsh search-n-copy

all:
	for f in $(dirs); do \
		tar zcvf $$f.tar.gz $$f; \
	done

clean:
	for f in $(dirs); do \
		rm -f $$f.tar.gz ; \
	done

install:
	for f in $(dirs); do \
		install -d $(prefix)/usr/share/Quizzer ; \
		install -m 0644 $$f.tar.gz $(prefix)/usr/share/Quizzer ; \
	done
