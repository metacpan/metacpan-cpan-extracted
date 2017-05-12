package Perl::Visualize;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( etch paint );

our $VERSION = '1.02';

sub readgif {
  my($io, $chrs) = @_;
  read($io, my $result, $chrs) == $chrs or die "premature end of file: $io\n";
  return $result;
}

sub parsegif {
  my($in) = @_;
  open my $io, "<$in" or die "failed to parse input file, $in: $@\n";
  my $header = readgif($io, 3);
  $header eq "GIF" or die "input file is not a GIF\n";

  my $version = readgif($io,3);
  my $width = readgif($io,2);
  my $height = readgif($io,2);
  my $colordesc = readgif($io,1);
  my($num_of_colors) = ord($colordesc) & 0b10000000 
                     ? (1 << ((ord($colordesc) & 0b00000111) + 1)) * 3 
		     : 0;
  my $bkground = readgif($io, 2);
  my $colortable = readgif($io,$num_of_colors);

  local undef $/;  my $remainder = <$io>;
  close $io;
  return ($width, $height, $colordesc, $bkground, $colortable, $remainder);
}

sub gifcomment {
  my($code) = join '', @_;
  my($index) = 1 + ord substr $code, 0, 1;
  while ( $index < length $code ) {
    $index += 1 + ord substr $code, $index, 1;
  }
  $code .= " " x ($index - length $code);
  $code .= "\x04    \x00";
  return $code;
}

sub perlcomment {
  my($comment) = @_;
  $comment =~ s/\x0a/\x0b/g;
  return "# $comment";
}

sub perlstring {
  my($string) = @_;
  $string =~ s/\xfe/\xfd/g;
  return "q\xfe$string\xfe";
}

sub deparsegif {
  my($outputfile, $colordesc, $bkground, $colortable, $remainder, $escape, $perl) = @_;
  open my $io, ">$outputfile" or die "failed to open output file: $@\n";
  $colortable =~ s/\xfe/\xfd/g;
  print $io "GIF89a;";
  if ( $escape eq "comment" ) {
    print $io perlcomment ";$colordesc$bkground$colortable\x21\xfe";
    print $io gifcomment "\n$perl" # Comments terminated by EOL
  } else {
    print $io perlstring ";$colordesc$bkground$colortable\x21";
    print $io gifcomment ";$perl"  # String statement terminated by semicolon
  }
  print $io $remainder;
  close $io;
}

sub etch {
  my($imagefile, $outputfile, $perl) = @_;
  my($width, $height, $colordesc, $bkground, $colortable, $remainder) = parsegif($imagefile);
  deparsegif ( $outputfile, $colordesc, $bkground, $colortable, $remainder, "comment", $perl );
}

sub paint {
  my($imagefile, $outputfile, $perl) = @_;
  my($width, $height, $colordesc, $bkground, $colortable, $remainder) = parsegif($imagefile);
  deparsegif ( $outputfile, $colordesc, $bkground, $colortable, $remainder, "string", $perl );
}

1;
__END__

=head1 NAME

Perl::Visualize (like Perl only prettier)

=head1 VERSION

This document describes version 1.0 of Perl::Visualize,
released June 20, 2003.

=head1 SYNOPSIS

  # In program
  use Perl::Visualize qw/etch paint/;
  etch "larry.gif", "larrysig.gif", 'print "This is Larry Wall\n"';
  etch "nagra.gif", "nagraview.gif", 'exec "/usr/bin/display $0"';
  paint "damian.gif", "poetic-damian.gif", <<EOF;
  use Coy;
  Recite war "poetry";
  EOF

  # Sometime later
  bash$ perl larrysig.gif
  This is Larry Wall

=head1 DESCRIPTION

=head2 Overview

Perl::Visualize generates GIF/Perl polyglots.  A polyglot is a program
that can be validly executed by multiple interpreters.  Usually,
polyglots are written in multiple I<programming> languages -
Perl::Visualize is slightly different in that one of the languages
being generated is GIF - a format ordinarily used to encode images.

