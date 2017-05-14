PERL_PATH=/usr/lib/perl5/site_perl/Quizzer/
CONF_PATH=/etc
VERSION=$(shell cat VERSION)

install: esercizi install-esercizi
	install -d $(prefix)$(PERL_PATH)
	install -d $(prefix)$(CONF_PATH)
	install -d $(prefix)/usr/bin
	install -d $(prefix)/usr/share/Quizzer

	install -m 0644 *.pm $(prefix)$(PERL_PATH)
	find Element FrontEnd -type d | grep -v CVS | \
		xargs -i__ install -d $(prefix)$(PERL_PATH)__
	find Element FrontEnd -type f | grep .pm\$$ | \
		xargs -i__ install -m 0644 __ $(prefix)$(PERL_PATH)__
	install -m 0755 Quizzer $(prefix)/usr/bin
	install -m 0644 Quizzer.tpl $(prefix)$(CONF_PATH)
	install -m 0644 Quizzer.conf $(prefix)$(CONF_PATH)
	install -m 0644 quiz-sample.txt $(prefix)/usr/share/Quizzer
	install -m 0644 quiz-interactive.txt $(prefix)/usr/share/Quizzer
	install -m 0644 quiz-long.txt $(prefix)/usr/share/Quizzer

esercizi: 
	make -C exercises

install-esercizi:
	make -C exercises install

dist: clean
	rm -f /tmp/Quizzer-$(VERSION).tar.gz; \
	cd ..; \
	cp -dpR Quizzer Quizzer-$(VERSION) ; \
	tar zcvf /tmp/Quizzer-$(VERSION).tar.gz Quizzer-$(VERSION); \
	mv /tmp/Quizzer-$(VERSION).tar.gz Quizzer ; \
	rm -rf Quizzer-$(VERSION)

clean: 
	rm -f Quizzer-$(VERSION).tar.gz
	make -C exercises clean
