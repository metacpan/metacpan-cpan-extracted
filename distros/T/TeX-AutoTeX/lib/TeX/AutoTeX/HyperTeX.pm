package TeX::AutoTeX::HyperTeX;

#
# $Id: HyperTeX.pm,v 1.10.2.7 2011/01/27 18:42:28 thorstens Exp $
# $Revision: 1.10.2.7 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/HyperTeX.pm,v $
#
# $Date: 2011/01/27 18:42:28 $
# $Author: thorstens $
#

use strict;
### use warnings;

our ($VERSION) = '$Revision: 1.10.2.7 $' =~ m{ \$Revision: \s+ (\S+) }x;

sub copy_source_from_hyper {
  my ($this_type, $file, $dir, $log, $local_hyper_transform) = @_;

  my $protect = q{};
  my $stripping = 0;

  if ($this_type eq 'TYPE_LATEX' ||
      $this_type eq 'TYPE_LATEX2e' ||
      $this_type eq 'TYPE_PDFLATEX') {
    $protect = '\\protect';
    $stripping = 1;
  }

  my $customfilter = 0;
  if (ref($local_hyper_transform) =~ /Filter/) {
    $customfilter = 1;
    $local_hyper_transform->{protect} = $protect;
  }

  my $checktexsis = 0;
  if ($file !~ /texsis/) {
    $checktexsis = 1;
  }

  # aipproc often does not work with hypertex
  # supercite, crckapb10, crckapb..., lamuphys do not work with hypertex
  # heron2e.sty style does not work with hypertex
  my $incompatiblemacropackages = qr/aipproc|supercite|crckapb|lamuphys|heron2e/;

  open (my $WITH_HYPER, '>', "$dir/$file.with_hyper")
    || $log->error("failed to create '$file.with_hyper': $!");
  open (my $WITHOUT_HYPER, '>', "$dir/$file.without_hyper")
    || $log->error("failed to create '$file.without_hyper': $!");
  open (my $SOURCE, '<', "$dir/$file")
    || $log->error("failed to open latex source file '$file' for parsing: $!");

  if ($stripping) {
    my $pos = tell $SOURCE;
  LEADINGCRUFT: while (<$SOURCE>) {
      if (/^\s*[\\\{]/) {
	seek $SOURCE, $pos, 0;
	$.--;
	last LEADINGCRUFT;
      }
      $pos = tell $SOURCE
    }
  }

  my $seen_doc_style_or_class;
  my $h_included;
  my $try_amslplain = 0;
  my $dont_hypertex = 0;

 SOURCE: while (<$SOURCE>) {

    # look for commented out phyzzx reference
    s/%macropackage=phyzzx/\\input\ phyzzx/;
    # Fix old versions of revtex by adding a version number
    s/^(\s*\\documentstyle\s*\[.*)revtex(.*)\]\s*{aps}/$1aps$2,version2]{revtex}/;
    # convert \texsis to \input mtexsis
    if ($checktexsis){
      s/(?<!\\def)\\texsis/\\input mtexsis/;
    }

    # include some stuff for hlatex2e - ignored by hlatex
    if (!$h_included &&
	$seen_doc_style_or_class &&
	/^[^%]*(?:\\newtheorem|\\begin\s*{document}|\\usepackage[^%{]*{amsrefs})/) {
      if ($this_type eq 'TYPE_PDFLATEX') {
	print {$WITH_HYPER} "\\RequirePackage[hyperindex,pdftex]{hyperref}\n";
      } else {
	print {$WITH_HYPER} "\\RequirePackage[hyperindex]{hyperref}\n";
      }
      $h_included = 1;
    }

    if (/^[^%]*\\(?:documentstyle|documentclass|usepackage|input)([^%]*)/) {
      my $macrostring = $1;
      if ($macrostring =~ /($incompatiblemacropackages)/) {
	$dont_hypertex = nohypertex($log, $1);
      }
      # current (as of 10/2007) ws-procs9x6.cls, ws-procs10x7.sty ...
      # do not work with hypertex. some previous versions were ok
      if ($macrostring =~ /ws-procs\d{1,2}x\d/) {
	$dont_hypertex = nohypertex($log, 'ws-procs');
      }
      if (/\\document(?:style|class)/) {
	$seen_doc_style_or_class = 1;
      }
      # look for amsppt style - it must be AMSTeX in disguise
      if (s/^([^%]*\\documentstyle(\[.*])?\{amsppt\})/\\input\ amstex\n$1/) {
	$log->verbose('Whoahaa. This looks like AMSTeX not latex');
	$this_type = 'TYPE_TEX'; # Passed back to calling routine at end
      }
      if (/^[^%]*\\documentstyle(\[.*])?\{amsart\}/) {
	$log->verbose("File contains 'amsart' doc style. Will remember that and\n  revert to amslplain should things fail");
	$try_amslplain = 1;
      }
    }

    print {$WITHOUT_HYPER} $_;

    # amslatex can now include hyper stuff
    # TS: 12/09 should this test be limited to $. == 1 or  $. < 5?
    if (substr $_, 0, 5 eq '%&ams') {
      s/^%&amslplain/\\input hyperlatex%/;
      s/^%&amstex/\\input hyperbasics%/;
    }

    # TS: 12/10 skip past verbatim environments.  handles multiple
    #     consecutive verbatim environments on the same line (for those
    #     pathologically newline challenged OSes). does not bother parsing
    #     things interspersed, preceeding, or following the verbatim env on
    #     the same source line. a line for arXiv's parsing purposes is
    #     defined by unix line delimiter \n (012)
    #    FIXME: What other environments should be skipped?

    if (0 <= index $_, '\begin{verbatim}') {
      if (/^([^%]*(?:(?<=\\)%)*)*\\begin{verbatim}/gc) {
	if (0 <= index $_, '\end{verbatim}', 16 + pos) { # 16 == length '\begin{verbatim}'
	  print {$WITH_HYPER} $_;
	  next SOURCE;
	}
	print {$WITH_HYPER} $_;
	while (<$SOURCE>) {
	  print {$WITHOUT_HYPER} $_;
	  if (0 <= (my $pos = rindex $_, '\end{verbatim}')) {
	    pos = $pos + 14; # 14 == length '\end{verbatim}'
	    if (/\G([^%]*(?:(?<=\\)%)*)*\\begin{verbatim}/gc) {
	      print {$WITH_HYPER} $_;
	      next;
	    }
	    print {$WITH_HYPER} $_;
	    next SOURCE;
	  }
	  print {$WITH_HYPER} $_;
	}
      }
    }

    my $n = 0; # counter to prevent deep recursion
    while (m!(^|[^{"]\s*)((ftp|http)://[^*)\s",>&;%]+)!i) {
      my $tex_url = $2;
      last if (/\\verb\*?\S\s*\Q$tex_url\E/);
      if ($tex_url =~ /\\\~\{?$/) {
	s/\\\~\s*(\{\s*\}\s*)?/\$\\sim\$/g;
	m#(^|[^{]\s*)((ftp|http)://[^]*)\s",>&;]+)#i;
	$tex_url = $2;
      }
      $tex_url =~ s/^([^\{]+)\}.*/$1/;
      $tex_url =~ s/^([^\[]+)\].*/$1/;
      $tex_url =~ s/^([^\$]+)\$[^\$]*$/$1/;
      while ($tex_url =~ tr/\}/\}/ > $tex_url =~ tr/\{/\{/) {
	last unless $tex_url =~ s/\}[^\}]*$//;
      }
      $tex_url =~ s/[\.\+\{\|\!\'\\]+(\[[^]]*\])?$//;
      s/\\verb(.)~\1/\$\\sim\$/g if
	$tex_url =~ s/\\verb(.)~\1/\$\\sim\$/g;    #/\verb|~|
      s{/~}{/\$\\sim\$}g if $tex_url =~ s{/~}{/\$\\sim\$}g;
      #  now  $\sim$ -> \string~, and e.g. \_ -> \string_
      my $special_url = $tex_url;
      # $special_url =~ s/\\,//g;
      $special_url =~ s/\\lower[^{}]*\{([^{}]*)\}/$1/g;
      $special_url =~ s/\\kern//g;
      $special_url =~ s/(\$\^?\\sim\$|\\symbol\{126\}|\\char\'176|\$\\(wide)?tilde\{[^\}]*\}\$|\\homepage)/\\string~/g;
      $special_url =~ s/(\\linebreak|\\\\)(\[[^]]*\])?//g;
      $special_url =~ s/\\([\W\_])(\s*\{\s*\}\s*)?/\\string$1/g;
      $special_url =~ tr/\{\}//d;
      $special_url =~ s/\\mbox//g;
      # FIXME: TS 7/2007
      # \mbox is but one special case
      # just skip out if we see any undesired character
      # e.g. '\', '|', '^', '[', ']', '`', or at least any \<command>?
      last if $n++ >= 5 && s/\Q$tex_url/$protect\\vrule width0pt$protect\\href\{$special_url}\{$tex_url}/;
    }
    if ($customfilter) {
      $_ = $local_hyper_transform->filter($_);
    }
    print {$WITH_HYPER} $_;
  }
  close $WITH_HYPER or $log->verbose("couldn't close source file with markup: $!");
  close $WITHOUT_HYPER or $log->verbose("couldn't close source file without markup: $!");
  close $SOURCE or $log->verbose("couldn't close source file: $!");

  my $setbacktime = time - 5;
  utime $setbacktime, $setbacktime, "$dir/$file", "$dir/$file.with_hyper", "$dir/$file.without_hyper";
  # Pass back information about new identifications
  return ($this_type, $dont_hypertex, $try_amslplain);
}

sub nohypertex {
  my ($log, $msg) = @_;
  $log->verbose("nohypertex: turning off hypertex because $msg does not work with hypertex");
  return 1;
}

1;

__END__

=for stopwords AutoTeX hypertex undef arxiv.org www-admin Schwander perlartistic

=head1 NAME

TeX::AutoTeX::HyperTeX - filter for augmenting TeX source with hypertex facilities

=head1 DESCRIPTION

The function copy_source_from_hyper() is filtering TeX source files through
an aggregation of a large number of regular expressions imported from the
original AutoTeX code. See HISTORY below.

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

=head2 Functions

=head3 copy_source_from_hyper()

Routine to create modified TeX source to automatically add hypertex
facilities.

Input parameters:

=over 4

=item $type is the file type of $file as determined by TeX::AutoTeX::File

=item $file is the TeX file name to be edited

=item $log is an TeX::AutoTeX::Log object for logging

=item $local_hyper_transform either undef or an instance of a C<Filter> class
with a C<filter()> method for local custom parsing to be executed line by
line after the standard hypertex transformations.

=back

Returns ($this_type, $dont_hypertex, $try_amsplain)

=head3 nohypertex()

Is called by the subroutine above. Essentially functions as a macro, prints
an appropriate message and always returns 1, which is then used to set
$dont_hypertex

=head1 BUGS AND LIMITATIONS

The parsing is somewhat inefficient and easily fooled.

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

See history above. Current maintainer: Thorsten Schwander for
L<arXiv.org|http://arxiv.org/>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
