# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Formatter::Markup_placer;

@EXPORT = qw(place);

use strict;
use Exporter;
use base 'Exporter';

sub flush_line();
sub process_list($;);

my $tagnr = 0;
sub new_tag() { "t".$tagnr++; }

#
# PLACE
# Run through the parsed tree, and assign locations... This work has to
# be redone when the fontsize changes.
#

my (%b, %g);
my ($self, $viewport);

sub place($$$)
{   my ($my_self, $show, $slide, $view, $part, $dx, $parsed) = @_;

    $self      = $my_self;
    my $canvas = $view->canvas;
    my $now    = new_tag;
    $view->addProgram('', $now);

    %b = # Variables which change in blocks.
    ( fonttype   => 'PROPORTIONAL'
    , fontsize   => $view->findFontSize(undef, 'normal')
    , fontweight => 'normal'
    , fontslant  => 'roman'
    , underline  => 0
    , overstrike => 0
    , backdrop   => $view->hasBackdrop
    , color      => $view->color('FGCOLOR')

    , indent     => 0
    , rindent    => 0  # right-side indentation.
    , reformatText=> 1
    , align      => 'left'
    , basealign  => 'none'
    , is_paragraph => 0
    , nesting    => 0

    , dynamictag => $now
    , listitem   => undef
    );

    %g = # Variables which are not block related.
    ( canvas     => $view->canvas
    , slide      => $slide
    , view       => $view
    , viewport   => $view->viewport
    , formatter  => $self

      # current line
    , lineascent => 0
    , linedescent=> 0
    , needs_space=> 0
    , accumx     => 0
    , accumy     => $part->{y}
    , makeLI     => undef

    , left_image_end  => 0
    , right_image_end => 0
    , image_indent    => 0
    , image_rindent   => 0
    );

    map {$g{$_} = $part->{$_}} qw/x y w h slidetag parttag/;
    $g{x} += $dx;

    no_marks();
    process_list($parsed);
    flush_line;
}

#
# Handling the commands
#

my %command_action;
%command_action =
( A    => sub {}
, B    => sub { $b{fontweight} = 'bold' }
, BD   => sub { $b{backdrop} = 1 }
, BQ   => sub { start_paragraph(@_);
                  $b{indent}  += 0.1*$g{w};
                  $b{rindent} += 0.1*$g{w}; }
, BR   => sub { start_paragraph(@_) }
, 'CENTER' => sub { start_paragraph(@_); $b{align} = 'center' }
, DIV  => sub { start_paragraph(@_) }
, I    => sub { $b{fontslant} = 'italic' }
, IMG  => \&include_image
, LI   => sub { start_paragraph(@_); change_font(@_);
                  $g{makeLI} = $b{dynamictag} }
, MARK => \&set_mark
, N    => sub { $b{fontweight} = 'normal' }
, O    => sub { $b{overstrike} = 1 }
, OL   => \&ordered_list
, P    => sub { flush_line; skip_line(@_); start_paragraph(@_) }
, PRE  => sub { $b{fonttype} = 'FIXED'; $b{reformatText} = 0;
                  start_paragraph(@_) }
, PROP => sub { $b{fonttype} = 'PROPORTIONAL' }
, REDO => \&restore_mark
, RIGHT => sub { start_paragraph(@_); $b{align} = 'right' }
, SUB  => sub { $b{fontsize} -=2; $b{basealign} = 'bottom' }
, SUP  => sub { $b{fontsize} -=2; $b{basealign} = 'top' }
, TEXT => sub {}
, TT   => sub { $b{fonttype} = 'FIXED' }
, U    => sub { $b{underline} = 1 }
, UL   => \&unordered_list
);

sub ordered_list
{   my $params = shift;
    start_paragraph(@_);
    my ($size, $perc, $src) = $self->nestInfo($g{view}, $b{nesting}++);

    $b{indent} = $self->takePercentage($perc,$g{w});
    $params->{SIZE} = $size unless exists $params->{SIZE};

    $b{listitem} = exists $params->{START} ? delete $params->{START} : 1;
}

sub unordered_list
{   my $params = shift;
    start_paragraph(@_);

    (my $size, my $perc, $b{listitem})
         = $self->nestInfo($g{view}, $b{nesting}++);

    $b{indent} = $self->takePercentage($perc,$g{w});
    $params->{SIZE} = $size unless exists $params->{SIZE};

    $b{listitem} = $g{view}->image(-file => delete $params->{SRC})
        if exists $params->{SRC};

    $b{listitem}->prepare(@g{ qw/viewport canvas/ } )
        if defined $b{listitem};
}

