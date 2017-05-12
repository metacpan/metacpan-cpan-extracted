
=head1 NAME

PostScript::Columns - Squeeze a text file into multiple columns.

=head1 SYNOPSIS

  use PostScript::ColDoc;
  
  $psdoc= pscolumns( 
    -margins => [30,20], # NSEW or NS,EW or N,EW,S or N,E,W,S (like CSS)
    -headfont => 'NimbusMonL-Bold', 
    -headsize => 12,
    -head => $head,
    -font => 'NimbusMonL-Regu', 
    -size => 10, 
    -text => $text,
      # default font/size for foot:
    -foot => "Page \$p of \$pp", # will interpolate later :)
  );

  # use all defaults, no footer 
  $doc= pscolumns(
    -size => 5,
    -head => "Left\nLeft Also\tTest Document\tRight",
    -text => $text,
    -foot => scalar(localtime)."\tFoot\tPage \$p of \$pp",
  );


=head1 DESCRIPTION

Creates a PostScript document with a user-defined header and footer, 
then attempts to squeeze the data into as many columns as possible.

=head1 AVAILABLE FONTS

Only the monospace PostScript fonts are available:

=over 4

=item C<NimbusMonL-Regu>

=item C<NimbusMonL-Bold>

=item C<NimbusMonL-ReguObli>

=item C<NimbusMonL-BoldObli>

=back

=head1 OPTIONS

=over 4

=item -margins

Array ref that specifies page margins, in I<points> (1/72 of an inch).
North, East, West South are expressed as
four elements: [ N, E, S, W ], three elements [ N, E_W, S ], two elements [ N_S, E_W ],
or one element [ N_S_E_W ].
(This is the same order that CSS uses.)

B<Note:> Different printers may require drastically different margins.
You'll have to experiment each time you use this module with a new printer.

=item -headfont

Name of the font to use for the header (see L<"AVAILABLE FONTS">).

=item -headsize

Size of the font to use for the header (in points).

=item -head

String to use as header.
Upper-right, centered, and upper-left fields are tab-separated.
In the string, C<$p> will be replaced by the current page number,
and C<$pp> with the total number of pages.

=item -font

Name of the font to use for the text (see L<"AVAILABLE FONTS">).

=item -size

Size of the font to use for the text (in points).

=item -text

Columnar text.

=item -footfont

Name of the font to use for the footer (see L<"AVAILABLE FONTS">).

=item -footsize

Size of the font to use for the footer (in points).

=item -foot

String to use as footer.
Lower-right, centered, and lower-left fields are tab-separated.
In the string, C<$p> will be replaced by the current page number,
and C<$pp> with the total number of pages.

=back

=head1 AUTHOR

v, E<lt>five@rant.scriptmania.comE<gt>

=head1 SEE ALSO

perl(1).

=cut

package PostScript::Columns;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw(%wratio);

$VERSION = '1.23';
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(pscolumns);

