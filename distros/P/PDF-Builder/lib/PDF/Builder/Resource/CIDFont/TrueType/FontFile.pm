package PDF::Builder::Resource::CIDFont::TrueType::FontFile;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

our $VERSION = '3.025'; # VERSION
our $LAST_UPDATE = '3.025'; # manually update whenever code is changed

use Carp;
use Encode qw(:all);
use Font::TTF::Font;
use POSIX qw(ceil floor);

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

our $cmap = {};

# for new() if not using find_ms() or .cmap files
# may be overridden fully or partially by cmaps option
# [0] is Windows list, [1] is non-Windows list  Platform/Encoding
# can substitute 'find_ms' instead of a list of P/E
# suggested default list by Alfred Reibenschuh (original PDF::API2 author)
my @default_CMap = ('0/6 3/10 0/4 3/1 0/3', '0/6 0/4 3/10 0/3 3/1');

=head1 NAME

PDF::Builder::Resource::CIDFont::TrueType::FontFile - additional code support for TT font files. Inherits from L<PDF::Builder::Basic::PDF::Dict>

=cut

# identical routine in Resource/CIDFont/CJKFont.pm
sub _look_for_cmap {
    my $map = shift;
    my $fname = lc($map);

    $fname =~ s/[^a-z0-9]+//gi;
    return ({%{$cmap->{$fname}}}) if defined $cmap->{$fname};
    eval "require 'PDF/Builder/Resource/CIDFont/CMap/$fname.cmap'"; ## no critic
    unless ($@) {
        return {%{$cmap->{$fname}}};
    } else {
        die "requested cmap '$map' not installed ";
    }
}

sub readcffindex {
    my ($fh, $off, $buf) = @_;

    my @idx = ();
    my $index = [];
    seek($fh, $off, 0);
    read($fh, $buf, 3);
    my ($count, $offsize) = unpack('nC', $buf);
    foreach (0 .. $count) {
        read($fh, $buf, $offsize);
        $buf = substr("\x00\x00\x00$buf", -4, 4);
        my $id = unpack('N', $buf);
        push(@idx, $id);
    }
    my $dataoff = tell($fh)-1;

    foreach my $i (0 .. $count-1) {
        push(@{$index}, { 'OFF' => $dataoff+$idx[$i], 
			  'LEN' => $idx[$i+1]-$idx[$i] });
    }
    return $index;
}

