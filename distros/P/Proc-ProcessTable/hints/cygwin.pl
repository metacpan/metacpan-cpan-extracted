symlink "os/MSWin32.c", "OS.c" || die "Could not link os/MSWin32.c to OS.c\n";

$self->{DEFINE} .= " -DUSE_CYGWIN";
