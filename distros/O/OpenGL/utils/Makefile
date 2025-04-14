#!make

# Default values for this Makefile
DEF = "ERROR: no DEF given. Please run: 'perl Makefile.PL verbose' and report result"
INC = "ERROR: no INC given. Please run: 'perl Makefile.PL verbose' and report result"
LIB = "ERROR: no LIB given. Please run: 'perl Makefile.PL verbose' and report result"

# Compile command
CC=cc
CCFLAGS=$(INC) $(DEF)

# Link command
LINK=cc
LDFLAGS=$(LIB)

all: glversion.txt

glversion.txt: glversion
	./glversion > glversion.txt

glversion: glversion.o
	$(LINK) glversion.o $(LDFLAGS) -o glversion
	chmod u+x glversion

clean:
	rm -f glversion.txt glversion glversion.o

.c.o:
	$(CC) $(CCFLAGS) -c $<
