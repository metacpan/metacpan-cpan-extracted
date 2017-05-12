
require 5;
package RTF::Writer::TableRowDecl;
use strict;  # Time-stamp: "2003-09-23 21:26:40 ADT"
use Carp ();

BEGIN {
  if(defined &DEBUG) { } # nil
  elsif(defined &RTF::Writer::DEBUG) { *DEBUG = \&RTF::Writer::DEBUG }
  else { *DEBUG = sub(){0} }
}
#--------------------------------------------------------------------------

use vars qw($DEFAULT_BORDER_WIDTH %Directions %Align_Directions);
$DEFAULT_BORDER_WIDTH ||= 15;

unless(keys %Directions) {
  @Directions{qw(N S E W)} = (0 .. 3);
  @Directions{qw(n s e w)} = (0 .. 3);
  @Directions{qw(T B R L)} = (0 .. 3);
  @Directions{qw(t b r l)} = (0 .. 3);
}
                   # N S E W
my(@tabledirs) = qw( t b r l );

unless(keys %Align_Directions) { for my $d (\%Align_Directions) {
  # First char is vertical, second is horiz

  @$d{qw(NW N NE)} = qw(tl tc tr);
  @$d{qw(W  C  E)} = qw(cl cc cr);
  @$d{qw(SW S SE)} = qw(bl bc br);

  @$d{qw(WN EN)} = qw(tl tr);
  @$d{qw(WS ES)} = qw(bl br);

  @$d{qw(TL T TR)} = qw(tl tc tr);
  @$d{qw(L  C  R)} = qw(cl cc cr);
  @$d{qw(BL B BR)} = qw(bl bc br);

  @$d{qw(LT RT)} = qw(tl tr);
  @$d{qw(LB RB)} = qw(bl br);

  @$d{map lc($_), keys %$d}
              = values %$d;
}}

#--------------------------------------------------------------------------
#   INSIDES:
#    0: the right-ends table
#    1: the left-margin setting
#    2: the inbetween setting
#    3: a list of border settings
#    4: a list of valign settings
#    5: a list of halign settings
#    6: the cached decl string

sub new {
  my($it, %h) = @_;
  my $new;

  my(@reaches);
  if(ref $it) { # clone
    $new = $it->clone();
  } else {
    $new = bless [
      \@reaches,
      int( $h{'left_start'}||0 ) || 0,
      int( $h{'inbetween' }||0 ) || 120,  # 6 points, 1/12th-inch, about 2mm
    ];
  }
  
  my $x; # scratch
  if($x = $h{'widths'}) {
    Carp::croak("'widths' value has to be an arrayref")
     unless ref($x) eq 'ARRAY';
    my $start = $new->[1];
    foreach my $w (map int($_), @$x) {
      push @reaches, ($start += ($w < 1 ) ? 1 : $w);
    }
  } elsif($x = $h{'reaches'}) {
    Carp::croak("'reaches' value has to be an arrayref")
     unless ref($h{'reaches'}) eq 'ARRAY';
    @reaches = sort {$a <=> $b} map int($_), @$x;
  }

  $new->make_border_decl(
    defined($h{'borders'}) ? $h{'borders'} : $h{'border'}
  );
  $new->make_alignment_decl(
    defined($h{'align'})   ? $h{'align'}   : $h{'alignment'}
  );
  return $new;
}

#--------------------------------------------------------------------------

sub clone {
  # sufficient to our task, I think
  bless [ map {;
            (!defined $_) ? undef
            : (ref($_) eq 'ARRAY') ? [@$_]
            : (ref($_) eq 'HASH' ) ? {%$_}
            : $_
          } @{$_[0]}
        ],
        ref $_[0];
}

#--------------------------------------------------------------------------

sub make_border_decl {
  my($it, @params) = @_;
  my @borders;

  $it->[3] = \@borders;

  unless( @params and grep defined($_), @params ) {
    @params = ('1');
  }

  @params = @{$params[0]} if @params == 1 and ref $params[0];
   # I.e., if they passed border => [...] 
  @params = "all-$DEFAULT_BORDER_WIDTH-s"
   if @params == 1 and $params[0] eq '1';
   #  if they passed just border => 1
  
  foreach my $spec (@params) {
    push @borders, $it->_borderspec2bordercode($spec);
  }
  
  return;
}
#--------------------------------------------------------------------------

sub make_alignment_decl {
  my($it,@alignments) = @_;
  my(@valign, @halign);
  $it->[4] = \@valign;
  $it->[5] = \@halign;

  unless(@alignments and grep defined($_), @alignments) {
    # most common case: nothing
    push @valign, '';
    push @halign, '';
    return;
  }
  
  if( @alignments != 1) {
    # Pass thru (altho normally impossible)
  } elsif( ref $alignments[0] ) {
    @alignments = @{$alignments[0]}
    # I.e., they passed align => [...] 
  } else {
    @alignments =  grep length($_), split m/(?:\s*,\s*)|\s+/, $alignments[0];
    # I.e., they passed in align => 'sw c c t' or 'sw, c, t' or whatever.
  }
  
  my($x, $v, $h);
  foreach my $spec (@alignments) {
    unless(defined $spec and length $spec) {
      push @valign, '';
      push @halign, '';
      DEBUG and printf " - => valign -             halign -\n";
      next;
    }
    $x = $Align_Directions{$spec};
    unless($x) {
      require Carp;
      Carp::croak "Unintelligible alignment spec \"$spec\"";
    }
    die "WHAAAAA? [$x]" unless 2 == length $x;  # sanity
    my($v,$h) = split '', $x;
    push @valign, "\\clvertal$v";
    push @halign, "\\q$h";
    DEBUG and printf "% 2s => valign %s    halign %s\n",
     $spec, $valign[-1], $halign[-1];
  }
  
  return;
}

