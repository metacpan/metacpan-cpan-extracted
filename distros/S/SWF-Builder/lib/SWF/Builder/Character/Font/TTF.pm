package SWF::Builder::Character::Font::TTF;  # stub

our $VERSION="0.07";

####

package SWF::Builder::Character::Font::Def;  # addition

use strict;
use utf8;

use SWF::Builder::ExElement;
use SWF::Builder::Shape;
use Font::TTF::Font;
use Font::TTF::Ttc;
use Carp;

sub _init_font {
    my ($self, $fontfile, $fontname) = @_;

    my $type = 0;
    my $tag = $self->{_tag};
    $self->{_ttf_tables} = (my $ttft = bless {}, 'SWF::Builder::Font::TTFTables');

    my $font = Font::TTF::Font->open($fontfile) ||  
	       Font::TTF::Ttc->open($fontfile) 
		   or croak "Can't open font file '$fontfile'";
    my ($p_font, $head, $name, $os2, $hhea, $cmap, $loca, $hmtx, $kern);
    $ttft->{_font} = $p_font = $font;
    
    if (ref($font)=~/:Ttc$/) {   # TrueType collection
	my @names;
	$p_font = $font->{directs}[0];   # Primary font needs to access some table. 
	for my $f (@{$font->{directs}}) { # For each collected font...
	    my $names;
	    $f->{name}->read;
	    for my $pid (@{$f->{name}{strings}[1]}) { # gathers all font names ( latin, unicode...)
		
		for my $eid (@$pid) {
		    while (my ($lid, $s) = each(%$eid)) {
			$names .= "$s\n";
		    }
		}
	    }
	    if (index($names, "$fontname\n") >=0) { # if match $fontname to the gathered,
		$font = $f;                         # accept the font.
		last;
	    }
	}
    }

  EMBED:
    {
	$name = $font->{name}||$p_font->{name} # font name
	or croak 'Invalid font';
	if ($os2 = $font->{'OS/2'}||$p_font->{'OS/2'}) {  # get OS/2 table to check the lisence.
	    $os2->read;
	    my $fstype = $os2->{fsType} && 0;
	    
	    if ($fstype & 0x302) {
		warn "Embedding outlines of the font '$fontfile' is not permitted.\n";
		$self->{_embed} = 0;
		last EMBED;
	    } elsif ($fstype & 4) {
		warn "The font '$fontfile' can use only for 'Preview & Print'.\n";
		$self->{_read_only} = 1;
	    }
	} else {
	    warn "The font '$fontfile' doesn't have any lisence information. See the lisence of the font.\n";
	}
	$head = $font->{head}||$p_font->{head} # header
	or croak "Can't find TTF header of the font $fontname";
	$hhea = $font->{hhea}||$p_font->{hhea} # horizontal header
	or croak "Can't find hhea table of the font $fontname";
	$cmap = $font->{cmap}||$p_font->{cmap} # chr-glyph mapping
	or croak "Can't find cmap table of the font $fontname";
	$loca = $font->{loca}||$p_font->{loca} # glyph location index
	or croak "Can't find glyph index table of the font $fontname";
	$hmtx = $font->{hmtx}||$p_font->{hmtx} # horizontal metrics
	or croak "Can't find hmtx table of the font $fontname";
	$kern = $font->{kern}||$p_font->{kern} # kerning table (optional)
	and $kern->read;
	$head->read;
	$name->read;
	$hhea->read;
	$cmap->read;
	$hmtx->read;
	$loca->read;
	my $scale = 1024 / $head->{unitsPerEm};   # 1024(Twips/Em) / S(units/Em) = Scale(twips/unit)
	$tag->FontAscent($hhea->{Ascender} * $scale);
	$tag->FontDescent(-$hhea->{Descender} * $scale);
	$tag->FontLeading($hhea->{LineGap} * $scale);  # ?
	$self->{_scale}  = $scale/20; # pixels/unit
	$self->{_average_width} = defined($os2) ? $os2->{xAvgCharWidth}*$scale : 512;
	$ttft->{_cmap}   = ($cmap->find_ms or croak "Can't find unicode cmap table in the font $fontname")->{val}; # Unicode cmap
	$ttft->{_advance}= $hmtx->{advance};
	$ttft->{_loca} = $loca; 
	eval {
	    for my $kt (@{$kern->{tables}}) {
		if ($kt->{coverage} & 1) {
		    $self->{_ttf_tables}{_kern} = $kt->{kern}; # horizontal kerning
		    last;
		}
	    }
	};
    }
    unless ($fontname) {
	($fontname) = ($name->find_name(1)=~/(.+)/);  # Cleaning up is needed. But why?
	($fontname) = ($fontfile =~ /.*\/([^\\\/.]+)/) unless $fontname;
    }
    utf2bin($fontname);
    $tag->FontName($fontname);
    $type = $head->{macStyle};
    $tag->FontFlagsBold(1) if ($type & 1);
    $tag->FontFlagsItalic(1) if ($type & 2);

    $self;
}

