# Regexp::HTMLify.pm

# Copyright (c) 2008-2011 Niels van Dijke <PerlboyAtCpanDotOrg> http://PerlBoy.net
# All rights reserved. This program is free software.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

package Regexp::HTMLify;

require 5.008002;
require Exporter;
use vars qw(@ISA @EXPORT);

use strict;
use Carp 'croak';
use CGI qw/:standard/;

use vars qw($VERSION);
$VERSION = sprintf('%d.%03d', q$Revision: 0.002 $ =~ m#(\d+)\.(\d+)#);

use vars qw($MAXCOLORS $CSS_COLORMAP);

###############################################################################
# prototypes
###############################################################################
sub HTMLifyGetColormapCSS (;$$);
sub HTMLifyRE ($;\@$$);
sub HTMLifyREmatches ($;\@$$);

@ISA = qw(Exporter);
@EXPORT = qw(
	HTMLifyGetColormapCSS
	HTMLifyRE
	HTMLifyREmatches
);

sub HTMLifyGetColormapCSS (;$$) {
  my $fHandle = $_[0];
  my $prefix = defined($_[1]) ? $_[1] : 'cDef';

  local $_;

  if (!defined $fHandle) {
    if (!defined $CSS_COLORMAP) {
      $fHandle = *Regexp::HTMLify::DATA;
    } else {
      # hide $CSS_COLORMAP and return cached version
      return $CSS_COLORMAP;
    }
  }

  my @colorMap = <$fHandle>;
  map { $MAXCOLORS++ if (/^\s*\.$prefix(\d+)\s*{/ and $1 > 0) } @colorMap;
  $CSS_COLORMAP = join('',@colorMap);

  return $CSS_COLORMAP;
}

sub _init {
  return HTMLifyGetColormapCSS() ne '';
}

# sub HTMLifyRE ($RegExp,[\@variables,$startColorIndex,$templateClass])
sub HTMLifyRE ($;\@$$) {
  my $re = shift;
  my $varnames = shift || [];
  my $startColorIndex = defined $_[0] ? $_[0] : 1;
  my $cssClass = defined $_[1] ? $_[1] : 'cDef';

  local $_;

  # perl 5.12 qr((.)) => '(?-xism:(.))'
  # perl 5.14 qr((.)) => '(?:(.))'
 
  # No support for code execution in regexp
  no re 'eval'; 
  eval { my $tmpRe = qr($re)};
  if ($@) {
    croak("HTMLifyRE('\$regexp') => $@\n");
  }

  # Check whether we support the given regexp
  if ($re =~ m#\)[*+?{]#sm) {
    croak("HTMLre: Unsupported regexp (backref quantifiers)");
  }
  if ($re =~ m#\(\?\|#sm) {
    croak("HTMLre: Unsupported regexp (branch reset (v5.10.x and higher))");
  }

  my $i = 1; 
  my @brStack = ('(');
  my $ret;

  # find first 'real' (non escaped) '(' or ')'
  while ($re =~ m#^(.*?)(?!\\)([()])(.*)#sm) {
    my ($pre,$br,$post) = ($1,$2,$3);
    $ret .= escapeHTML($pre);
    #print STDERR scalar(@brStack)."($brStack[-1]) [".join("] [",$pre,$br,$post)."]<br/>\n";
    if ($br eq '(') {
      # a bracket which creates a capture buffer? 
	  #(capture buffer: $1, $2, etc. or \g{1}, \g{2} etc. in Perl v5.10.x)
      if ($post =~ m#^[\?\*]#) {
        push(@brStack,'');		  
	    $ret .= '(';
	  } else {
        my $title = defined $varnames->[$i-1] ?
                      qq(title="$varnames->[$i-1]") : '';
        my $cdef = ($startColorIndex - 1 + (13 * $i++) % $MAXCOLORS) + 1;
        $ret .= qq[<span class="${cssClass}0">(<span class="$cssClass$cdef" $title>]; 
	    push(@brStack,'(');
	  }
    } else {
      $br = pop(@brStack);
      if ($br eq '(') {
        $ret .= '</span>)</span>';
      } else {
        $ret .= ')';
      }
    }
    $re = $post;
  }
  $ret .= escapeHTML($re);
  return $ret;
}


# sub HTMLifyREmatches ($var,\@variables[,$startColorIndex,$cssClass])
sub HTMLifyREmatches ($;\@$$) {
  my $var = shift;
  my $varnames = shift || [];
  my $startColorIndex = defined $_[0] ? $_[0] : 1;
  my $cssClass = defined $_[1] ? $_[1] : 'cDef';

  local $_;

  my @c = split(//,$var);
  for (my $i = 1; $i < scalar(@-); $i++) {
    next if !defined $-[$i];
    my $title = defined $varnames->[$i-1] ?
                qq(title="$varnames->[$i-1]") : '';
    my $cdef = ($startColorIndex - 1 + (13 * $i) % $MAXCOLORS) + 1;
    $c[$-[$i]] = qq[<span class="$cssClass$cdef" $title>$c[$-[$i]]];
    $c[$+[$i]-1] .= '</span>';
  }
  return join('',@c);
}

_init();


=head1 NAME

Regexp::HTMLify - Highlight regular expression capture buffers and matches using HTML and CSS

=head1 SYNOPSIS

    use Regexp::HTMLify;

    my $re = qr((?i)(This) (?!and not that )(will match));
    my $match = 'This will match';
    my @titles = qw(this matches);
	
    print 
      start_html('A simple example of Regexp::HTMLify'),
      HTMLifyGetColormapCSS(),
      p('Regexp: ',HTMLifyRE($re,@titles));
	  
    if ($match =~ m#$re#) {
      print p('MATCH :',HTMLifyREmatches($match,@titles));
    } else {
      print p('NO match');
    }
	
    print end_html;


=head1 DESCRIPTION

This library offers (limited, see below) functionality to highlight 
regular expression capture buffers using HTML and CSS.

=head1 LIMITATIONS

This library has the following limitations:

=over

=item *

No support for code execution within regexp; B<(?{....})>

=item *

No support for regexp capture buffer quantifiers;

=over

=item *

(...)B<*>

=item *

(...)B<+>

=item *

(...)B<?>

=item *

(...)B<{n}>

=item *

(...)B<{n,}>

=item *

(...)B<{n,m}>

=back

=back

=head1 AUTHOR

Niels van Dijke <CpanDotOrgAtPerlboyDotNet>

=head1 TODO

=over

=item *

Speedup of HTMLifyREmatches()

=item *

Work on capture buffer quantifier limitations

=item *

Add support for backrefs (\1, \2 and Perl v5.10.x \g{1}, \g{2})

=item *

Add more 'real life' tests and/or examples

=item *

Enhance documentation instead of RTFS (read the fine source)

=back

=head1 NOTES

This is alpha code and not extensively tested. Use with care!

=head1 COPYRIGHT

Copyright (c) 2008-2011 Niels van Dijke L<mailto:CpanDotOrgAtPerlboyDotNet> L<http://PerlBoy.net>
All rights reserved. This program is free software.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

__DATA__
<!-- 
  Default colormap of Perl library Regexp::HTMLify 
  by Niels van Dijke / http://PerlBoy.net 
  (based on: http://www.visibone.com/colorlab)
-->
<style type="text/css">
.cDef0{color:#f00; background-color: rgba(255,255,255,0.2);}
.cDef1{color:#fff;background-color:#936;}
.cDef2{color:#fff;background-color:#639;}
.cDef3{color:#fff;background-color:#369;}
.cDef4{color:#fff;background-color:#396;}
.cDef5{color:#fff;background-color:#693;}
.cDef6{color:#fff;background-color:#963;}
.cDef7{color:#fff;background-color:#c06;}
.cDef8{color:#fff;background-color:#60c;}
.cDef9{color:#fff;background-color:#06c;}
.cDef10{color:#fff;background-color:#0c6;}
.cDef11{color:#fff;background-color:#6c0;}
.cDef12{color:#fff;background-color:#c60;}
.cDef13{color:#fff;background-color:#c69;}
.cDef14{color:#fff;background-color:#96c;}
.cDef15{color:#fff;background-color:#69c;}
.cDef16{color:#fff;background-color:#6c9;}
.cDef17{color:#fff;background-color:#9c6;}
.cDef18{color:#fff;background-color:#c96;}
.cDef19{color:#000;background-color:#f39;}
.cDef20{color:#000;background-color:#93f;}
.cDef21{color:#000;background-color:#39f;}
.cDef22{color:#000;background-color:#3f9;}
.cDef23{color:#000;background-color:#9f3;}
.cDef24{color:#000;background-color:#f93;}
.cDef25{color:#000;background-color:#f9c;}
.cDef26{color:#000;background-color:#c9f;}
.cDef27{color:#000;background-color:#9cf;}
.cDef28{color:#000;background-color:#9fc;}
.cDef29{color:#000;background-color:#cf9;}
.cDef30{color:#000;background-color:#fc9;}
.cDef31{color:#000;background-color:#fcc;}
.cDef32{color:#000;background-color:#fcf;}
.cDef33{color:#000;background-color:#ccf;}
.cDef34{color:#000;background-color:#cff;}
.cDef35{color:#000;background-color:#cfc;}
.cDef36{color:#000;background-color:#ffc;}
.cDef37{color:#000;background-color:#f00;}
.cDef38{color:#000;background-color:#f0f;}
.cDef39{color:#000;background-color:#00f;}
.cDef40{color:#000;background-color:#0ff;}
.cDef41{color:#000;background-color:#0f0;}
.cDef42{color:#000;background-color:#ff0;}
.cDef43{color:#fff;background-color:#c00;}
.cDef44{color:#fff;background-color:#c0c;}
.cDef45{color:#fff;background-color:#00c;}
.cDef46{color:#fff;background-color:#0cc;}
.cDef47{color:#fff;background-color:#0c0;}
.cDef48{color:#fff;background-color:#cc0;}
.cDef49{color:#fff;background-color:#900;}
.cDef50{color:#fff;background-color:#909;}
.cDef51{color:#fff;background-color:#009;}
.cDef52{color:#fff;background-color:#099;}
.cDef53{color:#fff;background-color:#090;}
.cDef54{color:#fff;background-color:#990;}
.cDef55{color:#000;background-color:#c66;}
.cDef56{color:#000;background-color:#c6c;}
.cDef57{color:#000;background-color:#66c;}
.cDef58{color:#000;background-color:#6cc;}
.cDef59{color:#000;background-color:#6c6;}
.cDef60{color:#000;background-color:#cc6;}
.cDef61{color:#000;background-color:#966;}
.cDef62{color:#000;background-color:#969;}
.cDef63{color:#000;background-color:#669;}
.cDef64{color:#000;background-color:#699;}
.cDef65{color:#000;background-color:#696;}
.cDef66{color:#000;background-color:#996;}
</style>