#--------------------------------------------------------------------------
sub _borderspec2bordercode {

  my($it, $spec) = @_;

  $spec = 'all' unless defined $spec and length $spec;
  return '' if lc($spec) eq 'none';
  
  $spec = "all-$spec-s" if $spec =~ m/^\d+$/s;

  my @widths = (undef, undef, undef, undef);
  my @styles = (undef, undef, undef, undef);

  my($dir, $width, $style);
  my @specs = split m/(?:,|\s+)/, $spec;
  
  foreach my $it (@specs) {
    next unless $it;

    unless( ($dir, $width, $style) =  $it =~
     m/
      ^\s*
      (all|[nsewNSEWtbrlTBRL])
      (?:-(\d+))?
      (?:-([a-z]+))?
      \s*
      $
     /xs
    ) {
      require Carp;
      Carp::croak "Unintelligible cell-border spec \"$spec\"";
    }
    
    $width = $DEFAULT_BORDER_WIDTH unless defined $width and length $width;

    #print " $it => [$dir] [$width] [$style]\n";

    $style ||= 's';
      
    if($dir eq 'all') {
      @widths = ($width) x 4;
      @styles = ($style) x 4;
    } else {
      $dir = $Directions{$dir};
      $widths[$dir] = $width;
      $styles[$dir] = $style;
    }
  }

  my @out;
  foreach my $i (0 .. 3) {
    next unless $styles[$i];
    push @out, sprintf '\clbrdr%s\brdrw%s\brdr%s',
      $tabledirs[$i],
      $widths[$i],
      $styles[$i],
    ;
  }
  return join "\n", @out;
}

#--------------------------------------------------------------------------

sub new_auto_for_rows {
  my $class = shift;
  my $max_cols = 1;
  foreach my $r (@_) {
    next unless defined $r and ref $r eq 'ARRAY';
    $max_cols = @$r if @$r > $max_cols;
  }
  return
   $class->new( 'width' => [ ((6.5 * 1440) / $max_cols) x scalar(@_) ] );
}

#--------------------------------------------------------------------------

sub row_count {  return scalar @{ $_[0][0] } }
 # How many rows we were declared to handle

#--------------------------------------------------------------------------

sub decl_code {
  my $it = shift;
  return $it->[6] if defined $it->[6];
  
  my $reaches = $it->[0];
  my $cell_count = int($_[0] || 0) || scalar @$reaches;
  
  if($cell_count > @$reaches) {
    # Uncommon case -- we need to ad-hoc pad this decl.
    $reaches = [@$reaches];   # so we won't mutate the original
    while(@$reaches < $cell_count) {
      if(@$reaches == 0) {
        push @$reaches, $it->[1] + 1440;
         # sane and noticeable default width, I think: 1 inch, 2.54cm
      } elsif(@$reaches == 1) {
        push @$reaches, 2 * $reaches->[0] - $it->[1];
         # The left-margin setting
      } else {
        push @$reaches, 2 * $reaches->[-1] - $reaches->[-2];
          # i.e., last + (last - one_before)
        # DEBUG and printf "Improvised the width %d based on %d,%d\n",
        #    $reaches->[-1], $reaches->[-3], $reaches->[-2];
      }
    }
  }
  my @borders = @{ $it->[3] || [] };
  push @borders, ($borders[-1]) x ($cell_count - @borders)
   if @borders > 0 and @borders < $cell_count;
  
  my @valign  = @{ $it->[4] || [] };
  push @valign , ($valign[-1] ) x ($cell_count - @valign )
   if @valign  > 0 and @valign < $cell_count;
    # Or should I have it default to a lack of any alignment code?
  
  $it->[6] = \join '', 
    # Cache it for next time (and there usually are many next-times)
    sprintf("\\trowd\\trleft%d\\trgaph%d\n", $it->[1], int($it->[2] / 2) ),
    map(
      sprintf("%s%s\\cellx%d\n",
        (shift(@borders) ||''),
        (shift(@valign ) ||''),
        $_,
      ),
      @$reaches
    ),
  ;
  DEBUG and print "Init code:\n", ${ $it->[6] }, "\n\n";
  return $it->[6];
}

#--------------------------------------------------------------------------
sub cell_content_init {
  return @{ $_[0][5] || [] };
}

#--------------------------------------------------------------------------
1;

__END__

=head1 NAME

RTF::Writer::TableRowDecl - class for RTF table settings

=head1 SYNOPSIS

  # see RTF::Writer

=head1 DESCRIPTION

See L<RTF::Writer|RTF::Writer>.

=head1 AUTHOR

Sean M. Burke, E<lt>sburke@cpan.orgE<gt>

=cut

# zing!

#           s : Single-thickness border
#          th : Double-thickness border
#          sh : Shadowed border
#          db : Double border
#         dot : Dotted border
#        dash : Dashed border
#        hair : Hairline border
#       inset : Inset border
#      dashsm : Dashed border (small)
#       dashd : Dot-dashed border
#      dashdd : Dot-dot-dashed border
#      outset : Outset border
#      triple : Triple border
#      tnthsg : Thick-thin border (small)
#      thtnsg : Thin-thick border (small)
#    tnthtnsg : Thin-thick thin border (small)
#      tnthmg : Thick-thin border (medium)
#      thtnmg : Thin-thick border (medium)
#    tnthtnmg : Thin-thick thin border (medium)
#      tnthlg : Thick-thin border (large)
#      thtnlg : Thin-thick border (large)
#    tnthtnlg : Thin-thick-thin border (large)
#        wavy : Wavy border
#      wavydb : Double wavy border
#  dashdotstr : Striped border
#      emboss : Embossed border
#     engrave : Engraved border
#       frame : Border resembles a "Frame"

