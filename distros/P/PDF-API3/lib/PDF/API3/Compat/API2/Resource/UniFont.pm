#=======================================================================
#    ____  ____  _____              _    ____ ___   ____
#   |  _ \|  _ \|  ___|  _   _     / \  |  _ \_ _| |___ \
#   | |_) | | | | |_    (_) (_)   / _ \ | |_) | |    __) |
#   |  __/| |_| |  _|    _   _   / ___ \|  __/| |   / __/
#   |_|   |____/|_|     (_) (_) /_/   \_\_|  |___| |_____|
#
#   A Perl Module Chain to faciliate the Creation and Modification
#   of High-Quality "Portable Document Format (PDF)" Files.
#
#   Copyright 1999-2005 Alfred Reibenschuh <areibens@cpan.org>.
#
#=======================================================================
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the
#   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#   Boston, MA 02111-1307, USA.
#
#   $Id: UniFont.pm,v 2.1 2007/01/04 16:02:28 areibens Exp $
#
#=======================================================================
package PDF::API3::Compat::API2::Resource::UniFont;

BEGIN {

    use utf8;
    use Encode qw(:all);

    use PDF::API3::Compat::API2::Util;

    use POSIX;

    use vars qw($VERSION);

    ( $VERSION ) = sprintf '%i.%03i', split(/\./,('$Revision: 2.1 $' =~ /Revision: (\S+)\s/)[0]); # $Date: 2007/01/04 16:02:28 $

}
no warnings qw[ deprecated recursion uninitialized ];

=item $font = PDF::API3::Compat::API2::Resource::UniFont->new $pdf, @fontspecs, %options

Returns a uni-font object.

=cut

=pod

B<FONTSPECS:> fonts can be registered using the following hash-ref:

    {
        font   => $fontobj,     # the font to be registered
        blocks => $blockspec,   # the unicode blocks, the font is being registered for
        codes  => $codespec,    # the unicode codepoints, -"-
    }

B<BLOCKSPECS:> 

    [
        $block1, $block3,    # register font for block 1 + 3
        [$blockA,$blockZ],   # register font for blocks A .. Z
    ]
    
B<CODESPECS:> 

    [
        $cp1, $cp3,          # register font for codepoint 1 + 3
        [$cpA,$cpZ],         # register font for codepoints A .. Z
    ]
    
B<NOTE:> if you want to register a font for the entire unicode space 
(ie. U+0000 .. U+FFFF), then simply specify a font-object without the hash-ref.


Valid %options are:

  '-encode' ... changes the encoding of the font from its default.
    (see "perldoc Encode" for a list of valid tags)

=cut

sub new {
    my ($class,$pdf,@fonts) = @_;

    $class = ref $class if ref $class;
    my $self={
        fonts=>[],
        block=>{},
        code=>{},
    };
    bless $self,$class;

    $self->{pdf}=$pdf;
    
    # look at all fonts
    my $fn=0;
    while (ref $fonts[0])
    {
        my $font=shift @fonts;
        if(ref($font) eq 'ARRAY')
        {
            push @{$self->{fonts}},$font->[0];
            shift @{$font};
            while(defined $font->[0])
            {
                my $r0=shift @{$font};
                if(ref $r0)
                {
                    foreach my $b ($r0->[0]..$r0->[-1])
                    {
                        $self->{block}->{$b}=$fn;
                    }
                }
                else
                {
                    $self->{block}->{$r0}=$fn;
                }
            }
        }
        elsif(ref($font) eq 'HASH')
        {
            push @{$self->{fonts}},$font->{font};
            
            if(defined $font->{blocks} && ref($font->{blocks}) eq 'ARRAY')
            {
                foreach my $r0 (@{$font->{blocks}})
                {
                    if(ref $r0)
                    {
                        foreach my $b ($r0->[0]..$r0->[-1])
                        {
                            $self->{block}->{$b}=$fn;
                        }
                    }
                    else
                    {
                        $self->{block}->{$r0}=$fn;
                    }
                }
            }
            
            if(defined $font->{codes} && ref($font->{codes}) eq 'ARRAY')
            {
                foreach my $r0 (@{$font->{codes}})
                {
                    if(ref $r0)
                    {
                        foreach my $b ($r0->[0]..$r0->[-1])
                        {
                            $self->{code}->{$b}=$fn;
                        }
                    }
                    else
                    {
                        $self->{code}->{$r0}=$fn;
                    }
                }
            }
        }
        else
        {
            push @{$self->{fonts}},$font;
            foreach my $b (0..255)
            {
                $self->{block}->{$b}=$fn;
            }
        }
        $fn++;
    }
    
    my %opts=@fonts;
    
    $self->{encode}=$opts{-encode} if(defined $opts{-encode});
    
    return($self);
}