=head2 API

The Perl::Visualize module has two methods in its external interface:
C<paint> and C<etch>.  Each of these methods takes the name
of a GIF file as input, the name of a GIF file to output and a string
containing the Perl code to embed.

  paint $inputfile, $outputfile, $code
  etch $inputfile, $outputfile, $code

The two methods are functionally equivalent - the difference is merely
the technique used to embed perl in the GIF image as described in a
L<later section|HOW IT ALL WORKS>.

=head1 EXAMPLES

=head2 Marquee de World

Let's begin by paying homage to several decades of computer science
and writing our Hello World program.  We select a suitable image and
embed a trivial perl program in it using the following snippet:

=for comment '

  #! /usr/bin/perl -w
  use strict;
  use Perl::Visualize qw/etch/;
  etch("world.gif", "helloworld.gif", 'print "Hello Spinning World\n"' );

=begin html

	      <table width="100%">
		  <tr>
		    <td width="30%">
		      <center><img src="http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/world.gif" alt=""></center>
		    </td>
		    <td width="5%">+</td>
		    <td width="30%">
		      <center>
			print "Hello Spinning World\n";
		      </center>
		    </td>
		    <td width="5%">=</td>
		    <td>
		      <center>
			<a href="http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/helloworld.gif">helloworld.gif</a>
		      </center>
		    </td>
		  </tr>
	      </table>

=end html

Original image L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/world.gif>

Polyglot image L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/helloworld.gif>

This results in a valid GIF file can be directly executed by the perl
interpreter simply by calling C<perl helloworld.gif> or viewed in any
GIF browser.

=head2 I See Perl

Source code sometimes fails to capture the underlying design of a perl
program. With C<Perl::Visualize>, you have the option of distributing
an executable but clearly annotated picture of your source code
instead.  In order to create a visual view of a Perl program, we use
the very clever L<Devel::GraphVizProf|Devel::GraphVizProf> module - a
profiling tool and L<GraphViz|GraphViz> - a graph drawing package from
AT&T.

  #!/usr/bin/perl -w
  
  use strict;
  use Perl::Visualize qw/paint/;
  my $program = "fibo";
  `perl -d:GraphVizProf $program.pl | dot -Tgif -o $program.gif`;
  open CODE, "<$program.pl" or die "Could not open $program.pl: $@";
  my(@lines) = <CODE>;
  close CODE;
  paint "$program.gif", "$program.gif", join '',@lines;

=begin html

	      <table width="100%">
		  <tr>
		    <td width="30%">
		      <center><img src="http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/fibo.gif" alt=""></center>
		    </td>
		    <td width="5%">+</td>
		    <td width="30%">
                      <pre>
sub fib {
  my($howmany, $n1, $n2) = @_;
  my(@result);
  if ( $howmany > 0 ) {
    push @result, $n1+$n2, fib($howmany-1, $n2, $n1+$n2);
  }
  return @result;
}
fib(10,1,1);
</pre>
		    </td>
		    <td width="5%">=</td>
		    <td>
		      <center>
			<a href="http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/v-fibo.gif">v-fibo.gif</a>
		      </center>
		    </td>
		  </tr>
	      </table>

=end html

Original image L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/fibo.gif>

Embedded code L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/fibo.pl>

Polyglot image L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/v-fibo.gif>

=head2 The Art of Computer Programs

Piet is a programming language in which programs look like abstract
paintings.  A complete description of the language can be found at
L<http://www.dangermouse.net/esoteric/piet.html>.  There is a
module L<Piet::Interpreter|Piet::Interpreter> that executes Piet.  We
can use Perl::Visualize and this module to make Piet programs directly
executable using perl.

  #!/usr/bin/perl -w
  
  use strict;
  use Perl::Visualize;
  
  die "Usage: piet pietprogram.gif codel_size" unless $#ARGV == 1 ;
  my($program, $codel) = @ARGV;
  Perl::Visualize::paint($program,"v-$program", <<EOF );
  use Piet::Interpreter;
  my \$p = Piet::Interpreter->new(image => \$0, codel_size=>"$codel");
  \$p->run;
  EOF

