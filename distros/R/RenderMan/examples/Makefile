# Makefile for lwo2rib

all: lwo2rib lwo2pl cow.rib cow.pl
CFLAGS= -Wall -g -I/home/guest/glewis/include
LFLAGS= -L/home/guest/glewis/lib

lwo2rib: lwo2rib.c
	gcc $(CFLAGS) -o lwo2rib lwo2rib.c $(LFLAGS) -lribout -lm

lwo2pl: lwo2pl.c
	gcc $(CFLAGS) -o lwo2pl lwo2pl.c $(LFLAGS) -lribout -lm

cow.rib: lwo2rib cow.lwo
	lwo2rib -s cow.lwo > cow.rib

cow.pl: lwo2pl cow.lwo
	lwo2pl -s cow.lwo > cow.pl
