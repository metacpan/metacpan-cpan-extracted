# -*- cperl -*-
# PODNAME: Spel Wizard class
# ABSTRACT: engine to build audio files from the spel files generated by SpeL and maintain their up-to-dateness



use strict;
use warnings;
package SpeL::Wizard;

use SpeL::Parser::Auxiliary;
use SpeL::Parser::Chunk;

use SpeL::I18n;
use SpeL::Object::Command;
use SpeL::Object::Environment;

use IO::File;
use File::Path;
use FindBin;

use Regexp::Grammars;
use Regexp::Common qw /number/;
use Digest::MD5::File qw(md5_hex);

use IPC::Run;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;


sub new {
  my $class = shift;

  my $self = {};
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  $self->{auxDB} = {
		    newlabel => [],
		    bibcite => [],
		   };


  $self->{argument} = $_[0];
  $self->{config}   = $_[1];
  
  $self->{auxParser}   = SpeL::Parser::Auxiliary->new();
  $self->{chunkParser} = SpeL::Parser::Chunk->new();

  return $self;
}


sub parseAuxFile {
  my $this = shift;
  my ( $verbosity, $test ) = @_;  

  my ( $volume, $path, $file ) = File::Spec->splitpath( $this->{argument} );
  
  my $auxFileName = File::Spec->catpath( $volume, $path, $file . '.aux' );
  
  unless( -r $auxFileName ) {
    warn( "- no $auxFileName available" ) if( $verbosity >= 2 );
    return 1;
  }
  
  $this->{auxParser}->parseAuxFile( $auxFileName );
  $this->{auxDB} = $this->{auxParser}->database();
  $SpeL::Object::Command::labelhash = $this->{auxDB}->{newlabel};
  $SpeL::Object::Command::citationhash = $this->{auxDB}->{bibcite};

  if ( $test ) {
    say STDOUT Data::Dumper->Dump( [ $this->{auxDB} ] , [ qw(auxDB) ] );
    return 0;
  }
  return 1;
}




