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

my @files = glob "$path/*.tex";

plan tests => scalar @files + 2;

use SpeL::Parser::Chunk;
pass( "Module loading" );
$SpeL::I18n::lh = SpeL::I18n->get_handle( 'en' );
  
my $parser = SpeL::Parser::Chunk->new();
pass( "Parser creation" );

foreach my $testfile ( sort @files ) {
  $testfile =~ qr{(?<base>.*)\.(?<ext>[^\.]+)$};
  $base = $+{base};
  eval {
    $parser->parseDocument( $testfile );
    
    my $logfile = IO::File->new();
    $logfile->open(">$base.brown")
      or die( "Error cannot open brown file $testfile.brown\n" );
    my $tex = $parser->object();
    say $logfile Data::Dumper->Dump( [ $tex ], [ qw (tex) ] );
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

foreach my $testfile ( sort @badfiles ) {
  $testfile =~ qr{(?<base>.*)\.(?<ext>[^\.]+)$};
  $base = $+{base};
  eval {
    $parser->parseTopFile( $testfile );
    my $tex = $parser->object();
    fail( "Diagnosing $testfile" );
    1;
  } or do {
    my $logfile = IO::File->new();
    $logfile->open(">$base.brown")
      or die( "Error cannot open brown file $base.brown\n" );
    say $logfile "$@\n";
    $logfile->close();
    eval {
      if( File::Compare::compare_text( "$base.brown",
				       "$base.golden",
				       sub { $_[0] =~ s/\015$//; $_[0] ne $_[1] } ) ) {
	fail( "Diagnosing $testfile" );
      }
      else {
	pass( "Diagnosing $testfile" );
      }
      1;
    } or do {
      say STDERR "Error: $testfile $@\n";
      fail( "Diagnosing $testfile" );
    };
  };
}


foreach my $testfile ( sort @gooddocs ) {
  $testfile =~ qr{(?<base>.*)\.(?<ext>[^\.]+)$};
  $base = $+{base};
  eval {
    $parser->parseDocument( $testfile );

    my $logfile = IO::File->new();
    $logfile->open(">$base.brown")
      or die( "Error cannot open brown file $testfile.brown\n" );
    my $tex = $parser->object();
    say $logfile Data::Dumper->Dump( [ $tex ], [ qw (tex) ] );
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