=begin html

	      <table width="100%">
		  <tr>
		    <td width="30%">
		      <center><img src="http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/piet.gif" alt=""></center>
		    </td>
		    <td width="5%">+</td>
		    <td width="30%">
<pre>
  use Piet::Interpreter;
  my $p = Piet::Interpreter->new( image => $0, 
                                  codel_size => 16);
  $p->run;
</pre>
		    </td>
		    <td width="5%">=</td>
		    <td>
		      <center>
			<a href="http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/v-piet.gif">v-piet.gif</a>
		      </center>
		    </td>
		  </tr>
	      </table>

=end html

Original image L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/piet.gif>

Polyglot image L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/v-piet.gif>

Note that the program we embed is very simple.  It simply calls the
Piet::Interpreter with itself (C<$0>) as the argument.  This example
is interesting because it actually interprets the same GIF file twice
- and in two different ways.  The first time the GIF file is
interpreted as a perl program by the perl interpreter.  This causes
the embedded perl code to execute which in turn calls the Piet
interpreter.  The Piet interpreter then reads the GIF file again - but
this time it considers the actual image in the GIF file and interprets
that according to the rules of Piet.

The examples that we have looked at so far do not require
Perl::Visualize to be installed in order for it to be run once the GIF
files have been generated - indeed the resulting GIF files are as
portable as perl. The next example we look at does require
Perl::Visualize to be installed because we generate executable images
on the fly.


=head2 Yet Another 99 Bottles of Beer and the Wall

Printing out the hundred stanzas of "Ninety-nine bottles of beer on
the wall" song is another common example of programming tradition.
Over 550 ways of printing out this song has been recorded in over 100
programming languages and archived at
L<http://99-bottles-of-beer.ls-la.net>. For our I<piece de
resistance>, we will write a self replicating version of the "99
bottles of beer" program.  But because it is sometimes difficult to
understand just how much beer that is, we will write our program as a
executable self replicating image using Perl::Visualize.

Instead of producing the entire song at once we will design our
program so that every time it is run it will print out a verse of the
song.  It will then modify itself so that it is primed for the next
verse.  Further more, we would like its picture representation to
reflect the number of bottles of beer currently on the wall.

Let us start with the easiest problem - that of printing out each
stanza.

  sub printMessage {
    my($number) = @_;
    my($prev) = $number+1;
    $number = $number <  1 ? "No bottles" 
            : $number == 1 ? "1 bottle"
            : "$number bottles";
    $prev = $prev <  1 ? "No bottles" 
            : $prev == 1 ? "1 bottle"
            : "$prev bottles";
    print <<BOTTLES;
  $prev of beer on the wall
  $prev of beer on the wall
  Take one down dash it to the ground
  $number of beer on the wall
  BOTTLES
  }

