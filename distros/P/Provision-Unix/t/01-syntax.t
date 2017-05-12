
use strict;
#use warnings;

use Config;
use Data::Dumper;
use English qw/ -no_match_vars /;

use Test::More;


use lib 'lib';

if ( ! -d 'bin' ) {
    plan skip_all => "unable to find bin";
} 
elsif ( $OSNAME =~ /cygwin|win32|windows/i ) {
    plan skip_all => "doesn't work on windows";
}
else {
    plan tests => 32;
}

my $this_perl = $Config{'perlpath'} || $EXECUTABLE_NAME;

ok( $this_perl, "this_perl: $this_perl" );

if ($OSNAME ne 'VMS' && $Config{_exe} ) {
    $this_perl .= $Config{_exe}
        unless $this_perl =~ m/$Config{_exe}$/i;
}

ok( $this_perl, "this_perl: $this_perl" );

foreach ( glob("bin/*") ) {
    my $cmd = "$this_perl -c $_";
    my $r = system "$cmd 2>/dev/null >/dev/null";
    ok( $r == 0, "syntax $_");
};

my $dir = 'lib/*';
foreach ( 1..6 ) {
    foreach ( glob("$dir/*.pm") ) {
        my $cmd = "$this_perl -c $_";
        my $r = `$cmd 2>&1`;
        my $exit_code = sprintf ("%d", $CHILD_ERROR >> 8);
        my $pretty_name = substr($_, 4);
        ok( $exit_code == 0, "syntax $pretty_name");
    };
    $dir .= '/*';
};

