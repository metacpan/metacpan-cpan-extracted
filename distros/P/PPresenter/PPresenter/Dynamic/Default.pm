# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Dynamic::Default;

use strict;
use PPresenter::Dynamic;
use base 'PPresenter::Dynamic';

use Tk;

use constant ObjDefaults =>
{ -name           => 'default'
, -aliases        => undef
, -appearTime     => 5
, -appear         => 'phase 0 appear'
};

sub directions($$)
{   my ($dynamic, $string) = (shift, shift);
    local $_  = shift;
    return ($1, $2) if m/^([ns]?)([we]?)$/;
    warn "Direction can be n,ne,e,se,s,sw,w,nw, in $string\n";
    ('', '');
}

sub start_visible()
{   my $cmd = shift;
    $cmd->{move} eq 'disappear' || $cmd->{move} eq 'to';
}

sub parse($$$$)
{   my ($dynamic, $program, $slide, $affected, $string) = @_;

    $string = $dynamic->{-appear} unless $string;

    my $success =
    my ($phase, $after, $move, $movedir, $movesec, $appear) =
        $string =~ m/^\s*(?:phase\s+(\S+))?
          \s*(?:after\s+(\d+\.?\d*))?
          \s*(?:(?:(from|to)\s+(\S+)\s*(\d+\.?\d*)?)
                |(disappear|appear)
             )?
          \s*$/x;

    unless($success)
    {   warn "Dynamic format wrong for: \"$string\"\n";
        return;
    }

    my $cmd = bless
    { after   => $after   || 0
    , move    => $appear  || $move || undef
    , movesec => $movesec || $dynamic->{-appearTime}
    , affected=> $affected
    , string  => $string
    , slide   => $slide
    };

    @$cmd{'dir_y','dir_x'} = $dynamic->directions($string, $movedir||'');

    local $_ = defined $phase ? $phase : 0;

    if( my ($go) = /^(\d+)\-?$/ )
    {   $cmd->{phase} = $go;
        $cmd->{move}  = 'appear' unless defined $cmd->{move};
        $dynamic->parse($program, $slide, $affected, 'phase 0 appear')
            if $cmd->start_visible;

        $program->add($go, $cmd);
    }
    elsif( ($go) = m/^\-(\d+)$/ )
    {   $cmd->{move}  = 'disappear' unless defined $cmd->{move};
        if($cmd->start_visible)
        {   $dynamic->parse($program, $slide, $affected, 'phase 0 appear');
            $cmd->{phase} = ++$go;
            $program->add($go, $cmd);
        }
        else
        {   warn "Phase $_, then move \"to\" or \"disappear\": $string.\n"}
    }
    elsif( (my $come, $go) = m/^(\d+)\-(\d+)$/ )
    {   warn "Move neglected for $string.\n" if defined $cmd->{move};
        $cmd->{phase} = $come;
        $cmd->{move}  = 'appear';
        $program->add($come, $cmd);
        $cmd = bless { %$cmd };  #copy;
        $cmd->{phase} = ++$go;
        $cmd->{move}  = 'disappear';
        $program->add($go, $cmd);
    }
    else
    {   warn "Phase formats: \"3\", \"3-\", \"-3\", \"2-3\": $string.\n";
    }

    $dynamic;
}

sub start($$$)
{   my ($cmd, $canvas, $displace_x) = @_;

    return $cmd->make_start($canvas, $displace_x)
        if $cmd->{after} == 0;

    $cmd->{after_start} = time;
    $canvas->after(int($cmd->{after}*1000),
                   [ \&make_start, $cmd, $canvas, $displace_x ] );
}

sub make_start($$)
{   my ($cmd, $canvas, $displace_x) = @_;

    my ($move, $affected) = @$cmd{'move', 'affected'};

    return $affected->Call
        if $affected->isa('Tk::Callback');

    my $tag = $affected;

    return $canvas->move($tag, -$displace_x, 0)
        if $move eq 'appear';

    return $canvas->move($tag, $displace_x, 0)
        if $move eq 'disappear';

    my ($left, $top, $right, $bottom) = $canvas->bbox($tag);
    return unless defined $left;

    unless($cmd->start_visible)
    {   $left  -= $displace_x;   # The location where it should be.
        $right -= $displace_x;   # The location where it should be.
    }

    my $outx = $cmd->{dir_x} eq 'w' ? -$right
             : $cmd->{dir_x} eq 'e' ? $canvas->width
             : $left;
    my $outy = $cmd->{dir_y} eq 'n' ? -$bottom
             : $cmd->{dir_y} eq 's' ? $canvas->height
             : $top;

    if($cmd->{move} eq 'to')   # are already visible...
    {   @$cmd{'start_x', 'start_y', 'end_x', 'end_y'}
           = ($left,      $top,      $outx,   $outy);
         $canvas->after(10, [ \&linear_move, $cmd, $canvas ]);
    }
    elsif($cmd->{move} eq 'from')
    {   $canvas->move($tag, $outx-$left-$displace_x, $outy-$top);
        @$cmd{'start_x', 'start_y','end_x', 'end_y'}
           = ($outx,     $outy,    $left,   $top);
        $canvas->after(10, [ \&linear_move, $cmd, $canvas ]);
    }
    @$cmd{'cur_x', 'cur_y'} = @$cmd{'start_x', 'start_y'};

    use Tk;
    $cmd->{start_time} = Tk::timeofday(); # undocumented, but is there!

    $cmd;
}

sub linear_move($$)
{   my ($cmd, $canvas) = @_;
    return if $cmd->{end_x}==$cmd->{cur_x} && $cmd->{end_y}==$cmd->{cur_y};

    use Tk;
    my $progress = $cmd->{movesec} < 0.01 ? 2
            : (Tk::timeofday() - $cmd->{start_time}) / $cmd->{movesec};

    return $cmd->flushMove($canvas)
        if $progress >= 1.0;

    my ($sx, $cx, $ex) = @$cmd{'start_x', 'cur_x', 'end_x'};
    my $dx = ($ex-$sx)*$progress + $sx - $cx;

    my ($sy, $cy, $ey) = @$cmd{'start_y', 'cur_y', 'end_y'};
    my $dy = ($ey-$sy)*$progress + $sy - $cy;

    $canvas->after(10, [ \&linear_move, $cmd, $canvas ] );
    return unless $dx || $dy;

    $canvas->move($cmd->{affected}, $dx, $dy);
    $cmd->{cur_x} += $dx;
    $cmd->{cur_y} += $dy;
}

sub flushMove($$)
{   my ($cmd, $canvas) = @_;

    return unless exists $cmd->{end_x};

    my $dx = $cmd->{end_x} - $cmd->{cur_x};
    my $dy = $cmd->{end_y} - $cmd->{cur_y};
    return unless $dx || $dy;   # already at the end?

    $canvas->move($cmd->{affected}, $dx, $dy);
    @$cmd{'cur_x', 'cur_y'} = @$cmd{'end_x', 'end_y'};
}

1;
