
package rebuild_iff_necessary;

BEGIN {
    use IPC::System::Simple qw(systemx);
    systemx($^X, "Makefile.PL") if not -f "Makefile" or ((stat "Makefile")[9] > (stat "Makefile.PL")[9]);
    systemx("make");
}

1;