sub readcffdict {
    my ($fh, $off, $len, $foff, $buf) = @_;

    my @idx = ();
    my $dict = {};
    seek($fh, $off, 0);
    my @st = ();
    while (tell($fh) < ($off+$len)) {
        read($fh, $buf, 1);
        my $b0 = unpack('C', $buf);
        my $v = '';

        if      ($b0 == 12) { # two byte commands
            read($fh, $buf, 1);
            my $b1 = unpack('C', $buf);
            if      ($b1 == 0) {
                $dict->{'Copyright'} = { 'SID' => splice(@st, -1) };
            } elsif ($b1 == 1) {
                $dict->{'isFixedPitch'} = splice(@st, -1);
            } elsif ($b1 == 2) {
                $dict->{'ItalicAngle'} = splice(@st, -1);
            } elsif ($b1 == 3) {
                $dict->{'UnderlinePosition'} = splice(@st, -1);
            } elsif ($b1 == 4) {
                $dict->{'UnderlineThickness'} = splice(@st, -1);
            } elsif ($b1 == 5) {
                $dict->{'PaintType'} = splice(@st, -1);
            } elsif ($b1 == 6) {
                $dict->{'CharstringType'} = splice(@st, -1);
            } elsif ($b1 == 7) {
                $dict->{'FontMatrix'} = [ splice(@st, -4) ];
            } elsif ($b1 == 8) {
                $dict->{'StrokeWidth'} = splice(@st, -1);
            } elsif ($b1 == 20) {
                $dict->{'SyntheticBase'} = splice(@st, -1);
            } elsif ($b1 == 21) {
                $dict->{'PostScript'} = { 'SID' => splice(@st, -1) };
            } elsif ($b1 == 22) {
                $dict->{'BaseFontName'} = { 'SID' => splice(@st, -1) };
            } elsif ($b1 == 23) {
                $dict->{'BaseFontBlend'} = [ splice(@st, 0) ];
            } elsif ($b1 == 24) {
                $dict->{'MultipleMaster'} = [ splice(@st, 0) ];
            } elsif ($b1 == 25) {
                $dict->{'BlendAxisTypes'} = [ splice(@st, 0) ];
            } elsif ($b1 == 30) {
                $dict->{'ROS'} = [ splice(@st, -3) ];
            } elsif ($b1 == 31) {
                $dict->{'CIDFontVersion'} = splice(@st, -1);
            } elsif ($b1 == 32) {
                $dict->{'CIDFontRevision'} = splice(@st, -1);
            } elsif ($b1 == 33) {
                $dict->{'CIDFontType'} = splice(@st, -1);
            } elsif ($b1 == 34) {
                $dict->{'CIDCount'} = splice(@st, -1);
            } elsif ($b1 == 35) {
                $dict->{'UIDBase'} = splice(@st, -1);
            } elsif ($b1 == 36) {
                $dict->{'FDArray'} = { 'OFF' => $foff+splice(@st, -1) };
            } elsif ($b1 == 37) {
                $dict->{'FDSelect'} = { 'OFF' => $foff+splice(@st, -1) };
            } elsif ($b1 == 38) {
                $dict->{'FontName'} = { 'SID' => splice(@st, -1) };
            } elsif ($b1 == 39) {
                $dict->{'Chameleon'} = splice(@st, -1);
            }
 	    next;
        } elsif ($b0 < 28) { # commands
            if      ($b0 == 0) {
                $dict->{'Version'} = { 'SID' => splice(@st, -1) };
            } elsif ($b0 == 1) {
                $dict->{'Notice'} = { 'SID' => splice(@st, -1) };
            } elsif ($b0 == 2) {
                $dict->{'FullName'} = { 'SID' => splice(@st, -1) };
            } elsif ($b0 == 3) {
                $dict->{'FamilyName'} = { 'SID' => splice(@st, -1) };
            } elsif ($b0 == 4) {
                $dict->{'Weight'} = { 'SID' => splice(@st, -1) };
            } elsif ($b0 == 5) {
                $dict->{'FontBBX'} = [ splice(@st, -4) ];
            } elsif ($b0 == 13) {
                $dict->{'UniqueID'} = splice(@st, -1);
            } elsif ($b0 == 14) {
                $dict->{'XUID'} = [ splice(@st, 0) ];
            } elsif ($b0 == 15) {
                $dict->{'CharSet'} = { 'OFF' => $foff+splice(@st, -1) };
            } elsif ($b0 == 16) {
                $dict->{'Encoding'} = { 'OFF' => $foff+splice(@st, -1) };
            } elsif ($b0 == 17) {
                $dict->{'CharStrings'} = { 'OFF' => $foff+splice(@st, -1) };
            } elsif ($b0 == 18) {
                $dict->{'Private'} = { 'LEN' => splice(@st, -1), 
			               'OFF' => $foff+splice(@st, -1) };
            }
            next;
        } elsif ($b0 == 28) { # int16
            read($fh, $buf, 2);
            $v = unpack('n', $buf);
            $v = -(0x10000 - $v) if $v > 0x7fff;
	    # alt: $v = unpack('n!', $buf);
        } elsif ($b0 == 29) { # int32
            read($fh, $buf, 4);
            $v = unpack('N', $buf);
            $v = -$v + 0xffffffff+1 if $v > 0x7fffffff;
	    # alt: $v = unpack('N!', $buf);
        } elsif ($b0 == 30) { # float
            my $e = 1;
            while ($e) {
                read($fh, $buf, 1);
                my $v0 = unpack('C', $buf);
                foreach my $m ($v0 >> 8, $v0&0xf) {
                    if      ($m < 10) {
                        $v .= $m;
                    } elsif ($m == 10) {
                        $v .= '.';
                    } elsif ($m == 11) {
                        $v .= 'E+';
                    } elsif ($m == 12) {
                        $v .= 'E-';
                    } elsif ($m == 14) {
                        $v .= '-';
                    } elsif ($m == 15) {
                        $e = 0;
                        last;
                    }
                }
            }
        } elsif ($b0 == 31) { # command
            $v = "c=$b0";
            next;
        } elsif ($b0 < 247) { # 1 byte signed
            $v = $b0 - 139;
        } elsif ($b0 < 251) { # 2 byte plus
            read($fh, $buf, 1);
            $v = unpack('C', $buf);
            $v = ($b0 - 247)*256 + ($v + 108);
        } elsif ($b0 < 255) { # 2 byte minus
            read($fh, $buf, 1);
            $v = unpack('C', $buf);
            $v = -($b0 - 251)*256 - $v - 108;
        }
        push(@st, $v);
    }

    return $dict;
}

