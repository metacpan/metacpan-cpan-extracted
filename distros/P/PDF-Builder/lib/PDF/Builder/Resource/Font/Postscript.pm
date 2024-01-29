package PDF::Builder::Resource::Font::Postscript;

use base 'PDF::Builder::Resource::Font';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

use Encode qw(:all);
use IO::File qw();

use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Resource::Font::Postscript - support routines for using PostScript fonts. Inherits from L<PDF::Builder::Resource::Font>

=head1 METHODS

=head2 new

    PDF::Builder::Resource::Font::Postscript->new($pdf, $psfile, %opts)

=over

Create an object for a PostScript font. Handles ASCII (.pfa), binary (.pfb), and
T1 (.t1) font files, as well as ASCII (.afm) and binary (.pfm) metrics files.

=back

=cut

sub new {
    my ($class, $pdf, $psfile, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-encode'} && !defined $opts{'encode'}) { $opts{'encode'} = delete($opts{'-encode'}); }
    if (defined $opts{'-afmfile'} && !defined $opts{'afmfile'}) { $opts{'afmfile'} = delete($opts{'-afmfile'}); }
    if (defined $opts{'-pfmfile'} && !defined $opts{'pfmfile'}) { $opts{'pfmfile'} = delete($opts{'-pfmfile'}); }
    if (defined $opts{'-xfmfile'} && !defined $opts{'xfmfile'}) { $opts{'xfmfile'} = delete($opts{'-xfmfile'}); }
    if (defined $opts{'-pdfname'} && !defined $opts{'pdfname'}) { $opts{'pdfname'} = delete($opts{'-pdfname'}); }
    if (defined $opts{'-nocomps'} && !defined $opts{'nocomps'}) { $opts{'nocomps'} = delete($opts{'-nocomps'}); }
    if (defined $opts{'-dokern'} && !defined $opts{'dokern'}) { $opts{'dokern'} = delete($opts{'-dokern'}); }

    my ($self);
    my ($data);

    if (defined $opts{'afmfile'}) {
        $data = $class->readAFM($opts{'afmfile'});
    } elsif (defined $opts{'pfmfile'}) {
        $data = $class->readPFM($opts{'pfmfile'});
    } elsif (defined $opts{'xfmfile'}) {
        $data = $class->readXFM($opts{'xfmfile'});
    } else {
        die "No proper font-metrics file specified for PostScript file '$psfile'.";
    }

    $class = ref $class if ref $class;
#   $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey().'~'.time());
    $self = $class->SUPER::new($pdf, $data->{'apiname'}.'PST1f'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);
    $self->{' data'} = $data;

    if ($opts{'pdfname'}) {
        $self->name($opts{'pdfname'});
    }

    $self->{'Subtype'} = PDFName("Type1");
    $self->{'FontDescriptor'} = $self->descrByData();
    if (-f $psfile) {
#       $self->{'BaseFont'} = PDFName(pdfkey().'+'.$self->fontname().'~'.time());
        $self->{'BaseFont'} = PDFName(pdfkey().'+'.$self->fontname());

        my ($l1,$l2,$l3, $stream) = $self->readPFAPFB($psfile);

        my $s = PDFDict();
        $self->{'FontDescriptor'}->{'FontFile'} = $s;
        $s->{'Length1'} = PDFNum($l1);
        $s->{'Length2'} = PDFNum($l2);
        $s->{'Length3'} = PDFNum($l3);
        $s->{'Filter'} = PDFArray(PDFName("FlateDecode"));
        $s->{' stream'} = $stream;
        if (defined $pdf) {
            $pdf->new_obj($s);
        }
    } else {
        $self->{'BaseFont'} = PDFName($self->fontname());
    }

    if (defined $opts{'encode'} && $opts{'encode'} =~ m/^utf/i) {
	die "Invalid multibyte encoding for psfont: $opts{'encode'}\n";
	# probably more encodings to check
    }
    $self->encodeByData($opts{'encode'});  # undef arg OK

    $self->{'-nocomps'} = 1 if $opts{'nocomps'};
    $self->{'-dokern'} = 1 if $opts{'dokern'};

    return $self;
}  # end of new()

sub readPFAPFB {
    my ($self, $file) = @_;
    my ($l1,$l2,$l3, $stream, $t1stream, @lines, $line, $head, $body, $tail);

    die "Cannot find PFA/PFB font file '$file' ..." unless -f $file;

    my $l = -s $file;
    $l1 = $l2 = $l3 = 0;
    $head = $body = $tail = '';

    my $type = 'pfa';
    if      ($file =~ m/\.pfb$/i) {
	$type = 'pfb';
    } elsif ($file =~ m/\.t1$/i) {
	$type = 't1';
    }

    open(my $inf, "<", $file) or die "$!: $file";
    binmode($inf,':raw');
    read($inf, $line, 2); # read 2 bytes to check header
    @lines = unpack('C*', $line);

    if      ($lines[0] == 0x80 && $lines[1] == 1) {  # .pfb
	# first 6 bytes are 80 01, 4 byte LSB $l1 head length
        read($inf, $line, 4);
        $l1 = unpack('V', $line); # length of head
        seek($inf, $l1, 1);
        read($inf, $line, 2);
        @lines = unpack('C*', $line);
	# at start of binary body, 6 bytes 80 01, 4 byte LSB $l2 body length
        if ($lines[0] == 0x80 && $lines[1] == 2) {
            read($inf, $line, 4);
            $l2 = unpack('V', $line);
        } else {
            die "Corrupt PFB in file '$file' at marker='2'.";
        }
        seek($inf, $l2, 1);
        read($inf, $line, 2);
        @lines = unpack('C*', $line);
	# after body, 6 bytes 80 01, 4 byte LSB $l3 tail length
        if ($lines[0] == 0x80 && $lines[1] == 1) {
            read($inf, $line, 4);
            $l3 = unpack('V', $line);
        } else {
            die "Corrupt PFB in file '$file' at marker='3'.";
        }
        seek($inf, 0, 0);
        @lines = <$inf>;
        $stream = join('', @lines);
	# each section, skip over 80 01, length; read in length of section
        $t1stream = substr($stream, 6, $l1);
        $t1stream .= substr($stream, 12+$l1, $l2);
        $t1stream .= substr($stream, 18+$l1+$l2, $l3);

    } elsif ($line eq '%!' && $type eq 'pfa') { 
        seek($inf, 0, 0);
        while ($line = <$inf>) {
            if      (!$l1) {  # $head empty or not complete yet?
                $head .= $line; # up through and including currentfile eexec
                if ($line=~/eexec$/) {
                    chomp($head);
                    $head .= "\x0d";
                    $l1 = length($head);
                }
            } elsif (!$l2) {  # $body empty or not complete yet?
                if ($line =~ /^0+$/) {  # at block of 0's, marking end of body
                    $l2 = length($body);
                    $tail = $line;
                } else {
                    chomp($line);
                    $body .= pack('H*', $line); # binary form of hex codes
                }
            } else {  # rest goes into the $tail
                $tail .= $line;
            }
        }
        $l3 = length($tail);
	# head = individual lines (^M terminated) with settings list
	# body = one long string of bytes (binary)
	# tail = 8 lines x 64 0's ^M terminated, cleartomark (no ^M)
        $t1stream = "$head$body$tail";

    } elsif ($line eq '%!' && $type eq 't1') { 
	# .t1
	my $pos;
        seek($inf, 0, 0);
        while (1) { # head
            read($inf, $line, 200);
	    $head .= $line;
	    $pos = index($head, "currentfile eexec\x0D");
	    if ($pos > 0) {
		# found end of head, so split there
		$body = substr($head, $pos+18);
		$head = substr($head, 0, $pos+18);
		$l1 = length($head);
		last;
	    }
	}
	while (1) { # body
            read($inf, $line, 200);
	    $body .= $line;
	    #                             1111111111222222222233333333334444444444555555555566666
	    #                    1234567890123456789012345678901234567890123456789012345678901234
	    $pos = index($body, "0000000000000000000000000000000000000000000000000000000000000000");
	    if ($pos > 0) {
		# found end of body, so split there
		$tail = substr($body, $pos);
		$body = substr($body, 0, $pos);
		$l2 = length($body);
		last;
	    }
	}
	while (1) { # remainder into tail
            read($inf, $line, 200);
	    $tail .= $line;
	    if (length($line) == 0) {
		# found end of tail
		$l3 = length($tail);
		last;
	    }
	}

	# head = individual lines (^M terminated) with settings list
	# body = one long string of bytes (binary)
	# tail = 8 lines x 64 0's ^M terminated, cleartomark (no ^M)
        $t1stream = "$head$body$tail";

    } else {
        die "Unsupported font-format in file '$file' at marker='1'.";
    }
    close($inf);

    return($l1,$l2,$l3, $t1stream);
}  # end of readPFAPFB()

# $datahashref = $self->readAFM( $afmfile );

sub readAFM {
    my ($self, $file) = @_;

    my $data = {};
    $data->{'wx'} = {};
    $data->{'bbox'} = {};
    $data->{'char'} = [];
    $data->{'firstchar'} = 255;
    $data->{'lastchar'} = 0;

    if (! -e $file) {
	die "File='$file' not found.";
    }
    open(my $afmf, "<", $file) or die "Can't find the AFM file for $file";
    local($/, $_) = ("\n", undef);  # ensure correct $INPUT_RECORD_SEPARATOR
    while ($_ = <$afmf>) {
        if (/^StartCharMetrics/ .. /^EndCharMetrics/) {
            # only lines that start with "C" or "CH" are parsed
            next unless $_ =~ /^CH?\s/;
            my ($ch)   = $_ =~ /^CH?\s+(\d+)\s*;/;
            $ch = $ch || 0;
            my ($name) = $_ =~ /\bN\s+(\.?\w+)\s*;/;
            my ($wx)   = $_ =~ /\bWX\s+(\d+)\s*;/;
            my ($bbox) = $_ =~ /\bB\s+([^;]+);/;
            $bbox =~ s/\s+$//;
            # Should also parse ligature data (format: L successor ligature)
            $data->{'avgwidth2'} += $wx ;
            $data->{'maxwidth'} = ($data->{'maxwidth'}||0) < $wx? $wx: $data->{'maxwidth'}||0;
            $data->{'wx'}->{$name} = $wx;
            $data->{'bbox'}->{$name} = [split(/\s+/,$bbox)];
            if ($ch > 0) {
                $data->{'char'}->[$ch] = $name;
            }
            $data->{'lastchar'} = $data->{'lastchar'} < $ch? $ch: $data->{'lastchar'};
            $data->{'firstchar'} = $data->{'firstchar'} > $ch? $ch: $data->{'firstchar'};
            next;
        } elsif (/^StartKernData/ .. /^EndKernData/) {
            $data->{'kern'} ||= {};
            if ($_ =~ m|^KPX\s+(\S+)\s+(\S+)\s+(\S+)\s*$|i) {
                $data->{'kern'}->{"$1:$2"} = $3;
            }
        } elsif (/^StartComposites/ .. /^EndComposites/) {
            $data->{'comps'} ||= {};
            if ($_ =~ m|^CC\s+(\S+)\s+(\S+)\s+;|i) {
                my ($name, $comp) = ($1, $2);
                my @cv = split(/;/, $_);
                shift @cv;
                my $rng = [];
                foreach (1..$comp) {
                    my @c1 = split(/\s+/,shift @cv);
                    push @{$rng}, $c1[1],$c1[2],$c1[3];
                }
                $data->{'comps'}->{$name} = $rng;
            }
        }
        last if $_ =~ /^EndFontMetrics/;
        if (/(^\w+)\s+(.*)/) {
            my($key, $val) = ($1, $2);
            $key = lc($key);
	    if (defined $data->{$key}) {
            #    $data->{$key} = [ $data->{$key} ] unless ref $data->{$key};
            #    push(@{$data->{$key}}, $val);
	    } else {
                $val =~ s/[\x00\x1f]+//g;
                $data->{$key} = $val;
            }
        } else {
            ## print STDERR "Can't parse: $_";
        }
    }
    close($afmf);
    unless (exists $data->{'wx'}->{'.notdef'}) {
        $data->{'wx'}->{'.notdef'} = 0;
        $data->{'bbox'}{'.notdef'} = [0, 0, 0, 0];
    }

    $data->{'avgwidth2'} /= scalar keys %{$data->{'bbox'}} ;
    $data->{'avgwidth2'} = int($data->{'avgwidth2'});

    $data->{'fontname'} =~ s/[\x00-\x20]+//og;
    ## $data->{'fontname'} =~ s/[^A-Za-z0-9]+//og;

    if (defined $data->{'fullname'}) {
        $data->{'altname'} = $data->{'fullname'};
    } else {
        $data->{'altname'} = $data->{'familyname'};
        $data->{'altname'} .= ' Italic' if $data->{'italicangle'} < 0;
        $data->{'altname'} .= ' Oblique' if $data->{'italicangle'} > 0;
        $data->{'altname'} .= ' '.$data->{'weight'};
    }
    $data->{'apiname'} = $data->{'altname'};
    $data->{'altname'} =~ s/[^A-Za-z0-9]+//og;

    $data->{'subname'} = $data->{'weight'};
    $data->{'subname'} .= ' Italic' if $data->{'italicangle'} < 0;
    $data->{'subname'} .= ' Oblique' if $data->{'italicangle'} > 0;
    $data->{'subname'} =~ s/[^A-Za-z0-9]+//og;

    $data->{'missingwidth'} ||= $data->{'avgwidth2'};

    $data->{'issymbol'} = 0;
    $data->{'fontbbox'} = [ split(/\s+/,$data->{'fontbbox'}) ];

    $data->{'apiname'} = join('', map { ucfirst(lc(substr($_, 0, 2))) } split m/[^A-Za-z0-9\s]+/, $data->{'apiname'});

    $data->{'flags'} = 34;

    $data->{'uni'} ||= [];
    foreach my $n (0..255) {
        $data->{'uni'}->[$n] = uniByName($data->{'char'}->[$n] || '.notdef') || 0;
    }
    delete $data->{'bbox'};

    return $data;
}  # end of readAFM()

sub readPFM {
    my ($self, $file) = @_;

    if (! -e $file) {
	die "pfmfile='$file' not found.";
    }
    my $fh = IO::File->new();
    my $data = {};

    $data->{'issymbol'} = 0;

    $data->{'wx'} = {};
    $data->{'bbox'} = {};
    $data->{'kern'} = {};
    $data->{'char'} = [];

    my $buf;
    open($fh, "<", $file) || return;
    binmode($fh, ':raw');
    read($fh, $buf, 117 + 30);

    my %df;
    # Packing structure for PFM Header
    (   $df{'Version'},
        $df{'Size'},
        $df{'Copyright'},
        $df{'Type'},
        $df{'Point'},
        $df{'VertRes'},
        $df{'HorizRes'},
        $df{'Ascent'},
        $df{'InternalLeading'},
        $df{'ExternalLeading'},
        $df{'Italic'},
        $df{'Underline'},
        $df{'StrikeOut'},
        $df{'Weight'},
#define FW_DONTCARE 0
#define FW_THIN 100
#define FW_EXTRALIGHT   200
#define FW_ULTRALIGHT   FW_EXTRALIGHT
#define FW_LIGHT    300
#define FW_NORMAL   400
#define FW_REGULAR  400
#define FW_MEDIUM   500
#define FW_SEMIBOLD 600
#define FW_DEMIBOLD FW_SEMIBOLD
#define FW_BOLD 700
#define FW_EXTRABOLD    800
#define FW_ULTRABOLD    FW_EXTRABOLD
#define FW_HEAVY    900
#define FW_BLACK    FW_HEAVY
        $df{'CharSet'},
#define ANSI_CHARSET    0
#define DEFAULT_CHARSET 1
#define SYMBOL_CHARSET  2
#define SHIFTJIS_CHARSET    128
#define HANGEUL_CHARSET 129
#define HANGUL_CHARSET  129
#define GB2312_CHARSET  134
#define CHINESEBIG5_CHARSET 136
#define GREEK_CHARSET   161
#define TURKISH_CHARSET 162
#define HEBREW_CHARSET  177
#define ARABIC_CHARSET  178
#define BALTIC_CHARSET  186
#define RUSSIAN_CHARSET 204
#define THAI_CHARSET    222
#define EASTEUROPE_CHARSET  238
#define OEM_CHARSET 255
#define JOHAB_CHARSET   130
#define VIETNAMESE_CHARSET  163
#define MAC_CHARSET 77
#define BALTIC_CHARSET 186
#define JOHAB_CHARSET 130
#define VIETNAMESE_CHARSET 163
        $df{'PixWidth'},
        $df{'PixHeight'},
        $df{'PitchAndFamily'},
#define DEFAULT_PITCH   0
#define FIXED_PITCH 1
#define VARIABLE_PITCH  2
#define MONO_FONT 8
#define FF_DECORATIVE   80
#define FF_DONTCARE 0
#define FF_MODERN   48
#define FF_ROMAN    16
#define FF_SCRIPT   64
#define FF_SWISS    32
        $df{'AvgWidth'},
        $df{'MaxWidth'},
        $df{'FirstChar'},
        $df{'LastChar'},
        $df{'DefaultChar'},
        $df{'BreakChar'},
        $df{'WidthBytes'},
        $df{'Device'},
        $df{'Face'},
        $df{'BitsPointer'},
        $df{'BitsOffset'},
        $df{'SizeFields'},        # Two bytes, the size of extension section
        $df{'ExtMetricsOffset'},  # Four bytes, offset value to the 'Extended Text Metrics' section
        $df{'ExtentTable'},       # Four bytes Offset value to the Extent Table
        $df{'OriginTable'},       # Four bytes 0
        $df{'PairKernTable'},     # Four bytes 0
        $df{'TrackKernTable'},    # Four bytes 0
        $df{'DriverInfo'},        # Four bytes Offset value to the PostScript font name string
        $df{'Reserved'},          # Four bytes 0
    ) = unpack("vVa60vvvvvvvCCCvCvvCvvCCCCvVVVV vVVVVVVV",$buf); # PFM Header + Ext

    seek($fh, $df{Device}, 0);
    read($fh, $buf, 250);

    ($df{'postScript'}) = unpack("Z*", $buf);
    $buf = substr($buf, length($df{'postScript'})+1, 250);
    ($df{'windowsName'}) = unpack("Z*", $buf);
    $buf = substr($buf, length($df{'windowsName'})+1, 250);
    ($df{'psName'}) = unpack("Z*", $buf);

    seek($fh, $df{'ExtMetricsOffset'}, 0);
    read($fh, $buf, 52);

    (   $df{'etmSize'},
        $df{'PointSize'},
        $df{'Orientation'},
        $df{'MasterHeight'},
        $df{'MinScale'},
        $df{'MaxScale'},
        $df{'MasterUnits'},
        $df{'CapHeight'},
        $df{'xHeight'},
        $df{'LowerCaseAscent'},
        $df{'LowerCaseDescent'},
        $df{'Slant'},
        $df{'SuperScript'},
        $df{'SubScript'},
        $df{'SuperScriptSize'},
        $df{'SubScriptSize'},
        $df{'UnderlineOffset'},
        $df{'UnderlineWidth'},
        $df{'DoubleUpperUnderlineOffset'},
        $df{'DoubleLowerUnderlineOffset'},
        $df{'DoubleUpperUnderlineWidth'},
        $df{'DoubleLowerUnderlineWidth'},
        $df{'StrikeOutOffset'},
        $df{'StrikeOutWidth'},
        $df{'KernPairs'},
        $df{'KernTracks'} ) = unpack('v*', $buf);

    $data->{'fontname'} = $df{'psName'};
    $data->{'fontname'} =~ s/[^A-Za-z0-9]+//og;
    $data->{'apiname'} = join('', map { ucfirst(lc(substr($_, 0, 2))) } split m/[^A-Za-z0-9\s]+/, $df{'windowsName'});

    $data->{'upem'} = 1000;

    $data->{'fontbbox'} = [-100,-100, $df{'MaxWidth'},$df{'Ascent'}];

    $data->{'stemv'} = 0;
    $data->{'stemh'} = 0;

    $data->{'lastchar'} = $df{'LastChar'}||0;  # running max
    $data->{'firstchar'} = $df{'FirstChar'}||255;  # running min

    $data->{'missingwidth'} = $df{'AvgWidth'};
    $data->{'maxwidth'} = $df{'MaxWidth'};
    $data->{'ascender'} = $df{'Ascent'};
    $data->{'descender'} = -$df{'LowerCaseDescent'};

    $data->{'flags'} = 0;
    # FixedPitch 1
    $data->{'flags'} |= 1 if (($df{'PitchAndFamily'} & 1) || ($df{'PitchAndFamily'} & 8)) && !($df{'PitchAndFamily'} & 2);
    # Serif 2
    $data->{'flags'} |= 2 if ($df{'PitchAndFamily'} & 16) && !($df{'PitchAndFamily'} & 32);
    # Symbolic 4
    $data->{'flags'} |= 4 if $df{'PitchAndFamily'} & 80;
    # Script 8
    $data->{'flags'} |= 8 if $df{'PitchAndFamily'} & 64;
    # Nonsymbolic   32
    $data->{'flags'} |= 32 unless $df{'PitchAndFamily'} & 80;
    # Italic 64
    $data->{'flags'} |= 64 if $df{'Italic'};

    #bit 17 AllCap
    #bit 18 SmallCap
    #bit 19 ForceBold

    $data->{'capheight'} = $df{'CapHeight'};
    $data->{'xheight'} = $df{'xHeight'};

    $data->{'uni'} = [ unpack('U*', decode('cp1252', pack('C*',(0..255)))) ];
    $data->{'char'} = [ map { nameByUni($_) || '.notdef' } @{$data->{'uni'}} ];

    $data->{'italicangle'} = -12*$df{'Italic'};
    $data->{'isfixedpitch'} = ($df{'PitchAndFamily'} & 8) || ($df{'PitchAndFamily'} & 1);
    $data->{'underlineposition'} = -$df{'UnderlineOffset'};
    $data->{'underlinethickness'} = $df{'UnderlineWidth'};

    seek($fh, $df{'ExtentTable'}, 0);

    foreach my $k ($df{'FirstChar'} .. $df{'LastChar'}) {
        read($fh, $buf, 2);
        my ($wx) = unpack('v', $buf);
        $data->{'wx'}->{$data->{'char'}->[$k]} = $wx;
#       print STDERR "e: c=$k n='".$data->{'char'}->[$k]."' wx='$wx'\n";
    }
    $data->{'pfm'} = \%df;
    close($fh);

    return $data;
}  # end of readPFM()

sub readXFM {
    my ($class, $xfmfile) = @_;

    die "Cannot find font '$xfmfile' ..." unless -f $xfmfile;

    my $data = {};

    return $data;
}

1;
