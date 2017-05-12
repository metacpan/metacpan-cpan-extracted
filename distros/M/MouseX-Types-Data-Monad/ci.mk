CPANM = cpanm
CARTON = carton
CARTON_EXEC = $(CARTON) exec --
PROVE = $(CARTON_EXEC) prove
COVER = $(CARTON_EXEC) cover
COVER_OPTIONS = -ignore_re 'inc|blib|modules|^t/|^scripts/|^local/' -make 'make -f ci.mk'
TEST_TARGET = t/

test:
	$(PROVE) $(TEST_TARGET)

prepare:
	$(CPANM) --notest Carton

deps:
	$(CARTON) install

coverage:
	$(COVER) $(COVER_OPTIONS) -test

coveralls: coverage
	$(COVER) -report coveralls
