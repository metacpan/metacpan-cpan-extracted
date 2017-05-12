require Config;
my($maj) = $Config::Config{osvers} =~ m{^(\d+)};
if ($maj < 5) {
    print STDERR "Using procfs implementation\n";
    symlink "os/FreeBSD.c", "OS.c" || die "Could not link os/FreeBSD.c to os/OS.c\n";
} else {
    print STDERR "Using kvm implementation\n";
    symlink "os/FreeBSD-kvm.c", "OS.c" || die "Could not link os/FreeBSD-kvm.c to os/OS.c\n";
    $self->{LIBS} = ['-lkvm'];
}

