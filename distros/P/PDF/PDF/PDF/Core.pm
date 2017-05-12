#
# PDF::Core.pm, version 1.11 February 2000 antro
#
# Copyright (c) 1998 - 2000 Antonio Rosella Italy antro@tiscalinet.it, Johannes Blach dw235@yahoo.com 
#
# Free usage under the same Perl Licence condition.
#

package PDF::Core;

$PDF::Core::VERSION = "1.11";

=pod

=head1 NAME

PDF::Core - Core Library for PDF library

=head1 SYNOPSIS

  use PDF::Core;

  $pdf=PDF::Core->new ;
  $pdf=PDF->new(filename);

  $res= $pdf->GetObject($ref);

  $name = UnQuoteName($pdfname);							  
  $string = UnQuoteString($pdfstring);							  

  $pdfname = QuoteName($name);							  
  $pdfhexstring = QuoteHexString($string);
  $pdfstring = QuoteString($string);

  $obj = PDFGetPrimitive (filehandle, \$offset);
  $line = PDFGetLine (filehandle, \$offset);
  

=head1 DESCRIPTION

The main purpose of the PDF::Core library is to provide the data structure
and the constructor for the more general PDF library.

=cut

require 5.005;
use strict;
use Carp;
use Exporter ();

use vars qw(@ISA @EXPORT_OK $UseObjectCache);

@ISA = qw(Exporter);

@EXPORT_OK = qw( GetObject );

#
# Object caching
#
# If this variable is true, all processed objects will be added to the
# object cache. If only header information of a PDF are read or very
# big PDF are processed, turning off the cache reduces the memory usage.
#
$UseObjectCache = 1;


#################################################################
#
# Helper functions
#
#################################################################

=pod

=head1 Helper functions

This functions are not part of the class, but perform useful services.

=cut

#
# Modification by johi: 18.12.1999
#

#################################################################
=pod

=head2 UnQuoteName ( string )

This function processes quoted characters in a PDF-name. PDF-names returned by
B<GetObject> are already processed by this function.

Returns a string.

=cut

sub UnQuoteName ($)
	{
	my $value = shift;
	$value =~ s/#([\da-f]{2})/chr(hex($1))/ige;
	return $value;
	}

#################################################################
=pod

=head2 UnQuoteString ( string )

This function extracts the text from PDF-strings and PDF-hexstrings.
It will process all quoted characters and remove the enclosing braces.

WARNING: The current version doesn't handle unicode strings properly.

Returns a string.

=cut

sub UnQuoteString ($)
	{
#
# Translate quoted character. 
#
	my $param = shift;
	my $value;
	if (($value) = $param =~ m/^<(.*)>$/)
		{
		$value =~ tr/0-9A-Fa-f//cd;
		$value .= "0" if (length ($value) % 2);
		$value =~ s/([\da-f]{2})/chr(hex($1))/ige;
		}
	elsif (($value) = $param =~ m/^\((.*)\)$/)
		{
		my %quoted = ("n" => "\n", "r" => "\r",
					  "t" => "\t", "b" => "\b",
					  "f" => "\f", "\\" => "\\",
					  "(" => "(", ")" => ")");
		$value =~ s/\\([nrtbf\\()]|[0-7]{1,3})/
		defined ($quoted{$1}) ? $quoted{$1} : chr(oct($1))/gex;
		}
	else
		{
		$value = $param;
		}

	return $value;
	}

#################################################################
=pod

=head2 QuoteName ( string )

This function quotes problematic characters in a PDF-name. This
function should be used before writing a PDF-name back to a PDF-file.

Returns a string.

=cut

