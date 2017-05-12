CC = gcc
# F77 = g77
F77 = /opt/local/bin/gfortran-mp-4.7
CFLAGS = -O3 -fPIC

all:    solve.QP.o dpofa.o dpo.o

%.o: %.f
	$(F77) $(CFLAGS) -c $<

clean : 
	rm *.o