sub pscolumns
{ # Hey! I know what's mine! ;) 
  my %arg= @_;
  my($now,$who)= (scalar localtime, getlogin);
  ## initial metrics 
  my($margin_N,$margin_E,$margin_S,$margin_W)= @{$arg{-margins}||[]};
  $margin_N= 30 unless defined $margin_N;
  $margin_E= 20 unless defined $margin_E;
  $margin_S= $margin_N unless defined $margin_S;
  $margin_W= $margin_E unless defined $margin_W;
  my $font= ( $wratio{$arg{-font}} ? $arg{-font} : 'NimbusMonL-Regu' );
  my $font_Y= $arg{-size} || 7;
  my $font_X= $font_Y * $wratio{$font};
  my $line_Y= $arg{-linewidth} || 0.2;
  ## head metrics 
  my @head_right= split /\t/, $arg{-head};
  my @head_left= split /\n/, $head_right[0];
  my @head_center= split /\n/, $head_right[1];
  @head_right= split /\n/, $head_right[2];
  my($head_lines)= sort {$b<=>$a} 
    (scalar @head_left, scalar @head_center, scalar @head_right);
  my $head_font= $arg{-headfont} || 'NimbusMonL-Bold';
  my $head_font_Y= $arg{-headsize} || 10;
  my $head_font_X= $head_font_Y * $wratio{$head_font};
  my $head_Y= $head_font_Y * $head_lines;
  ## foot metrics 
  my @foot_right= split /\t/, $arg{-foot};
  my @foot_left= split /\n/, $foot_right[0];
  my @foot_center= split /\n/, $foot_right[1];
  @foot_right= split /\n/, $foot_right[2];
  my($foot_lines)= sort {$b<=>$a} 
    (scalar @foot_left, scalar @foot_center, scalar @foot_right);
  my $foot_font= $arg{-footfont} || 'NimbusMonL-Regu';
  my $foot_font_Y= $arg{-footsize} || 8;
  my $foot_font_X= $foot_font_Y * $wratio{$foot_font};
  my $foot_Y= $foot_font_Y * $foot_lines;
  ## text metrics 
  local $_= $arg{-text} || ' '; s/\t/  /g;
  my @text= split /\n/;
  my($maxlen)= sort {$b<=>$a} map {length} @text;
  my $col_X= $maxlen * $font_X;
  my $paper_Y= 792;
  my $paper_X= 612;
  my $right= $paper_X-$margin_E;
  my $head_top= $paper_Y-$margin_N;
  my $head_line_top= $head_top-$head_Y+($head_font_Y/2);
  my $text_top= $head_top-$head_Y-($font_Y/2);
  my $foot_top= $foot_Y+$margin_S;
  my $foot_line_top= $foot_top+($foot_font_Y);
  my $text_Y= $text_top-$foot_line_top-4;
  my $text_X= $paper_X-$margin_E-$margin_W;
  my $rows= int( $text_Y / $font_Y );
  my $cols= int( $text_X / $col_X ) || 1;
  $col_X= $text_X / $cols;
  my $pagelines= $rows * $cols;
  my $pp= int( ( @text / $pagelines ) +0.999 );
  my $ps= <<".";
%!PS-Adobe-3.0
%%Title: Columnar Document
%%Creator: PostScript::Columns v$VERSION
%%CreationDate: $now
%%For: $who
%%BoundingBox: 0 0 $paper_X $paper_Y
%%Pages: $pp
%Columns: $cols @ $col_X pt
%%EndComments
.
  my $ps_head= "/$head_font findfont $head_font_Y scalefont setfont\n";
  for my $y (map {$head_top-$head_font_Y*$_} reverse (0..$head_lines-1))
  {
    local $_= pop @head_left;
    s/(\(|\)|\\)/\\$1/g;
    $ps_head.= "$margin_W $y moveto ($_) show\n" if $_;
    $_= pop @head_center;
    my $x= ( $paper_X - ($head_font_X * length) )/2;
    s/(\(|\)|\\)/\\$1/g;
    $ps_head.= "$x $y moveto ($_) show\n" if $_;
    $_= pop @head_right;
    $x= $paper_X - $margin_E - ($head_font_X * length);
    s/(\(|\)|\\)/\\$1/g;
    $ps_head.= "$x $y moveto ($_) show\n" if $_;
  }
  $ps_head.= "$margin_W $head_line_top moveto $right $head_line_top ".
    "lineto $line_Y setlinewidth stroke\n".
    "/$foot_font findfont $foot_font_Y scalefont setfont\n";
  for my $y (map {$foot_top-$foot_font_Y*$_} (0..$foot_lines-1))
  {
    local $_= shift @foot_left;
    s/(\(|\)|\\)/\\$1/g;
    $ps_head.= "$margin_W $y moveto ($_) show\n" if $_;
    $_= shift @foot_center;
    my $x= ( $paper_X - ($foot_font_X * length) )/2;
    s/(\(|\)|\\)/\\$1/g;
    $ps_head.= "$x $y moveto ($_) show\n" if $_;
    $_= shift @foot_right;
    $x= $paper_X - $margin_E - ($foot_font_X * length);
    s/(\(|\)|\\)/\\$1/g;
    $ps_head.= "$x $y moveto ($_) show\n" if $_;
  }
  $ps_head.= "$margin_W $foot_line_top moveto $right $foot_line_top ".
    "lineto $line_Y setlinewidth stroke\n";
  $ps_head.= "/$font findfont $font_Y scalefont setfont\n";
  $ps_head=~ s/\$pp\b/$pp/g;
  my $p;
  PAGE: while(@text)
  {
    $p++;
    (my $thishead= $ps_head)=~ s/\$p\b/$p/g;
    $ps.= "\n%%Page: (Page $p) $p\n".$thishead;
    for my $x (map {$margin_W+$col_X*$_} (0..$cols-1))
    {
      for my $y (map {$text_top-$font_Y*$_} (0..$rows-1))
      {
        next unless local $_= shift @text;
        last if /\x0c/; # end col at formfeed 
        s/(\(|\)|\\)/\\$1/g;
        $ps.= "$x $y moveto ($_) show\n";
        last PAGE unless @text;
      }
    }
    $ps.= "showpage\n";
  } 
  $ps.= "showpage\n";
  return $ps;
}

%wratio=
( # Hmmm.... not a lot of variance.  Keep? 
  'NimbusMonL-Regu'     => 0.6,
  'NimbusMonL-Bold'     => 0.6,
  'NimbusMonL-ReguObli' => 0.6,
  'NimbusMonL-BoldObli' => 0.6,
);

1;
