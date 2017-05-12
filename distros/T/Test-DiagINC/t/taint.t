use warnings;
use strict;
use File::Spec;
use Config;

# operation of File::Temp under taint-check is broken for 'MSWin32' with non-user writable root directory (default for Win8+)
# ... here File::Temp is required by Capture::Tiny in 'basic.t'
# ... fix for File::Temp is committed but not distributed
# ... ref: [RT#60340](https://rt.cpan.org/Ticket/Display.html?id=60340)
# ToDO: revisit after File::Temp > v0.2302 is released
if ('MSWin32' eq $^O) {
    print "1..0 # SKIP broken (by File::Temp) on many 'MSWin32' platforms...\n";
    exit 0;
}

# there is talk of possible perl compilations where -T is a fatal
# we don't want to have the user deal with that
system( $^X => -T => -e => 'use warnings; use strict; exit 0' );
if ($?) {
    print "1..0 # SKIP Your perl does not seem to like -T...\n";
    exit 0;
}

# Taint mode ignores PERL5LIB, we have to convert to -I switches just
# like Test::Harness does
my @lib_switches;
for my $env ( grep { defined $ENV{$_} } (qw/PERL5LIB PERLLIB/) ) {
    push @lib_switches,
      map { "-I$_" } grep { length($_) } split /\Q$Config{path_sep}\E/, $ENV{$env};
}

# all is well - just rerun the basic test
exec( $^X => -T => @lib_switches =>
      File::Spec->catpath( ( File::Spec->splitpath(__FILE__) )[ 0, 1 ], 'basic.t' ) );
