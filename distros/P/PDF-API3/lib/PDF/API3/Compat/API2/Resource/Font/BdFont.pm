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
#   $Id: BdFont.pm,v 2.0 2005/11/16 02:18:14 areibens Exp $
#
#=======================================================================
package PDF::API3::Compat::API2::Resource::Font::BdFont;

BEGIN {

    use utf8;
    use Encode qw(:all);

    use vars qw( @ISA $VERSION $BmpNum);
    use PDF::API3::Compat::API2::Resource::Font;
    use PDF::API3::Compat::API2::Util;
    use PDF::API3::Compat::API2::Basic::PDF::Utils;
    use Math::Trig;
    use Unicode::UCD 'charinfo';

    @ISA=qw(PDF::API3::Compat::API2::Resource::Font);

    ( $VERSION ) = sprintf '%i.%03i', split(/\./,('$Revision: 2.0 $' =~ /Revision: (\S+)\s/)[0]); # $Date: 2005/11/16 02:18:14 $

    $BmpNum=0;
    
}
no warnings qw[ deprecated recursion uninitialized ];

=head1 NAME

PDF::API3::Compat::API2::Resource::Font::BdFont - Module for using bitmapped Fonts.

=head1 SYNOPSIS

    #
    use PDF::API3::Compat::API2;
    #
    $pdf = PDF::API3::Compat::API2->new;
    $sft = $pdf->bdfont($file);
    #

=head1 METHODS

=over 4

=cut

=item $font = PDF::API3::Compat::API2::Resource::Font::BdFont->new $pdf, $font, %options

Returns a BmpFont object.

=cut

=pod

Valid %options are:

I<-encode>
... changes the encoding of the font from its default.
See I<perl's Encode> for the supported values.

I<-pdfname> ... changes the reference-name of the font from its default.
The reference-name is normally generated automatically and can be
retrived via $pdfname=$font->name.

=cut

sub new {
    my ($class,$pdf,$file,@opts) = @_;
    my ($self,$data);
    my %opts=@opts;

    $class = ref $class if ref $class;
    $self = $class->SUPER::new($pdf, sprintf('%s+Bdf%02i',pdfkey(),++$BmpNum).'~'.time());
    $pdf->new_obj($self) unless($self->is_obj($pdf));

    # adobe bitmap distribution font
    $self->{' data'}=$self->readBDF($file);
    
    my $first=1;
    my $last=255;

    $self->{'Subtype'} = PDFName('Type3');
    $self->{'FirstChar'} = PDFNum($first);
    $self->{'LastChar'} = PDFNum($last);
    $self->{'FontMatrix'} = PDFArray(map { PDFNum($_) } ( 0.001, 0, 0, 0.001, 0, 0 ) );
    $self->{'FontBBox'} = PDFArray(map { PDFNum($_) } ( $self->fontbbox ) );

    my $xo=PDFDict();
    $self->{'Encoding'}=$xo;
    $xo->{Type}=PDFName('Encoding');
    $xo->{BaseEncoding}=PDFName('WinAnsiEncoding');
    $xo->{Differences}=PDFArray(PDFNum('0'),(map { PDFName($_||'.notdef') } @{$self->data->{char}}));
   
    my $procs=PDFDict();
    $pdf->new_obj($procs);
    $self->{'CharProcs'} = $procs;

    $self->{Resources}=PDFDict();
    $self->{Resources}->{ProcSet}=PDFArray(map { PDFName($_) } qw(PDF Text ImageB ImageC ImageI));
    foreach my $w ($first..$last) {
        $self->data->{uni}->[$w]=uniByName($self->data->{char}->[$w]);
        $self->data->{u2e}->{$self->data->{uni}->[$w]}=$w;
    }
    my @widths=();
    foreach my $w (@{$self->data->{char2}}) {
        $widths[$w->{ENCODING}]=$self->data->{wx}->{$w->{NAME}};
        my @bbx=@{$w->{BBX}};
        my $stream=pack('H*',$w->{hex});
        my $y=$bbx[1];
        my $char=PDFDict();
        $char->{Filter}=PDFArray(PDFName('FlateDecode'));
        ## $char->{' stream'}=$widths[$w->{ENCODING}]." 0 ".join(' ',map { int($_) } $self->fontbbox)." d1\n";
        $char->{' stream'}=$widths[$w->{ENCODING}]." 0 d0\n";
        $char->{Comment}=PDFStr("N='$w->{NAME}' C=($w->{ENCODING})");
        $procs->{$w->{NAME}}=$char;
        @bbx=map { $_*1000/$self->data->{upm} } @bbx;
        if($y==0) {
            $char->{' stream'}.="q Q\n";
        } else {
            my $x=8*length($stream)/$y; # q $x 0 0 $y 50 50 cm
            my $img=qq|BI\n/Interpolate true/Mask[0 0.1]/Decode[1 0]/H $y/W $x/BPC 1/CS/G\nID $stream\nEI\n|;
            $procs->{$self->data->{char}->[$w]}=$char;
            $char->{' stream'}.="$bbx[0] 0 0 $bbx[1] $bbx[2] $bbx[3] cm\n$img\n";
        }
        $pdf->new_obj($char);
    }
    $procs->{'.notdef'}=$procs->{$self->data->{char}->[32]};
    delete $procs->{''};
    $self->{Widths}=PDFArray(map { PDFNum($widths[$_]||0) } ($first..$last));
    $self->data->{e2n}=$self->data->{char};
    $self->data->{e2u}=$self->data->{uni};

    $self->data->{u2c}={};
    $self->data->{u2e}={};
    $self->data->{u2n}={};
    $self->data->{n2c}={};
    $self->data->{n2e}={};
    $self->data->{n2u}={};

    foreach my $n (reverse 0..255) {
        $self->data->{n2c}->{$self->data->{char}->[$n] || '.notdef'}=$n unless(defined $self->data->{n2c}->{$self->data->{char}->[$n] || '.notdef'});
        $self->data->{n2e}->{$self->data->{e2n}->[$n] || '.notdef'}=$n unless(defined $self->data->{n2e}->{$self->data->{e2n}->[$n] || '.notdef'});

        $self->data->{n2u}->{$self->data->{e2n}->[$n] || '.notdef'}=$self->data->{e2u}->[$n] unless(defined $self->data->{n2u}->{$self->data->{e2n}->[$n] || '.notdef'});
        $self->data->{n2u}->{$self->data->{char}->[$n] || '.notdef'}=$self->data->{uni}->[$n] unless(defined $self->data->{n2u}->{$self->data->{char}->[$n] || '.notdef'});

        $self->data->{u2c}->{$self->data->{uni}->[$n]}=$n unless(defined $self->data->{u2c}->{$self->data->{uni}->[$n]});
        $self->data->{u2e}->{$self->data->{e2u}->[$n]}=$n unless(defined $self->data->{u2e}->{$self->data->{e2u}->[$n]});

        $self->data->{u2n}->{$self->data->{e2u}->[$n]}=($self->data->{e2n}->[$n] || '.notdef') unless(defined $self->data->{u2n}->{$self->data->{e2u}->[$n]});
        $self->data->{u2n}->{$self->data->{uni}->[$n]}=($self->data->{char}->[$n] || '.notdef') unless(defined $self->data->{u2n}->{$self->data->{uni}->[$n]});
    }

    return($self);
}


