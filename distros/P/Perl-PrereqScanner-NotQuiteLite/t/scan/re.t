use strict;
use warnings;
use t::scan::Util;

test(<<'TEST');
while ( $message =~ m{((!)?(?:https?:)(?://[^\s/?#]*)[^\s?#]*(?:\?[^\s#]*)?(?:#.*)?)}g ) {
}
TEST

test(<<'TEST'); # FIVE/Mail-MsgStore-1.51/MsgStore.pm
sub msgpath
{
  local $_= shift;
  return '/' if m<^[@*/!?\\]$>; # convenience root
  return if /^[<|>].*[<|>]$/;   # not a path
  s</{2,}|\\></>g;              # clean path
  return $_ if -d "$mailroot/$_"
    or s</$><> or not m<^\W?(.*)/(mail[^/]+mail)$>i;
  return($1,$2);
}
TEST

test(<<'TEST'); # AUTRIJUS/Pod-HtmlHelp-1.1/WinHtml.pm
    $rest =~ s{
        \b                          # start at word boundary
        (                           # begin $1  {
        $urls     :               # need resource and a colon
        [$any] +?                 # followed by on or more
                    #  of any valid character, but
                    #  be conservative and take only
                    #  what you need to....
        )                           # end   $1  }
        (?=                         # look-ahead non-consumptive assertion
            [$punc]*            # either 0 or more puntuation
            [^$any]             #   followed by a non-url char
            |                       # or else
                $                   #   then end of the string
        )
    }{<A HREF="$1">$1</A>}igox;
TEST

test(<<'TEST'); # ROSSI/LaTeX-Authors-0.81/Authors.pm
    my @list_file_sdir = <*/*.tex>;
    my @list_file = (@list_file_dir,@list_file_sdir);
    my $nbr_file = @list_file;

    my $tex_file;

    if ($nbr_file == 1) {
    $tex_file = $list_file[0];
    } elsif ($nbr_file > 1) {
    foreach (@list_file) {
        open(FILEGREP,"$_");
        my $tempo_file = $_;
        while (<FILEGREP>) {
        s/(^\s*|[^\\])%.*/$1/g;
        s/^\s*\n$//g;
        if ((/\\begin\{document\}/) || (/\\bye/) || (/\\documentstyle/) ) {
            $tex_file  = $tempo_file;
            last;
        }
        }

    }
TEST

test(<<'TEST'); # MICB/wing-0.9/Wing.pm
    my ($loc, $handler, $username, $url_session, $cmd, @args)
    = split(m(/), $r->path_info);
TEST

test(<<'TEST'); # DCONWAY/Perl6-Rules-0.03/Rules.pm
our $charset = qr{ \[ \]? (?:\\[cCxX]\[ [^]]* \]|\\.|[^]])* \] }xs;
TEST

test(<<'TEST'); # DCONWAY/Perl6-Rules-0.03/Rules.pm
our $codeblock = qr{
    (?{$debug = 2 if $debug})
    (\{) (?{mark($^N)})
    (?>
        (?: ($i_scalar) (?{addscalar_internal $^N, 'rw'})
          | ($e_scalar) (?{addscalar_external $^N, 'rw'})
          | ($i_array)  (?{addarray_internal $^N, 'rw'})
          | ($e_array)  (?{addarray_external $^N, 'rw'})
          | ($i_hash)   (?{addhash_internal $^N, 'rw'})
          | ($e_hash)   (?{addhash_external $^N, 'rw'})
          | \$ (\d+)    (?{add '$'.$^N, "\$Perl6::Rules::d0[$^N]"})
          | ((?:\$\^\w+|[^{}\$]|\\[{}\$])+) (?{add $^N, $^N})
          | (??{$nestedcodeblock})
        )*
    )
    (?{$debug = 1 if $debug})
    (\}) (?{codeblock($^N)})
    |
    (??{$debug=1 if $debug;'(?!)'})
}x;
TEST

