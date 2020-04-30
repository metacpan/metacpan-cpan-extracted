#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    use Cwd qw(abs_path);
    use File::Basename;
    use File::Spec;

    my $libpath =
      File::Spec->catdir( dirname( dirname( abs_path($0) ) ), 't', 'tlib', );
    unshift @INC, $libpath;
    $libpath =
      File::Spec->catdir( dirname( dirname( abs_path($0) ) ), 'lib', );
    unshift @INC, $libpath;
}

use Test::Class::Simple::ModuleTest;

Test::Class::Simple::ModuleTest->new()->runtests();

exit 0;
