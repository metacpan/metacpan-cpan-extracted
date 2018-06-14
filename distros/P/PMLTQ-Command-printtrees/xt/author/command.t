use strict;
use warnings;
use Test::Most;
use File::Which;
use File::Spec;
use File::Temp;
use File::Basename qw/fileparse dirname basename/;
use File::Grep;
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__),File::Spec->updir, File::Spec->updir, 'lib' ) );
use Capture::Tiny ':all';
use PMLTQ::Command::printtrees;
use PMLTQ::Commands;
use LWP::Simple;
use Archive::Unzip::Burst;
use Treex::PML;

is(which('btred'),undef,'btred is not in $PATH'); # make sure that btred is not in path
is($ENV{BTRED},undef,'btred is not in $ENV{BTRED}');# make sure that btred is not in $ENV{BtRED}
dies_ok { PMLTQ::Command::printtrees->new(config => {})->run() } "calling printtrees without btred";

my $btred_path = $ENV{BTRED_PATH} || '/opt/tred/btred';

print STDERR $ENV{BTRED_PATH} ? "Using custom \$ENV{BTRED_PATH}='$ENV{BTRED_PATH}'\n" : "Using default btred path '$btred_path'\n";

ok( -f $btred_path, "right btred location: $btred_path");
ok( -x $btred_path, "btred is executable");
my $valid_btred;
my $h = capture_merged {
  lives_ok {  system($btred_path,'--help')} "calling btred help";
};
$valid_btred = like($h,"/btred - non-interactive scriptable version of the tree editor TrEd/ms","$btred_path looks like btred");

$h = capture_merged {
  lives_ok {  system($btred_path,'--version')} "calling btred version";
};
$h =~ s/^.*BTrEd\s*([0-9\.]*)\n.*$/$1/ms;
## $valid_btred &= cmp_ok($h, '>=', 2.5156,"btred - valid version (2.5156 - svg compression)");
## $valid_btred &= cmp_ok($h, '>=', 2.5157,"btred - valid version (2.5157 - create directory when one tree is in file)");
$valid_btred &= cmp_ok($h, '>=',PMLTQ::Command::printtrees::minimum_btred_version ,"btred - valid version");

my $tmp_dir_b = File::Temp->newdir( CLEANUP => 0 );
my $invalid_btred_path = File::Spec->catdir($tmp_dir_b->dirname,'btred');
open(my $fh, '>', $invalid_btred_path) or die "Could not open file $!";
print $fh '#!/usr/bin/env perl
print "BTrEd 0\nPerl: $]\nPlatform: $^O\n";
exit;
';
close $fh;
chmod 0755, $invalid_btred_path;
$h =  capture_merged {
  lives_ok { PMLTQ::Command::printtrees->new(config => {printtrees=>{btred=>$invalid_btred_path}})->run() } "calling printtrees with invalid btred version";
};
like($h,"/Minimum required BTrEd version is not satisfied/","Minimum required BTrEd version is not satisfied");

plan(skip_all => " !!! NO btred !!!") unless $valid_btred;

$h =  capture_merged {
  lives_ok { PMLTQ::Command::printtrees->new(config => {printtrees=>{btred=>$btred_path}})->run() } "calling printtrees with btred";
};
like($h,"/no layers/","no layers is set");

my $treebanks_dir = File::Spec->catdir('treebanks','pdt_small_trees');
my %tb_config = %{ PMLTQ::Commands::_load_config( File::Spec->catdir( dirname(__FILE__), $treebanks_dir, 'pmltq.yml' ) ) };

my $tmp_dir = File::Temp->newdir( CLEANUP => 0 );
$h = capture_merged {
  lives_ok { PMLTQ::Command::printtrees->new(
    config => {
      printtrees => {
        btred => $btred_path,
        extensions => '',
        tree_dir => $tmp_dir->dirname},
      %tb_config})->run() } "calling printtrees with btred without extensions";
};

like($h,"/WARNING: No extension/","no extension is loaded");

my $extension_dir = File::Temp->newdir( CLEANUP => 0 );
my $extension_dir_path = $extension_dir->dirname;
my $btred_rc_path = File::Spec->catdir($extension_dir_path,'btred.rc');
open($fh, '>', $btred_rc_path) or die "Could not open file '$btred_rc_path' $!";
print $fh "font='{Arial} 9'
pml_compile=2

