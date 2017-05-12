ALL := \
    ../lib/Mo/xxx.pm \

all: $(ALL)

$(ALL): Makefile

../lib/%.pm : %.pm
	perl -I../lib -MMo::Golf=golf < $< > $@
