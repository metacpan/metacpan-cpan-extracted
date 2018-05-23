use strict;
use warnings;
use Test::Most;
use File::Which;
use File::Spec;
use File::Temp;
use File::Basename qw/dirname basename/;
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__),File::Spec->updir, File::Spec->updir, 'lib' ) );
use Capture::Tiny ':all';
use PMLTQ::Command::printtrees;
use PMLTQ::Commands;
use LWP::Simple;
use Archive::Unzip::Burst;


is(which('btred'),undef,'btred is not in $PATH'); # make sure that btred is not in path
is($ENV{BTRED},undef,'btred is not in $ENV{BTRED}');# make sure that btred is not in $ENV{BtRED}
dies_ok { PMLTQ::Command::printtrees->new(config => {})->run() } "calling printtrees without btred";

my $btred_path = '/opt/tred/btred';

ok( -f $btred_path, "right btred location: $btred_path");
ok( -x $btred_path, "btred is executable");
my $valid_btred;
my $h = capture_merged {
  lives_ok {  system($btred_path,'--help')} "calling btred help";
};
$valid_btred = like($h,"/btred - non-interactive scriptable version of the tree editor TrEd/ms","$btred_path looks like btred");

plan(skip_all => " !!! NO btred !!!") unless $valid_btred;


$h =  capture_merged {
  lives_ok { PMLTQ::Command::printtrees->new(config => {printtrees=>{btred=>$btred_path}})->run() } "calling printtrees with btred";
};
like($h,"/no layers/","no layers is set");

my $treebanks_dir = File::Spec->catdir('treebanks','pdt_test');
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
open(my $fh, '>', $btred_rc_path) or die "Could not open file '$btred_rc_path' $!";
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

done_testing();
