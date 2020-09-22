MAKEINSERT = ../../books/postgres/make-insert.pl
TABLES = resource_type resource_format organisations resources
FILES = $(TABLES:%=../%.data)

insert.sql: $(MAKEINSERT) $(FILES)
	$(MAKEINSERT) $(TABLES) > $@

clean:
	rm -f insert.sql