sub include_image($)
{   my $params = shift;
    my $src   = exists $params->{SRC} ? delete $params->{SRC} : 'dot_green.gif';
    my $align = exists $params->{ALIGN} ? lc delete $params->{ALIGN} : 'center';

    my $img   = $g{view}->image
    ( -file => $src
    , (exists $params->{RESIZE} ? (-resize  => delete $params->{RESIZE} ) : ())
    , (exists $params->{ENLARGE}? (-enlarge => delete $params->{ENLARGE}) : ())
    , (exists $params->{BASE}   ? (-sizeBase=> delete $params->{BASE})    : ())
    );

    return unless defined $img;

    $img->prepare(@g{ qw/viewport canvas/ });
    my ($width, $height) = $img->dimensions($g{viewport});

    my $hspace = $self->takePercentage(
        (exists $params->{HSPACE} ? delete $params->{HSPACE}
        : $self->{-imageHSpace}), $width);
    my $vspace = $self->takePercentage(
        (exists $params->{VSPACE} ? delete $params->{VSPACE}
        : $self->{-imageVSpace}), $height);

    my ($imgx, $imgy);

    flush_line;
    if($align eq 'left')
    {   $imgx = $b{indent};
        $imgy = $g{accumy};
        $imgy += $vspace unless $g{accumy} == $g{'y'};
        $g{left_image_end} = $imgy + $height + $vspace;
        $g{image_indent}   = $b{indent} +$width +$hspace;
    }
    elsif($align eq 'right')
    {   $imgx = $g{w} -$b{rindent}-$width;
        $imgy = $g{accumy};
        $imgy += $vspace unless $g{accumy} == $g{'y'};
        $g{right_image_end} = $imgy + $height + $vspace;
        $g{image_rindent}   = $b{rindent} +$width +$hspace;
    }
    elsif($align eq 'center')
    {   $imgx = ($g{w} / 2) - ($width / 2);  
        $imgy = $g{accumy};
        $imgy += $vspace unless $g{accumy} == $g{'y'};
        $g{accumy} += $height;
    }
    else
    {   warn "Unknown image alignment key '$align'.\n";
        return
    }

    $img->show(@g{ qw/viewport canvas/ },
        , $g{'x'} + $imgx, $imgy
        , -tags   => [ $g{slidetag}, $g{parttag}, $b{dynamictag} ]
        , -anchor => 'nw'
        );
}

sub change_font($)
{   my $params = shift;

    if(exists $params->{LARGE})
    {   delete $params->{LARGE};
        $params->{SIZE} = '+1';
    }

    if(exists $params->{SMALL})
    {   delete $params->{SMALL};
        $params->{SIZE} = '-1';
    }

    $b{fontsize} = $g{view}->findFontSize($b{fontsize}, delete $params->{SIZE})
        if exists $params->{SIZE};

    $b{fonttype} = delete $params->{FACE} if exists $params->{FACE};
    if(exists $params->{TT}){$b{fonttype}='FIXED'; delete $params->{TT}}
    if(exists $params->{PROP}){$b{fonttype}='PROPORTIONAL'; delete $params->{PROP}}
    if(exists $params->{B}) {$b{fontweight}='bold'; delete $params->{B}}
    if(exists $params->{I}) {$b{fontweight}='italic'; delete $params->{I}}
    if(exists $params->{N}) {$b{fontweight}='normal'; delete $params->{N}}
    if(exists $params->{BD}){$b{backdrop}=delete $params->{BD} }
    $b{color} = $g{view}->color(delete $params->{COLOR})
        if exists $params->{COLOR};

    if(exists $params->{SHOW})
    {   $b{dynamictag} = new_tag;
        my $when = delete $params->{SHOW};
        $when =~ s/"//g;
        $g{view}->addProgram($when, $b{dynamictag});
    }
}

sub start_paragraph()
{   flush_line;
    my $params = shift;

    if(exists $params->{CLEAR})
    {   my $dir = uc delete $params->{CLEAR};
        if($dir ne 'LEFT' && $dir ne 'RIGHT' && $dir ne 'ALL')
        {   warn "WARNING slide \"$g{slide}\": CLEAR left|right|all, not $dir.\n";
            $dir = 'ALL';
        }

        $g{accumy} = $g{left_image_end}
            if ($dir eq 'LEFT'  || $dir eq 'ALL')
               && $g{accumy} < $g{left_image_end};
                
        $g{accumy} = $g{right_image_end}
            if ($dir eq 'RIGHT'  || $dir eq 'ALL')
               && $g{accumy} < $g{right_image_end};
                
    }

    $b{align} = delete $params->{ALIGN} if exists $params->{ALIGN};
    $b{is_paragraph} = 1;
}

