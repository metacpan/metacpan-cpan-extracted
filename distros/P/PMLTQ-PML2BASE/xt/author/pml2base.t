#!/usr/bin/env perl
# Run this like so: `perl -I ../lib pml2base.t'
#   Matyas Kopp <matyas.kopp@gmail.com>     2019/01/15 09:11:00

use Test::Most;
use File::Basename 'dirname';

use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'lib' ) );

BEGIN {
  require 'bootstrap.pl';
}

use PMLTQ::PML2BASE;


for my $treebank ( treebanks() ) {
  my $tmp_dir       = File::Temp->newdir( CLEANUP => 0 );
  my $output_dir    = $tmp_dir->dirname;
  my $treebank_name = $treebank->{name};
  my $config        = $treebank->{config};

  chdir $treebank->{dir};

  #run treebank conversion

  Treex::PML::AddResourcePath( $config->{resources} );

  for my $layer ( @{ $config->{layers} } ) {
    print STDERR "==== Converting data for layer $layer->{name}\n";

    $PMLTQ::PML2BASE::opts{'no-secondary-files'} = 1;
    $PMLTQ::PML2BASE::opts{'resource-dir'}       = $config->{resources};
    $PMLTQ::PML2BASE::opts{'related-schema'}     = $layer->{'related-schema'} || [];
    $PMLTQ::PML2BASE::opts{'data-dir'}           = $config->{data_dir};
    $PMLTQ::PML2BASE::opts{'output-dir'}         = $output_dir;
    %{ $PMLTQ::PML2BASE::opts{'ref'} } = ();
    $PMLTQ::PML2BASE::opts{'ref'}{$_} = $layer->{'references'}{$_} for ( keys %{ $layer->{'references'} || {} } );
    PMLTQ::PML2BASE::init();
    my %roots;
    my ($num_of_trees)=(0);

    for my $file ( glob( File::Spec->catfile( $config->{data_dir}, $layer->{data} ) ) ) {
      print STDERR "$file\n";
      my $fsfile = Treex::PML::Factory->createDocumentFromFile($file);
      if ($Treex::PML::FSError) {
        die "Error loading file $file: $Treex::PML::FSError ($!)\n";
      }
      my @trees = $fsfile->trees();

      for my $t (@trees){
        $t = $fsfile->determine_node_type($t->root())->{'-path'};
        $t =~ s/^!//;
        $t =~ s/\.type$//;
        $roots{$t} = 1;
      }
      $num_of_trees += scalar(@trees);
      PMLTQ::PML2BASE::fs2base($fsfile);
    }
    PMLTQ::PML2BASE::finish();
    PMLTQ::PML2BASE::destroy();

    ok(-s File::Spec->catdir($output_dir,$layer->{name}."__init.list"), "File ".$layer->{name}."__init.list exists and is not empty" );
    ok(open(my $fh, '<', File::Spec->catdir($output_dir,$layer->{name}."__init.list")),"openning ".$layer->{name}."__init.list");
    while(my $file = <$fh>){
      $file =~ s/\n//;
      my $file_path = File::Spec->catdir($output_dir,$file);
      ok(-s $file_path, "File $file exists and is not empty" );
      if($file =~ m/\.ctl*/){
        ok(open(my $fhctl, '<', $file_path),"openning $file");
        my $firstrow = <$fhctl>;
        my ($column_names) = $firstrow =~ m/COPY .*? \((.*?)\)/;
        ok($firstrow =~ m/COPY .* FROM '(.*?)'/, "match COPY ... FROM $1 patern");
        my $dumpfile_path = File::Spec->catdir($output_dir,$1);
        ok(-e $dumpfile_path, "File $1 exists" );
        if($firstrow =~ m/#tree/){
          my $root = join("|",keys %roots);
          my $root_regex = $column_names;
          $root_regex =~ s/"(#idx)"/(\\d+)/g;
          $root_regex =~ s/"#root_idx"/\\1/g;
          $root_regex =~ s/"#type"/(:?$root)/g;
          $root_regex =~ s/"([^"]*?)"/.*?/g;
          $root_regex =~ s/ ?, ?/\\t/g;
          ok(open(my $fhtree, '<', $dumpfile_path),"openning $dumpfile_path");
          my $num_of_converted_trees = 0;
          while( my $line = <$fhtree>){
            if($line=~ qr/$root_regex/){
              $num_of_converted_trees += 1;
            }
          }
          is($num_of_converted_trees,$num_of_trees, "Number of converted trees is equal to number of trees in files");

        }
      }
    }
  }
}




done_testing();

