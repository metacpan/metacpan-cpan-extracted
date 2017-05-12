#!/usr/bin/perl -w
# Use the tutorials as a test suite
@tutorials = (sort(glob("t?")), sort(glob("t??")));
for $tutorial (@tutorials) {
    chdir($tutorial) || next;
    system("$^X -w $tutorial.pl");
    chdir("..");
}
