# -*- cperl -*-
use Test::More;

use IO::File;
use File::Compare;

use SpeL::Object::Document;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

$0 =~ qr{(?<path>.*)\.(?<ext>[^\.]+)$};
$path = $+{path};
$path =~ s/\.\///;

my @goodfiles = glob "$path/test-file-*.aux";

plan tests =>
  scalar @goodfiles + 2;

use SpeL::Parser::Auxiliary;
pass( "Module loading" );
my $parser = SpeL::Parser::Auxiliary->new();
pass( "Parser creation" );

foreach my $testfile ( sort @goodfiles ) {
  # say STDERR $testfile;
  $testfile =~ qr{(?<base>.*)\.(?<ext>[^\.]+)$};
  $base = $+{base};
  eval {
    $parser->parseAuxFile( $testfile );

    my $logfile = IO::File->new();
    $logfile->open(">$base.brown")
      or die( "Error cannot open brown file $testfile.brown\n" );
    my $aux = $parser->database();
    say $logfile Data::Dumper->Dump( [ $aux ], [ qw (aux) ] );
    $logfile->close();
    if( File::Compare::compare_text( "$base.brown",
				     "$base.golden",
				     sub { $_[0] =~ s/\015$//; $_[0] ne $_[1] } ) ) {
      fail( $testfile );
    }
    else {
      pass( "Parsing $testfile" );
    }
    1;
  } or do {
    say STDERR "Error: $testfile $@\n";
    fail( "Parsing $testfile" );
  };
}