sub QuoteName ($)
	{
	my $value = shift;
	$value =~ s/(?<!\A)([\x00-\x20\x7f-\xff%()\[\]<>\/{}#])/
						 sprintf ("#%2.2X", ord($1))/gex;
	return $value;
	}

#################################################################
=pod

=head2 QuoteHexString ( string )

This function translates a string into a PDF-hexstring. 

Returns a string.

=cut

sub QuoteHexString ($)
	{
	my $value = shift;

	$value =~ s/(.)/sprintf ("%2.2X", ord($1))/ge;
	return ("<" . $value . ">");
	}

#################################################################
=pod

=head2 QuoteString ( string )

This function translates a string into a PDF-string. Problematic
character will be quoted.

WARNING: The current version doesn't handle unicode strings properly.

Returns a string.

=cut

sub QuoteString ($)
	{
	#
	# Only \character style quotes will be added. The really important
	# characters to quote are: ()\
	# 
	my $value = shift;

	my %quote = ("\n" => "\\n", "\r" => "\\r",
				  "\t" => "\\t", "\b" => "\\b",
				  "\f" => "\\f", "\\" => "\\\\",
				  "(" => "\\(", ")" => "\\)");
	$value =~ s/([\n\r\t\b\f\\()])/$quote{$1}/g;
	return ("(" . $value . ")");
	}

#################################################################
=pod

=head2 PDFGetPrimitive ( filehandle, offset )

This internal function is used while parsing a PDF-file. If you are
not writing extentions for this library and are parsing some special
parts of the PDF-file, stay away and use B<GetObject> instead.

This function has many quirks and limitations. Check the source for details.

=cut

sub PDFGetPrimitive (*\$)
	{
	my $fd = shift;
	my $offset = shift;

	binmode $fd;
	seek $fd, $$offset, 0;

	my $state = 0;
	my $buffer;
	my @collector;
	my $lastchar;

	while ()
		{
		# File offset is positioned on start of stream.
		last if ($state == -4);

		$state = 0;

		# Process last element
		if ($#collector >= 0)
			{
			my $lastvalue = $collector[$#collector];
			
			if ($lastvalue eq "R")
				{
				# Process references
				if ($#collector >= 2
					&& $collector[$#collector - 1] =~ m/\d+/
					&& $collector[$#collector - 2] =~ m/\d+/)
					{
					$collector[$#collector - 2] .= join (" ", 
						"", @collector[$#collector - 1, $#collector]);
					$#collector -= 2; 
					}
				else
					{
					carp "Bad reference at offset ", $$offset;
					}
				}
			elsif ($lastvalue eq "endobj")
				{
				# End of object
				last;
				}
			elsif ($lastvalue eq "stream")
				{
				# End of object
				$state = -4;
				}
			}
		
		# Set state for next element
		if ($buffer eq "[") 
			{
			# Read array
			$buffer = "";
			push @collector, [ PDFGetPrimitive ($fd, $offset) ];
			}
		elsif ($buffer eq "<<")
			{
			# Read dictionary
			$buffer = "";
			push @collector, { PDFGetPrimitive ($fd, $offset) };
			}
		elsif ($buffer eq "(") 
			{
			# Here comes a string
			$state = 1;
			$lastchar = "";
			}
		elsif ($buffer eq "<") 
			{
			# Here comes a hex string
			$state = -1;
			}
		elsif ($buffer eq ">")
			{
			# Wait for next > to terminate dictionary
			$state = -2;
			}
		elsif ($buffer eq "%")
			{
			# Skip comments
			$state = -3;
			$buffer = "";
			}
		elsif ($buffer eq "]")
			{
			last;
			}
		elsif ($buffer eq ">>")
			{
			last;
			}

		# Read next item
		while (read ($fd, $_, 1))
			{
			$$offset++;

			if ($state == 0)
				{
				# Normal mode
				if (m/[^\x00-\x20\x7f-\xff%()\[\]<>\/]/)
					{
					# Normal character inside a name or number
					$buffer .= $_;
					}
				elsif (m/[\/\(\[\]\<\>%]/)
					{
					if ($buffer ne "")
						{
						# A new item starts
						if ($buffer =~ m/^\//)
							{
							push @collector, UnQuoteName ($buffer);
							}
						else
							{
							push @collector, $buffer;
							}
						}
					$buffer = $_;
					last;
					}
				elsif (m/\s/)
					{
					# All kind of whitespaces are ignored
					if ($buffer ne "")
						{
						# The old item is done starts
						if ($buffer =~ m/^\//)
							{
							push @collector, UnQuoteName ($buffer);
							}
						else
							{
							push @collector, $buffer;
							}
						$buffer = "";
						last;
						}
					}
				else
					{
					# Strange character. Should not exist.
					# Complain and move on.
					carp "Strange character '", $_, "' at offset ",
					$$offset, " in mode ", $state, " detected";
					$buffer .= $_;
					}
				}
			elsif ($state > 0)
				{
				# We have a string

				if ($lastchar =~ m/\\[\r\n]+/ && m/[^\r\n]/)
					{
					# Clean up after line continuation
					$lastchar = "";
					}

				if ($lastchar =~ m/\\[\r\n]*/)
					{
					# Process character after backslash
					if (m/[\r\n]/)
						{
						# end of line
						$lastchar .= $_;
						}
					else
						{
						# Just a quote
						$buffer .= $lastchar . $_;
						$lastchar = "";
						}
					}
				else
					{
					if ($_ eq "\\")
						{
						# Quoted string starts
						$lastchar = $_;
						}
					elsif ($_ eq "(")
						{
						# Count braces
						$buffer .= $_;
						$state ++;
						}
					elsif ($_ eq ")")
						{
						# End of string
						$buffer .= $_;
						unless (-- $state)
							{
							push @collector, $buffer;
							$buffer = "";
							last;
							}
						}
					else
						{
						$buffer .= $_;
						}
					}
				}
			elsif ($state == -1)
				{
				if (m/[0-9a-f\s]/i)
					{
					# Hex character
					$buffer .= $_;
					}
				elsif ($_ eq ">")
					{
					# End of string
					$buffer .= $_;
					push @collector, $buffer;
					$buffer = "";
					last;
					}
				elsif ($_ eq "<" && $buffer eq "<")
					{
					# This is not a string, but a dictionary instead
					$buffer .= $_;
					last;
					}
				else
					{
					# Should not be there. Complain and add it to the $buffer
					carp "Bad character '", $_ , "' in hex string";
					$buffer .= $_;
					}
				}
			elsif ($state == -2)
				{
				# Wait for second > to terminate dictionary

				# Some sanity checks
				carp "Character '", $_, "' appeared while waiting for '>'" 
				if ($_ ne ">");
				carp "Buffer contains '", $buffer, "' and not '>'" 
				if ($buffer ne ">");

				$buffer = ">>";
				last;
				}
			elsif ($state == -3)
				{
				# Skip comments;
				last if (m/[\r\n]/);
				}
			elsif ($state == -4)
				{
				# Wait for newline to start stream

				if ($_ eq "\n")
					{
					# Some sanity checks
					carp "Text '", $buffer, 
					"' appeared while waiting for start of stream" 
					if ($buffer ne "");

					$buffer = "";
					last;
					}
				elsif (m/\S/)
					{
					$buffer .= $_;
					}
				}
			else
				{
				# Unhandled status. Complain and reset
				carp "Unhandled status ", $state;
				}
			}
		if ($_ eq "")
			{
			# Unhandled status. Complain and reset
			carp "Premature end of file reached";
			
			if ($buffer ne "")
				{
				push @collector, $buffer;
				$buffer = "";
				}
			last;
			}
		}

	return @collector;
	}

#################################################################
=pod

=head2 PDFGetline ( filehandle, offset )

This internal function was used to read a line from a PDF-file. It has
many limitations and you should stay away from it, if you don't know
what you are doing. Use B<GetObject> or B<PDFGetPrimitive> instead.

=cut

sub PDFGetline {
#
# BUG WARNING:
#
# This function returns only one line, which doesn't mean anything most of the
# time. Except for the fileheader and the xref-table, linebreaks can (and will!)
# occur everywhere in a PDF and are just whitespace. You may find only part of a
# PDF-primitve on one line, or more than one of them.
#
# If you want to read PDF-Primitves, use the function PDFGetPrimitive instead.
#
    my $fd = shift;
    my $offset=shift;

    my $buffer;
    my $endflag=1;

    binmode $fd;
    seek $fd, $$offset, 0;

    read($fd,$buffer,2);
    $buffer =~ s/^\r?\n?// ;

    $$offset +=2;

    while ($endflag) {
      read($fd,$_,1);
      $$offset++;
      $endflag = 0 if ( $_ eq "\r" || $_ eq "\n");
      $buffer = $buffer . $_ ;
    }
    return $buffer;
	}

#################################################################
#
# Constructors
#
#################################################################

=pod

=head1 Constructor

=cut

#################################################################
=pod

=head2 new ( [ filename ] )

This is the constructor of a new PDF object. If the filename is
missing, it returns an empty PDF descriptor ( can be filled with
$pdf->TargetFile). Otherwise, It acts as the B<PDF::Parse::TargetFile>
method.

=cut

sub new {

	my %PDF_Fields = (
		  File_Name => undef, # Name of file
		  File_Handler => undef, # Open handle to file
		  Header => undef, # Identification string

		  Objects => [], # Offset of objects
		  Gen_Num => [], # Genereation number of objects
		  Object_Length => [],	# Length of processed objects
		  Object_Cache => {}, # Cache for objects.
		  Page => [], # Information about all pages. Useful.

		  Updated => 0,	# Is the PDF updated 
		  Last_XRef_Offset => undef, # File offset of active Xref table
		  Trailer => {}, # Content of active trailer
		  Info => {}, # Content of active info object
		  Catalog => {}, # Content of catalog
		  PageTree => {}, # Content of root page
		  );
my $that = shift;
my $class=ref($that) || $that ;
  my $self = \%PDF_Fields ;
  my $buf2=bless $self, $class;
  if ( @_ ) { 			# I have the filename
    $buf2->TargetFile($_[0]) ; 
  }
  return bless $self, $class;
};

#################################################################
sub DESTROY {
#
# Close the file if not empty
#
  my $self = shift;
  close ( $self->{File_Handler} ) if $self->{File_Handler} ;
}

#################################################################
#
# Methods
#
#################################################################

=pod

=head1 Methods

The available methods are:

=cut

#################################################################
=pod

=head2 GetObject (reference)

This methods returns the PDF-object for B<reference>. The string
B<reference> must match the regular expression /^\d+ \d+ R$/,
where the first number is the object number, the second number the
generation number.

The return value is a PDF-primitive, the type depends on the content
of the object:

=over

=item B<undef>

The object could not be found or an error. Not all referenced objects
need to be present in a PDF-file. This value can be ignored.

=item B<Hash Reference>

If (UNIVERSAL::isa ($retval, "HASH") is true, the object is a
PDF-dictionary. The keys of the hash should be either a PDF name (eg:
/MediaBox) or a generated value like Stream_Offset. Everything else is
an error.

The values of the hash can be any PDF-primitive, including PDF-arrays
and other dictionaries.

This is the most common value returned by GetObject. If the key
Stream_Offset exists, the dictionary is followed by stream data,
starting at the file offeset indicated by this value.

=item B<Array Reference>

If (UNIVERSAL::isa ($retval, "ARRAY") is true, the object is a
PDF-array. Each element may be of a different type, and may contain
further references to arrays or any other PDF-primitive.

=item B<String matching /^\d+ \d+ R$/>

This is a reference to another PDF-Object. This value can be passed to
GetObject. This kind of value may appear instead of most other types.
Some PDF-writing programs seem to have special fun writing references
when a simple number is expected. If the final number is need, use
code like this to resolve references:

while ($len =~ m/^\d+ \d+ R$/) {$len = $self->GetObject ($len);	}

Example: 22 0 R

=item B<String matching /^\//>

This is a Name in a PDF dictionary. This string is already processed
by B<UnQuotName> and may differ from the value in the PDF-file. In
some very old andstrange non-standard PDF-files, this may lead to
confusion.

Example: /MediaBox

=item B<String matching /^\(.*\)$/>

This is a string. It may contain newlines, quoted characters und other
strange stuff. Use PDF::UnQuoteString to extract the text.

Example: (This is\na string with two \(2\) lines.)

=item B<String matching /^E<lt>.*E<gt>$/>

This is a hex encoded string. Use PDF::UnQuoteString to extract the text.

Example: E<lt>48 45 4c4C4 F1cE<gt>

=item B<String matching /^[\d.\+\-]+$/>

This is probably a number.

Example: 611

=item B<String matching none of the above>

this is either a PDF bareword (eg. true, false, ...) or a value
generated by this method like Stream_Offset.

Example: true

=back

To improve performance GetObject uses an internal cache for objects.
Repeated requests for the same objects are not read form the file but
satisfied from the cache. With the Variable B<$PDF::Core::UseObjectCache>,
the caching mechanism can be turned off.

B<WARNING>

Special care must be taken, when returned objects are modified. If the
object contains sub-objects, the sub-objects are not duplicated and
all changes affect all other copies of this object. Use your own copy,
if you need to modify those values.

=cut

sub GetObject (\*$;$)
	{
	my $self = shift;
	my $ref = shift;
	my $force = shift;

#
# Is PDF file open?
#
	croak "PDF-file not open." unless ($self->{"File_Handler"});

#
# Check reference
#
	my ($ind, $gen);
	unless (($ind,$gen) = $ref =~ m/^(\d+) (\d+) R$/)
		{
		carp "Bad object reference '", $_, "'";
		return undef;
		}
	if ($ind > $#{$self->{"Gen_Num"}} || $self->{"Gen_Num"}[$ind] != $gen)
		{
		#
		# The page does not exist. According to the PDF specification,
		# this is not an error.
		#
		return undef;
		}

	# Remove leading zero for cache key.
	$ind += 0;
	# Check cache
	if ($UseObjectCache && ! $force
		&& defined($self->{"Object_Cache"}{$ind}))
		{
		return $self->{"Object_Cache"}{$ind};
		}

	my $offset = $self->{"Objects"}[$ind];
	my @data = PDFGetPrimitive ($self->{"File_Handler"}, $offset);

	unless ($#data == 4  && $data[0] == $ind 
		&& $data[1] == $gen && $data[2] eq "obj")
		{
		carp "Object mismatch: Got '", join (" ", @data[0..2]),
		"' instead of '", join (" ", $ind, $gen, "obj"), "'";
		return;
		}

	#
	# An object is not always a dictionary. In such cases,
	# adding additional keys breaks the content.
	#
	if (UNIVERSAL::isa ($data[3], "HASH"))
		{
		if ($data[4] eq "stream")
			{
			#
			# Find end of a stream object
			#
			$data[3]{"Stream_Offset"} = $offset;
			my $len = $data[3]{"/Length"};

			# Length can be a reference to another object. 
			# Resolve references in this case till something else appears.
			while ($len =~ m/^\d+ \d+ R$/)
				{
				$len = $self->GetObject ($len);
				}

			# Skip stream
			if ($len =~ m/^\d+$/)
				{
				$offset += $len;
				}
			else
				{
				carp "Strange: /Length resolves to '", $len, "' in object ", 
				join (" ", @data[0..2]);
				}

			my @enddata = PDFGetPrimitive ($self->{"File_Handler"}, $offset);
			$data[4] = $enddata[$#enddata];
			}
		}

	#
	# Save length of object.
	#
	$self->{"Object_Length"}[$ind] = $offset - $self->{"Objects"}[$ind];

	carp "Bad object termination '", $data[4], "' in object ", 
	join (" ", @data[0..2]) if ($data[4] ne "endobj");
	

	# Update cache
	$self->{"Object_Cache"}{$ind} = $data[3] if ($UseObjectCache);

	return $data[3];
	}

#
# End of Modification by johi: 18.12.1999
#
#################################################################


1;
__END__

=pod

=head1 Variables

Available variables are:

=over 4

=item B<$PDF::Core::VERSION>

Contains the version of the library installed

=item B<$PDF::Core::UseObjectCache>

If this variable is true, all processed objects will be added to the
object cache. If only header information of a PDF are read or very big
PDF are processed, turning off the cache reduces the memory usage.

=back 4

=head1 Copyright

  Copyright (c) 1998 - 2000 Antonio Rosella Italy antro@tiscalinet.it, Johannes Blach dw235@yahoo.com 

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 Availability

The latest version of this library is likely to be available from:

http://www.geocities.com/CapeCanaveral/Hangar/4794/

=cut