=item $font = PDF::API3::Compat::API2::Resource::Font::BdFont->new_api $api, %options

Returns a BdFont object. This method is different from 'new' that
it needs an PDF::API3::Compat::API2-object rather than a PDF::API3::Compat::API2::PDF::File-object.

=cut

sub new_api {
  my ($class,$api,@opts)=@_;

  my $obj=$class->new($api->{pdf},@opts);

  $api->{pdf}->new_obj($obj) unless($obj->is_obj($api->{pdf}));

  $api->{pdf}->out_obj($api->{pages});
  return($obj);
}

sub readBDF {
    my ($self,$file)=@_;
    my $data={};
    $data->{char}=[];
    $data->{char2}=[];
    $data->{wx}={};

    if(! -e $file) {die "file='$file' not existant.";}
    open(AFMF, $file) or die "Can't find the BDF file for $file";
    local($/, $_) = ("\n", undef);  # ensure correct $INPUT_RECORD_SEPARATOR
    while ($_=<AFMF>) {
        chomp($_);
        if (/^STARTCHAR/ .. /^ENDCHAR/) {
            if (/^STARTCHAR\s+(\S+)/) {
                my $name=$1;
                $name=~s|^(\d+.*)$|X_$1|;
                push @{$data->{char2}},{'NAME'=>$name};
            } elsif (/^BITMAP/ .. /^ENDCHAR/) {
                next if(/^BITMAP/);
                if(/^ENDCHAR/){
                    $data->{char2}->[-1]->{NAME}||='E_'.$data->{char2}->[-1]->{ENCODING};
                    $data->{char}->[$data->{char2}->[-1]->{ENCODING}]=$data->{char2}->[-1]->{NAME};
                    ($data->{wx}->{$data->{char2}->[-1]->{NAME}})=split(/\s+/,$data->{char2}->[-1]->{SWIDTH});
                    $data->{char2}->[-1]->{BBX}=[split(/\s+/,$data->{char2}->[-1]->{BBX})];
                } else {
                    $data->{char2}->[-1]->{hex}.=$_;
                }
            } else {
                m|^(\S+)\s+(.+)$|;
                $data->{char2}->[-1]->{uc($1)}.=$2;
            }
        ## } elsif(/^STARTPROPERTIES/ .. /^ENDPROPERTIES/) {
        } else {
                m|^(\S+)\s+(.+)$|;
                $data->{uc($1)}.=$2;
        }
    }
    close(AFMF);
    unless (exists $data->{wx}->{'.notdef'}) {
        $data->{wx}->{'.notdef'} = 0;
        $data->{bbox}{'.notdef'} = [0, 0, 0, 0];
    }

    $data->{fontname}=pdfkey().pdfkey().'~'.time();
    $data->{apiname}=$data->{fontname};
    $data->{flags} = 34;
    $data->{fontbbox} = [ split(/\s+/,$data->{FONTBOUNDINGBOX}) ];
    $data->{upm}=$data->{PIXEL_SIZE} || ($data->{fontbbox}->[1] - $data->{fontbbox}->[3]);
    @{$data->{fontbbox}} = map { int($_*1000/$data->{upm}) } @{$data->{fontbbox}};

    foreach my $n (0..255) {
        $data->{char}->[$n]||='.notdef';
    #    $data->{wx}->{$data->{char}->[$n]}=int($data->{wx}->{$data->{char}->[$n]}*1000/$data->{upm});
    }
    
    $data->{uni}||=[];
    foreach my $n (0..255) {
        $data->{uni}->[$n]=uniByName($data->{char}->[$n] || '.notdef') || 0;
    }
    $data->{ascender}=$data->{RAW_ASCENT} 
        || int($data->{FONT_ASCENT}*1000/$data->{upm});
    $data->{descender}=$data->{RAW_DESCENT} 
        || int($data->{FONT_DESCENT}*1000/$data->{upm});

    $data->{type}='Type3';
    $data->{capheight}=1000;
    $data->{iscore}=0;
    $data->{issymbol} = 0;
    $data->{isfixedpitch}=0;
    $data->{italicangle}=0;
    $data->{missingwidth}=$data->{AVERAGE_WIDTH} 
        || int($data->{FONT_AVERAGE_WIDTH}*1000/$data->{upm}) 
        || $data->{RAW_AVERAGE_WIDTH} 
        || 500;
    $data->{underlineposition}=-200;
    $data->{underlinethickness}=10;
    $data->{xheight}=$data->{RAW_XHEIGHT} 
        || int($data->{FONT_XHEIGHT}*1000/$data->{upm}) 
        || int($data->{ascender}/2);
    $data->{firstchar}=1;
    $data->{lastchar}=255;

    delete $data->{wx}->{''};

    return($data);
}