PreinstalledExtensionsDir = $extension_dir_path
ExtensionsDir=$extension_dir_path
";
close $fh;
ok(-f $btred_rc_path, "$btred_rc_path is created");
my %extensions = (pdt20=>'core', pdt25=>'external', pdt30=>'external', pdt_vallex=>'core');
my $extensions_list_path = File::Spec->catdir($extension_dir_path,'extensions.lst');
open($fh, '>', $extensions_list_path) or die "Could not open file 'extensions.lst' $!";
print $fh join("\n",keys %extensions);
close $fh;
ok(-f $extensions_list_path , "$extensions_list_path  is created");

for my $ext (keys %extensions) {
  is(getstore("http://ufal.mff.cuni.cz/tred/extensions/$extensions{$ext}/$ext.zip", File::Spec->catdir($extension_dir_path,"$ext.zip")),200,"downloading http://ufal.mff.cuni.cz/tred/extensions/$extensions{$ext}/$ext.zip") ;
  $h =  capture_merged {
  	lives_ok { Archive::Unzip::Burst::unzip( File::Spec->catdir($extension_dir_path,"$ext.zip"), File::Spec->catdir($extension_dir_path,"$ext"))} "unpacking $ext.zip"
  };
  is($h,'',"no errors $ext.zip");
  # TODO: test extension version -> warn if is not proper
}

$h = capture_merged {
  lives_ok { PMLTQ::Command::printtrees->new(
    config => {
      printtrees => {
        btred_rc => $btred_rc_path,
        btred => $btred_path,
        extensions => join(',',keys %extensions),
        tree_dir => $tmp_dir->dirname},
      %tb_config})->run() } "calling printtrees with btred with extensions";
};
like($h,"/(Context: PDT_30_A.*){3}/sm",'PDT_30_A contex is set');
like($h,"/(Stylesheet: PDT_30_A.*){3}/sm",'PDT_30_A stylesheet is set');
like($h,"/(Context: PDT_30_T.*){3}/sm",'PDT_30_T contex is set');
like($h,"/(Stylesheet: PDT_30_T.*){3}/sm",'PDT_30_T stylesheet is set');


my $cmd = PMLTQ::Command::printtrees->new(
    config => {
      printtrees => {
        btred_rc => $btred_rc_path,
        btred => $btred_path,
        extensions => join(',',keys %extensions),
        tree_dir => $tmp_dir->dirname},
      %tb_config});


my %files;

my $data_dir = $tb_config{data_dir};
my $output_dir = $cmd->config->{printtrees}->{tree_dir};

Treex::PML::AddResourcePath(
       PMLTQ->resources_dir,
       $tb_config{resources}
      );

for my $layer (@{ $cmd->config->{layers} }){
  my $layername = $layer->{name};
  $files{$layername} = {};
  for my $file ($cmd->files_for_layer($layer)) {
    my ($img_name,$img_dir) = fileparse($file,qr/\.[^\.]*/);
    $img_dir =~ s/$data_dir/$output_dir/;
    my $fsfile = Treex::PML::Factory->createDocumentFromFile($file);
    $file = File::Spec->abs2rel ($file,  '.');
    my $file_out = File::Spec->catfile($img_dir,$img_name);
    $files{$layername}->{$file} = {
      numtree => ($fsfile->lastTreeNo // -1) + 1, # number of trees in file
      svgpath => $file_out # path to svg directory, for each tree is a file
    };
  }
}

for my $layername (keys %files){
  subtest "test files on $layername layer" => sub {
    for my $file (keys %{$files{$layername}}){
      my $svgpath = $files{$layername}->{$file}->{svgpath};
      my $numtree = $files{$layername}->{$file}->{numtree};

      ok(-d $svgpath, "Directory for trees in $file exists");
      ok($numtree > 0, "input file $file contains positive number of trees ($numtree)");
      for my $svgnum (0..($numtree-1)) {
        my $treenum = $svgnum+1;
        my $svgfile = File::Spec->catfile($svgpath, sprintf("page_%03d.svg",$svgnum));
        ok(-f $svgfile, "$svgfile exists");
        ok(File::Grep::fgrep(sub {/<title>.* \($treenum\/$numtree\)<\/title>/},$svgfile), "correct svg title");
        is(File::Grep::fgrep(sub {/<script[\s>]/},$svgfile),0, "$svgfile does not contain scripts");
      }
    }
  }
}


done_testing();
