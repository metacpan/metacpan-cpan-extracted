BINLOGS=$(shell ls -X binlogs/*.0*)

all: binlogs/test-bin.index

clean:
	rm binlogs/test-bin.index

binlogs/test-bin.index:
	@echo creating binlog index
	$(foreach binlog,$(BINLOGS), $(shell echo `pwd`/$(binlog) >> binlogs/test-bin.index) )