sub parseChunks {
  my $this = shift;
  my ( $verbosity, $test ) = @_;
  
  my ( $volume, $path, $file ) = File::Spec->splitpath( $this->{argument} );

  my $spelIdxFileName = File::Spec->catpath( $volume, $path, $file . '.spelidx' );
  unless( -r $spelIdxFileName ) {
    warn( "- no $spelIdxFileName available" ) if( $verbosity >= 2 );
    return;
  }

  # count number of lines in spel file
  my $nrLines = 0;
  my $chunks;
  my $spelIdxFile = _openIOFile( "$spelIdxFileName", '<', "input file" );
  while( my $line = <$spelIdxFile> ) {
    unless( $line =~ /(?:^format)|(?:^audiodir)|(?:^chunkdir)|(?:^mac)|(?:^env)|(?:^language)/ ) {
      # count number of chunks to read
      ++$nrLines;
      # register in database
      chomp( $line );
      my ($label, $rest ) = split( /\|/, $line );
      $chunks->{$rest} = 1;
    }
  }
  $spelIdxFile->close();

  die( "Error: found no chunks to read" ) unless $nrLines;
  
  # open the playlist
  my $m3uFileName  = File::Spec->catpath( $volume, $path, $file . '.m3u' );
  my $m3uFile = _openIOFile( $m3uFileName, '>', 'playlist' );
  print $m3uFile
    "#EXTM3U\n" .
    "#EXTINF: Playlist for audiobook generated with SpeLbox\n";

  # parse spel file
  my $linenr = 0;
  $spelIdxFile = _openIOFile( "$spelIdxFileName", '<', 'input file' );

  my $tts = $this->{config}->{engine}->{tts};
  my $audiodir;
  my $chunkdir;
  my $exec;
  my $format;
  my $language;
  my $languagetag;
  my $voice;

  my $m3u_db = {};
  my $m3u_db_active = [];
  
  while( my $line = <$spelIdxFile> ) {

    # parse the line
    chomp $line;
    my ($label, $rest ) = split( /\|/, $line );

    if ( $label eq 'format' ) {
      $format = $rest;
      $exec = "$tts.pl";
      $exec = ( -r "$FindBin::Bin/$exec" )  ?
	"$FindBin::Bin/$exec" : "$exec";
      die( "Error: cannot find text-to-speech engine '$exec'" ) unless ( -r $exec );
      next;
    }
    
    if ( $label eq 'language' ) {
      $language = $rest;
      $languagetag = $this->{config}->{languagetags}->{$language};
      
      $SpeL::I18n::lh = SpeL::I18n->get_handle( $languagetag )
	or die( "Error: I'm not capable of reading the language '$language'\n" );
      
      die( "Error: engine '$tts' is not configured with a voice for language '$language'\n" )
	unless exists $this->{config}->{voices}->{$language};
      $voice = $this->{config}->{voices}->{$language};
      next;
    }
    
    if ( $label eq 'audiodir' ) {
      $audiodir = $rest;
      mkpath( $audiodir );
      next;
    }

    if ( $label eq 'chunkdir' ) {
      $chunkdir = $rest;
      next;
    }

    if ( $label eq 'envpp' ) {
      my ( undef, $env, $argcount, $optarg, $action ) = split( /\|/, $line );

      my $envbegin_regexp  = qr/ \\ begin \{ $env \} /x;
      my $optarg_regexp = qr/ (?:
				\[
				[^]]*
				\]
			      )?
			    /x;
      my $mndarg_regexp = qr/ (
				\{
				(
				  (?:
				    (?> [^{}]+ )
				  |
				    (?1)
				  )*
				)
				\}
			      )
			    /x;
      my $envcontent_regexp = qr/ ( .* ) /sx;
      my $envend_regexp  = qr/ \\ end \{ $env \} /x;

      my $regexp = $envbegin_regexp;
      if ( $argcount ne '-NoValue-'
	   and
	   $argcount > 0 ) {
	if ( $optarg ne '-NoValue-' ) {
	  $regexp .= $optarg_regexp;
	  --$argcount;
	}
	for( my $i = 1; $i <= $argcount; ++$i ) {
	  $regexp .= $mndarg_regexp;
	}
      }
      $regexp .= $envcontent_regexp . $envend_regexp;

      push @{$SpeL::Parser::Chunk::prepenvlist},
	[ $regexp, $action ];
      
      next;
    }
    
    if ( $label eq 'macpp' ) {
      my ( undef, $macro, $argcount, $optarg, $action ) = split( /\|/, $line );

      my $macro_regexp  = qr/ \\
			      $macro /x;
      my $optarg_regexp = qr/ (?:
				\[
				[^]]*
				\]
			      )?
			    /x;
      my $mndarg_regexp = qr/ (
				\{
				(
				  (?:
				    (?> [^{}]+ )
				  |
				    (?1)
				  )*
				)
				\}
			      )
			    /x;

      my $regexp = $macro_regexp;
      if ( $argcount ne '-NoValue-'
	   and
	   $argcount > 0 ) {
	if ( $optarg ne '-NoValue-' ) {
	  $regexp .= $optarg_regexp;
	  --$argcount;
	}
	for( my $i = 1; $i <= $argcount; ++$i ) {
	  $regexp .= $mndarg_regexp;
	}
      }

      push @{$SpeL::Parser::Chunk::prepmacrolist},
	[ $regexp, $action ];
      
      next;
    }
    
    if ( $label eq 'macad' ) {
      my ( undef, $macro, $argcount, $optarg, $reader ) = split( /\|/, $line );
      $SpeL::Object::Command::macrohash->{$macro} =
	{
	 argc   => $argcount,
	 optarg => $optarg,
	 reader => $reader
	};
      next;
    }
    
    if ( $label eq 'envad' ) {
      my ( undef, $env, $argcount, $optarg, $pre, $post ) 
	= split( /\|/, $line );
      $SpeL::Object::Environment::environmenthash->{$env} =
	{
	 argc   => $argcount,
	 optarg => $optarg,
	 pre    => $pre,
	 post   => $post,
	};
      next;
    }

    my $filetoread = $rest;
    
    die( "Error: $spelIdxFileName damaged - format not specified\n" )
      unless defined $format;
    die( "Error: $spelIdxFileName damaged - audio directory not specified\n" )
      unless defined $audiodir;
    die( "Error: $spelIdxFileName damaged - reader directory not specified\n" )
      unless defined $chunkdir;
    die( "Error: $spelIdxFileName damaged - language not specified\n" )
      unless defined $language;

    # make the path OS ready
    my $fullFilePath = File::Spec->catpath( $volume, $path,
					    File::Spec->catfile( $audiodir, split( /\//, $filetoread ) ));

    # read the text from the chunk file
    my $chunkFileName = File::Spec->catpath( $volume, $path,
					     File::Spec->catfile( $chunkdir, $filetoread . ".tex") );

    say STDERR '- Treating ' . pack( "A56", $chunkFileName ) if ( $verbosity >= 1 );

    print STDERR
      "  Parsing " . pack( "A50", $fullFilePath . ".tex" ) .
      sprintf( "[%3d%%]\r", 100 * $linenr / $nrLines )
      if( $verbosity >= 1 );
    
    $this->{chunkParser}->parseDocument( $chunkFileName );

    print STDERR
      "  Parsed  " . pack( "A50", $fullFilePath . ".tex" ) .
      sprintf( "[%3d%%]\r", 100 * $linenr / $nrLines )
      if( $verbosity >= 1 );

    my $text;
    foreach( $label ) {
      /^title$/ and do
	{
	  $text = $SpeL::I18n::lh->maketext( 'title' ) . ": ";
	  next;
	};
      /^author$/ and do
	{
	  $text = $SpeL::I18n::lh->maketext( 'author' ) . ": ";
	  next;
	};
      /^part\s+(.*)/ and do
	{
	  $text = $SpeL::I18n::lh->maketext( 'part' ) . " $1: ";
	  next;
	};
      /^chapter\s+(.*)/ and do
	{
	  $text = $SpeL::I18n::lh->maketext( 'chapter' ) . " $1: ";

	  next;
	};
      /^((?:sub)*section)\s+(.*)/ and do
	{
	  my ( $level, $label ) = ($1, $2);
	  # count the number of matches of sub in the section
	  my $count = () = $level =~ /sub/g;

	  # pop as many actives of the activestack until stack has appropriate length
	  pop @$m3u_db_active while( $count < $#$m3u_db_active );

	  # register yourself on the activestack
	  $m3u_db_active->[$count] = $rest;
	  
	  # make sure every chunk and section registers on the m3u_db for all activestack levels
	  # see elsewhere in the code

	  # generate the level and labe text
	  $text = $SpeL::I18n::lh->maketext( $level ) . " $label: ";

	  # say STDERR Data::Dumper->Dump( [ $m3u_db_active ], [ qw(dba) ] );
	  
	  next;
	};
      /^footnote\s+(.*)/ and do
	{
	  $text = $SpeL::I18n::lh->maketext( 'footnote' ) . " $1: ";
	  next;
	};
    }

    say STDERR Data::Dumper->Dump( [ $this->{chunkParser}->object()->{tree}->{ElementList} ],
				   [ qw( Parsetree ) ] )
      if( $test );
    
    $text .= $this->{chunkParser}->object()->{tree}->{ElementList}->read(0);
    ## clean up:
    # double spaces
    $text =~ s/\s+/ /g;
    # trailing spaces
    $text =~ s/\s+$//;
    # trailing comma
    $text =~ s/,$//;

    if ( $test ) {
      say STDOUT $text;
      return 0;
    }
    else {
      # preprocess the file if there is a translation file
      my $canonicalvoice = $voice;
      $canonicalvoice =~ s/:/-/;
      my $trfilename =
	File::Spec->catfile( File::ShareDir::dist_dir( 'SpeL-Wizard' ),
			     "$tts-$canonicalvoice.tr" );
      
      if ( -r $trfilename ) {
	my $trf = _openIOFile(  $trfilename, "<", "translation file" );
	while ( my $line = <$trf> ) {
	  chomp( $line );
	  $line =~ s/^\s+|\s+$//g;
	  my ( $key, $replace ) = split( /\s*:=\s*/, $line );
	  next unless( defined $replace );
	  $text =~ s/$key/$replace/gi;
	}
      }
      
      
      my $text_md5_hex = "";
      if ( defined( $text ) )
	{
	  $text_md5_hex = md5_hex( $text ) . "-" . $languagetag;
	}
      else
	{
	  $text = "";
	  $text_md5_hex = "";
	  warn( pack( "A74", "Warning: parser error on `$file'" ) . "\n" );
	}

      # read existing MD5 sum
      my $MD5SumFile = IO::File->new();
      my $md5sum = "";
      if ( $MD5SumFile->open( "<$fullFilePath.md5" ) )
	{
	  $md5sum = <$MD5SumFile>;
	  $MD5SumFile->close();
	  $md5sum = "" unless defined( $md5sum );
	}
      else
	{
	  _writeToFile( "$fullFilePath.md5", $text_md5_hex );
	}

      if ( $md5sum ne $text_md5_hex )
	{
	  print STDERR
	    "  Creating " . pack( "A50", $fullFilePath . ".spel" ) .
	    sprintf( "[%3d%%]\r", 100 * $linenr++ / $nrLines )
	    if( $verbosity >= 1 );

	  # write spel file to disk
	  _writeToFile( "$fullFilePath.spel", $text );
	  my $command = [
			 "perl",
			 "$exec",
			 "$fullFilePath.spel",
			 "$fullFilePath.$format",
			 "$voice" ];
	  my $out;
	  IPC::Run::run( $command, '>', \$out )
	    or die( "Error: could not start '$exec' with voice '$voice' " .
		    "(exit value $?)\n" );
	  _writeToFile( "$fullFilePath.md5", $text_md5_hex );
	}
      else
	{
	  print STDERR
	    "  Reusing  " . pack( "A50", $fullFilePath . ".spel" ) .
	    sprintf( "[%3d%%]\r", 100 * $linenr++ / $nrLines )
            if( $verbosity >= 1 );
        }

      # update the section m3u database
      for( my $i = 0; $i < @$m3u_db_active; ++$i ) {
	push @{$m3u_db->{$m3u_db_active->[$i]}}, "$filetoread.$format";
      }
      
      # update the global m3u file
      print $m3uFile "$fullFilePath.$format\n";
    }
  }

  $spelIdxFile->close();
  $m3uFile->close();

  say STDERR "- Generating m3u playlists";
  
  # write all m3u files corresponding to the (sub)sections
  foreach my $key (sort keys %$m3u_db ) {
    my $list = $m3u_db->{$key};
    my $fn = File::Spec->catpath( $volume, $path,
				  File::Spec->catfile( $audiodir, $key . ".m3u" ) );
    say STDERR "  - Generating $fn";
    _writeToFile( $fn,
		  "#EXTM3U\n" .
		  "#EXTINF: section playlist generated with SpeLbox\n" .
		  join( "\n", @$list ) );
  }
  # say STDERR Data::Dumper->Dump( [ $m3u_db ], [ qw( m3u_db ) ] );

  
  # clean the speech directory from old files that are obsolete
  say STDERR "- Cleaning directory " . pack( "A50", "'$audiodir'" );
  my $audiodirpath =
    File::Spec->catpath( $volume, $path,
			 File::Spec->catfile( $audiodir, '' ) );
  my $audiodirectoryglob =
    File::Spec->catpath( $volume, $path,
			 File::Spec->catfile( $audiodir, "*" ) );
  foreach my $file ( glob( $audiodirectoryglob ) ) {
    my $basename = $file;
    $basename =~ s/^$audiodirpath//;
    $basename =~ s/\\?(.*)\.(?:tex|spel|md5|m3u|ogg)$/$1/;
    unless( exists $chunks->{$basename} ) {
      say STDERR "  - Deleting $file because obsolete";
      unlink $file if ( -e $file );
    }
  }
}

sub _openIOFile {
  my ( $fileName, $direction, $fileDesc ) = @_;
  my $file = IO::File->new();
  $file->open( "$direction$fileName" )
    or die( "Error: cannot open $fileDesc `$fileName' for "
            . ( ( $direction eq '<' ) ? "reading" : "writing" ) );
  return $file;
}

sub _writeToFile {
  my ( $fileName, $text ) = @_;
  my $file = IO::File->new();

  $file->open( ">$fileName" )
    or die( "Error: cannot open file `$fileName' for writing\n" );
  print $file $text;
  $file->close();
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spel Wizard class - engine to build audio files from the spel files generated by SpeL and maintain their up-to-dateness

=head1 VERSION

version 20240620.1922

=head1 METHODS

=head2 new( argument, config )

constructor of the Wizard;

=over 4

=item argument: contains the basename (including path) of the .tex document

=item config: contains the configuration object

=back

=head2 parseAuxFile( verbosity, test )

parses the aux file

=over 4

=item verbosity: verbosity level (the higher, the more info will be written to STDERR

=item test: runs the parsing in test mode if true

=back

=head2 parseChunks( verbosity, test )

parses the chunks file

=over 4

=item verbosity: verbosity level (the higher, the more info will be written to STDERR

=item test: runs the parsing in test mode if true

=back

=head1 SYNOPSYS

Parses .aux files and .spelidx files to convert .tex files into text and audio files.
This module is used in the spel-wizard.pl script.

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
