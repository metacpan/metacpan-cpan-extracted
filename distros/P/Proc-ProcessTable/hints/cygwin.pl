symlink "os/Cygwin.c", "OS.c" || die "Could not link os/Cygwin.c to OS.c\n";

my @obstack_files = ("obstack.c", "obstack.h", "obstack_printf.c");

for my $f (@obstack_files) {
  symlink "os/$f", $f || die "Could not link os/$f to $f\n";
}

delete $self->{LIBS};
$self->{OBJECT} .= ' obstack.o obstack_printf.o';