This subroutine prints out one verse of the song given the number of
bottles that remain.  Next we need some code to produce a picture of a
wall with beer bottles on it.  For this we will use, Image::Magick.
Image::Magick is a toolkit for editing a large variety of image
formats programmatically. We will use it to generate our GIF images on
the fly.

  sub drawWall {
    my($image, $width,$height) = @_;
    for my $y ( 0..3 ) {
      for my $x ( 0..($width/10) ) {
        my $warn = $image->Draw ( primitive=>'Rectangle',
  				  points=>"@{[($x - ($y%2)*.5)*10]},
                                           @{[$height - $y*5]} 
                                           @{[($x - ($y%2)*.5)*10 + 10]},
                                           @{[ $height - $y*5 - 5]}",
  				  fill=>'red' );
        warn $warn if $warn;
      }
    }
  }
  
  sub drawBottle {
    my($image, $x,$y) = @_;
    my $warn = $image->Draw ( primitive=>'Rectangle',
  			      points=>"$x,$y 
                                       @{[$x+5]},@{[$y-10]}",
  			      fill=>'brown');
    warn $warn if $warn;
  
    my $warn = $image->Draw ( primitive=>'Polygon',
       			      points=>"@{[$x+2]},@{[$y-13]} 
                                       $x,@{[$y-10]} 
                                       @{[$x+5]},@{[$y-10]} 
                                       @{[$x+3]},@{[$y-13]} 
                                       @{[$x+5]},@{[$y-10]}" );
    warn $warn if $warn;
  }
  
  sub drawBottles {
    my($bottles, $image, $width,$height) = @_;
    for my $bottle_number ( 1..$bottles ) {
      my $x = ($bottle_number + .5 ) * $width / ($bottles+2);
      drawBottle $image, $x, $height - 20;
    }
  }

Now for the crucial part.  We need to make the program have access to
its own source.  Note however that the source will in fact be embedded
inside a GIF so we cannot necessarily simply open ourselves as a file
in an attempt to copy and edit our contents.  Instead we will use
techniques for writing quines to embed the source code in the program
itself.  We embed most of the code as a string in C<$_>, eval it then
we edit C<$_> so that it is initialized for one less beer bottle.
Finally, we embed the edited C<$_> in a GIF file.

  #!/usr/bin/perl
  
  $_=<<'CODE';
  use strict;
  use Perl::Visualize;
  use Image::Magick;
  
  sub printMessage {...}
  sub drawWall {...}
  sub drawBottle {...}
  sub drawBottles {...}
  
  my $width = 600;
  my $height = 100;
  my $bottles = 5;
  my $image = Image::Magick->new(size=>"${width}x$height");
  my $warn;
  
  $image->ReadImage('xc:white');
  
  printMessage $bottles;
  drawWall($image, $width, $height);
  drawBottles($bottles, $image, $width, $height);
  
  $warn = $image->Write('99.gif');
  warn $warn if $warn;
  __END__
  eval $_;
  s/^(my \$bottles = )(\d+)/$1.($2?$2-1:$2)/em;
  m/^__END__(.*)/ms;
  Perl::Visualize::paint ( '99.gif', '99.gif', "\$_=<<'CODE';\n${_}CODE".$1);
  CODE
  eval $_;
  s/^(my \$bottles = )(\d+)/$1.($2?$2-1:$2)/em;
  m/^__END__(.*)/ms;
  Perl::Visualize::paint ( '99.gif', '99.gif', "\$_=<<'CODE';\n${_}CODE".$1);


Polyglot image L<http://search.cpan.org/src/JNAGRA/Perl-Visualize-1.02/examples/99.gif>

=head1 HOW IT ALL WORKS

The choice of GIF as the image format to use was mostly in response to
a challenge that it could not be done. Certainly, several other image
formats appear to be lend themselves more easily to being made into
polyglots. In particular, it is worth noting that PBM and XPM image
formats - because of their ASCII like headers, end of line conventions
and use of # to introduce comments - are almost trivial to use to
embed polyglots, not merely using Perl, but also in C, Python and a
handful of other languages.

In fact the first image polyglots the author created were perl
embedded in black and white XPM images.  However, neither the XPM not
PBM formats are particularly prolific except on Unix platforms. They
are also generally quite large and used more as an intermediate
language than a target language. Much more importantly, making image
polyglots is almost entirely a recreational exercise and only worth
doing if there at least a few challenges along the way.

=head2 GIF file format

The GIF file format was originally proposed in 1989 by Unisys as a way
of reducing the amount of bandwidth taken up by image transfers.
Several aspects of the encoding was controlled by a patent - one which
with some jubilation expired on 20 June, 2003.

In order to successfully build a polyglot we have to be able to shift
gears mentally between programming in Perl and maintaining consistency
with the GIF specification.  The GIF standard is very particular about
the order and interpretation of every byte in the header of a GIF
file.  Since perl is comparatively more lenient, let us being with a
GIF file and try to alter it into also being a valid perl program.  We
begin by taking a look at a few lines of a GIF image:

  00000000: 4749 4638 3961 3000 3000 e300 0000 0000  GIF89a0.0.......
  00000010: abab ab99 9999 4545 45de dede 2121 21cc  ......EEE...!!!.
  00000020: cccc 7878 7866 6666 5454 54ed eded 1212  ..xxxfffTTT.....
  00000030: 12bf bfbf 0000 0000 0000 0000 0021 f904  .............!..
  00000040: 0100 000c 002c 0000 0000 3000 3000 0004  .....,....0.0...
  .
  .
  .
  00000240: 0bb1 966e cec8 0746 392d 4f25 f7e8 2bd7  ...n...F9-O%..+.
  00000250: 8c40 cde0 8705 216f 6c12 4923 bf28 c1c0  .@....!ol.I#.(..
  00000260: 4b01 c6a1 5f83 0ee2 239d 218d 34e3 8c83  K..._...#.!.4...
  00000270: 5e99 a7d0 72ac fd30 4204 003b            ^...r..0B..;

Comparing this against the GIF specification, it is easy to decode the
various fields.

  G    I    F		Marks the beginning of a GIF file

  8    9    a		Identifies the version of this file format.  Later
            		version have extensions to the file format.  In
            		particular, version 89a introduced comment blocks,
            		text blocks and application blocks.

  0x30 0x00 0x30 0x00	Specifies the logical screen width and
                        height stored in little endian format.  This
                        image, for example, is has a width of 0x0030 and a
                        height of 0x0030 - that is it is 48 by 48 pixels.

  0xe3			The first bit indicates the presence of a
			color table, the next three bits indicate the
			resolution of the image, the fifth bit
			indicates whether the color table is ordered
			and the final three bits indicate the size of
			the color table.

  0x00			Index into the color table that identifies the
			background color.

  0x00			Ratio of pixel width to height. 

  0x02 0x02 0x02 ...  	Colors in the color table.  There are 3 * 2 ^
                   	(size of color table + 1) entries in the color
                   	table

=head2 Making code not code

The standard trick in a polyglots toolbox when embedding one language
in another, is to use operators that are comment indicators in one
language but have meaning in other.  When embedding perl in C++ for
example, we have the option of using the "//" characters.  In C++ this
would make the rest of the line a comment and thus be ignored by a C++
compiler while perl would treat it as a valid regex and continue to
execute code that occurs after this.

Perl comments are introduced using a "#" character which makes the
perl interpreter ignore the rest of the line.  In fact, in perl, we
have a second mechanism to make the compiler ignore sections of the
source.  First we note that when running without warnings, perl will
automagically quote barewords - that is unquoted strings without any
spaces are automatically quoted.  Secondly, a statement that consists
solely of a string is valid statement equivalent to a NOP (no-op).

This means, for instance, that the following is in fact a valid perl
program!

  $ cat nop.pl
  The_rain_in_Spain_falls_mainly_down_a_drain
  $

We can use the L<B::Deparse|B::Deparse> module to see how the perl
interprets this piece of code.

  $ perl -MO=Deparse nop.pl
  '???';
  $

=head2 Embedding Perl

Armed with these two tricks, let us approach our GIF header once
more. Notice that if we alter the first byte of the logical screen
width to 0x3b (ASCII ";"), then we have our first valid line of perl -
namely "GIF89a".  This as we discussed earlier is a bareword and thus
a NOP in perl.  Also, we can do this safely because the GIF standard
specifies that the logical screen width merely defines the largest
image that can be displayed.  Each actual image in a GIF file (defined
further in the file) carries its own size.

Note that at this point, we have set only the lower byte of the two
byte logical screen width.  We would like to cause perl to continue to
skip interpreting bytes until such a point where we can begin
inserting perl code without interfering with the rather strict
specifications of the GIF format.  We can do this either by setting
the higher byte of the logical screen width to 0x23 (ASCII "#") thus
inserting a comment indicator and ensuring there are no end of line
characters till we are ready, or by introducing a string.

Before we decide which of these two equally valid techniques to use,
let us decide where we will embed the actual perl code that we would
like to interpret.  The GIF standard is designed to be backward
compatible and extensible in the sense that blocks with markers that
are not recognized by a program are simply ignored.  We could choose
to use this fact and introduce an unimplemented block code which would
thus be ignored by GIF viewers.  Alternatively, we could choose to
embed our program in the standard GIF comments section.
Perl::Visualize uses currently uses this second option which has the
added advantage that on many image viewers, the comments embedded in a
GIF file can be displayed either by moving the mouse over the image or
by some other means giving the user the opportunity to see the program
that is embedded in the image.

Perl::Visualize allows the user to use either of the embedding tricks
we have described.  The C<paint> function uses the strings technique
(because painting is done with a I<stringed> instrument) while the
C<etch> function uses the comment technique (because etching is done
using a sharp(#) tool.  Ahem). Both of these techniques cause perl to
skip over the remainder of the logical screen specification and the
color table as well as the first two bytes that indicate the start of
a GIF comment as described L<next|GIF Comments>.

=head2 GIF Comments

GIF comments are stored in a section marked by C<0x21 0xfe>.  Comments
consist of a series of Pascal style strings - that is a sequence of
characters preceded by a byte containing the length of the string.
The comments section is terminated by an empty string.

At this point, it is probably very clearly how to achieve the
remainder of our task.  We have so far been able to make perl skip
over the GIF header and begin executing the code found in the GIF
comment section.  Simultaneously, we have managed to preserve the
original image except for altering it logical width and height and
introducing a new comment block.  These are arguably semantic
preserving transformations on the image.  We need to finish inserting
the remainder of perl code, terminate the GIF comment section and
leave the rest of the GIF image alone.

The only real complication that remains to be handled is that the
Pascal styled strings introduce a extraneous byte at the beginning of
every embedded string.  We can manage this final hurdle by B<not>
introducing extraneous length bytes but instead treating some of the
existing characters in the code we are embedding as length bytes.
This is best understood by example.  Suppose we have are embedding a
Perl string:

  '!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ'

We can consider this a sequence of Pascal strings by repeatedly
reading a length byte then as many bytes as indicated by that length
giving us:

  Length=0x21 (ASCII '!') '"#$%&'()*+,-./0123456789:;<=>?@AB'
  Length=0x43 (ASCII 'C') 'DEFGHIJKLMNOPQRSTUVWXYZ...'

Note that the second string is now "incomplete".  Since these will be
statements in Perl, we can probably safely pad the last statement
string using spaces.

Finally, we need to terminate the execution of perl so that the rest
of image bytes are ignored.  We can do this appending "\n__END__\n" or
control characters C<^Z> or C<^D> to the Perl code before embedding
it.  Following this we insert a blank Pascal string, C<0x00> to end
the GIF comment section.

And we are done.

=head1 SEE ALSO

L<http://www.nyx.net/~gthompso/poly/polyglot.htm>

=head1 BUGS

Yes.

Not all programs can be embedded.  In particular, embedding programs
that rely on their own structure to function correctly cannot be
embedded - for example Acme::Bleach'ed programs are not correctly
embedded.

Bug reports and patches gratefully accepted

=head1 ACKNOWLEDGMENTS

I would like to thank Christian Collberg for not dissuading me from
writing this module. C<:-)>

=head1 AUTHOR

Jasvir Nagra http://www.cs.auckland.ac.nz/~jas

=head1 COPYRIGHT AND LICENSE

   Copyright (c) 2003, Jasvir Nagra. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)

=cut
