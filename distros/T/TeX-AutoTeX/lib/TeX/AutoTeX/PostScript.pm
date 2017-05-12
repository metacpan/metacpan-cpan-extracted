package TeX::AutoTeX::PostScript;

#
# $Id: PostScript.pm,v 1.11.2.5 2011/01/27 18:42:28 thorstens Exp $
# $Revision: 1.11.2.5 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/PostScript.pm,v $
#
# $Date: 2011/01/27 18:42:28 $
# $Author: thorstens $
#

use strict;
### use warnings;

our ($VERSION) = '$Revision: 1.11.2.5 $' =~ m{ \$Revision: \s+ (\S+) }x;

sub fix_ps_title {
  my ($sfile, $dir, $title, $log) = @_;

  my $file = "$dir/$sfile";
  if (!(-e $file && -r _)) {
    $log->verbose("'$sfile' does not exist or doesn't have adequate permissions, not setting the %%Title");
    return;
  }
  $log->verbose("Backing up '$sfile'. Going to change %%Title line.");
  if (!rename($file, "$file.xbak")) {
    $log->verbose("failed to make backup of '$file', so we'll skip the title change.");
  } else {
    my ($CHANGED, $ORIG);
    if (!(open($CHANGED, '>', $file) && open($ORIG, '<', "$file.xbak"))) {
      $log->verbose("failed to create new '$file' or read '$file.xbak', so we'll revert to the old one.");
      if (!rename "$file.xbak", $file) {
	throw TeX::AutoTeX::FatalException("woe is me, now that failed. We're doomed.\nGiving up!");
      }
    } else {
    TITLE: while (<$ORIG>) {
	# Only change first title line if any before line 6
	if (substr($_, 0, 7) eq '%%Title') {
	  print {$CHANGED} "%%Title: $title\n";
	  $log->verbose('%%Title: line found and changed.');
	  last TITLE;
	}
	print {$CHANGED} $_;
	last TITLE if $. > 5;
      }
      # TS: ps files can be huge, don't go line by line.
      #     consider sysread/syswrite a la File::Copy
      my $chunk = 2097152; # 2MB = 1024 * 1024 * 2;
      my ($r, $buf);
      while (1) {
	defined ($r = read $ORIG, $buf, $chunk) ||
	  throw TeX::AutoTeX::FatalException('read after title change failed.');
	last if $r == 0;
	print {$CHANGED} $buf
	  or throw TeX::AutoTeX::FatalException('print after title change failed');
      }
      close $ORIG;
      close $CHANGED;

      $log->verbose('Title change completed.');
      if (-e "$file.xbak") {
	unlink "$file.xbak" or $log->verbose("couldn't unlink '$file.xbak': $!");
      }
    }
  }
  return 0;
}

