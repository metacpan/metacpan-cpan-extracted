package Palm::PalmDoc;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.13';

# Palm::PalmDoc Constructor

sub new {
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $self = {};
 $self->{TITLE} = "PalmDoc Document";
 $self->{INFILE} = undef;
 $self->{OUTFILE} = undef;
 $self->{INFILEH} = undef;
 $self->{OUTFILEH} = undef;
 $self->{BODY} = undef;
 $self->{COMPRESS} = 0;
 $self->{BLOCK_SIZE} = [];
 $self->{IGNORENL} = 0;
 bless($self,$class);
 if (@_) 
 { my $ref = shift;
   my %params = ();
   if (ref $ref eq 'ARRAY')
   { %params = @{$ref}; }
   if (ref $ref eq 'HASH')
   { %params = %{$ref}; }
   if (ref $ref eq '') 
   { unshift @_,$ref;
     if (!(@_ % 2)) 
     { %params = @_; }
   }
   foreach (keys %params) { my $tkey = uc $_; my $tvalue = $params{$_}; delete $params{$_}; $params{$tkey} = $tvalue; } 
   $self->infile($params{INFILE}) if exists $params{INFILE};
   $self->outfile($params{OUTFILE}) if exists $params{OUTFILE};
   $self->title($params{TITLE}) if exists $params{TITLE};
   $self->compression($params{COMPRESS}) if exists $params{COMPRESS};
   $self->ignorenl($params{IGNORENL}) if exists $params{IGNORENL};
   $self->body($params{BODY}) if exists $params{BODY};
   $self->compressed(0);
 }
 return $self;
}

sub body {
 my $self = shift;
 if (@_) { 
 $self->{BODY} = shift;
 if ($self->ignorenl) 
    { my @body = split(/\n/, $self->{BODY});
      my $sep = "";
      $self->{BODY} = "";
      foreach (@body) 
      { if (/^\s*$/)
        { $self->{BODY} .= "\n";
          $sep = "";
        } else 
        { $self->{BODY} .= "$sep$_";
          $sep = " ";
        }
      }
     if ($sep eq " ") 
     { $self->{BODY} .= "\n"; }
   }
 $self->length(CORE::length $self->{BODY});
 if ($self->compression && !$self->compressed) { $self->compressed(1); $self->{BODY} = $self->compr_text($self->{BODY}); }
 }
 return($self->{BODY});
}

sub length {
 my $self = shift;
 if (@_) { $self->{LENGTH} = shift; }
 return($self->{LENGTH});
}

sub title {
 my $self = shift;
 if (@_) { $self->{TITLE} = shift; }
 return($self->{TITLE});
}

sub compression {
 my $self = shift;
 if (@_) { $self->{COMPRESS} = shift @_ ? 1 : 0; }
 return($self->{COMPRESS});
}

sub compressed {
 my $self = shift;
 if (@_) { $self->{COMPRESSED} = shift @_ ? 1 : 0; }
 return($self->{COMPRESSED});
}

sub ignorenl {
 my $self = shift;
 if (@_) { $self->{IGNORENL} = shift @_ ? 1 : 0; }
 return($self->{IGNORENL});
}


