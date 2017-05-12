#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

no if ($] >= 5.017011), 'warnings' => 'experimental::smartmatch';

use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

use File::Path qw/ rmtree /;
use Mojo::Home;

use Test::More;

if ( $^O eq 'MSWin32' ) {
    plan skip_all => 'Skipped for MS Windows';
}
else {
    plan tests => 3;
}

use_ok( 'Mojolicious::Plugin::BModel' );

my $home = Mojo::Home->new;
$home->detect;

my $app_name      = 'MyTestApp02';
my $model_path    = $app_name . '::Model';
my @subdirs       = qw/ SubDir FirstMoreDir SecondMoreDir /;
my $path_to_model = $home->to_string . '/' . $app_name . '/Model';
my $bmodel        = Mojolicious::Plugin::BModel->new;

rmtree( $app_name ) if -e $app_name;

mkdir $home->to_string . '/' . $app_name or die "can't create folder $app_name: $!";
mkdir $path_to_model or die "can't create folder $path_to_model: $!";
for my $subdir ( @subdirs ) {
    mkdir "$path_to_model/$subdir" or die "can't create folder $path_to_model/$subdir: $!";
}

my $find_res = $bmodel->find_models( $path_to_model, $model_path );

is( ref $find_res, 'ARRAY', "Search result is array" );

subtest "Check search result" => sub {
    for my $subdir ( @subdirs ) {
        my $subdir_path = $model_path . '::' . $subdir;
        ok( $subdir_path ~~ $find_res, "Search result contains $subdir" );
    }
};

rmtree( $app_name );

done_testing();
