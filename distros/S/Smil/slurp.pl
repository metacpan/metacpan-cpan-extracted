#!/usr/bin/perl -w

use lib '.';
use Smil;
use Cwd;

my $debug = 0;

my %args = @ARGV;

my $media_types = "img|ref|image|animation|anim|video|audio|text|textstream";

my $input = $args{ '--input' };
my $output = $args{ '--output' };
my $inline = 1 if $args{ '--inline' };

die "Must specify --input <existing_filename> and --output <filename> for the script (and --inline to inline all media)."
unless $input and -e $input and $output;

my $s = "";

my $newdir = "";
my $owd = cwd;

if( open INPUTFILE, $input ) {

	# Might want to be in the directory where the files are, just in 
	# case they aren't local to this directory
	$newdir = $1 if $input =~ /^(.*)\/[^\/]*$/;
	chdir $newdir;
	print "Changing to $newdir\n" if $newdir;

	while( <INPUTFILE> ) {
		$file .= $_;
	}
	
	my @chunks = split />/, $file;

	for( @chunks ) {

		if( /\s*<smil/ or /\s*<head/ or /\s*<layout/ ) {
			# ignore
		}
		elsif( /\s*<root-layout([^>]*)\// ) {
			# Make into key value pairs
			print "Creating SMIL\n" if $debug;
			$s = new Smil( &getAttributes( $1 ) );			
			$s->setBackwardsCompatible( "player" => "rp", "version" => 6 );
		}
		elsif( /\s*<region([^\/]*)\// ) {
			if( $s ) {
				$s->addRegion( &getAttributes( $1 ) );
				print "Adding region\n" if $debug;
			} else { print "Nope\n"; }
		}
		elsif( /\s*<par/ ) {
						$s = new Smil if( !$s );
			$s->startParallel;
			print "Starting parallel" if $debug;
		}
		elsif( /\s*<\/par/ ) {
						$s = new Smil if( !$s );
			$s->endParallel;
			print "Ending parallel\n" if $debug;
		}
		elsif( /\s*<seq/ ) {
						$s = new Smil if( !$s );
			$s->startSequence;
			print "Starting sequence\n" if $debug;
		}
		elsif( /\s*<\/seq/ ) {
						$s = new Smil if( !$s );
			$s->endSequence;
			print "Ending sequence\n" if $debug;
		}
		elsif( /\s*<[$media_types]([^>]*)/ ) {
						$s = new Smil if( !$s );
			$s->addMedia( &getAttributes( $1 ), ( $inline ? ( "inline" => 1 ) : () ) );
			print "Adding media\n" if $debug;
		}

	}

	close INPUTFILE;

}

if( open OUTPUTFILE, ">" . $output ) {
	print OUTPUTFILE $s->getAsString;
	close OUTPUTFILE;
}

# Move back
print "Moving back to old directory\n" if $newdir;
chdir $owd;

sub getAttributes {

	my $string = shift;
	my %attributes = ();
	# Make into key value pairs
	my @tuples = split /\s/, $string;
	foreach $tuple ( @tuples ) {
		my( $key, $value ) = ( $1, $2 ) if $tuple =~ /([^=]*)="?([^"]*)"?/;
		$attributes{ $key } = $value if $key and $value;
		
	}

	return( %attributes );
}
