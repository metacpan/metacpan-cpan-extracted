#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use File::Spec;
use File::Basename;
use Test::CheckManifest;
use Test::More;

# create a directory and a file 
my $sub = Test::CheckManifest->can('_check_excludes');
my $dir = Cwd::realpath( dirname __FILE__ );
$dir    =~ s{.t\z}{};

{
    is_deeply $sub->( { exclude => ['testing'] }, $dir ), [], 'empty excludes';
    is_deeply $sub->( { exclude => ['/t'] }, $dir ), [ File::Spec->catdir( $dir, 't' ) ], 't directory';
    is_deeply $sub->( { exclude => ['/t'] }, '.' ), [ File::Spec->catdir( $dir, 't' ) ], 't directory - home: .';
    is_deeply $sub->( { exclude => ['/t2'] }, '.' ), [ ], 't2 directory, that does not exist';
    is_deeply $sub->( { exclude => [''] }, '' ), [ ], 'empty strings';
    is_deeply $sub->( { exclude => [undef] }, '' ), [ ], 'undef excluded path';

    is_deeply $sub->( { exclude => undef }, '' ), [ ], 'exclude is undef';
}


done_testing();
