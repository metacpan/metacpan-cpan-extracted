use File::Copy;
unlink "OS.c" if -e "OS.c";
File::Copy::copy "os/MSWin32.c", "OS.c" or die "Could not copy os/MSWin32.c to OS.c\n";
utime time, time, "OS.c"; # Win32 does not update the mod time of a copied file