sub read_kern_table {
    my ($font, $upem, $self) = @_;
    my $fh = $font->{' INFILE'};
    my $data;
    my $buf;

    return unless $font->{'kern'};

    seek($fh, $font->{'kern'}->{' OFFSET'}+2, 0);
    read($fh, $buf, 2);
    my $num = unpack('n', $buf);
    foreach my $n (1 .. $num) {
        read($fh, $buf, 6);
        my ($ver, $len, $cov) = unpack('n3', $buf);
        $len -= 6;
        my $fmt = $cov >> 8;
        if      ($fmt == 0) {
            $data ||= {};
            read($fh, $buf, 8);
            my $nc = unpack('n', $buf);
            foreach (1 .. $nc) {
                read($fh, $buf, 6);
                my ($idx1, $idx2, $val) = unpack('n2n!', $buf);
		# alt: unpack('nnn', $buf);
                $val -= 65536 if $val > 32767;
                $val = $val<0? -floor($val*1000/$upem): -ceil($val*1000/$upem);
                if ($val != 0) {
                    $data->{"$idx1:$idx2"} = $val;
                    $data->{join(':',
		                 ($self->data()->{'g2n'}->[$idx1] // ''),
				 ($self->data()->{'g2n'}->[$idx2] // '')
				)} = $val;
                }
            }
        } elsif ($fmt==2) {
            read($fh, $buf, $len);
        } else {
            read($fh, $buf, $len);
        }
    }
    return $data;
}

sub readcffstructs {
    my $font = shift;

    my $fh = $font->{' INFILE'};
    my $data = {};
    # read CFF table
    seek($fh, $font->{'CFF '}->{' OFFSET'}, 0);
    my $buf;
    read($fh, $buf, 4);
    my ($cffmajor, $cffminor, $cffheadsize, $cffglobaloffsize) = unpack('C4', $buf);

    $data->{'name'} = readcffindex($fh, $font->{'CFF '}->{' OFFSET'}+$cffheadsize);
    foreach my $dict (@{$data->{'name'}}) {
        seek($fh, $dict->{'OFF'}, 0);
        read($fh, $dict->{'VAL'}, $dict->{'LEN'});
    }

    $data->{'topdict'} = readcffindex($fh, $data->{'name'}->[-1]->{'OFF'}+$data->{'name'}->[-1]->{'LEN'});
    foreach my $dict (@{$data->{'topdict'}}) {
        $dict->{'VAL'} = readcffdict($fh, $dict->{'OFF'}, $dict->{LEN}, $font->{'CFF '}->{' OFFSET'});
    }

    $data->{'string'} = readcffindex($fh, $data->{'topdict'}->[-1]->{'OFF'}+$data->{'topdict'}->[-1]->{'LEN'});
    foreach my $dict (@{$data->{'string'}}) {
        seek($fh, $dict->{'OFF'}, 0);
        read($fh, $dict->{'VAL'}, $dict->{'LEN'});
    }
    push(@{$data->{'string'}}, { 'VAL' => '001.000' });
    push(@{$data->{'string'}}, { 'VAL' => '001.001' });
    push(@{$data->{'string'}}, { 'VAL' => '001.002' });
    push(@{$data->{'string'}}, { 'VAL' => '001.003' });
    push(@{$data->{'string'}}, { 'VAL' => 'Black' });
    push(@{$data->{'string'}}, { 'VAL' => 'Bold' });
    push(@{$data->{'string'}}, { 'VAL' => 'Book' });
    push(@{$data->{'string'}}, { 'VAL' => 'Light' });
    push(@{$data->{'string'}}, { 'VAL' => 'Medium' });
    push(@{$data->{'string'}}, { 'VAL' => 'Regular' });
    push(@{$data->{'string'}}, { 'VAL' => 'Roman' });
    push(@{$data->{'string'}}, { 'VAL' => 'Semibold' });

    foreach my $dict (@{$data->{'topdict'}}) {
        foreach my $k (keys %{$dict->{'VAL'}}) {
            my $dt = $dict->{'VAL'}->{$k};
            if ($k eq 'ROS') {
                $dict->{'VAL'}->{$k}->[0] = $data->{'string'}->[$dict->{'VAL'}->{$k}->[0]-391]->{'VAL'};
                $dict->{'VAL'}->{$k}->[1] = $data->{'string'}->[$dict->{'VAL'}->{$k}->[1]-391]->{'VAL'};
                next;
            }
            next unless ref($dt) eq 'HASH' && defined $dt->{'SID'};
            if ($dt->{'SID'} >= 379) {
                $dict->{'VAL'}->{$k} = $data->{'string'}->[$dt->{'SID'}-391]->{'VAL'};
            }
        }
    }
    my $dict = {};
    foreach my $k (qw[ CIDCount CIDFontVersion FamilyName FontBBX FullName ROS Weight XUID ]) {
        $dict->{$k} = $data->{'topdict'}->[0]->{'VAL'}->{$k} if defined $data->{'topdict'}->[0]->{'VAL'}->{$k};
    }
    return $dict;
}

sub new {
    my ($class, $pdf, $file, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-noembed'} && !defined $opts{'noembed'}) { $opts{'noembed'} = delete($opts{'-noembed'}); }
    if (defined $opts{'-isocmap'} && !defined $opts{'isocmap'}) { $opts{'isocmap'} = delete($opts{'-isocmap'}); }
    if (defined $opts{'-debug'} && !defined $opts{'debug'}) { $opts{'debug'} = delete($opts{'-debug'}); }
    if (defined $opts{'-cmaps'} && !defined $opts{'cmaps'}) { $opts{'cmaps'} = delete($opts{'-cmaps'}); }
    if (defined $opts{'-usecmf'} && !defined $opts{'usecmf'}) { $opts{'usecmf'} = delete($opts{'-usecmf'}); }

    my $data = {};
# some debug settings
#$opts{'debug'} = 1;
#$opts{'cmaps'} = '0/6, 0/4, 3/10, 0/3, 3/1';
#$opts{'cmaps'} = '7/8; 8/7';  # invalid P/E, should use find_ms instead
#$opts{'cmaps'} = 'find_ms;   find_ms ';
#$opts{'usecmf'} = 1;

    confess "cannot find font '$file'" unless -f $file;
    my $font = Font::TTF::Font->open($file);
    $data->{'obj'} = $font;

    $class = ref $class if ref $class;
    my $self = $class->SUPER::new();

    $self->{'Filter'} = PDFArray(PDFName('FlateDecode'));
    $self->{' font'} = $font;
    $self->{' data'} = $data;
    
    $data->{'noembed'} = ($opts{'noembed'}||0)==1? 1: 0;
    $data->{'iscff'} = (defined $font->{'CFF '})? 1: 0;

    $self->{'Subtype'} = PDFName('CIDFontType0C') if $data->{'iscff'};

    $data->{'fontfamily'} = $font->{'name'}->read()->find_name(1);
    $data->{'fontname'} = $font->{'name'}->read()->find_name(4);

    $font->{'OS/2'}->read();
    my @stretch = qw[
        Normal
        UltraCondensed
        ExtraCondensed
        Condensed
        SemiCondensed
        Normal
        SemiExpanded
        Expanded
        ExtraExpanded
        UltraExpanded
    ];
    $data->{'fontstretch'} = $stretch[$font->{'OS/2'}->{'usWidthClass'}] || 'Normal';

    $data->{'fontweight'} = $font->{'OS/2'}->{'usWeightClass'};

    $data->{'panose'} = pack('n', $font->{'OS/2'}->{'sFamilyClass'});

    foreach my $p (qw[bFamilyType bSerifStyle bWeight bProportion bContrast bStrokeVariation bArmStyle bLetterform bMidline bXheight]) {
        $data->{'panose'} .= pack('C', $font->{'OS/2'}->{$p});
    }

    $data->{'apiname'} = join('', map { ucfirst(lc(substr($_, 0, 2))) } split m/[^A-Za-z0-9\s]+/, $data->{'fontname'});
    $data->{'fontname'} =~ s/[\x00-\x1f\s]//og;

    $data->{'altname'} = $font->{'name'}->find_name(1);
    $data->{'altname'} =~ s/[\x00-\x1f\s]//og;

    $data->{'subname'} = $font->{'name'}->find_name(2);
    $data->{'subname'} =~ s/[\x00-\x1f\s]//og;

    # TBD in PDF::API2 the following line is just find_ms()
    $font->{'cmap'}->read()->find_ms($opts{'isocmap'} || 0);
    if (defined $font->{'cmap'}->find_ms()) {
        $data->{'issymbol'} = ($font->{'cmap'}->find_ms()->{'Platform'} == 3 &&
	                      $font->{'cmap'}->read()->find_ms()->{'Encoding'} == 0) || 0;
    } else {
        $data->{'issymbol'} = 0;
    }

    $data->{'upem'} = $font->{'head'}->read()->{'unitsPerEm'};

    $data->{'fontbbox'} = [
        int($font->{'head'}->{'xMin'} * 1000 / $data->{'upem'}),
        int($font->{'head'}->{'yMin'} * 1000 / $data->{'upem'}),
        int($font->{'head'}->{'xMax'} * 1000 / $data->{'upem'}),
        int($font->{'head'}->{'yMax'} * 1000 / $data->{'upem'})
    ];

    $data->{'stemv'} = 0;
    $data->{'stemh'} = 0;

    $data->{'missingwidth'} = int($font->{'hhea'}->read()->{'advanceWidthMax'} * 1000 / $data->{'upem'}) || 1000;
    $data->{'maxwidth'} = int($font->{'hhea'}->{'advanceWidthMax'} * 1000 / $data->{'upem'});
    $data->{'ascender'} = int($font->{'hhea'}->read()->{'Ascender'} * 1000 / $data->{'upem'});
    $data->{'descender'} = int($font->{'hhea'}{'Descender'} * 1000 / $data->{'upem'});

    $data->{'flags'} = 0;
    $data->{'flags'} |= 1 if $font->{'OS/2'}->read()->{'bProportion'} == 9;
    $data->{'flags'} |= 2 unless $font->{'OS/2'}{'bSerifStyle'} > 10 && 
                                 $font->{'OS/2'}{'bSerifStyle'} < 14;
    $data->{'flags'} |= 8 if $font->{'OS/2'}{'bFamilyType'} == 2;
    $data->{'flags'} |= 32; # if $font->{'OS/2'}{'bFamilyType'} > 3;
    $data->{'flags'} |= 64 if $font->{'OS/2'}{'bLetterform'} > 8;

    $data->{'capheight'} = $font->{'OS/2'}->{'CapHeight'} || int($data->{'fontbbox'}->[3]*0.8);
    $data->{'xheight'} = $font->{'OS/2'}->{'xHeight'} || int($data->{'fontbbox'}->[3]*0.4);

    if ($data->{'issymbol'}) {
        $data->{'e2u'} = [0xf000 .. 0xf0ff];
    } else {
        $data->{'e2u'} = [ unpack('U*', decode('cp1252', pack('C*', 0..255))) ];
    }

    if ($font->{'post'}->read()->{'FormatType'} == 3 && defined($font->{'cmap'}->read()->find_ms())) {
        $data->{'g2n'} = [];
        foreach my $u (sort {$a <=> $b} keys %{$font->{'cmap'}->read()->find_ms()->{'val'}}) {
            my $n = nameByUni($u);
            $data->{'g2n'}->[$font->{'cmap'}->read()->find_ms()->{'val'}->{$u}] = $n;
        }
    } else {
        $data->{'g2n'} = [ map { $_ || '.notdef' } @{$font->{'post'}->read()->{'VAL'}} ];
    }

    $data->{'italicangle'} = $font->{'post'}->{'italicAngle'};
    $data->{'isfixedpitch'} = $font->{'post'}->{'isFixedPitch'};
    $data->{'underlineposition'} = $font->{'post'}->{'underlinePosition'};
    $data->{'underlinethickness'} = $font->{'post'}->{'underlineThickness'};

    if ($self->iscff()) {
        $data->{'cff'} = readcffstructs($font);
    }

    if ($opts{'debug'}) {
        print "CMap determination for file $file\n";
    }
    if ($data->{'issymbol'}) {
	# force 'find_ms' if we know it's a symbol font anyway
	if ($opts{'debug'}) {
            print "This is a symbol font 3/0\n";
	}
	$opts{'cmaps'} = 'find_ms';
    }

    # first, see if CJK .cmap file exists, and want to use it
    # apparently, very old CJK fonts lack internal cmap tables and need this
    my $CMapfile = '';
    if (defined $data->{'cff'}->{'ROS'}) {
        my %cffcmap = (
            'Adobe:Japan1' => 'japanese',
            'Adobe:Korea1' => 'korean',
            'Adobe:CNS1'   => 'traditional',
            'Adobe:GB1'    => 'simplified',
        );
        $CMapfile = $cffcmap{"$data->{'cff'}->{'ROS'}->[0]:$data->{'cff'}->{'ROS'}->[1]"};
	if ($opts{'debug'}) {
	    if ($CMapfile ne '') {
		print "Available CMap file $CMapfile.cmap\n";
	    } else {
		print "No CMap file found\n";
	    }
	}
    }
    my $CMap = $CMapfile;  # save original name for later
    if ($CMapfile ne '' && $opts{'usecmf'}) {
        my $ccmap = _look_for_cmap($CMapfile);
        $data->{'u2g'} = $ccmap->{'u2g'};
        $data->{'g2u'} = $ccmap->{'g2u'};
    } else {
	# there is no .cmap file for this alphabet, or we don't want to use it
	if ($opts{'debug'} && $CMapfile ne '') {
	    print "Choose not to use .cmap file\n";
	}
        $data->{'u2g'} = {};

	if ($opts{'debug'}) {
            # debug stuff
            my $numTables = $font->{'cmap'}{'Num'}; # number of subtables in cmap table
            for my $iii (0 .. $numTables-1) {
              print "CMap Table $iii, ";
              print " Platform/Encoding = ";
	      print   $font->{'cmap'}{'Tables'}[$iii]{'Platform'};
	      print   "/";
              print   $font->{'cmap'}{'Tables'}[$iii]{'Encoding'};
              print ", Format = ".$font->{'cmap'}{'Tables'}[$iii]{'Format'};
              print ", Ver = ".$font->{'cmap'}{'Tables'}[$iii]{'Ver'};
              print "\n";
            }
	}

        # Platform
	#   0 = Unicode
	#   1 = Mac (deprecated)
	#   2 = ISO (deprecated in favor of Unicode)
	#   3 = Windows
	#   4 = Custom
	# Encodings 
	#   Platform 0 (Unicode)
	#     0 = Unicode 1.0
	#     1 = Unicode 1.1
	#     2 = ISO/IEC 10646
	#     3 = Unicode 2.0+ BMP only, formats 0/4/6
	#     4 = Unicode 2.0+ full repertoire, formats 0/4/6/10/12
	#     5 = Unicode Variation Sequences, format 14
	#     6 = Unicode full repertoire, formats 0/4/6/10/12/13
	#   Platform 1 (Macintosh) has encodings 0-32 for various alphabets
	#   Platform 2 (ISO)
	#     0 = 7 bit ASCII
	#     1 = ISO 10646
	#     2 = ISO 8859-1
	#   Platform 3 (Windows)
	#     0 = Symbol
	#     1 = Unicode BMP
	#     2 = ShiftJIS
	#     3 = PRC
	#     4 = Big5
	#     5 = Wansung
	#     6 = Johab
	#     7-9 = Reserved
	#     10 = Unicode full repertoire
	#   Platform 4 (Custom)
	#     0-255 OTF Windows NT compatibility mapping
	# Format 0-14 ?
	# Ver ?

	my $cmap_list = '';
	my $OS = $^O;
	if ($opts{'debug'}) {
	    print "OS string is '$OS', ";
	}
	if ($OS eq 'MSWin32' || $OS eq 'dos' || 
	    $OS eq 'os2' || $OS eq 'cygwin') {
	    $OS = 0; # Windows request
	    if ($opts{'debug'}) {
	        print "treat as Windows platform\n";
	    }
	} else {
	    $OS = 1; # non-Windows request
	    if ($opts{'debug'}) {
	        print "treat as non-Windows platform\n";
	    }
	}
	my $gmap;
	if (defined $opts{'cmaps'}) {
	    $CMap = $opts{'cmaps'};
	    # 1 or 2 lists, Windows and non-Windows, separated by ;
	    # if no ;, assume same list applies to both Platforms
	    # a list may be the string 'find_ms' to just use that mode
	    # otherwise, a list is p1/e1 p2/e2 etc. separated by max 1 comma
	    #   and any number of whitespace
	    if (index($CMap, ';') < 0) {
		# no ;, so single entry for both
		$CMap = $CMap.";".$CMap;
	    }
	    $cmap_list = (split /;/, $CMap)[$OS];
	    $cmap_list =~ s/^\s+//;
	    $cmap_list =~ s/\s+$//;
	} else {
	    # will use @default_CMap list
	    $cmap_list = '';
	}
	if ($cmap_list eq '') {
	    # empty list? use default CMap entry
	    $cmap_list = $default_CMap[$OS];
	}
	# now we have a cmap_list string of target P/E's to look for (either
	# specified with cmap, or default), OR just 'find_ms'
	if ($opts{'debug'}) {
	    print "search list '$cmap_list' for match, else find_ms()\n";
	}
	if ($cmap_list eq 'find_ms') {
	    # use original find_ms() call
            $gmap = $font->{'cmap'}->read()->find_ms();
	} else {
	    my @list = split/[,\s]+/, $cmap_list;
	    # should be list of P/E settings, like 0/6, 3/10, etc.
	    # following after code from Bob Hallissy (TTF::Font author)
	    my ($cmap, %cmaps, $i);
	    $cmap = $font->{'cmap'}->read();
	    for ($i = 0; $i < $font->{'cmap'}{'Num'}; $i++) {
		my $s = $font->{'cmap'}{'Tables'}[$i];
		my $key = "$s->{'Platform'}/$s->{'Encoding'}";
		$cmaps{$key} = $s;
	    }
	    foreach (@list) {
		if ($_ eq '') { next; } # empty entry got into list?
		if (exists $cmaps{$_}) {
		    $cmap->{' mstable'} = $cmaps{$_}; # might be unnecessary
		    if ($opts{'debug'}) {
			print "found internal cmap table '$_' on search list\n";
		    }
		    $gmap = $cmaps{$_};
		    last;
		}
	    }
	} # not 'find_ms' request

	# final check (.cmap wasn't used). no useful internal cmap found?
	if (! $gmap) {
	    # ignored existing .cmap before? use it anyway
            if ($CMapfile ne '' && !$opts{'usecmf'}) {
		if ($opts{'debug'}) {
		    print "need to use .cmap file '$CMapfile.cmap' anyway\n";
		}
                my $ccmap = _look_for_cmap($CMapfile);
                $data->{'u2g'} = $ccmap->{'u2g'};
                $data->{'g2u'} = $ccmap->{'g2u'};
            } else {
		# Hail Mary pass to use find_ms()
                $gmap = $font->{'cmap'}->read()->find_ms();
		if (! $gmap) {
	            die "No useful internal cmap found for $file\n";
		}
	    }
	} 
	# we SHOULD have a valid $gmap at this point
	# load up data->u2g and g2u from gmap (one 'Tables' entry)
        $gmap = $gmap->{'val'};
	foreach my $u (sort {$a<=>$b} keys %{$gmap}) {
	    my $uni = $u || 0;
	    $data->{'u2g'}->{$uni} = $gmap->{$uni};
	}
	$data->{'g2u'} = [ map { $_ || 0 } $font->{'cmap'}->read()->reverse() ];
    } # no .cmap or don't want to use it

    # 3/0 cmap table
    if ($data->{'issymbol'}) {
        map { $data->{'u2g'}->{$_} ||= $font->{'cmap'}->read()->ms_lookup($_) } (0xf000 .. 0xf0ff);
        map { $data->{'u2g'}->{$_ & 0xff} ||= $font->{'cmap'}->read()->ms_lookup($_) } (0xf000 .. 0xf0ff);
    }

    $data->{'e2n'} = [ map { $data->{'g2n'}->[$data->{'u2g'}->{$_} || 0] || '.notdef' } @{$data->{'e2u'}} ];

    $data->{'e2g'} = [ map { $data->{'u2g'}->{$_ || 0} || 0 } @{$data->{'e2u'}} ];
    $data->{'u2e'} = {};
    foreach my $n (reverse 0..255) {
        $data->{'u2e'}->{$data->{'e2u'}->[$n]} = $n unless defined $data->{'u2e'}->{$data->{'e2u'}->[$n]};
    }

    $data->{'u2n'} = { map { $data->{'g2u'}->[$_] => $data->{'g2n'}->[$_] } (0 .. (scalar @{$data->{'g2u'}} -1)) };

    $data->{'wx'} = [];
    foreach my $i (0..(scalar @{$data->{'g2u'}}-1)) {
	my $hmtx = $font->{'hmtx'}->read()->{'advance'}->[$i];
	if ($hmtx) {
            $data->{'wx'}->[$i] = int($hmtx * 1000/ $data->{'upem'});
	} else {
            $data->{'wx'}->[$i] = $data->{'missingwidth'};
	}
    }

    $data->{'kern'} = read_kern_table($font, $data->{'upem'}, $self);
    delete $data->{'kern'} unless defined $data->{'kern'};

    $data->{'fontname'} =~ s/\s+//og;
    $data->{'fontfamily'} =~ s/\s+//og;
    $data->{'apiname'} =~ s/\s+//og;
    $data->{'altname'} =~ s/\s+//og;
    $data->{'subname'} =~ s/\s+//og;

    $self->subsetByCId(0);

    return ($self, $data);
}

sub font { 
    return $_[0]->{' font'}; 
}

sub data { 
    return $_[0]->{' data'}; 
}

sub iscff { 
    return $_[0]->data()->{'iscff'}; 
}

sub haveKernPairs { 
    return $_[0]->data()->{'kern'}? 1: 0; 
}

sub kernPairCid {
    my ($self, $i1, $i2) = @_;

    return 0 if $i1 == 0 || $i2 == 0;
    return $self->data()->{'kern'}->{"$i1:$i2"} || 0;
}

sub subsetByCId {
    my $self = shift;
    my $g = shift;

    $self->data()->{'subset'} = 1;
    vec($self->data()->{'subvec'}, $g, 1) = 1;
    return if $self->iscff();
    # if loca table not defined in the font (offset into glyf table), is there
    # an alternative we can use, or just return undef? per Apple TT Ref:
    # The 'loca' table only used with fonts that have TrueType outlines (that 
    # is, a 'glyf' table). Fonts that have no TrueType outlines do not require 
    # a 'loca' table. 
    return if !defined $self->font()->{'loca'};
    if (defined $self->font()->{'loca'}->read()->{'glyphs'}->[$g]) {
        $self->font()->{'loca'}->read()->{'glyphs'}->[$g]->read();
        return map { vec($self->data()->{'subvec'}, $_, 1) = 1; } $self->font()->{'loca'}->{'glyphs'}->[$g]->get_refs();
    }
    return;
}

sub subvec {
    my $self = shift;
    return 1 if $self->iscff();
    my $g = shift;
    return vec($self->data()->{'subvec'}, $g, 1);
}

sub glyphNum { 
    my $self = shift;
    return $self->font()->{'maxp'}->read()->{'numGlyphs'}; 
}

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    my $f = $self->font();

    if ($self->iscff()) {
        $f->{'CFF '}->read_dat();
	# OTF files were always being written into PDF, even if noembed = 1
	if ($self->data()->{'noembed'} != 1) {
            $self->{' stream'} = $f->{'CFF '}->{' dat'};
	}
    } else {
        if ($self->data()->{'subset'} && !$self->data()->{'nosubset'}) {
	  # glyf table is optional, according to Apple
	  if (defined $f->{'glyf'}) {
            $f->{'glyf'}->read();
            for (my $i = 0; $i < $self->glyphNum(); $i++) {
                next if $self->subvec($i);
                $f->{'loca'}{'glyphs'}->[$i] = undef;
            }
          }
        }

	if ($self->data()->{'noembed'} != 1) {
            $self->{' stream'} = "";
            my $ffh;
            CORE::open($ffh, '+>', \$self->{' stream'});
            binmode($ffh, ':raw');
            $f->out($ffh, 'cmap', 'cvt ', 'fpgm', 'glyf', 'head', 'hhea', 'hmtx', 'loca', 'maxp', 'prep');
            $self->{'Length1'} = PDFNum(length($self->{' stream'}));
            CORE::close($ffh);
	}
    }

    return $self->SUPER::outobjdeep($fh, $pdf);
}

1;