sub get_fontnames {
    my ($self, $ttc) = @_;

    my $font = Font::TTF::Ttc->open($ttc) 
      or croak "Can't open TTC font file '$ttc'";

    my @names;
    for my $f (@{$font->{directs}}) { # For each collected font...
	$f->{name}->read;
	my @alias_names;
	for my $pid (@{$f->{name}{strings}[1]}) { # gathers all font names ( latin, unicode...)

	    for my $eid (@$pid) {
		while (my ($lid, $s) = each(%$eid)) {
		    push @alias_names, $s;
		}
	    }
	}
	push @names, \@alias_names;
    }
    return \@names;
}

sub kern {
    my ($self, $code1, $code2) = @_;
    my $kern_t = $self->{_ttf_tables}{_kern} or return 0;
    my $cmap = $self->{_ttf_tables}{_cmap};
    if (exists $kern_t->{$cmap->{$code1}}) {
	if (exists $kern_t->{$cmap->{$code1}}{$cmap->{$code2}}) {
	    return $kern_t->{$cmap->{$code1}}{$cmap->{$code2}}/20;
	}
    }
    return 0;
}

sub _draw_glyph {
    my ($self, $c, $gshape) = @_;
    return unless $self->{_embed};

    my $scale = $self->{_scale};
    my $gid = $self->{_ttf_tables}{_cmap}{ord($c)};
    my $gtable = $self->{_ttf_tables}{_loca}{glyphs};
    my $glyph1 = $gtable->[$gid];
    if (defined $glyph1) {
	$glyph1->read_dat;
	unless (exists $glyph1->{comps}) {
	    $self->_draw_glyph_component($glyph1, $gshape);
	} else {
	    for my $cg (@{$glyph1->{comps}}) {
		my @m;
		@m = (translate => [$cg->{args}[0] * $scale, -$cg->{args}[1] * $scale]) if exists $cg->{args};
		if (exists $cg->{scale}) {  # Not tested...
		    my $s = $cg->{scale};
		    push @m, (ScaleX => $s->[0], RotateSkew0 => $s->[1], RotateSkew1 => $s->[2], ScaleY => $s->[3]);
		}
		my $ngs = $gshape->transform(\@m);
		my $glyph = $gtable->[$cg->{glyph}];
		$glyph->read_dat;
		$self->_draw_glyph_component($glyph, $ngs);
		$ngs->end_transform;
	    }
	}
    }
    return $self->{_ttf_tables}{_advance}[$gid] * $scale;
}

sub _draw_glyph_component {
    my ($self, $glyph, $gshape) = @_;

    my $scale = $self->{_scale};

    my $i = 0;
    for my $j (@{$glyph->{endPoints}}) {
	my @x = map {$_ * $scale} @{$glyph->{x}}[$i..$j];
	my @y = map {-$_ * $scale} @{$glyph->{y}}[$i..$j];
	my @f = @{$glyph->{flags}}[$i..$j];
	$i=$j+1;
	my $sx = shift @x;
	my $sy = shift @y;
	my $f  = shift @f;
	unless ($f & 1) {
	    push @x, $sx;
	    push @y, $sy;
	    push @f, $f;
	    if ($f[0] & 1) {
		$sx = shift @x;
		$sy = shift @y;
		$f  = shift @f;
	    } else {
		$sx = ($sx+$x[0])/2;
		$sy = ($sy+$y[0])/2;
		$f = 1;
	    }
	}
	push @x, $sx;
	push @y, $sy;
	push @f, $f;
	$gshape->moveto($sx, $sy);
	while(@x) {
	    my ($x, $y, $f)=(shift(@x), shift(@y), (shift(@f) & 1));
	    
	    if ($f) {
		$gshape->lineto($x, $y);
	    } else {
		my ($ax, $ay);
		if ($f[0] & 1) {
		    $ax=shift @x;
		    $ay=shift @y;
		    shift @f;
		} else {
		    $ax=($x+$x[0])/2;
		    $ay=($y+$y[0])/2;
		}
		$gshape->curveto($x, $y, $ax, $ay);
	    }
	}
    }
}

sub _destroy {
    my $self = shift;
    my $f = $self->{_ttf_tables}{_font};
    %{$self->{_ttf_tables}} = ();
    $f->release if $f;
    $self->SUPER::_destroy;
}

1;
