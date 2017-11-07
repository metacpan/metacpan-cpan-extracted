#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw( :all );

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use File::pushd;
use File::Temp qw( tempdir );
use Path::Tiny qw( path tempdir );
use Path::Tiny::Rule;

my $branch = shift || 'master';

my $tempdir = tempdir();

{
    my $dir = pushd($tempdir);
    system(
        'git',      'clone',
        '--branch', $branch,
        'https://github.com/dagolden/Path-Iterator-Rule',
        'pir'
    );
}

my $t_root = $tempdir->child( 'pir', 't' );

for my $file ( Path::Tiny::Rule->new->name(qr/\.(?:t|pm)$/)->all($t_root) ) {
    my $to_file = path( 't', 'pir', $file =~ s{^\Q$t_root\E/}{}r );

    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    $to_file->parent->mkpath( { mode => 0755 } );
    ## use critic

    my $content = $file->slurp_utf8;
    $content =~ s/Path::Iterator::Rule/Path::Tiny::Rule/g;
    $content =~ s{use lib 't/lib'}{use lib 't/pir/lib'}g;
    if ( $file->basename eq 'basic.t' ) {
        $content =~ s/^ *is\(.+"Iterator returns string, not object".*\);$//m;
    }

    $to_file->spew_utf8($content);
}