sub skip_line(;)
{   my $font = create_font();
    my %metrics = $g{canvas}->fontMetrics($font);
    $g{accumy} += $self->takePercentage($self->{-lineSkip},
                           $metrics{-ascent} + $metrics{-descent});
}

#
# Markings.
#

my %marks;

sub no_marks()
{   %marks = ();
}

sub set_mark($)
{   my $params = shift;
    my $name   = exists $params->{NAME}
               ? delete $params->{NAME}
               : 'default';

    if(exists $marks{$name})
    {   warn "Mark named $name already defined.";
        return;
    }

    my %b_copy    = %b;
    my %g_copy    = %g;
    $marks{$name} = [ \%b_copy, \%g_copy ];
}
    
sub restore_mark($;)
{   my $params = shift;
    my $name   = exists $params->{NAME}
               ? delete $params->{NAME}
               : 'default';

    unless(exists $marks{$name})
    {   warn "No mark with named $name.  Skipped.";
        return;
    }

    flush_line;
    %b = %{$marks{$name}->[0]};
    %g = %{$marks{$name}->[1]};
}

#
# Handling text.
#

sub create_font()
{    $g{viewport}->font(@b{qw/fonttype fontweight fontslant fontsize/} );
}

sub current_bounds()
{
    ( $g{left_image_end} <= $g{accumy}
          ? $b{indent}  : $g{image_indent}
    , $g{right_image_end} <= $g{accumy}
          ? $b{rindent} : $g{image_rindent})
}

sub process_line($)
{   my ($line) = @_;

    return unless defined $line;

    # Fonts change all the time :(
    my $font = create_font;

    # Also the width changes constantly.
    my ($left, $right) = current_bounds;
    my $maxwidth = $g{w} - $left - $right;

    if($b{reformatText})
    {   # Layout multiline.
        foreach (split /(\s+)/s,$line,-1)
        {
           next if $_ eq '';

           if(/\s+/s)
           {   $g{needs_space} = (exists $g{linewords} && @{$g{linewords}} > 0);
               next;   # will be space at the end or begin string.
           }

           my $word = decode_string($_);
           my $put  = $g{needs_space} ? " $word" : $word;
           my $wordlength = $g{canvas}->fontMeasure($font, $put);
           $g{needs_space} = 0;

           if(   $g{accumx}+$wordlength > $maxwidth
              && $g{accumx}!=0 ) # Long words will have their own line..
           {   flush_line;
               ($left, $right) = current_bounds;
               $maxwidth = $g{w} - $left - $right;
               redo;                    # Try same word again.
           }

           my %metrics = $g{canvas}->fontMetrics($font);
           my ($ascent,$descent) = @metrics{'-ascent', '-descent'};
           $g{lineascent} = $ascent  if $g{lineascent} < $ascent;
           $g{linedescent}= $descent if $g{linedescent}<$descent;

           push @{$g{linewords}}, [ $put, $g{accumx}, $ascent, $font,
                    $b{color}, $b{dynamictag}, $b{backdrop}, $b{basealign} ];
           $g{accumx} += $wordlength;
        }
    }
    else
    {   # Preformatted text.
        my @lines = split /\n/, $line, -1;
        while(@lines>0)
        {   my $put = decode_string(shift @lines);
            $put = " ".$put if $g{needs_space};
            my $wordlength = $g{canvas}->fontMeasure($font, $put);

            my %metrics = $g{canvas}->fontMetrics($font);
            my ($ascent,$descent) = @metrics{'-ascent', '-descent'};
            $g{lineascent} = $ascent  if $g{lineascent} < $ascent;
            $g{linedescent}= $descent if $g{linedescent}<$descent;

            push @{$g{linewords}},
               [ $put, $g{accumx}, $ascent, $font, $b{color}
               , $b{dynamictag}, $b{backdrop}, $b{basealign} ];
            $g{accumx}     += $wordlength;

            flush_line if @lines > 0;
        }
        $g{needs_space} = 0;
    }
}

