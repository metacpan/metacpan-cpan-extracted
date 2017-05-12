#!perl
use strict;
use warnings;

use Test::More tests => 1;
use Cwd;

is( check_output_diff(), '', 'Perl output should be the same as C++/Java output');


sub check_output_diff {
    chdir '../t' or chdir 't' or die "Cannot cd to 't' directory.";

    my $dir = '.';
    my $perl_out = "$dir/Operl_output";
    # Run perl from the same path running us to avoid
    # the 'Perl lib version (x.y.z) doesn't match executable version' error.
    # This happens on systems with multiple perl installs, like CPAN testers
    my $perl_path = $^X;
    system("$perl_path $dir/Mbase_derived_main.pl > $perl_out") == 0
        or die $?;
    my $diff = qx( diff -b $perl_out $dir/c++_java_output );
    #unlink $perl_out;

    return $diff;
}

