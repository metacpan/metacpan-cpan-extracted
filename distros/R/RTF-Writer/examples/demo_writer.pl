
require 5.005;
use strict;  # Time-stamp: "2001-04-24 01:50:43 MDT"
use RTF::Writer 1.01;

=head1 NAME

demo_writer.pl -- a lame sample program for outputting RTF

=head1 SYNOPSIS

  Read the source of this program.
  It's ejumucational.

=head1 DESCRIPTION

One of my many superpowers is writing Perl programs that read lexical
databases, chew them up, and spit out a tidily formatted
dictionary, in RTF.

Why RTF?  Just convenience -- I happened to know a
bit about RTF, and I didn't know TeX.  (And XML+XSL didn't
exist at the time.)  For ages I wrote (and rewrote, anew each time)
completely ad-hoc code to
spit out RTF.  But after a few years of having to consult the icky
I<RTF Specification> to remember how to turn on page numbering,
or emit a useful prolog, I decided to write RTF::Writer, to
simplify these tasks.

This program, demo_writer.pl, is just an example program that
uses RTF::Writer to emit RTF.  The RTF it happens to emit, is
a miniature lexicon file, based an a miniature lexical
database as input.

See also L<RTF::Writer|RTF::Writer> and
L<RTF::Cookbook|RTF::Cookbook>.

=head1 AUTHOR

Sean M. Burke, sburke@cpan.org

=cut


my $nl = "
";


my @records = split("\n\n", q{

\hw toc
\en tap
\en knock
\pos n.m.

\hw lys
\pos n.m.
\en lily
\en knock

\hw flétrir
\pos v.itr.
\en to wilt
\en for a flower or beauty to fade
\en for a plant to wither

\hw mort
\pos adj.
\en dead
\xref mourir

\hw emporter
\pos v.tr.
\en to take a person or thing [somewhere]
\en to take [out/away/etc.] or carry [away] a thing

\hw toquer
\pos v.itr.
\en to tap
\en to knock

\hw trotter
\pos v.itr.
\en to trot
\en to scurry

\hw souris
\pos n.f.
\en mouse
\semantic_field animals

});

#------------------------------------------------------------------------

{
  # A private class for lexicon entries:
  package _SMB::Lexicon::Entry;
  sub get ($) {
    my $x = $_[0]->{$_[1]} || [];
    return @$x if wantarray;
    return join '', @$x;
  }
}
#------------------------------------------------------------------------

# Init records:

foreach my $r (@records) {
  my %hash;
  foreach my $l (grep m/\S/, split "\n", $r) {
    if($l =~ m/^\\(\w+)\s+(.+)/s) {
      # print "<$1> <$2>\n";
      push @{$hash{$1} ||= []}, $2;
    } else {
      die "Line <$l> is bonkers";
    }
  }
  $r = bless(\%hash, '_SMB::Lexicon::Entry') if scalar keys %hash;
}

{
  my $nil = [''];
  @records =
    # Actually we'd really want to use Sort::ArbBiLex instead
    sort { 
      # Sort according to the (first) headword
      lc( ($a->{'hw'} || $nil )->[0] ) cmp
      lc( ($b->{'hw'} || $nil )->[0] )
    }
    grep ref($_), @records;
}


my $rtf = RTF::Writer->new_to_file('lex_out.rtf');
$rtf->prolog;
$rtf->number_pages("Lexicon, p.");

$rtf->paragraph(\'\sa400\fs44\scaps', "Sample Lexicon",);

#------------------------------------------------------------------------
# Write out each record:

foreach my $r (@records) {
  next unless ref $r;
  
  # use Data::Dumper;  print Dumper($r), "\n\n";

  my @stuff;

  $rtf->printf( \'{\pard\li300\fi-150\plain\fs24' );

  my $hw = $r->get('hw');

  my $pos = $r->get('pos');

  if($pos) {
    $rtf->printf(
      \'{\fs30\b\lang1036\noproof %s}{\i  (%s)} \endash  ',
      $hw || '??', $pos
    );
  } else {
    $rtf->printf(
      \'{\fs30\b\lang1036 %s} \emdash  ',
      $hw || '??'
    );
  }

  $rtf->print(join '; ', $r->get('en'));

  $rtf->printf( \"\\par}\n\n" );
}

$rtf->paragraph(\'\sb400',
  sprintf("--\n%d entries.  Generated %s by \xAB%s\xBB",
    scalar(@records),
    scalar(localtime), 
    $0 || '??',
  )
);

exit;


