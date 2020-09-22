TABLES = country author book
FILES = $(TABLES:%=../%.data)

insert.sql: ../postgres/make-insert.pl $(FILES)
	../postgres/make-insert.pl $(TABLES) > $@

clean:
	rm -f insert.sql