=item $font = PDF::API3::Compat::API2::Resource::UniFont->new_api $api, $name, %options

Returns a uni-font object. This method is different from 'new' that
it needs an PDF::API3::Compat::API2-object rather than a Text::PDF::File-object.

=cut

sub new_api {
    my ($class,$api,@opts)=@_;

    my $obj=$class->new($api->{pdf},@opts);
    $obj->{api}=$api;

    return($obj);
}

sub isvirtual { return(1); }

sub fontlist
{
    my ($self)=@_;
    return [@{$self->{fonts}}];
}

sub width {
    my ($self,$text)=@_;
    $text=decode($self->{encode},$text) unless(is_utf8($text));
    my $width=0;
    if(1)
    {
        my @blks=();
        foreach my $u (unpack('U*',$text))
        {
            my $fn=0;
            if(defined $self->{code}->{$u})
            {
                $fn=$self->{code}->{$u};
            }
            elsif(defined $self->{block}->{($u>>8)})
            {
                $fn=$self->{block}->{($u>>8)};
            }
            else
            {
                $fn=0;
            }
            if(scalar @blks==0 || $blks[-1]->[0]!=$fn)
            {
                push @blks,[$fn,pack('U',$u)];
            }
            else
            {
                $blks[-1]->[1].=pack('U',$u);
            }
        }
        foreach my $blk (@blks)
        {
            $width+=$self->fontlist->[$blk->[0]]->width($blk->[1]);
        }
    }
    else
    {
        foreach my $u (unpack('U*',$text))
        {
            if(defined $self->{code}->{$u})
            {
                $width+=$self->fontlist->[$self->{code}->{$u}]->width(pack('U',$u));
            }
            elsif(defined $self->{block}->{($u>>8)})
            {
                $width+=$self->fontlist->[$self->{block}->{($u>>8)}]->width(pack('U',$u));
            }
            else
            {
                $width+=$self->fontlist->[0]->width(pack('U',$u));
            }
        }
    }

    return($width);
}

sub text 
{ 
    my ($self,$text,$size,$ident)=@_;
    $text=decode($self->{encode},$text) unless(is_utf8($text));
    die 'textsize not specified' unless(defined $size);
    my $newtext='';
    my $lastfont=-1;
    my @codes=();
    
    foreach my $u (unpack('U*',$text))
    {
        my $thisfont=0;
        if(defined $self->{code}->{$u})
        {
            $thisfont=$self->{code}->{$u};
        }
        elsif(defined $self->{block}->{($u>>8)})
        {
            $thisfont=$self->{block}->{($u>>8)};
        }
        
        if($thisfont!=$lastfont && $lastfont!=-1)
        {
            my $f=$self->fontlist->[$lastfont];
            if(defined($ident) && $ident!=0)
            {
	            $newtext.='/'.$f->name.' '.$size.' Tf ['.$ident.' '.$f->text(pack('U*',@codes)).'] TJ ';
	            $ident=undef;
            }
            else
            {
	            $newtext.='/'.$f->name.' '.$size.' Tf '.$f->text(pack('U*',@codes)).' Tj ';
            }
            @codes=();
        }
        
        push(@codes,$u);
        $lastfont=$thisfont;
    }

    if(scalar @codes > 0)
    {
        my $f=$self->fontlist->[$lastfont];
        $newtext.='/'.$f->name.' '.$size.' Tf '.$f->text(pack('U*',@codes),$size).' ';
    }

    return($newtext);
}

1;

__END__
