#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    chdir 't' if -d 't';
    use File::Spec;
    use lib File::Spec->catdir( qw[.. lib] );
}

use Test::More 'tests' => 1;

my $Class = 'Term::UI';

use_ok( $Class );

diag "Testing $Class " . $Class->VERSION . ", Perl $], $^X"
  unless $ENV{ 'PERL_CORE' };