sub infile {
 my $self = shift;
 if (@_) 
 { $self->{INFILE} = shift; 
   $self->{INFILE} =~ s/([;\`'\\\|"*~<>^\(\)\[\]\{\}\$\n\r\0\t\s])//g;
 }
 return($self->{INFILE});
}

sub outfile {
 my $self = shift;
 if (@_) { 
 $self->{OUTFILE} = shift; 
 $self->{OUTFILE} =~ s/([;\`'\\\|"*~<>^\(\)\[\]\{\}\$\n\r\0\t\s])//g; 
 }
 return($self->{OUTFILE});
}

sub parse_from_file {
 my $self = shift;
 $self->infile(shift) if @_;
 $self->outfile(shift) if @_;
}

sub parse_from_filehandle {
 my $self = shift;
 ($self->{INFILEH},$self->{OUTFILEH}) = @_;
 $self->{INFILEH} ||= \*STDIN;
 $self->{OUTFILEH} ||= \*STDOUT;
}

sub read_text {
 my $self = shift;
 if ($self->infile) 
 { open (IN, "<".$self->infile) || die "Can't open ".$self->infile.": $!\n";
   { local $/ = undef;
     $self->body(<IN>);
   }
   close (IN);
   if ($self->{INFILEH} && !$self->infile)
   { local $/ = undef;
     $self->body(<INFILEH>);
   }
   $self->{INFILEH} and close($self->{INFILEH}) || die "Can't close input filehandle after reading: $!";
   if ($self->compression && !$self->compressed) { $self->compressed(1); $self->body($self->compr_text($self->body)); }
   return ($self->body);
 } else { return(0); }
}

sub write_text {
 my $self = shift;
 if ($self->body) 
 { if ($self->outfile) 
   { open (OUT,">".$self->outfile) || die "Can't open ".$self->outfile.": $!\n";
     binmode(OUT);
     print OUT $self->pdb_header(),$self->body;	
     close (OUT);
   }
   if ($self->{OUTFILEH} && !$self->outfile) 
   { binmode($self->{OUTFILEH});
     my $foo = $self->{OUTFILEH};
     print $foo $self->pdb_header,$self->body;
     $self->{OUTFILEH} and close($self->{OUTFILEH}) || die "Can't close output filehandle after reading: $!";
   }
   return (1); 
  } else { return(0); }
}

sub pdb_header {
my $self = shift;
my $COUNT_BITS = 3;
my $DISP_BITS = 11;
my $DOC_CREATOR = "REAd";
my $DOC_TYPE = "TEXt";
my $RECORD_SIZE_MAX = 4096;	# 4k record size
my $dmDBNameLength = 32;	# 31 chars + 1 null

my $pdb_rec_offset;		# PDB record offset
my $header_buff = "";		# Temporary buffer to build the headers in.
my $x;
my $y;
my $pdb_header_size = 78;
my $pdb_attributes = 0;
my $pdb_version = 0;
my $pdb_create_time = 0x11111111;			# Palm Desktop demands
my $pdb_modify_time = 0x11111111;			# a timestamp.
my $pdb_backup_time = 0;
my $pdb_modificationNumber = 0;
my $pdb_appInfoID = 0;
my $pdb_sortInfoID = 0;
my $pdb_type = $DOC_TYPE;
my $pdb_creator = $DOC_CREATOR;
my $pdb_id_seed = 0;
my $pdb_id_nextRecordList = 0;
my $pdb_numRecords = (int ($self->length / 4096)) + 2;	# +1 for record 0
							# +1 for fractional part
						
my $pdb_header = pack("a32nnNNNNNNa4a4NNn",substr($self->title,0,31)."\0",$pdb_attributes,
					 $pdb_version,$pdb_create_time,
					 $pdb_modify_time,$pdb_backup_time,
					 $pdb_modificationNumber,$pdb_appInfoID,
					 $pdb_sortInfoID,$pdb_type,$pdb_creator,
					 $pdb_id_seed,$pdb_id_nextRecordList,
					 $pdb_numRecords);

if ( (CORE::length $pdb_header) != 78) { die "pdb_header malformed\n"; }

my $doc_header_size = 16;
my $doc_version = 1 + $self->compression;
my $reserved1 = 0;
my $doc_doc_size = $self->length;
my $doc_rec_size = 4096;
my $doc_num_recs = (int ($self->length / 4096)) + 1;	
my $doc_reserved2 = 0;

my $doc_header = pack("nnNnnN",$doc_version,$reserved1,$doc_doc_size,
			     $doc_num_recs,$doc_rec_size,$doc_reserved2);

if ( (CORE::length $doc_header) != 16) { die "doc_header malformed\n"; }

my $pdb_rec_header_size = 8;
my $pdb_rec_attributes = 0x40;		# We'll fake this, 0x40 = 'dirty'
my $pdb_rec_uniqueID = 0x3D0;		# Simple increment

my $pdb_rec_header_template = "Nccn";

	$pdb_rec_offset = $pdb_header_size + 
			  (($pdb_numRecords)* $pdb_rec_header_size) + 2;

	$header_buff = $pdb_header . pack($pdb_rec_header_template,
					  $pdb_rec_offset, $pdb_rec_attributes,
					  ord('a'),$pdb_rec_uniqueID );
	$pdb_rec_offset += $doc_header_size;	# Add offset for doc_header

	for ($x = 0; $x < $pdb_numRecords - 1; $x++) {	

#		if ($x > 0 ) 
#			{ $self->{BLOCK_SIZE}[$x] = $RECORD_SIZE_MAX; }
			
		$pdb_rec_offset += $self->{BLOCK_SIZE}[$x];
		++$pdb_rec_uniqueID;
		$header_buff .=	pack($pdb_rec_header_template,$pdb_rec_offset,
				     $pdb_rec_attributes,ord('a'),$pdb_rec_uniqueID);
	}
	
	$header_buff .= 0x00 . 0x00;

	$header_buff .= $doc_header;	

return ($header_buff);
}

sub compr_text {
my $self = shift;
my $total_compr_size = 0;		# Final compressed text size
my $compr_buff = "";			# Temporary output buffer
my $numrecords = (int($self->{LENGTH} / 4096) +1);	# Number of blocks to compress.
my $x;
my $y;
my $block_offset;
my $block;			# Contains the current 4096 byte block of text
my $block_len;			# Length of current block
my $index;			# Current scan position in block
my $byte;			# Char at index (for space + char compression)
my $byte2;			# Char at index+1
my $test;			# Potentially compressible text for 
				# LZ77 compression.

my $frag_size;			# Current size of above
my $frag_size2;			# Spare for lazy byte compression	
my $test2;			# spare for above
my $test3; 			# second spare				
my $pos;			# Position (in $block) of reference text 
				# for $test
				# to compress against.

my $pos2;			# spare for above
my $pos3;			# second spare
my $back;			# $index - pos
my $mask;			# Bitwise mask to do LZ77 'magic'
my $compr_ratio;		# Compression ratio
my $done;				
my $comp_block_offset = 0;	# The $compr_buff index
				# block begins.
my $FRAG_MAX = 10;		# Max LZ77 fragment size
my $FRAG_MIN = 3;		# Min LZ77 fragment size
my $LAZY_BYTE_FRAG = $FRAG_MAX + $FRAG_MIN - 1;

		
$self->{BLOCK_SIZE}[0] = 0;	# Record 0 is already written and 
				# is not compressed.
for ($x = 1; $x <= $numrecords; $x++) {

	$block_offset = ($x - 1) * 4096;
	$block = substr($_[0],$block_offset, 4096);
	if ($x >= $numrecords) {			# Last block
		$block = substr($block,0,($self->{LENGTH} % 4096));

	}
		
$block_len = CORE::length($block);	

$index = 0;

while ( $index < $block_len ) {

	$byte = substr($block,$index,1);	# Char at $index
	if ($byte =~ /[\200-\377]/) {   # is high bit set?

		$y = 1;			# found at least one!

		while ( (substr($block,$index + $y ,1)  =~ 
			      /[\200-\377]/) &&
			($y < 8) ) {

			++$y;		# If found, increment counter
				 	
		}			

		$compr_buff .= chr($y); # Write escape code
		$compr_buff .= substr($block,$index,$y); # Write text
		$index += $y;		# Increment the index		

	 } else { 			# Real compression routines

	$frag_size = $FRAG_MIN;		# We don't care about anything less

	$test = substr($block,$index,$frag_size); # pull the current fragment
	$pos = rindex($block, $test, $index - 1); # check against the buffer

	if ( ($pos > 0) &&		 	
	     ($index - $pos <= 2047) && 	# Inside our 2047 byte window
	     ( $index < $block_len - $frag_size) ) { 

		for ($y = 4; $y <= $FRAG_MAX; $y++ ) { 
			++$frag_size ;
			$test2 = substr($block,$index,$frag_size);
			$pos2 = rindex($block, $test2, $index - 1);
			if (($pos2 > 0) && 
			    ($index - $pos2 <= 2047) && 
			    ($index < $block_len - $frag_size) ) { 
						# found a match!
				$pos = $pos2;
				$test = $test2;
			} else {		# no match, go back
				--$frag_size;
				last;
				
			}
			 
		}
						# Sanity check		
		if ($frag_size > $FRAG_MAX) 
		  { die "frag_size too big!!!: $frag_size\n"; }	
		  
	   $frag_size2 = $frag_size + 2;
	   $test2 = substr($block,$index + 1, $frag_size2);
	   $pos2 = rindex($block, $test2, $index - 1);
	   if (($pos2 > 0) && 
		    ($index - $pos2 <= 2047) && 
		    ($index < $block_len - $frag_size2) ) { 

		   for ($y = $frag_size2;$y <= $LAZY_BYTE_FRAG; 
		        $y++ ) { 		# Look for more
			++$frag_size2;
			$test2 = substr($block,$index + 1, $frag_size2);
			$pos2 = rindex($block, $test2, $index - 1);
			if (($pos2 > 0) && 
			    ($index - $pos2 <= 2047) && 
			    ($index < $block_len - $frag_size2) ) { 
							# found a match!

			} else {			# no match, go back
				--$frag_size2;
			        last;
				
			}			    		       
		   }
		  if ($frag_size2 < $LAZY_BYTE_FRAG)  {	

		       $pos = 0;		
		       $compr_buff .= substr($block,$index,1);	
		       ++$index; 
		  }
	    }	  		
		
	   if ($pos > 0) {		# Did we abort the compression?
		
	      $back = $index - $pos;
	      $mask = 0x8000 | int($frag_size - 3);

	      $compr_buff .= pack("n",int($back << 3) | $mask);
	      $index += $frag_size;
	   }
	   
	} else {

		$byte = substr($block,$index,1);	# Char at $index
		$byte2 = substr($block,$index + 1,1);	# next char as well
		if ( ($byte eq " ") && 
		     ($byte2 =~ /[\100-\176]/ ) && 
		     ($index <= $block_len - 1)) {
		       					# Got a space + char
						
							# Set the high bit
							# and add to output 
							# buffer.
	         		$compr_buff .= pack("C", ord ($byte2) | 0x80 );
				$index += 2;		# Compressed 2 bytes
	
		} else {
			$compr_buff .= $byte;		# No compression
		     	++$index; 
		}
	}
}
}

$self->{BLOCK_SIZE}[$x] = (CORE::length ($compr_buff)) - $total_compr_size;
$total_compr_size = CORE::length ($compr_buff);

}

return ($compr_buff);	
}


1;
__END__

=head1 NAME

Palm::PalmDoc - Perl extension for PalmDoc format

=head1 SYNOPSIS

  # Example 1
  use Palm::PalmDoc;
  my $doc = Palm::PalmDoc->new({INFILE=>"foo.txt",OUTFILE=>"foo.pdb",TITLE=>"foo bar",COMPRESS=>1});
  $doc->read_text();
  $doc->write_text();

  # Example 2
  use Palm::PalmDoc;
  my $doc = Palm::PalmDoc->new({OUTFILE=>"foo.pdb",TITLE=>"foo bar"});
  $doc->compression(1);
  $doc->body("Foo Bar"x100);
  $doc->write_text();

  # Example 3
  use Palm::PalmDoc;
  my $doc = Palm::PalmDoc->new(INFILE=>"README");
  $doc->compression(1); #Compression is off by default
  $doc->read_text();
  open(F,">readme.pdb") || die $!;
  print F $doc->pdb_header,$doc->body;
  close(F);

  # Example 4
  use Palm::PalmDoc;
  my $doc = Palm::PalmDoc->new();
  $doc->parse_from_file("README");
  open(F,">readme.pdb") || die $!;
  $doc->parse_from_filehandle("",\*F);
  $doc->compression(1); #Compression is off by default
  $doc->read_text();
  $doc->write_text();


=head1 DESCRIPTION

This module can format ASCII text into a PalmDoc PDB file.

Palm::PalmDoc provides the following functions :

=over 3

=item new(@params)

The constructor of Palm::PalmDoc. This function can accept parameters used to 
generate the PalmDoc file. Parameters accepted are INFILE, OUTFILE, TITLE 
and BODY. They need to be passed in hash context (or a list/array mimicking 
a hash). A reference to a hash is also accepted, as well as a reference to 
an array.

  my $doc = Palm::PalmDoc->new({INFILE=>"foo.txt",OUTFILE=>"foo.pdb"});

is same as 

  my $doc = Palm::PalmDoc->new(INFILE=>"foo.txt",OUTFILE=>"foo.pdb");

or as 

  my $doc = Palm::PalmDoc->new("INFILE","foo.txt","OUTFILE","foo.pdb");

Keys are always uppercased (even though they may not be passed as such). 
Possible keys are:

=back

=over 3

=item INFILE

=back

  The input filename

=over 3

=item OUTFILE

=back

  The output filename

=over 3

=item TITLE

=back

  The document title

=over 3

=item BODY

=back

  The document body

=over 3

=item COMPRESS

=back

  Boolean to indicate compression

=over 3

=item IGNORENL

=back

  Boolean to indicate to ingoring newlines.

=over 3

=item body($body)

=back

This is a plain getter/setter function except that it also sets the required 
length. The same action can be performed by setting the appropriate hash 
key/value pair in the constructor or by using the read_text function.

  $doc->body("Foo Bar"x100);

=over 3

=item title($title)

=back

This is a plain getter/setter function for the title. The same action can be 
performed by setting the appropriate hash key/value pair in the constructor.

  $doc->title("Foo Bar Baz");


=over 3

=item infile($filename)

=back

This is a plain getter/setter function for the Input filename. The same 
action can be performed by setting the appropriate hash key/value pair in 
the constructor. If both an input file and an input filehandle are defined,
the input file is used.

  $doc->infile("foo.txt");

=over 3

=item outfile($filename)

=back

This is a plain getter/setter function for the Output filename.	The same 
action can be performed by setting the appropriate hash key/value pair in 
the constructor. If both an output file and an output filehandle are defined,
the output file is used.

  $doc->outfile("foo.pdb");


=over 3

=item parse_from_file($inputfile,$outputfile)

=back

parse_from_file uses infile() and outfile() to set the filenames. If both an 
input file and an input filehandle are defined, the input file is used. Same
applies for output file and output filehandle.


  $doc->parse_from_file("foo.txt","foo.pdb");

=over 3

=item parse_from_filehandle($inputfilehandle,$outputfilehandle)

=back

parse_from_filehandle takes filehandle as arguments. When no input filehandle 
is defined STDIN is used. When no output filehandle is defined STDOUT is used.
If both an input file and an input filehandle are defined, the input file is 
used. Same applies for output file and output filehandle.

  $doc->parse_from_filehandle(\*FOO,\*BAR);

=over 3

=item read_text()

=back

This function uses the inputfile property to read the body from a file. It 
also sets the required length. This function returns the text read if 
successfull or a false if not successfull.	

  $doc->read_text();

=over 3

=item write_text()

=back

This function uses the outputfile property to write the header and body to a 
file. The headers are generated by the pdb_header function. This function 
returns true if successfull or false if not successfull.

  $doc->write_text();

=over 3

=item pdb_header()

=back

This function generates the correct PDB headers for the body and length. 
You only need to use this function if you're writing the body to a file 
manually since write_text() already used pdb_header. This function returns 
the generated header which should precede the converted body. Writing to an
already opened filehandle can be done with parse_from_filehandle too.

  use Palm::PalmDoc;
  my $doc = Palm::PalmDoc->new();
  $doc->body("Foo Bar"x1000);
  $doc->title("Foo Bar Baz");
  open(FOO,">foo.pdb") || die $!;
  print FOO $doc->pdb_header(),$doc->body();
  close(FOO);

=over 3

=item compression($boolean)

=back

This function toggles the compression. By default compression is off.
The same action can be performed by setting the appropriate hash 
key/value pair in the constructor.

  $doc->compression(1); #Turn PalmDoc Compression on

=over 3

=item ignorenl($boolean)

=back

This function toggles the ignoring the newlines. By default newlines are not 
ignored. The same action can be performed by setting the appropriate hash 
key/value pair in the constructor. Credit for this functionality goes to 
Josef Moellers.

  $doc->ignorenl(1); #Ignore newlines


=head1 THANK YOU!!!!

A HUGE thanks goes to Josef Moellers for fixing 2 BIG bugs in the code.

Thanks also to Scott Wiersdorf for adding warning cleanness.

Waves to Steve Swantz for pointing me to the typos in the POD and README.

John G. Smith for pointing out that titles can't be longer than 31 chars and providing fix for it.

=head1 TODO

Since my primary goal was to port the core, most of the features present in
Bibelot are not included. 

=head1 DISCLAIMER

MOST of this code is borrowed from Bibelot (http://www.sourceforge.net/projects/bibelot/).
This code is released under GPL (GNU Public License). More information can be 
found on http://www.gnu.org/copyleft/gpl.html

=head1 VERSION

This is Palm::PalmDoc 0.12.

=head1 AUTHOR

Hendrik Van Belleghem (beatnik@quickndirty.org)

=head1 SEE ALSO

Bibelot - http://www.sourceforge.net/projects/bibelot/

GNU & GPL - http://www.gnu.org/copyleft/gpl.html

=cut

