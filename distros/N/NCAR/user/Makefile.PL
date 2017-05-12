

open MAKEFILE, ">Makefile";

print MAKEFILE << "EOF";
all: libuser.a

EOF

my @s = map { s/\.F$//o; $_ } <*.F>;

for my $s ( @s ) {
  my $S = uc( $s );
  print MAKEFILE << "EOF";
$s.o: $s.F
	g77 -c -D$S=NCAR$S $s.F
EOF
}

my @o = map { "$_.o" } @s;

print MAKEFILE << "EOF";
libuser.a: @o
	ar rv libuser.a @o
clean:
	\\rm -f @o libuser.a
	\\mv Makefile Makefile.old

test:

EOF

close MAKEFILE;