sub flush_line()
{   $g{needs_space} = 0;
    return unless exists $g{linewords};

    my $slide = $g{slide};

    # Alignment
    my ($left, $right) = current_bounds;
    my $xcorrect = $g{'x'}
        + ( $b{align} eq 'left'  ? $left
          : $b{align} eq 'right' ? $g{w} - $right - $g{accumx}
          : $left + ($g{w} -$left -$right -$g{accumx})/2
          );

    $g{lineascent} *= (1.0 + $self->toPercentage($self->{-listSkip}))
        if $g{makeLI};

    my $baseline = $g{accumy} + $g{lineascent};
    $g{accumy}  += $g{lineascent} + $g{linedescent};

    # Realization of words.
    my $refascent = 0;
    my $baseoffset;
    my @linewords = @{$g{linewords}};

    while(@linewords>0)
    {   my $word = shift @linewords; # [ text,x,ascent,font,color,tag,bd,va ]
        my ($text, $x, $ascent, $font, $color, $dynamictag, $backdrop,
            $vert_align) = @$word;
        while(@linewords > 0
           && $linewords[0][2]==$ascent   && $linewords[0][3]."" eq $font.""
           && $linewords[0][4] eq $color  && $linewords[0][5] eq $dynamictag
           && $linewords[0][6] eq $backdrop && $linewords[0][7] eq $vert_align)
        {   # Note: same font but different ascent possible for sub/superscript
            $text .= $linewords[0][0];
            shift @linewords;
        }

        my @tags = @g{ 'slidetag', 'parttag' };
        push @tags, $dynamictag if defined $dynamictag;

        $baseoffset = $vert_align eq 'top'    ? int($refascent*1.1-$ascent)
                    : $vert_align eq 'bottom' ? int(-$refascent*.2)
                    : 0;

        if($backdrop)
        {   my $backdrop = int ($ascent/12);
            $g{canvas}->createText
            ( $x+$xcorrect+$backdrop,
            , $baseline-$ascent+$backdrop-$baseoffset
            , -text   => $text
            , -anchor => 'nw'
            , -fill   => $g{view}->color('BDCOLOR')
            , -font   => $font
            , -tags   => \@tags
            , -width  => 0
            );
        }

        $g{canvas}->createText
        ( $x+$xcorrect, $baseline-$ascent-$baseoffset
        , -text   => $text
        , -anchor => 'nw'
        , -fill   => $color
        , -font   => $font
        , -tags   => \@tags
        , -width  => 0
        );

        $refascent = $ascent;
    }

    # List-items can only be produced when we know the height of
    # the line.  That's now!

    if(defined $g{makeLI} && defined $b{listitem})
    {
        if(ref $b{listitem})
        {   # LI as part of UL
            $b{listitem}->show( @g{ qw/viewport canvas/ }
            , $xcorrect-10, int ($baseline - $g{lineascent}/3)
            , -tags     => [ @g{ qw/slidetag parttag makeLI/ } ]
            , -anchor   => 'e'
            );
        }
        else
        {   # LI as part of OL
            my $number = $b{listitem}++ . '.';

            $g{canvas}->createText
            ( $xcorrect-5, $baseline + $g{linedescent}
            , -text   => $number
            , -anchor => 'se'
            , -fill   => $g{linewords}[0][4]  # forms to font and color
            , -font   => $g{linewords}[0][3]  #   of first word in line.
            , -tags   => [ @g{ qw/slidetag parttag makeLI/ } ]
            , -width  => 0
            );
        }
    }

    # Reset line.
    delete $g{linewords};
    $g{lineascent}  = 0;
    $g{linedescent} = 0;
    $g{accumx}      = 0;
    $g{makeLI}      = undef;
}

sub process_list($;)
{   my $parsed = shift;

    my %safe_b        = %b;
    $b{is_paragraph}  = 0;

    for(my $str=0; $str< @$parsed; $str+=2)
    {
        if(ref $parsed->[$str] eq 'ARRAY')
        {   process_list($parsed->[$str]);
            process_line($parsed->[$str+1]);
            next;
        }

        delete $parsed->[$str]{cmd};           # cmd as the user specified.
        my $cmd = delete $parsed->[$str]{CMD}; # translated cmd.

        if(not exists $command_action{$cmd})
        {   warn "Unknown command $cmd used.\n";      }
        elsif(not defined $command_action{$cmd})
        {   warn "Command $cmd not yet implemented.\n"}
        else
        {   &{$command_action{$cmd}}($parsed->[$str]);
            change_font($parsed->[$str]);

            foreach my $k (keys %{$parsed->[$str]})
            {  warn "Slide $g{slide}, unknown parameter $k for $cmd.\n";
            }
        }

        process_line($parsed->[$str+1])
            if defined $parsed->[$str+1];  # only undef at toplevel
    }

    flush_line if $b{is_paragraph};
    %b = %safe_b;
}

sub decode_string($)
{   my $string = shift;
    return '' if !defined $string || $string eq '';

    @_ = split /\&(\w+)\;/, $string;
    return $string if @_ == 1;           # no specials

    my $translations = $self->{specials};

    my $decoded = shift;
    while(@_)
    {   my $char = shift;
        if(exists $translations->{$char})
        {   $decoded .= $translations->{$char};
        }
        else
        {   warn "Cannot decode &$char; in $string" if $^W;
            $decoded .= "&$char;";
        }
        $decoded .= shift if @_;
    }

    $decoded;
}

1;