1;

__END__

=back

=head1 AUTHOR

alfred reibenschuh

=head1 HISTORY

    $Log: BdFont.pm,v $
    Revision 2.0  2005/11/16 02:18:14  areibens
    revision workaround for SF cvs import not to screw up CPAN

    Revision 1.2  2005/11/16 01:27:50  areibens
    genesis2

    Revision 1.1  2005/11/16 01:19:27  areibens
    genesis

    Revision 1.7  2005/10/01 22:41:07  fredo
    fixed font-naming race condition for multiple document updates

    Revision 1.6  2005/06/17 19:44:03  fredo
    fixed CPAN modulefile versioning (again)

    Revision 1.5  2005/06/17 18:53:34  fredo
    fixed CPAN modulefile versioning (dislikes cvs)

    Revision 1.4  2005/03/14 22:01:27  fredo
    upd 2005

    Revision 1.3  2004/12/16 00:30:54  fredo
    added no warn for recursion

    Revision 1.2  2004/07/24 23:33:35  fredo
    added compression

    Revision 1.1  2004/07/24 23:08:57  fredo
    genesis

    Revision 1.9  2004/06/15 09:14:53  fredo
    removed cr+lf

    Revision 1.8  2004/06/07 19:44:43  fredo
    cleaned out cr+lf for lf

    Revision 1.7  2004/02/10 15:55:42  fredo
    fixed glyph generation for .notdef glyphs

    Revision 1.6  2004/02/01 22:06:26  fredo
    beautified caps generation

    Revision 1.5  2004/02/01 19:27:18  fredo
    fixed width calc for caps

    Revision 1.4  2004/02/01 19:04:31  fredo
    added caps capability

    Revision 1.3  2003/12/08 13:06:01  Administrator
    corrected to proper licencing statement

    Revision 1.2  2003/11/30 17:32:48  Administrator
    merged into default

    Revision 1.1.1.1.2.2  2003/11/30 16:57:05  Administrator
    merged into default

    Revision 1.1.1.1.2.1  2003/11/30 14:45:23  Administrator
    added CVS id/log


=cut