test(<<'TEST'); # DCONWAY/Perl6-Rules-0.03/Rules.pm
our $bspat = qr{                # Bracketed and Slashed patterns

 # Explicit whitespace (possibly repeated)...

      $ows ($ews)
            (?{add $^N, $ews{$^N}})
      $stdrep $ows

 # Actual whitespace (insert :words spacing if in appropriate mode)...

    | $ws
            (?{wordspace}) 

 # Backreference as literal (interpolated $1, $2, etc.)...

    | \$ (\d+)
            (?{add '$'.$^N, "(??{quotemeta \$Perl6::Rules::d0[$^N]})"})
      $stdrep

 # Interpolated variable as literal...

    | ($i_scalar) (?{ addscalar_internal $^N, 'quotemeta' }) $stdrep
    | ($i_array)  (?{ addarray_internal $^N, 'quotemeta' })  $stdrep
    | ($i_hash)   (?{ addhash_internal $^N, 'quotemeta' })   $stdrep
    | ($e_scalar) (?{ addscalar_external $^N, 'quotemeta' }) $stdrep
    | ($e_array)  (?{ addarray_external $^N, 'quotemeta' })  $stdrep
    | ($e_hash)   (?{ addhash_external $^N, 'quotemeta' })   $stdrep
    | ($bad_var)  (?{error("Can't use unqualified variable ($^N)")})

 # Character class...

    | < (?: ([+-]?) (?{$^N||""}) ($charset)
            (?{mark ""; add "<$^R.$^N", transcharset($^N, $^R)})
		|   ([+-]?) (?{$^N||""}) < ([-!]? $ident) >
            (?{mark ""; add "<$^R.$^N", getprop($^N, $^R)})
		)
        (?: ([+-]?) (?{$^N||""}) ($charset)
            (?{add "$^R.$^N", transcharset($^N, $^R)})
		|   ([+-]?) (?{$^N||""}) < ([-!]? $ident) >
            (?{add "$^R.$^N", getprop($^N, $^R)})
		)*
      > 
            (?{make_charset})
      $stdrep

 # <(...)> assertion block...

    | $assertblock

 # Backreference as pattern (interpolated <$1>, <$2>, etc.)...

    | <(\$ \d+)>
            (?{add "<$^N>", error("Cannot interpolate $^N as pattern")})

 # Interpolate variable as pattern...

    | <($i_scalar)> (?{addscalar_internal $^N}) $stdrep
    | <($i_array)>  (?{addarray_internal $^N})  $stdrep
    | <($i_hash)>   (?{addhash_internal $^N})   $stdrep
    | <($e_scalar)> (?{addscalar_external $^N}) $stdrep
    | <($e_array)>  (?{addarray_external $^N})  $stdrep
    | <($e_hash)>   (?{addhash_external $^N})   $stdrep
    | <($bad_var)>  (?{error("Can't use unqualified variable (<$^N>)")})

 # Code block as action...

    | $codeblock

 # Code block as interpolated pattern...

    | <($braceblock)>
            (?{add $^N, "(??{Perl6::Rules::ispat do$^N})"}) 

 # Literal in <'...'> format...

    | <' ( [^'\\]* (\\. [^'\\])* ) '>
            (?{add "<'$^N'>", "\Q$^N\E"}) 

 # Match any Unicode character, regardless of :uN level...

    | (< \. >)
            (?{add $^N, '(?:\X)'})

 # Match newline or anything-but-newline...

    | \\n
            (?{add '\n', $newline}) $stdrep
    | \\N
            (?{add '\N', $notnewline}) $stdrep

 # Quotemeta's literal (\Q[...])...

    | \\Q ( $squareblock )
            (?{add "\\Q$^N", quotemeta substr($^N,1,-1)}) $stdrep

 # Named and numbered characters (\c[...], \C[...], \x[...], \0[...], etc)...

    | ( \\[cCxX0] $squareblock
      | \\[xX][0-9A-Fa-f]+
      | \\0[0-7]+
      )
            (?{add $^N,  transchars($^N)}) $stdrep

	| (\\[cCxX0] \[) (?{$^N}) ((?>.*))
			(?{error "Untermimated $^R...] escape: $^R$^N"})

 # Literal dot...

    | (\\.)
            (?{add $^N, $^N}) $stdrep

 # Backtracking limiter...

    | : (?=\s|\z)
            (?{nobacktrack})

 # Lexical insensitivity...

    | :i
            (?{add ":i", '(?i)'})

 # Continuation marker...

    | :c (?{add '\G'})

 # Other lexical flags (NOT YET IMPLEMENTED)...

    | :(u0|u1|u2|u3|w|p5)
            (?{error "In-pattern :$^N not yet implemented"})

 # Match any character...

    | \.
            (?{add '.', '[\s\S]'}) $stdrep

 # Start of line marker...

    | \^\^
            (?{add '^^', '(?:(?<=\n)|(?<=\A))'})

 # End of line marker...

    | \$\$
            (?{add '$$', '(?:(?<=\n)|(?=\z))'})

 # Start of string marker...

    | \^
            (?{add '^', '\A'})

 # End of string marker...

    | \$
            (?{add '$', '\z'})

 # Non-capturing subrule or property...

    | < ($callident) >
            (?{subrule($^N,"")}) $stdrep

    | < - ($callident) >
            (?{subrule($^N,"","","-")}) $stdrep

    | < ! ($callident) >
            (?{subrule($^N,"","","!")}) $stdrep

 # Capturing subrule...

    | < \? ($callident) >
            (?{$Perl6::Rules::srname=$^N})
      $ows $rep
            (?{ subrule($Perl6::Rules::srname, $^N, "cap")})
    | < \? ($callident) >
            (?{ subrule($^N, "", "cap")})

 # Alternative marker...

    | \|
            (?{alternative})

 # Comment...

    | $comment

 # Unattached repetition marker...

    | ($orep)
            (?{$^N&&badrep()})

}x;
TEST

test(<<'TEST'); # MLEHMANN/Games-Sokoban-1.01/Sokoban.pm
   for ($self->{data} = join "\n", @data) {
      s/#$//mg until /[^#]#$/m; # right
      s/^#//mg until /^#[^#]/m; # left
   }
TEST

test(<<'TEST'); # KARASIK/Prima-1.39/Prima/Edit.pm
sub set_hilite_res
{
        my ($self, $hi) = @_;
        if ( $hi) {
                push @{$hi}, cl::Fore if scalar @{$hi} / 2 != 0;
                $hi = [@{$hi}];
        }
        $self-> {hiliteREs} = $hi;
        if ( $self-> {syntaxHilite}) {
                $self-> reset_syntaxer;
                $self-> repaint;
        }
}

sub set_insert_mode
{
        my ( $self, $insert) = @_;
        my $oi = $self-> {insertMode};
        $self-> {insertMode} = $insert;
        $self-> reset_cursor if $oi != $insert;
        $::application-> insertMode( $insert);
        $self-> push_group_undo_action( 'insertMode', $oi) if $oi != $insert;
}


sub set_offset
{
        my ( $self, $offset) = @_;
        $offset = 0 if $offset < 0;
        $offset = 0 if $self-> {wordWrap};
        return if $self-> {offset} == $offset;
        if ( $self-> {delayPanning}) {
                $self-> {delay_offset} = $offset;
                return;
        }
        my $dt = $offset - $self-> {offset};
        $self-> push_group_undo_action( 'offset', $self-> {offset});
        $self-> {offset} = $offset;
        if ( $self-> {hScroll} && $self-> {scrollTransaction} != 2) {
                $self-> {scrollTransaction} = 2;
                $self-> {hScrollBar}-> value( $offset);
                $self-> {scrollTransaction} = 0;
        }
        $self-> reset_cursor;
        $self-> scroll( -$dt, 0,
                clipRect => [ $self-> get_active_area]);
}


sub set_selection
{
        my ( $self, $sx, $sy, $ex, $ey) = @_;
        my $maxY = $self-> {maxLine};
        my ( $osx, $osy, $oex, $oey) = $self-> selection;
        my $onsel = ( $osx == $oex && $osy == $oey);
        if ( $maxY < 0) {
                $self-> {selStart}  = [0,0];
                $self-> {selEnd}    = [0,0];
                $self-> {selStartl} = [0,0];
                $self-> {selEndl  } = [0,0];
                $self-> repaint unless $onsel;
                return;
        }
        $sy  = $maxY if $sy < 0 || $sy > $maxY;
        $ey  = $maxY if $ey < 0 || $ey > $maxY;
        ( $sy, $ey, $sx, $ex) = ( $ey, $sy, $ex, $sx) if $sy > $ey;
        $osx = $oex = $sx,  $osy = $oey = $ey  if $onsel;
        if ( $sx == $ex && $sy == $ey) {
                $osy  = $maxY if $osy < 0 || $osy > $maxY;
                $oey  = $maxY if $oey < 0 || $oey > $maxY;
                $sx  = $ex  = $osx;
                $sy  = $ey  = $osy;
        }
        my ($firstChunk, $lastChunk) = ( $self-> get_line( $sy), $self-> get_line( $ey));
        my ($fcl, $lcl) = ( length( $firstChunk), length( $lastChunk));
        my $bt = $self-> {blockType};
        $sx = $fcl if ( $bt != bt::Vertical && $sx > $fcl) || ( $sx < 0);
        $ex = $lcl if ( $bt != bt::Vertical && $ex > $lcl) || ( $ex < 0);
        ( $sx, $ex) = ( $ex, $sx) if $sx > $ex && (( $sy == $ey && $bt == bt::CUA) || ( $bt == bt::Vertical));
        my ( $lsx, $lsy) = $self-> make_logical( $sx, $sy);
        my ( $lex, $ley) = $self-> make_logical( $ex, $ey);
        ( $lsx, $lex) = ( $lex, $lsx) if $lsx > $lex && (( $lsy == $ley && $bt == bt::CUA) || ( $bt == bt::Vertical));
        $sy = $ey if $sx == $ex and $bt == bt::Vertical;
        my ( $_osx, $_osy) = @{$self-> {selStartl}};
        my ( $_oex, $_oey) = @{$self-> {selEndl}};
        $self-> {selStart}  = [ $sx, $sy];
        $self-> {selStartl} = [ $lsx, $lsy];
        $self-> {selEnd}    = [ $ex, $ey];
        $self-> {selEndl}   = [ $lex, $ley];
        return if $sx == $osx && $ex == $oex && $sy == $osy && $ey == $oey;
        return if $sx == $ex && $sy == $ey && $onsel;
        $self-> push_group_undo_action('selection', $osx, $osy, $oex, $oey);
        ( $osx, $osy, $oex, $oey) = ( $_osx, $_osy, $_oex, $_oey);
        ( $sx, $sy)   = @{$self-> {selStartl}};
        ( $ex, $ey)   = @{$self-> {selEndl}};
        $osx = $oex = $sx,  $osy = $oey = $ey  if $onsel;
        if (( $osy > $ey && $oey > $ey) || ( $oey < $sy && $oey < $sy))
        {
                $self-> repaint;
                return;
        }
        # connective selection
        my ( $start, $end);
        if ( $bt == bt::CUA || ( $sx == $osx && $ex == $oex)) {
                if ( $sy == $osy) {
                        if ( $ey == $oey) {
                                if ( $sx == $osx) {
                                        $start = $end = $ey;
                                } elsif ( $ex == $oex) {
                                        $start = $end = $sy;
                                } else {
                                        ($start, $end) = ( $sy, $ey);
                                }
                        } else {
                                ( $start, $end) = ( $ey < $oey) ? ( $ey, $oey) : ( $oey, $ey);
                        }
                } elsif ( $ey == $oey) {
                        ( $start, $end) = ( $sy < $osy) ? ( $sy, $osy) : ( $osy, $sy);
                } else {
                        $start = ( $sy < $osy) ? $sy : $osy;
                        $end   = ( $ey > $oey) ? $ey : $oey;
                }
        } else {
                $start = ( $sy < $osy) ? $sy : $osy;
                $end   = ( $ey > $oey) ? $ey : $oey;
        }
        my ( $ofs, $tl, $fh, $r, $yT) = (
                $self-> {offset}, $self-> {topLine },
                $self-> font-> height, $self-> {rows},
                $self-> {yTail}
        );
        my @a = $self-> get_active_area( 0);
        return if $end < $tl || $start >= $tl + $r + $yT;
        if ( $start == $end && $bt == bt::CUA) {
                # single connective line paint
                my $chunk;
                my ( $xstart, $xend);
                if ( $sx == $osx) {
                        ( $xstart, $xend) = ( $ex < $oex) ? ( $ex, $oex) : ( $oex, $ex);
                } elsif ( $ex == $oex) {
                        ( $xstart, $xend) = ( $sx < $osx) ? ( $sx, $osx) : ( $osx, $sx);
                } else {
                        $xstart = ( $sx < $osx) ? $sx : $osx;
                        $xend   = ( $ex > $oex) ? $ex : $oex;
                }
                unless ( $self-> {wordWrap}) {
                        if ( $start == $sy) {
                                $chunk = $firstChunk;
                        } elsif ( $start == $ey) {
                                $chunk = $lastChunk;
                        } else {
                                $chunk = $self-> get_chunk( $start);
                        }
                } else {
                        $chunk = $self-> get_chunk( $start);
                }
                $self-> invalidate_rect(
                        $a[0] - $ofs + $self-> get_chunk_width( $chunk, 0, $xstart) - 1,
                        $a[3] - $fh * ( $start - $tl + 1),
                        $a[0] - $ofs + $self-> get_chunk_width( $chunk, 0, $xend),
                        $a[3] - $fh * ( $start - $tl)
                );
        } else {
                # general connected lines paint
                $self-> invalidate_rect(
                        $a[0], $a[3] - $fh * ( $end - $tl + 1),
                        $a[2], $a[3] - $fh * ( $start - $tl),
                );
        }
}

sub set_tab_indent
{
        my ( $self, $ti) = @_;
        $ti = 0 if $ti < 0;
        $ti = 256 if $ti > 256;
        return if $ti == $self-> {tabIndent};
        $self-> {tabIndent} = $ti;
        $self-> reset;
        $self-> repaint;
}

sub set_syntax_hilite
{
        my ( $self, $sh) = @_;
        $sh = 0 if $self-> {wordWrap};
        return if $sh == $self-> {syntaxHilite};
        $self-> {syntaxHilite} = $sh;
        $self-> reset_syntaxer if $sh;
        $self-> reset_syntax;
        $self-> repaint;
}

sub set_word_wrap
{
        my ( $self, $ww) = @_;
        return if $ww == $self-> {wordWrap};
        $self-> {wordWrap} = $ww;
        $self-> syntaxHilite(0) if $ww;
        $self-> reset;
        $self-> reset_scrolls;
        $self-> repaint;
}

sub cut
{
        my $self = $_[0];
        return if $self-> {readOnly};
        $self-> begin_undo_group;
        $self-> copy;
        $self-> delete_block;
        $self-> end_undo_group;
}

sub copy
{
        my $self = $_[0];
        my $text = $self-> get_selected_text;
        $::application-> Clipboard-> text($text) if defined $text;
}

sub get_selected_text
{
        my $self = $_[0];
        return undef unless $self-> has_selection;
        my @sel = $self-> selection;
        my $text = '';
        my $bt = $self-> blockType;
        if ( $bt == bt::CUA) {
                if ( $sel[1] == $sel[3]) {
                        $text = substr( $self-> get_line( $sel[1]), $sel[0], $sel[2] - $sel[0]);
                } else {
                        my $c = $self-> get_line( $sel[1]);
                        $text = substr( $c, $sel[0], length( $c) - $sel[0])."\n";
                        my $i;
                        for ( $i = $sel[1] + 1; $i < $sel[3]; $i++) {
                                $text .= $self-> get_line( $i)."\n";
                        }
                        $c = $self-> get_line( $sel[3]);
                        $text .= substr( $c, 0, $sel[2]);
                }
        } elsif ( $bt == bt::Horizontal) {
                my $i;
                for ( $i = $sel[1]; $i <= $sel[3]; $i++) {
                $text .= $self-> get_line( $i)."\n";
                }
        } else {
                my $i;
                for ( $i = $sel[1]; $i <= $sel[3]; $i++) {
                        my $c = $self-> get_line( $i);
                        my $cl = $sel[2] - length( $c);
                        $c .= ' 'x$cl if $cl > 0;
                        $text .= substr($c, $sel[0], $sel[2] - $sel[0])."\n";
                }
                chomp( $text);
        }
        return $text;
}

sub lock_change
{
        my ( $self, $lock) = @_;
        $lock = $lock ? 1 : -1;
        $self-> {notifyChangeLock} += $lock;
        $self-> {notifyChangeLock} = 0 if $lock > 0 && $self-> {notifyChangeLock} < 0;
        $self-> notify(q(Change)) if $self-> {notifyChangeLock} == 0 && $lock < 0;
}

sub change_locked
{
        my $self = $_[0];
        return $self-> {notifyChangeLock} != 0;
}

sub insert_text
{
        my ( $self, $s, $hilite) = @_;
        return if !defined($s) or length( $s) == 0;
        $self-> begin_undo_group;
        $self-> cancel_block unless $self-> {blockType} == bt::CUA;
        my @cs = $self-> cursor;
        my @ln = split( "\n", $s, -1);
        pop @ln unless length $ln[-1];
        $s = $self-> get_line( $cs[1]);
        my $cl = $cs[0] - length( $s);
        $s .= ' 'x$cl if $cl > 0;
        $cl = 0 if $cl < 0;
        $self-> lock_change(1);
        if ( scalar @ln == 1) {
                substr( $s, $cs[0], 0) = $ln[0];
                $self-> set_line( $cs[1], $s, q(add), $cs[0], $cl + length( $ln[0]));
                $self-> selection( $cs[0], $cs[1], $cs[0] + length( $ln[0]), $cs[1])
                        if $hilite && $self-> {blockType} == bt::CUA;
        } else {
                my $spl = substr( $s, $cs[0], length( $s) - $cs[0]);
                substr( $s, $cs[0], length( $s) - $cs[0]) = $ln[0];
                $self-> lock;
                $self-> set_line( $cs[1], $s);
                shift @ln;
                $self-> insert_line( $cs[1] + 1, (@ln, $spl));
                $self-> selection( $cs[0], $cs[1], length( $ln[-1]), $cs[1]+scalar(@ln))
                        if $hilite && $self-> {blockType} == bt::CUA;
                $self-> unlock;
        }
        $self-> lock_change(0);
        $self-> end_undo_group;
}

sub paste
{
        my $self = $_[0];
        return if $self-> {readOnly};
        $self-> insert_text( $::application-> Clipboard-> text, 1);
}

sub make_logical
{
        my ( $self, $x, $y) = @_;
        return (0,0) if $self-> {maxChunk} < 0;
        return $x, $y unless $self-> {wordWrap};
        my $maxY = $self-> {maxLine};
        $y = $maxY if $y > $maxY || $y < 0;
        $y = 0 if $y < 0;
        my $l = length( $self-> {lines}-> [$y]);
        $x = $l if $x < 0 || $x > $l;
        $x = 0 if $x < 0;
        my $cm = $self-> {chunkMap};
        my $r;
        ( $l, $r) = ( 0, $self-> {maxChunk} + 1);
        my $i = int($r / 2);
        my $kk = 0;
        while (1) {
                my $acd = $$cm[$i * 3 + 2];
                last if $acd == $y;
                $acd > $y ? $r : $l   = $i;
                $i = int(( $l + $r) / 2);
                if ( $kk++ > 200) {
                        print "bcs dump to $y\n";
                        ( $l, $r) = ( 0, $self-> {maxChunk} + 1);
                        $i = int($r / 2);
                        for ( $kk = 0; $kk < 7; $kk++) {
                                my $acd = $$cm[$i * 3 + 2];
                                print "i:$i [$l $r] f() = $acd\n";
                                $acd > $y ? $r : $l   = $i;
                                $i = int(( $l + $r) / 2);
                        }
                        die;
                        last;
                }
        }
        $y = $i;
        $i *= 3;
        $i-= 3, $y-- while $$cm[ $i] != 0;
        $i+= 3, $y++ while $x > $$cm[ $i] + $$cm[ $i + 1];
        $x -= $$cm[ $i];
        return $x, $y;
}
TEST

test(<<'TEST'); # CHM/PDL-2.015/Doc/Doc.pm
    for (@funcs) {
      $sym->{$1}->{Module} = $this->{NAME} if m/\s*([^\s(]+)\s*/;
      $sym->{$1}->{Sig} = $2  if m/\s*([^\s(]+)\s*\(\s*(.+)\s*\)\s*$/;
    }
TEST

test(<<'TEST'); # BIGJ/Lingua-DE-ASCII-0.11/ASCII.pm
        {no warnings;
            s/((?:${prefix}|en)s)?(([tT])�n(de?|\b))(?!chen|lein|lich)
             /$1 ? "$1$2" : "$3uen$4"/xgeo;# Gro�tuende, but abst�nde, St�ndchen
        }
        s/($prefix s? t)�(r(ische?[mnrs]?|
                           i?[ns](nen)?)?\b)/$1ue$2/gx;
TEST

test(<<'TEST'); # KARASIK/Prima-1.39/Prima/FileDialog.pm
    unless ( scalar @fs) {
        $self-> path('.'), return unless $p =~ tr{/\\}{} > 1;
        $self-> {path} =~ s{[/\\][^/\\]+[/\\]?$}{/};
        $self-> path('.'), return if $p eq $self-> {path};
        $self-> path($self-> {path});
        return;
    }
TEST

test(<<'TEST'); # CINDY/Plack-Middleware-Session-SerializedCookie-1.03/t/Common.pm
    for( 0 .. int($#{$res->[1]}/2) ) {
        if( $res->[1][$_*2] =~ /^Set-Cookie$/i ) {
        $res->[1][$_*2+1] =~ /([^;]*)/;
        $cookie .= "$1;";
        }
    }
TEST

test(<<'TEST'); # DUKKIE/FarmBalance-0.03/lib/FarmBalance.pm
sub arrange_array {
    my ( $self, $arrayref)  = @_;
    my $sum = $self->array_val_sum($arrayref);
    my $kei = $self->{'percent'} / $sum;
    my @nums_new = map { $_ * $kei } @{$arrayref};
    return \@nums_new;
}

#- return standard deviation
sub sd {
    my ( $self, $arrayref )  = @_;
    my $avg = $self->average($arrayref);
    my $ret = 0;
    for  (@{$arrayref}) {
        $ret += ($_ - $avg)**2;
    }
    return ( $ret/($#$arrayref + 1));
}
sub average {
    my ( $self, $arrayref)  = @_;
    my $sum = $self->array_val_sum($arrayref);
    return ( $sum / ( $#$arrayref + 1)  );
}
TEST

test(<<'TEST'); # SJCARBON/go-db-perl-0.04/GO/Tango.pm
        foreach my $k (@k) {
            print STDERR "    key=$k\n";
            next if $domainh->{$k} < 2;
            # bayes
            # p = (p(ipr|t) * p(t)) / p(ipr)
            my $prob =
              (($domainh->{$k} / scalar(@$pl)) * (scalar(@$pl) / scalar(@allids))) /
                ($dc{$k} / scalar(@allids));
            printf "$neg [$prob] %s $k $got{$k} $domainh->{$k} / %d\n", $term->name, scalar @$pl;
            if ($prob > 0.8 && $domainh->{$k} > 4) {
                push(@rules, $term->acc." $k $prob $domainh->{$k}/".(scalar @$pl));
            }
            $probh{$k} = $prob;
        }
TEST

test(<<'TEST'); # BURAK/Scalar-Util-Reftype-0.40/builder/Build.pm
      printf $W q/BEGIN { $INC{$_} = 1 for qw(%s); }/, join(' ', @inc_files);
      print  $W "\n";

      foreach my $name ( @packages ) {
         print $W qq/package $name;\nsub ________monolith {}\n/;
      }
TEST

test(<<'TEST'); # VLADO/AI-NaiveBayes1-2.006/NaiveBayes1.pm
    foreach my $label (keys(%{$self->{stat_labels}}))
    { $m->{labelprob}{$label} = $self->{stat_labels}{$label} /
                                $self->{numof_instances} }

    $m->{condprob} = {};
    $m->{condprobe} = {};
    foreach my $att (keys(%{$self->{stat_attributes}})) {
        next if $self->{attribute_type}{$att} eq 'real';
    $m->{condprob}{$att} = {};
    $m->{condprobe}{$att} = {};
    foreach my $label (keys(%{$self->{stat_labels}})) {
        my $total = 0; my @attvals = ();
        foreach my $attval (keys(%{$self->{stat_attributes}{$att}})) {
        next unless
            exists($self->{stat_attributes}{$att}{$attval}{$label}) and
            $self->{stat_attributes}{$att}{$attval}{$label} > 0;
        push @attvals, $attval;
        $m->{condprob}{$att}{$attval} = {} unless
            exists( $m->{condprob}{$att}{$attval} );
        $m->{condprob}{$att}{$attval}{$label} =
            $self->{stat_attributes}{$att}{$attval}{$label};
        $m->{condprobe}{$att}{$attval} = {} unless
            exists( $m->{condprob}{$att}{$attval} );
        $m->{condprobe}{$att}{$attval}{$label} =
            $self->{stat_attributes}{$att}{$attval}{$label};
        $total += $m->{condprob}{$att}{$attval}{$label};
        }
        if (exists($self->{smoothing}{$att}) and
        $self->{smoothing}{$att} =~ /^unseen count=/) {
        my $uc = $'; $uc = 0.5 if $uc <= 0;
        if(! exists($m->{condprob}{$att}{'*'}) ) {
            $m->{condprob}{$att}{'*'} = {};
            $m->{condprobe}{$att}{'*'} = {};
        }
        $m->{condprob}{$att}{'*'}{$label} = $uc;
        $total += $uc;
        if (grep {$_ eq '*'} @attvals) { die }
        push @attvals, '*';
        }
        foreach my $attval (@attvals) {
        $m->{condprobe}{$att}{$attval}{$label} =
            "(= $m->{condprob}{$att}{$attval}{$label} / $total)";
        $m->{condprob}{$att}{$attval}{$label} /= $total;
        }
    }
    }
TEST

test(<<'TEST'); # AKSTE/Data-ShowTable-4.6/ShowTable.pm
sub PlainText {
    local($_) = shift if $#_ >= 0;  # set local $_ if there's an argument
                    # skip unless there's a sequence
    return $_ unless m=</?($HTML_Elements)=i;   # HTML text?
    s{</?(?:$HTML_Elements)#        # match and remove any HTML token..
     (?:\ \w+#          # ..then PARAM or PARAM=VALUE
         (?:\=(?:"(?:[^"]|\\")*"|#  # ...."STRING" or..
            [^"> ]+#        # ....VALUE
         )#
         )?#            # ..=VALUE is optional
     )*#                # zero or more PARAM or PARAM=VALUE
      >}{}igx;              # up to the closing '>'
    $_;                 # return the result
}
TEST

test(<<'TEST'); # TEEJAY/Math-Curve-Hilbert-0.04/Hilbert.pm
  if ($args{clockwise}) {
      if ($args{max} == $this_level) {
      $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
      $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
      $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
      } else {
      foreach (@{$self->right(X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
          push (@$coords,$_);
          $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
      }
      $$y -= $step; push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
      foreach (@{$self->up(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
          push (@$coords,$_);
          $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
      }
      $$x += $step; push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
      foreach (@{$self->up(clockwise=>1,X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
          push (@$coords,$_);
          $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
      }
      $$y += $step; push (@$coords,{X=>$$x,Y=>$$y});
      $self->{curve}{"$$x:$$y"} = $#$coords;
      foreach (@{$self->left(X=>$x,Y=>$y,level=>$this_level,max=>$args{max})}) {
          push (@$coords,$_);
          $self->{curve}{"$_->{X}:$_->{Y}"} = $#$coords;
      }
      }
  }
TEST

test(<<'TEST'); # TONYC/Imager-1.004/Imager.pm
    if (@$x < @$y) {
      $x = [ @$x, ($x->[-1]) x (@$y - @$x) ];
    }
    elsif (@$y < @$x) {
      $y = [ @$y, ($y->[-1]) x (@$x - @$y) ];
    }
TEST

test(<<'TEST'); # TMTM/CDDB-File-1.05/lib/CDDB/File.pm
sub _highest_track_no {
  my $self = shift;
  $self->{_high} ||= pop @{[ map /^TTITLE(\d+)=/, $self->_data ]}
}

sub track_count { shift->_highest_track_no + 1 }

# ==================================================================== #

package CDDB::File::Track;

use overload
  '""'  => 'title';

sub cd     { shift->{_cd} }
sub extd   { shift->{_extd}  }
sub length { shift->{_length}}
sub number { shift->{_number}}
sub offset { shift->{_offset}}

sub _split_title {
  my $self = shift;
  if ($self->cd->artist eq "Various") {
    ($self->{_artist}, $self->{_title}) = split /\s+\/\s+/, $self->{_tline}, 2
  } else {
    $self->{_title}  = $self->{_tline};
    $self->{_artist} = $self->cd->artist;
  }

  unless ($self->{_title}) {
    $self->{_title} = $self->{_artist};
    $self->{_artist} = $self->cd->artist;
  }
}
TEST

test(<<'TEST'); # MRDVT/Geo-Forward-0.14/lib/Geo/Forward.pm
#      CU=1./DSQRT(TU*TU+1.)
       my $CU=1./sqrt($TU*$TU+1.);
#      SU=TU*CU
       my $SU=$TU*$CU;
#      SA=CU*SF
       my $SA=$CU*$SF;
#      C2A=-SA*SA+1.
       my $C2A=-$SA*$SA+1.;
#      X=DSQRT((1./R/R-1.)*C2A+1.)+1.
       my $X=sqrt((1./$R/$R-1.)*$C2A+1.)+1.;
#      X=(X-2.)/X
       $X=($X-2.)/$X;
#      C=1.-X
       my $C=1.-$X;
TEST

test(<<'TEST'); # RBOW/Date-ICal-2.678/lib/Date/ICal.pm
    my @temp = $str =~ m{
            ([\+\-])?   (?# Sign)
            (P)     (?# 'P' for period? This is our magic character)
            (?:
                (?:(\d+)Y)? (?# Years)
                (?:(\d+)M)? (?# Months)
                (?:(\d+)W)? (?# Weeks)
                (?:(\d+)D)? (?# Days)
            )?
            (?:T        (?# Time prefix)
                (?:(\d+)H)? (?# Hours)
                (?:(\d+)M)? (?# Minutes)
                (?:(\d+)S)? (?# Seconds)
            )?
                }x;
TEST

test(<<'TEST'); # JMASON/Mail-SpamAssassin-2.64/t/SATest.pm
sub start_spamd {
  my $sdargs = shift;

  return if (defined($spamd_pid) && $spamd_pid > 0);

  rmtree ("log/outputdir.tmp"); # some tests use this
  mkdir ("log/outputdir.tmp", 0755);

  if (defined $ENV{'SD_ARGS'}) {
    $sdargs = $ENV{'SD_ARGS'} . " ". $sdargs;
  }

  my $spamdargs;
  if($sdargs !~ /(?:-C\s*[^-]\S+)/) {
    $sdargs = "$spamd_cf_args $spamd_localrules_args $sdargs";
  }
  if($sdargs !~ /(?:-p\s*[0-9]+|-o|--socketpath)/)
  {
    $spamdargs = "$spamd -D -p $spamdport $sdargs";
  }
  else
  {
    $spamdargs = "$spamd -D $sdargs";
  }
  $spamdargs =~ s!/!\\!g if ($^O =~ /^MS(DOS|Win)/i);

  if ($set_test_prefs) {
    warn "oops! SATest.pm: a test prefs file was created, but spamd isn't reading it\n";
  }

  print ("\t$spamdargs > log/$testname.spamd 2>&1 &\n");
  system ("$spamdargs > log/$testname.spamd 2>&1 &");

  # now find the PID
  $spamd_pid = 0;
  # note that the wait period increases the longer it takes,
  # 20 retries works out to a total of 60 seconds
  my $retries = 20;
  my $wait = 0;
  while ($spamd_pid <= 0) {
    my $spamdlog = '';

    if (open (IN, "<log/$testname.spamd")) {
      while (<IN>) {
        /Address already in use/ and $retries = 0;
        /server pid: (\d+)/ and $spamd_pid = $1;
        $spamdlog .= $_;
      }
      close IN;
      last if ($spamd_pid);
    }

    sleep (int($wait++ / 4) + 1) if $retries > 0;
    if ($retries-- <= 0) {
      warn "spamd start failed: log: $spamdlog";
      warn "\n\nMaybe you need to kill a running spamd process?\n\n";
      return 0;
    }
  }

  1;
}

sub stop_spamd {
  return 0 if defined($spamd_never_started);
  return 0 if defined($spamd_already_killed);

  $spamd_pid ||= 0;
  if ( $spamd_pid <= 1) {
    print ("Invalid spamd pid: $spamd_pid. Spamd not started/crashed?\n");
    return 0;
  } else {
    my $killed = kill (15, $spamd_pid);
    print ("Killed $killed spamd instances\n");

    # wait for it to exit, before returning.
    for my $waitfor (0 .. 5) {
      if (kill (0, $spamd_pid) == 0) { last; }
      print ("Waiting for spamd at pid $spamd_pid to exit...\n");
      sleep 1;
    }

    $spamd_pid = 0;
    undef $spamd_never_started;
    $spamd_already_killed = 1;
    return $killed;
  }
}
TEST

test(<<'TEST'); # JOSEF/Text-Glob-DWIW-0.01/lib/Text/Glob/DWIW.pm
sub _dequ ($@)  { my $o=shift; my $star=join '',map { $o&&$o->{star}=~/([$_])/ } qw'* ?';
                  my ($xa)=map {('^'x/[a\^]/).('^'x/[z\$]/)} $o->{rewrite}?'':$o->{anchors};
                  my $s=$star.($o->{minus}?'!':'').($o->{rewrite}?'':',{}').$xa;
                  my $dequ=qr/(?<=^\\)[!]|[[\]$s-]/; # $o{star} (\\?)
                  _map_r { s{$nobackslash\K\\($dequ)}{$1}gs;
                           s/\\\\/\\/gs if $o->{last} } @_ }# \# &c. = done elsewhere
TEST

test(<<'TEST'); # WINTRU/Carrot-1.1.309/lib/Carrot/Modularity/Package/Source_Code.pm
{
sub add_begin_block_after_warnings
# /type method
# /effect ""
# //parameters
# //returns
{
    my ($this) = @ARGUMENTS;

    unless ($$this =~ s
#       {use (warnings|strict)[^\015\012;]*;(?:\012|\015\012?)\K}
        {use warnings[^\015\012;]*;(?:\012|\015\012?)\K}
        {$begin_block}s)
    {
        die("Could not add a begin block.\n");
    }
    return;
}

my $carrot_modularity_start = '#--8<-- carrot-modularity-start -->8--#';
my $carrot_modularity_end = '#--8<-- carrot-modularity-end -->8--#';
}
TEST

test(<<'TEST'); # WINTRU/Carrot-1.1.309/lib/Carrot/Modularity/Package/Source_Code.pm
sub add_modularity_markers
# /type method
# /effect ""
# //parameters
# //returns
{
    my ($this) = @ARGUMENTS;

    unless ($$this =~ s
        {((?:\012|\015\012?)\h+)my\h+\$expressiveness\h+=\h+Carrot::modularity(?:\(\))?;\K}
        {$1$carrot_modularity_start}saa)
    {
        die("Could not add carrot-modularity-start. $$this\n");
    }
    unless ($$this =~ s
        {(((?:\012|\015\012?)\h+)\} \#BEGIN)}
        {$1$carrot_modularity_end$2}saa)
    {
        die("Could not add carrot-modularity-end.\n");
    }
    return;
}
TEST

test(<<'TEST'); # MONS/AnyEvent-SMTP-0.10/lib/AnyEvent/SMTP/Client.pm
m{# trying to cheat with cpants game ;)
use strict;
use warnings;
}x;
TEST

test(<<'TEST'); # CHILTS/SRS-EPP-Proxy-0.21/lib/SRS/EPP/Command.pm
sub rebless_class {
	my $object = shift;
	our $map;
	if ( !$map ) {
		$map = {
			map {
				$_->can("match_class") ?
					( $_->match_class => $_ )
						: ();
			}# map { print "rebless_class checking plugin $_\n"; $_ }
				grep m{${\(__PACKAGE__)}::[^:]*$},
				__PACKAGE__->plugins,
		};
	}
	$map->{ref $object};
}
TEST

test(<<'TEST'); # AKXLIX/Sisimai-4.1.25/lib/Sisimai/ARF.pm
my $RxARF0 = {
    'content-type' => qr/report-type=["]?feedback-report["]?/,
    'begin'  => qr{\A(?>
                     [Tt]his[ ]is[ ].+[ ]email[ ]abuse[ ]report
                    |[Tt]his[ ]is[ ](?:
                         an[ ]autogenerated[ ]email[ ]abuse[ ]complaint
                        |an?[ ].+[ ]report[ ]for
                        |a[ ].+[ ]authentication[ -]failure[ ]report[ ]for
                        )
                    )
                }x,
    'rfc822' => qr!\AContent-Type: (:?message/rfc822|text/rfc822-headers)!,
    'endof'  => qr/\A__END_OF_EMAIL_MESSAGE__\z/,
};
TEST

test(<<'TEST'); # LBENDAVID/Net-Telnet-Brcd-1.13/lib/Net/Brcd.pm
        if (m{
            ^\s* (\d+) : \s+ \w+ \s+  # Domain id + identifiant FC
            ${_brcd_wwn_re} \s+       # WWN switch
            (\d+\.\d+\.\d+\.\d+) \s+  # Adresse IP switch
            \d+\.\d+\.\d+\.\d+   \s+  # Adresse IP FC switch (FCIP)
            (>?)"([^"]+)              # Master, nom du switch
        }msx) {
            my ($domain_id, $switch_ip, $switch_master, $switch_name) = ($1, $2, $3, $4);
            my $switch_host = gethostbyaddr(inet_aton($switch_ip), AF_INET);
            my @fields      = qw(DOMAIN IP MASTER FABRIC NAME MASTER);
            foreach my $re ($domain_id, $switch_ip, $switch_master, $switch_host, $switch_name) {
                my $field = shift @fields;
                if ($re) {
                    $domain{$domain_id}->{$field}   = $re;
                    $fabric{$switch_name}->{$field} = $re;
                } 
            }
            
            $fabric{$switch_host} = $switch_name if $switch_host;
        }
TEST

test(<<'TEST'); # DCONWAY/Acme-Bleach-1.150/lib/Acme/DWIM.pm
	my @bits = split qr<(?!\s*\bx)($string|[\$\@%]\w+|[])}[({\w\s;/]+)>;
TEST

test(<<'TEST'); # EVO/Text-MicroMason-1.99/MicroMason/Embperl.pm
sub lex_token {
  # Blocks in [-/+/! ... -/+/!] tags.
  /\G \[ (\-|\+|\!) \s* (.*?) \s* \1 \] /gcxs ? ( $block_types{$1} => $2 ) :
  
  # Blocks in [$ command ... $] tags.
  /\G \[ \$ \s* (\S+)\s*(.*?) \s* \$ \] /gcxs ? ( "ep_$1" => $2 ) :
  
  # Things that don't match the above
  /\G ( (?: [^\[] | \[(?![\-\+\!\$]) )+ ) /gcxs ? ( 'text' => $1 ) : 

  ()
}
TEST

test(<<'TEST'); # DOMQ/Alien-Selenium-0.09/inc/Module/Load.pm
sub _is_file {
    local $_ = shift;
    return  /^\./               ? 1 :
            /[^\w:']/           ? 1 :
            undef
    #' silly bbedit..
}
TEST

test(<<'TEST'); # WOODY/Apache-Album-0.96/Album.pm
    my %params = split /=+/, $r->args;
TEST

test(<<'TEST'); # JONG/Bioinf_V2.0/Bioinf.pm
sub rand_word {
     my($length) = $_[0];
     my($word, $letter);
     srand(((time/$$)^($>*time))/(time/(time^$$)));

     foreach (1..$length){
          $letter = pack("c", rand(128));
          redo unless $letter =~ /[a-zA-Z]/;   # I just don't like \w, okay?
          $word .= $letter;
     }
     return(\$word);
}
TEST

test(<<'TEST'); # JOESUF/News-GnusFilter-0.55/GnusFilter.pm
    $count++ while
      /^\s*[^>#\%\$\@].{60,}\n[^>].{1,20}[^{}();|&]\n(?=[^>].{60})/gm;
TEST

test(<<'TEST'); # NWIGER/HTML-ActiveLink-1.02/ActiveLink.pm
    if ($path eq '/') {
       return $ifmatches if ($test =~ m#^/[^/]*$#);
       return $default;
    }
TEST

test(<<'TEST'); # CHORNY/Switch-2.17/Switch.pm
            elsif ($Perl5 && $source =~ m/\G\s*(([^\$\@{])[^\$\@{]*)(?=\s*{)/gc
               ||  $Perl6 && $source =~ m/\G\s*([^;{]*)()/gc) {
                my $code = filter_blocks($1,line(substr($source,0,pos $source),$line));
                $text .= ' \\' if $2 eq '%';
                $text .= " $code)";
            }
TEST

test(<<'TEST'); # UGEN/IMAPGet.pm
$self->{Opres} = "TIMEOUT";
while ($line = _getsock($sock)) {
	print "< $line" if $self->{Dump};
	last if $line =~/$self->{Opid}\s(\w+)\s/ and $self->{Opres}=$1;
}
TEST

test(<<'TEST'); # NEILB/Text-Autoformat-1.74/lib/Text/Autoformat.pm
    $eos = $str !~ /^($gen_abbrev)[^a-z]*\s/i
        && $str =~ /[a-z][^a-z]*$term([^a-z]*)\s/
        && !($1=~/[])]/ && !$brsent);
TEST

test(<<'TEST'); # JANPAZ/DBD-XBase-1.05/lib/XBase/Index.pm
if ($key =~ tr!,+*)('&%$#"!0123456789!) { $key = '-' . $key; }
TEST

test(<<'TEST'); # SPROUT/WWW-Scripter-0.031/lib/WWW/Scripter.pm
sub request {
  for (my $foo) { # protect against tied $_
    my $self = shift;
    return unless defined(my $request = shift);

    $request = $self->_modify_request( $request );

    my $meth = $request->method;
    my $orig_uri = $request->uri;
    my $new_uri;
    if ((my $path = $orig_uri->path) =~ s-^(/*)/\.\./-$1||'/'-e) {
     0while $path =~ s\\$1||'/'\e;
     ($new_uri = $orig_uri->clone)->path($path)
    }
    my $skip_fetch;
    if(defined($orig_uri->fragment)) {
     ($new_uri ||= $orig_uri->clone)->fragment(undef);

     # Skip fetching the URL if it is the same (and there is a fragment).
     # We don’t need to strip the fragment from $self->uri before compari-
     # son as that always contains the actual URL  sent  in  the  request.
     $meth eq "GET" and $new_uri->eq($self->uri) and ++$skip_fetch;
    }
    if ($new_uri) {
     $request->uri($new_uri);
    }

    my $response;

    if($skip_fetch) {
     $response = $self->response;
    }
    else {
     Scripter_REQUEST: {
        Scripter_ABORT: {
            $response = $self->_make_request( $request, @_ );
            last Scripter_REQUEST;
        }
        return 1
     }
    }

    if ( $meth eq 'GET' || $meth eq 'POST' ) {
        $self->get_event_listeners('unload') and
         $self->trigger_event('unload'),
         $self->{page_stack}->_delete_res;

        $self->{page_stack}->${\(
         $self->{Scripter_replace} ? '_replace' : '_add'
        )}($request, $response, $orig_uri);
    }

    return $self->_update_page($request, $response);
  }
}
TEST

test(<<'TEST'); # DYLUNIO/Gwybodaeth-0.02/lib/Gwybodaeth/Parsers/N3.pm
        if ($token =~ m/\[ # matches [ /x) {
            if ($token =~ m/
                            \[\]    # matches []
                            /x) {
                #logic specific to 'something' bracket operator
                next;
            }
            # logic
            while((my $tok=$self->_next_token($data,$indx)) =~ /
                                        # any character which is not
                                        # a right square brace
                                                [^\]]
                                                /x) {
                ++$indx;
            } 
            $indx = $self->_parse_n3($data,$indx);
            next;
        }
TEST

test(<<'TEST'); # BRICAS/Image-TextMode-0.25/lib/Image/TextMode/Writer/ADF.pm
my $default_pal = [
    map {
        my @d = split( //s, sprintf( '%06b', $_ ) );
        {
            [   oct( "0b$d[ 3 ]$d[ 0 ]" ) * 63,
                oct( "0b$d[ 4 ]$d[ 1 ]" ) * 63,
                oct( "0b$d[ 5 ]$d[ 2 ]" ) * 63,
            ]
        }
        } 0 .. 63
];
TEST

test(<<'TEST'); # AGENT/Test-Nginx-0.25/lib/Test/Nginx/Socket/Lua.pm
        unless ($config =~ s{(?<!\#  )(?<!\# )(?<!\#)init_by_lua\s*(['"])((?:\\.|.)*)\1\s*;}{init_by_lua $1$escaped_code$2$1;}s) {
            unless ($config =~ s{(?<!\#  )(?<!\# )(?<!\#)init_by_lua_block\s*\{}{init_by_lua_block \{ $code }s) {
                $config .= "init_by_lua '$escaped_code';";
            }
        }
TEST

test(<<'TEST'); # JHTHORSEN/Mojolicious-Plugin-AssetPack-1.04/lib/Mojolicious/Plugin/AssetPack.pm
sub _pipes {
  my ($self, $names) = @_;

  $self->{pipes} = [
    map {
      my $class = load_module /::/ ? $_ : "Mojolicious::Plugin::AssetPack::Pipe::$_";
      diag 'Loading pipe "%s".', $class if DEBUG;
      die qq(Unable to load "$_": $@) unless $class;
      my $pipe = $class->new(assetpack => $self);
      Scalar::Util::weaken($pipe->{assetpack});
      $pipe;
    } @$names
  ];
}

sub _process_from_def {
  my $self  = shift;
  my $file  = shift || 'assetpack.def';
  my $asset = $self->store->file($file);
  my $topic = '';
  my %process;

  die qq(Unable to load "$file".) unless $asset;
  diag qq(Loading asset definitions from "$file".) if DEBUG;

  for (split /\r?\n/, $asset->slurp) {
    s/\s*\#.*//;
    if (/^\<(\S*)\s+(.+)/) {
      my $asset = $self->store->asset($2);
      bless $asset, 'Mojolicious::Plugin::AssetPack::Asset::Null' if $1 eq '<';
      push @{$process{$topic}}, $asset;
    }
    elsif (/^\!\s*(.+)/) { $topic = $1; }
  }

  $self->process($_ => @{$process{$_}}) for keys %process;
  $self;
}
TEST

test(<<'TEST'); # CASIANO/Parse-Eyapp-1.182/lib/Parse/Eyapp/Cleaner.pm
            $$input=~/\G%{/gc
        and do {
            my($code);

                $$input=~/\G(.*?)%}/sgc
            or  _SyntaxError(2,"Unmatched %{ opened line $lineno[0]",-1);

            $code=$1;
            $lineno[1]+= $code=~tr/\n//;
            return('HEADCODE',[ $code, $lineno[0] ]);
        };
TEST

test(<<'TEST'); # MSERGEANT/XML-Handler-AxPoint-1.5/lib/XML/Handler/AxPoint.pm
    $phi_r = $phi * PI / 180.0;

    # Compute (x1, y1)
    $x1 = cos($phi_r) * $dx2 + sin($phi_r) * $dy2;
    $y1 = -sin($phi_r) * $dx2 + cos($phi_r) * $dy2;

    # Make sure radii are large enough
    $rx = abs($rx); $ry = abs($ry);
    $rx_sq = $rx * $rx;
    $ry_sq = $ry * $ry;
    $x1_sq = $x1 * $x1;
    $y1_sq = $y1 * $y1;

    my $radius_check = ($x1_sq / $rx_sq) + ($y1_sq / $ry_sq);
TEST

test(<<'TEST'); # AGENT/Test-Nginx-0.25/lib/Test/Nginx/Socket/Lua.pm
    Test::Nginx::Socket::set_http_config_filter(sub {
        my $config = shift;
        if ($config =~ /init_by_lua_file/) {
            return $config;
        }
        unless ($config =~ s{(?<!\#  )(?<!\# )(?<!\#)init_by_lua\s*(['"])((?:\\.|.)*)\1\s*;}{init_by_lua $1$escaped_code$2$1;}s) {
            unless ($config =~ s{(?<!\#  )(?<!\# )(?<!\#)init_by_lua_block\s*\{}{init_by_lua_block \{ $code }s) {
                $config .= "init_by_lua '$escaped_code';";
            }
        }
        return $config;
    });
TEST

test(<<'TEST'); # AWNCORP/Data-Object-0.05/lib/Data/Object/Role/String.pm
sub words {
    my ($string) = @_;
    return [CORE::split /\s+/, $string];
}
TEST

test(<<'TEST'); # OPI/HTML-YaTmpl-1.8/lib/HTML/YaTmpl/_parse.pm
  $regexp=qr{
#	     (?{
#		my $pos=pos;
#		my $prev=substr($str, $pos>=10?$pos-10:0, $pos>=10?10:$pos);
#		my $post=substr($str, $pos, 10);
#		print "start at position ",pos,": $prev^$post\n";
#	       })
	     <([=:\043])	# [=:#] goes to $1
	     (\w*)		# TAG to $2
	     ($re_tparam)	# tag params go to $3
	     (?:
	      (?> /> )
	      |
	      (?>
	       >
	       (		# the section content goes to $4
		(?:		# we are looking for a character
		 (?> [^<]+ )	# that is not the beginning of a TAG
		 |		# or
		 (?>
		  (??{$regexp})	# we are looking for something that is
		 )		# described by $regexp
		 |		# or
		 <(?!		# is the beginning of a TAG but not followed
		   (?>		# by the rest of an opening or closing TAG
		    \1\2 $re_tparam
		    |
		    /\1\2
		   )> )
		)*?		# and that many times
	       )
	       </\1\2> # the closing TAG
	      ))
#	     (?{
#		my $pos=pos;
#		my $prev=substr($str, $pos-10, 10);
#		my $post=substr($str, $pos, 10);
#		print "emitted at position ",pos,": $prev^$post\n";
#	       })
	    }xs;
TEST

test(<<'TEST'); # OPI/HTML-YaTmpl-1.8/lib/HTML/YaTmpl/_parse.pm
  my $re_nostr=qr{
		  (?:		# between <: and /> can be written perl code
		   [^\s\w/]>	# but perl knows the -> operator. Originally
		   |		# this (?:...) was written simply as [^"<>]
				# and <:$p->{xxx}/> was matched as $1=':',
				# $2='', $3='$p-' and not as $3='$p->{xxx}'
				# as expected. Now a character other than \s,
				# \w or / acts like an escape character for a
				# subsequent >.
		   /(?!>)
		   |
		   \\.
		   |
		   [^"<>/]	# "]# kein string
		  )*
		 }xs;
TEST

test(<<'TEST'); # DHARD/FAST-1.0/lib/FAST/Bio/SearchIO/Writer/HTMLResultWriter.pm
        if ($sec =~ s/((?:gi\|(\d+)\|)?        # optional GI
                     (\w+)\|([A-Z\d\.\_]+) # main 
                     (\|[A-Z\d\_]+)?) # optional secondary ID//xms) {
            my ($name, $gi, $db, $acc) = ($1, $2, $3, $4);
            #$acc ||= ($rest) ? $rest : $gi;
            $acc =~ s/^\s+(\S+)/$1/;
            $acc =~ s/(\S+)\s+$/$1/;
            $url =
            length($self->remote_database_url($type)) > 0 ? 
              sprintf('<a href="%s">%s</a> %s',
                      sprintf($self->remote_database_url($type),
                      $gi || $acc || $db), 
                      $name, $sec) :  $sec;
        } else {
            $url = $sec;
        }
TEST

test(<<'TEST'); # REID/Games-Go-AGATourn-1.035/AGATourn.pm
    if ($line =~ s/\s*#\s*(.*?)\s*$//) {
        $comment = $1;
    }
    if ($line eq '') {
        return {
            comment => $comment,
        };
    }

    if ($line =~ m/^\s*(\w+)(\d+)\s+(\w+)(\d+)\s+([bwBW\?])\s+(\d+)\s+(-?\d+)$/) {
        return {
            wcountry  => uc($1),
            wagaNum   => $2,
            bcountry  => uc($3),
            bagaNum   => $4,
            result    => lc($5),
            handi     => $6,
            komi      => $7,
            comment   => $comment,
        };
    }
TEST

test(<<'TEST'); # PERLANCAR/PERLANCAR-JSON-Match-0.02/lib/PERLANCAR/JSON/Match.pm
our $MATCH_JSON = qr{

(?&VALUE) (?{ $_ = $^R->[1] if 0 })

(?(DEFINE)

(?<OBJECT>
  #(?{ [$^R, {}] })
  \{\s*
    (?: (?&KV) # [[$^R, {}], $k, $v]
    #  (?{ # warn Dumper { obj1 => $^R };
    #      die "Duplicate key '$^R->[1]'" if exists $^R->[0][1]->{$^R->[1]};
    #      [$^R->[0][0], {$^R->[1] => $^R->[2]}] })
      (?: \s*,\s* (?&KV) # [[$^R, {...}], $k, $v]
    #    (?{ # warn Dumper { obj2 => $^R };
    #        die "Duplicate key '$^R->[1]'" if exists $^R->[0][1]->{$^R->[1]};
    #        [$^R->[0][0], {%{$^R->[0][1]}, $^R->[1] => $^R->[2]}] })
      )*
    )?
  \s*\}
)

(?<KV>
  (?&STRING) # [$^R, "string"]
  \s*:\s* (?&VALUE) # [[$^R, "string"], $value]
  #(?{ # warn Dumper { kv => $^R };
  #   [$^R->[0][0], $^R->[0][1], $^R->[1]] })
)

(?<ARRAY>
  #(?{ [$^R, []] })
  \[\s*
    (?: (?&VALUE) #(?{ [$^R->[0][0], [$^R->[1]]] })
      (?: \s*,\s* (?&VALUE) #(?{ # warn Dumper { atwo => $^R };
			 #[$^R->[0][0], [@{$^R->[0][1]}, $^R->[1]]] })
      )*
    )?
  \s*\]
)

(?<VALUE>
  \s*
  (
      (?&STRING)
    |
      (?&NUMBER)
    |
      (?&OBJECT)
    |
      (?&ARRAY)
    |
    true #(?{ [$^R, 1] })
  |
    false #(?{ [$^R, 0] })
  |
    null #(?{ [$^R, undef] })
  )
  \s*
)

(?<STRING>
  (
    "
    (?:
      [^\\"]+
    |
      \\ ["\\/bfnrt]
#    |
#      \\ u [0-9a-fA-f]{4}
    )*
    "
  )

  #(?{ [$^R, eval $^N] })
)

(?<NUMBER>
  (
    -?
    (?: 0 | [1-9]\d* )
    (?: \. \d+ )?
    (?: [eE] [-+]? \d+ )?
  )

  #(?{ [$^R, eval $^N] })
)

) }xms;
TEST

test(<<'TEST'); # MRDVT/List-NSect-0.06/lib/List/NSect.pm
sub spart {
  my $parts = shift || 0;
  my @deck  = ();
  #undef, 0 or empty array returns nothing as requested
  if ($parts > 0) {
    my $i = 0;
    @deck = part {int($i++ / $parts)} @_; #/#Each partition created is a reference to an array.
  }
  return wantarray ? @deck : \@deck;
}
TEST

test(<<'TEST'); # GEHIC/ConfigFile.pm
  while (<CONF>)
  { 
    # process a comment or blank line
    if (/^\s*[#;]/ || /^\s*$/)
    {  print TMP $_; next };
    		
    # Is this a section header?
    /^\s*\[\s*(.+)\s*\].*$/ && do
    {
      $sect = $1;
      print TMP $_;
      next;
    };
    
    # process definition
    /^\s*(.+)\s*=\s*(.+)\s*$/ && do
    {
      print TMP "$1 = $self->{Config}->{$sect}->{$1}\n";
      delete $self->{Config}->{$sect}->{$1};
    };
  };
TEST

test(<<'TEST'); # RHANDOM/Net-Server-2.008/lib/Net/Server/HTTP.pm
    $fmt =~ s{ % ([<>])?                      # 1
                 (!? \d\d\d (?:,\d\d\d)* )?   # 2
                 (?: \{ ([^\}]+) \} )?        # 3
                 ([aABDfhHmpqrsTuUvVhblPtIOCeinoPtX%])  # 4
    }{
        $info = $orig if $1 && $orig && $1 eq '<';
        my $v = $2 && (substr($2,0,1) eq '!' ? index($2, $info->{'response_status'})!=-1 : index($2, $info->{'response_status'})==-1) ? '-'
              : $fmt_map{$4}  ? $info->{$fmt_map{$4}}
              : $fmt_code{$4} ? do { my $m = $fmt_code{$4}; $self->$m($info, $3, $1, $4) }
              : $4 eq 'b'     ? $info->{'response_size'} || '-' # B can be 0, b cannot
              : $4 eq 'I'     ? $info->{'request_size'} + $info->{'request_header_size'}
              : $4 eq 'O'     ? $info->{'response_size'} + $info->{'response_header_size'}
              : $4 eq 'T'     ? sprintf('%d', $info->{'elapsed'})
              : $4 eq 'D'     ? sprintf('%d', $info->{'elapsed'}/.000_001)
              : $4 eq '%'     ? '%'
              : '-';
        $v = '-' if !defined($v) || !length($v);x
        $v =~ s/([^\ -\!\#-\[\]-\~])/$1 eq "\n" ? '\n' : $1 eq "\t" ? '\t' : sprintf('\x%02X', ord($1))/eg; # escape non-printable or " or \
        $v;
    }gxe;
TEST

test(<<'TEST'); # MLEHMANN/AnyEvent-GDB-0.2/GDB.pm
sub _parse_value {
   if (/\G"/gc) { # c-string
      &_parse_c_string

   } elsif (/\G\{/gc) { # tuple
      my $r = &_parse_results;

      /\G\}/gc
         or die "tuple does not end with '}'\n";

      $r
      
   } elsif (/\G\[/gc) { # list
      my @r;

      until (/\G\]/gc) {
         # if GDB outputs "result" in lists, let me know and uncomment the following lines
#         # list might also contain key value pairs, but apparently
#         # those are supposed to be ordered, so we use an array in perl.
#         push @r, $1
#            if /\G([^=,\[\]\{\}]+)=/gc;

         push @r, &_parse_value;

         /\G,/gc
            or last;
      }

      /\G\]/gc
         or die "list does not end with ']'\n";

      \@r

   } else {
      die "value expected\n";
   }
}
TEST

test(<<'TEST'); # DCONWAY/Dios-0.000007/lib/Dios.pm
sub import {
    my (undef, $opt) = @_;

    # What kind of accessors were requested in this scope???
    $^H{'Dios accessor_type'}
        = $opt->{accessor} // $opt->{accessors} // $opt->{acc} // q{standard};

    # How should the invocants be named in this scope???
    my $invocant_name = $opt->{invocant} // $opt->{inv} // q{$self};
    if ($invocant_name =~ m{\A (\$?) ([^\W\d]\w*+) \Z}xms) {
        $^H{'Dios invocant_name'} = ($1||'$').$2;
    }
    else {
        _error "Invalid invocant specification: '$invocant_name'\nin 'use Dios' statement";
    }

    # Class definitions are translated to encapsulated packages using OIO...
    keyword class (QualIdent $class_name, /is \s* (\w*)/x @bases?, Block $block) {{{
        { package <{$class_name}>;
          use Object::InsideOut <{ @bases ? qq{qw{@bases}} : q{} }>;
          <{ substr($block,1,-1) }>
        }
    }}}

    # How to recognize a set of sub attributes...
    keytype Attrs { /(?x: \s* : \s* (?: [^\W\d]\w* (?: \( .*? \) )? \s* )* )+/ }

    # Function definitions are translated to subroutines with extra argument-unpacking code...
    keyword func (QualIdent $sub_name = q{}, List $parameter_list?, Attrs $attrs = q{}, Block $block) {
        # Generate code that unpacks and tests arguments...
        $parameter_list = _translate_parameters($parameter_list, func => "$sub_name");

        # Peel the curlies from the block (because we're interpolating its code)...
        $block = substr($block,1,-1);

        # Assemble and return the method definition...
        qq{sub $sub_name $attrs { $parameter_list; $block } } =~ s/;/;\n/gr;
    }

    # Method definitions are translated to subroutines with extra invocant-and-argument-unpacking code...
    keyword method (QualIdent $sub_name = q{}, List $parameter_list?, Attrs $attrs = q{}, Block $block) {
        # Which kind of aliasing do we need (to create local vars bound to the object's fields)???
        my $use_aliasing = $] < 5.022 ? q{use Data::Alias} : q{use experimental 'refaliasing'};
        my $attr_binding = $^H{'Dios attrs'} ? "$use_aliasing; $^H{'Dios attrs'}" : q{};

        # Generate code that unpacks and tests arguments...
        $parameter_list = _translate_parameters($parameter_list, method => "$sub_name");

        # Peel the curlies from the block (because we're interpolating its code)...
        $block = substr($block,1,-1);

        # Assemble and return the method definition...
        qq{sub $sub_name $attrs { $attr_binding $parameter_list; $block } };
    }

    # Submethod definitions are translated like methods, but with special re-routing...
    keyword submethod (QualIdent $sub_name = q{}, List $parameter_list?, Attrs $attrs = q{}, Block $block) {
        # Which kind of aliasing do we need (to create local vars bound to the object's fields)???
        my $use_aliasing = $] < 5.022 ? q{use Data::Alias} : q{use experimental 'refaliasing'};
        my $attr_binding = $^H{'Dios attrs'} ? "$use_aliasing; $^H{'Dios attrs'}" : q{};

        # Handle any special submethod names...
        my $init_args = q{};
        if ($sub_name eq 'BUILD') {
            # Extract named args for :InitArgs hash (TODO: this should pull out type/required info too)...
            my @param_names = $parameter_list =~ m{ : [\$\@%]? (\w++) }gxms;

            # Tell OIO about this constructor args...
            $init_args = qq{ BEGIN{ my %$sub_name :InitArgs = map { \$_ => '' } qw{@param_names}; } };

            # Mark the sub as an initializer
            $attrs .= ' :Private :Init';

            # Repack the arguments from ($self, {attr=>val, et=>cetera}) to ($self, attr=>val, et=>cetera)...
            $attr_binding = q{@_ = ($_[0], %{$_[1]});} . $attr_binding;
        }
        elsif ($sub_name eq 'DESTROY') {
            # Parameter list will never be satisfied (which breaks cleanup), so don't allow it at all...
            return q{die 'submethod DESTROY cannot have a parameter list';}
                if $parameter_list && $parameter_list !~ /^\(\s*+\)$/;

            # Mark it as a destructor...
            $attrs .= ' :Private :Destroy';

            # Rename it so as not to clash with OIO's DESTROY...
            $sub_name = '___DESTROY___';
        }
        else {
            $attr_binding = qq{
                if ((ref(\$_[0])||\$_[0]) ne __PACKAGE__) {
                    return \$_[0]->SUPER::$sub_name(\@_[1..\$#_]);
                }
            } . $attr_binding;
        }

        # Generate the code to unpack and test arguments...
        $parameter_list = _translate_parameters($parameter_list, method => "$sub_name");

        # Peel the curlies from the block (because we're interpolating its code)...
        $block = substr($block,1,-1);

        # Assemble and return the method definition...
        qq{$init_args sub $sub_name $attrs { $attr_binding $parameter_list; $block } };
    }

    # What does an attribute variable look like???
    keytype HasVar { / .*? (?= [:;=] | \/\/= ) /x }

    # An attribute definition is translated into an array with a :Field attribute...
    keyword has (HasVar $variable, Attrs $attrs = q{}, ...';' $init) {
        _compose_field("$variable $attrs", $init)
    }

    # What does a shared attribute variable look like???
    keytype SharedVar { / .*? (?: is | (?= [;=] | \/\/= ) ) /x }

    # An attribute definition is translated into an my var with extra code for accessors...
    keyword shared (SharedVar $variable, /r[wo]/ $access = q{}, ...';' $init) {
        _compose_shared("$variable $access", $init)
    }

    # Subtypes are handled by Dios::Types...
    keyword subtype from Dios::Types;
}
TEST

done_testing;