sub stamp_postscript {
  my ($sfile, $dir, $stampref, $log) = @_;

  my $file = "$dir/$sfile";
  if (!(-e $file && -r _)) {
    $log->verbose("'$sfile' doesn't exist, or doesn't have adequate permissions, not stamping") if $log;
    return;
  }
  $log->verbose("Backing up '$sfile'. Going to add a name/date stamp to it.") if $log;
  if (!rename $file, "$file.bak") {
    $log->verbose("failed to make backup of '$file', so we'll skip the stamping.") if $log;
  } else {
    my ($STAMPED, $ORIG);
    if (!(open($STAMPED, '>', $file) && open($ORIG, '<', "$file.bak"))) {
      $log->verbose("failed to create new '$file' or read '$file.bak', so we'll revert to the old one.") if $log;
      if (!rename("$file.bak", $file) && $log) {
	throw TeX::AutoTeX::FatalException("woe is me, now that failed. We're doomed.\nGiving up!");
      }
    } else {
    PAGE1: while (<$ORIG>) {
	print {$STAMPED} $_;
	last PAGE1 if /^%%Page:\s+-?\d+\s+1\s*$/;
      }
    STAMP: while (<$ORIG>) {
	if (substr($_, 0, 2) ne '%%') {
	  $log->verbose('OK, inserting the stamp') if $log;
	  # we had a request for extra space in front of the v
	  # on postscript files (only)
	  my $xmoveto = int(6*72 - length($stampref->[0])*9/2);
	  #6in - halflength, ymoveto=39=.54in

	  if ($stampref->[1]) {
	    print {$STAMPED} <<"EOSTAMP";
gsave %matrix defaultmatrix setmatrix
90 rotate /stampsize 20 def /Times-Roman findfont stampsize scalefont setfont
currentfont /FontBBox get aload pop /pdf\@top exch 1000 div stampsize mul def
pop /pdf\@bottom exch 1000 div stampsize mul def pop
$xmoveto -32 moveto
currentpoint /pdf\@lly exch pdf\@bottom add def /pdf\@llx exch 2 sub def
0.5 setgray ($stampref->[0]) show
currentpoint /pdf\@ury exch pdf\@top add def /pdf\@urx exch 2 add def
/pdfmark where{pop}{userdict /pdfmark /cleartomark load put}ifelse
[ /H /I /Border [0 0 1] /BS <</S/D/D[2 6]/W 1>> /Color [0 1 1]
/Action << /Subtype /URI /URI ($stampref->[1])>>
/Subtype /Link /Rect[pdf\@llx pdf\@lly pdf\@urx pdf\@ury] /ANN pdfmark
grestore
EOSTAMP
	  } else {
	    print {$STAMPED} <<"EOPS";
gsave %matrix defaultmatrix setmatrix
90 rotate $xmoveto -39 moveto /Times-Roman findfont 20 scalefont setfont
0.3 setgray ($stampref->[0]) show grestore
EOPS
	  }
	  print {$STAMPED} $_;
	  last STAMP;
	}
	print {$STAMPED} $_;
      }
      # TS: ps files can be huge, don't go line by line.
      #     consider sysread/syswrite a la File::Copy
      my $chunk = 2097152; # 2MB = 1024 * 1024 * 2;
      my ($r, $buf);
      while (1) {
	defined ($r = read $ORIG, $buf, $chunk) ||
	  throw TeX::AutoTeX::FatalException('read after stamping failed.');
	last if $r == 0;
	print {$STAMPED} $buf
	  or throw TeX::AutoTeX::FatalException('print after stamping failed');
      }
      $log->verbose('Stamping completed.') if $log;
    }
    close $ORIG;
    close $STAMPED;
  }
  unlink "$file.bak" if -e "$file.bak";

  return 0;
}

1;

__END__

=for stopwords cwd undef arxiv.org PostScript Schwander perlartistic www-admin

=head1 NAME

TeX::AutoTeX::PostScript - watermark PostScript files and related manipulations

=head1 DESCRIPTION

Contains two methods that make changes to postscript files.

=head1 HISTORY

 AutoTeX automatic TeX processing system
 Copyright (c) 1994-2006 arXiv.org and contributors

 AutoTeX is supplied under the GNU Public License and comes
 with ABSOLUTELY NO WARRANTY; see COPYING for more details.

 AutoTeX is an automatic TeX processing system designed to
 process TeX/LaTeX/AMSTeX/etc source code of papers submitted
 to the arXiv.org (nee xxx.lanl.gov) e-print archive. The
 portable part of this code has been extracted and is made
 available in the hope that it will be useful to other projects
 and that the input of others will benefit arXiv.org.

 Code developed and contributed to by Tanmoy Bhattacharya, Rob
 Hartill, Mark Doyle, Thorsten Schwander, and Simeon Warner.
 Refactored to separate generic code from arXiv.org specific code
 by Stephen Marsh, Michael Fromerth, and Simeon Warner 2005/2006.

 Major cleanups and algorithmic improvements/corrections by
 Thorsten Schwander 2006 - 2011

=head1 FUNCTIONS

=head2 fix_ps_title($file, $title, $log)

Changes the %%Title line (the first occurrence) in the given PostScript file
if found within the first 6 lines. $log is a TeX::AutoTeX::Log object to log
errors.

=head2 stamp_postscript($file, $stampref, $log)

Adds a stamp to the PostScript file, and if $stampref specifies a link
target as its second element, makes the stamp an active hyperlink.

Input parameters:

=over 4

=item $file

  file name relative to cwd

=item $stampref = [$stamp, $link]

 $stamp string to add
 $link URL to link stamp to (if set, otherwise no link)

=item $log 

 this is an _optional_ TeX::AutoTeX::Log object to log errors:
 $log set   => usual $log->verbose() and $log->error()
 $log undef => no logging, returns error code else 0 for OK

=back

=head1 BUGS AND LIMITATIONS

The placement of the stamp assumes US letter size paper (11.5in tall) and
makes assumptions about the average character width at the given size. These
are expedients that work well most of the time. Obviously these would need to
be modified for say e-book reader formats.

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

Thorsten Schwander for L<arXiv.org|http://arxiv.org/>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
