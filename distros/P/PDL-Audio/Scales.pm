package PDL::Audio::Scales;

use PDL::Lite;

require Exporter;

@EXPORT = qw(scale_list get_scale);

$VERSION = 1.0;

=head1 NAME

PDL::Audio::Scales - Over 1200 musical scales in PDL format.

=head1 SYNOPSIS

 use PDL::Audio::Scales;

 @names = scale_list;

 # returns [1 1 1.5 5 7 8 8.5 1.2]
 $scale = get_scale 'arist_chromrej';

 ($scale, $desc) = get_scale 'arist_chromrej';
 # sets $desc to "Aristoxenos Rejected Chromatic, 6 + 3 + 21 parts 7"

=head1 EXAMPLE

The following script will play all the scales (unmodified, it will run for hours) :)

 use PDL::Audio;
 use PDL::Audio::Scales;

 sub osc {
    my ($dur,$freq) = @_;
    (gen_asymmetric_fm $dur, $freq, 0.9, 0.6)*
    (gen_env $dur, [0, 1, 2, 9, 10], [0, 1, 0.6, 0.3, 0]);
 }

 for (scale_list) {
    my ($scale, $desc) = get_scale($_);
    my @mix;
    my $i;
    print "$_ [$desc] $scale\n";
    my $l = $scale->list;
    for (($scale*880)->list) {
       push @mix, ($i*0.2*44100    , osc 0.3*44100, $_/44100);
       push @mix, ($l*0.2*44100+0.1, osc 0.8*44100, $_/44100);
       $i++;
    }
    (audiomix @mix)->scale2short->playaudio;
 }

=head1 AUTHOR

This file was translated from clm-2/scales.cl (common lisp music). the original comments are:

   ;;; This file contains more than 1100 musical scales, each one
   ;;; a separate list variable, containing notes as cents or ratios.
   ;;; The first note of 1/1 or 0.0 cents is implied.  The data was
   ;;; translated from ftp://ftp.cs.ruu.nl/pub/MIDI/DOC/scales.zip
   ;;; (a collection of around 1100 files) by Bill Schottstaedt
   ;;; 24-Aug-95.
   ;;;
   ;;; These scales were brought together mostly by John Chalmers
   ;;; (non12@cyber.net) and Manuel Op de Coul (coul@ezh.nl).
   ;;;
   ;;; The reference for the Greek scales in this archive is:
   ;;; John H. Chalmers: Divisions of the Tetrachord, 1993.
   ;;; Frog Peak, Box 1052, Lebanon NH 03766, USA.
   ;;;
   ;;; If you know of scales not in this archive please send them to
   ;;; Manuel Op de Coul (coul@ezh.nl).

   ;;; since doing this translation, another 100 or so scales have been added:
   ;;;
   ;;; ----------------
   ;;; Date: Thu, 12 Oct 1995 06:58:42 -0700
   ;;; From: COUL@ezh.nl (Manuel Op de Coul)
   ;;; Subject: Updated scale archive
   ;;; 
   ;;; The scale archive with the collections of John Chalmers and myself
   ;;; has been updated and contains now over 1250 scales.
   ;;; The scales.doc file contains the complete listing. It's found here:
   ;;; 
   ;;; http://www.cs.ruu.nl/pub/MIDI/DOC/scales.doc (readme file, ASCII)
   ;;; http://www.cs.ruu.nl/pub/MIDI/DOC/scales.zip (ZIP file, binary)
   ;;; 
   ;;; Use the "-a" option while unzipping. The size of the ZIP file is about
   ;;; 284 Kb. FTP is possible also from ftp.cs.ruu.nl.
   ;;; The file format of the scales is that of my tuning program Scala,
   ;;; which I hope will be available soon. The files are text files so also
   ;;; usable without it. 
   ;;; 
   ;;; Manuel Op de Coul    coul@ezh.nl
   ;;; ----------------

=head1 SEE ALSO

perl(1), L<PDL>, L<PDL::Audio>.

=cut

sub _parse {
   while (<DATA>) {
      /^#(.*)$/ or die "$_";
      my $desc = $1;
      <DATA> =~ /^(\S+)\s+([0-9\/. ]+)$/ or die "$_";
      my ($name, $def) = ($1,$2);
      my @def;
      $name =~ y/A-Z -/a-z__/;
      for (split / /, $def) {
         if (m%/%) {
            push @def, eval $_;
         } else {
            push @def, 2 ** ($_ / 1200);
         }
      }
      $scales{$name} = [pdl(@def), $desc];
   }
}

sub scale_list() {
   _parse unless %scales;
   sort keys %scales;
}

sub get_scale($) {
   _parse unless %scales;
   wantarray ? @{$scales{$_[0]}} : $scales{$_[0]}->[0];
}

1;

__DATA__
#5 out of 19-tET 5 
05-19 252.632 505.263 757.895 1010.526 1200.0
#7 out of 19-tET, major 7 
07-19 189.474 378.947 505.263 694.737 884.211 1073.684 1200.0
#8 out of 19-tET 8 
08-19 126.316 315.789 442.105 568.421 757.895 884.211 1010.526 1200.0
#10 out of 19-tET. For 9 out of 19 discard degree 3 10 
10-19 126.316 252.632 315.789 442.105 568.421 694.737 821.053 947.368 1073.684 1200.0
#11 out of 19-tET 11 
11-19 126.316 189.474 315.789 442.105 568.421 631.579 757.895 884.211 1010.526 1073.684 1200.0
#12 out of 19-tET scale from Mandelbaum's dissertation 12 
12-19 63.158 189.474 252.632 378.947 505.263 568.421 694.737 757.895 884.211 947.368 1073.684 1200.0
#13 out of 19-tET 13 
13-19 126.316 189.474 315.789 378.947 505.263 568.421 694.737 757.895 884.211 947.368 1073.684 1136.842 1200.0
#14 out of 19-tET 14 
14-19 63.158 189.474 252.632 315.789 442.105 505.263 568.421 694.737 757.895 821.053 947.368 1010.526 1136.842 1200.0
#2 out of 1/7 1/5 1/3 1 3 5 7 CPS 19 
19-any 16/15 35/32 8/7 7/6 6/5 5/4 21/16 4/3 7/5 10/7 3/2 32/21 8/5 5/3 12/7 7/4 64/35 15/8 2/1
#1.3.5.7.9.11.13 2)7 21-any, 1.3 tonic 21 
21-any 33/32 13/12 9/8 55/48 7/6 39/32 5/4 21/16 65/48 11/8 35/24 143/96 3/2 77/48 13/8 5/3 7/4 11/6 15/8 91/48 2/1
#12 and 18-tET mixed 24 
24-36 66.667 100.000 133.333 200.000 266.667 300.000 333.333 400.000 466.667 500.000 533.333 600.000 666.667 700.000 733.333 800.000 866.667 900.000 933.333 1000.000 1066.667 1100.000 1133.333 1200.0
#12 and 15-tET mixed 24 
24-60 80.000 100.000 160.000 200.000 240.000 300.000 320.000 400.000 480.000 500.000 560.000 600.000 640.000 700.000 720.000 800.000 880.000 900.000 960.000 1000.000 1040.000 1100.000 1120.000 1200.0
#6)8 28-any from 1.3.5.7.9.11.13.15, only 26 tones 26 
28-any 65/64 15/14 13/12 195/176 65/56 13/11 39/32 5/4 195/154 13/10 65/48 15/11 39/28 13/9 65/44 3/2 65/42 13/8 5/3 195/112 39/22 65/36 13/7 15/8 65/33 2/1
#30/29 x 29/28 x 28/27 plus 6/5 9 
30-29-min3 30/29 15/14 10/9 4/3 3/2 45/29 45/28 5/3 2/1
#3)8 56-any from 1.3.5.7.9.11.13.15, 1.3.5 tonic, only 48 notes 48 
56-any 65/64 33/32 1001/960 21/20 13/12 35/32 11/10 143/128 9/8 91/80 7/6 143/120 77/64 39/32 99/80 5/4 77/60 13/10 21/16 429/320 11/8 7/5 45/32 91/64 231/160 117/80 143/96 3/2 91/60 99/64 63/40 77/48 13/8 33/20 27/16 273/160 55/32 7/4 143/80 9/5 117/64 11/6 15/8 91/48 77/40 39/20 63/32 2/1
#1.3.5.7.11.13.17.19 4)8 70-any, tonic 1.3.5.7 70 
70-any 323/320 2717/2688 143/140 247/240 3553/3360 17/16 13/12 2431/2240 209/192 4199/3840 11/10 247/224 187/168 221/192 323/280 187/160 19/16 143/120 2717/2240 17/14 209/168 4199/3360 2431/1920 143/112 247/192 13/10 209/160 221/168 3553/2688 187/140 323/240 19/14 11/8 221/160 2717/1920 17/12 323/224 2431/1680 247/168 143/96 209/140 247/160 187/120 4199/2688 11/7 221/140 19/12 3553/2240 2717/1680 13/8 187/112 323/192 17/10 143/84 46189/26880 209/120 247/140 143/80 2431/1344 11/6 221/120 3553/1920 13/7 209/112 4199/2240 19/10 323/168 187/96 221/112 2/1
#Ancient Greek Aeolic 7 
aeolic 9/8 32/27 4/3 3/2 128/81 16/9 2/1
#Xylophone from West Africa 7 
african 152.000 287.000 533.000 724.000 890.000 1039.000 1200.0
#Agricola's Monochord 12 
agricola 135/128 9/8 1215/1024 81/64 4/3 45/32 3/2 405/256 27/16 16/9 243/128 2
#Al-Farabi Syn Chrom 7 
al-farabi 16/15 8/7 4/3 3/2 8/5 12/7 2/1
#Al-Farabi's Chromatic permuted 7 
AL-FARABI_chrom 16/15 56/45 4/3 3/2 8/5 28/15 2/1
#Al-Farabi's Diatonic 7 
al-farabi_diat 8/7 64/49 4/3 3/2 12/7 96/49 2/1
#Permuted form of Al-Farabi's reduplicated 10/9 diatonic genus 7 
AL-FARABI_diat2 10/9 6/5 4/3 3/2 5/3 9/5 2/1
#Dorian mode of Al-Farabi's 10/9 Diatonic 7 
AL-FARABI_dor 27/25 6/5 4/3 3/2 81/50 9/5 2/1
#Dorian mode of Al-Farabi's Diatonic 7 
AL-FARABI_DOR2 49/48 7/6 4/3 3/2 49/32 7/4 2/1
#Terry Riley's Harp of New Albion scale 12 
albion 16/15 9/8 6/5 5/4 4/3 64/45 3/2 8/5 5/3 16/9 15/8 2
#Wendy Carlos' Alpha scale with perfect fifth divided in nine 18 
alpha 78.000 156.000 234.000 312.000 390.000 468.000 546.000 624.000 702.000 780.000 858.000 936.000 1014.000 1092.000 1170.000 1248.000 1326.000 1404.000
#Wendy Carlos' Alpha prime scale with perfect fifth divided by eightteen 36 
alphap 39.000 78.000 117.000 156.000 195.000 234.000 273.000 312.000 351.000 390.000 429.000 468.000 507.000 546.000 585.000 624.000 663.000 702.000 741.000 780.000 819.000 858.000 897.000 936.000 975.000 1014.000 1053.000 1092.000 1131.000 1170.000 1209.000 1248.000 1287.000 1326.000 1365.000 1404.000
#Arabic 17-tone Pythagorean mode 17 
arabic 256/243 65536/59049 9/8 32/27 8192/6561 81/64 4/3 1024/729 262144/177147 3/2 128/81 32768/19683 27/16 16/9 4096/2187 1048576/531441 2/1
#From Fortuna. Try C or G major 12 
arabic1 100.000 200.000 300.000 350.000 500.000 600.000 700.000 800.000 900.000 1000.000 1050.000 1200.0
#From Fortuna. Try C or F minor 12 
arabic2 100.000 150.000 300.000 400.000 500.000 600.000 700.000 18/11 900.000 1000.000 1100.000 1200.0
#Archytas chromatic 7 
arch_chrom 28/27 9/8 4/3 3/2 14/9 27/16 2/1
#Archytas's Diatonic, also Lyra tuning 7 
ARCH_DIAT 28/27 32/27 4/3 3/2 14/9 16/9 2/1
#Dorian mode of Archytas's Chromatic with added 16/9 8 
arch_dor 28/27 9/8 4/3 3/2 14/9 16/9 27/16 2/1
#Archytas Enharmonic 7 
arch_enh 28/27 16/15 4/3 3/2 14/9 8/5 2/1
#Archytas's enharmonic with added 16/9 8 
ARCH_ENH2 28/27 16/15 4/3 3/2 14/9 16/9 8/5 2/1
#Complex 9 of p. 113 based on Archytas's Enharmonic 7 
arch_enh3 28/27 16/15 9/7 4/3 48/35 12/7 2/1
#Permutation of Archytas's Enharmonic with the 36/35 first 7 
ARCH_ENHp 36/35 16/15 4/3 3/2 54/35 8/5 2/1
#Complex 6 of p. 113 based on Archytas's Enharmonic 7 
arch_enht 36/35 28/27 16/15 9/7 4/3 27/14 2/1
#Complex 5 of p. 113 based on Archytas's Enharmonic 7 
ARCH_ENHt2 28/27 16/15 5/4 4/3 15/8 35/18 2/1
#Complex 1 of p. 113 based on Archytas's Enharmonic 7 
ARCH_ENHT3 28/27 16/15 784/729 448/405 4/3 112/81 2/1
#Complex 8 of p. 113 based on Archytas's Enharmonic 7 
arch_enht4 28/27 16/15 5/4 35/27 4/3 5/3 2/1
#Complex 10 of p. 113 based on Archytas's Enharmonic 7 
ARCH_ENHT5 245/243 28/27 16/15 35/27 4/3 35/18 2/1
#Complex 2 of p. 113 based on Archytas's Enharmonic 7 
arch_enht6 28/27 16/15 448/405 256/225 4/3 64/45 2/1
#Complex 11 of p. 113 based on Archytas's Enharmonic 7 
arch_enht7 36/35 28/27 16/15 192/175 4/3 48/35 2/1
#Multiple Archytas 12 
arch_mult 28/27 16/15 5/4 9/7 4/3 112/81 3/2 14/9 8/5 15/8 27/14 2/1
#Archytas/Ptolemy Hybrid 1 12 
arch_ptol 28/27 16/15 10/9 32/27 4/3 112/81 3/2 14/9 8/5 5/3 16/9 2/1
#Archytas/Ptolemy Hybrid 2 12 
arch_ptol2 28/27 16/15 9/8 6/5 4/3 112/81 3/2 14/9 8/5 27/16 9/5 2/1
#Archytas Septimal 12 
arch_sept 28/27 16/15 9/8 32/27 4/3 112/81 3/2 14/9 8/5 27/16 16/9 2/1
#Ariel 1 12 
ariel1 27/25 9/8 6/5 5/4 4/3 25/18 3/2 8/5 5/3 9/5 15/8 2
#Ariel 2 12 
ariel2 16/15 10/9 6/5 5/4 4/3 25/18 3/2 8/5 5/3 9/5 15/8 2
#Ariel's 12-tone JI scale 12 
ariel3 16/15 10/9 32/27 100/81 4/3 25/18 3/2 8/5 5/3 16/9 50/27 2/1
#Ariel's 31-tone system 31 
ariel_31 128/125 25/24 16/15 625/576 9/8 144/125 75/64 6/5 625/512 5/4 32/25 125/96 4/3 512/375 25/18 36/25 375/256 3/2 192/125 25/16 8/5 1024/625 5/3 128/75 125/72 16/9 1152/625 15/8 48/25 125/64 2/1
#PsAristo Arch. Enharmonic, 4 + 3 + 23 parts, similar to Archytas' enharmonic 7 
arist_archenh 66.667 116.667 500.000 700.000 766.667 816.667 1200.0
#Dorian Mode, Neo-Chromatic tetrachord, 6 + 18 + 6 parts 7 
arist_chrom 100.000 400.000 500.000 700.000 800.000 1100.000 1200.0
#Dorian Mode, a 1:2 Chromatic, 8 + 18 + 4 parts 7 
arist_chrom2 133.333 433.333 500.000 700.000 833.333 1133.333 1200.0
#PsAristo 3 Chromatic, 7 + 7 + 16 parts 7 
arist_chrom3 445/416 230/201 295/221 442/295 928/579 1159/676 2/1
#PsAristo Chromatic, 5.5 + 5.5 + 19 parts 7 
ARIST_CHROM4 91.667 183.333 500.000 700.000 791.667 883.333 1200.0
#PsAristo Ch/Enh, 3 + 9 + 18 parts 7 
arist_chromenh 50.000 200.000 500.000 700.000 770.000 900.000 1200.0
#Aristo's Inverted Chromatic, Dorian Mode 18 + 6 + 6 parts 7 
arist_chrominv 300.000 400.000 500.000 700.000 1000.000 1100.000 1200.0
#Aristoxenos Rejected Chromatic, 6 + 3 + 21 parts 7 
arist_chromrej 100.000 150.000 500.000 700.000 800.000 850.000 1200.0
#Unmelodic Chromatic, genus of Aristoxenos, Dorian Mode, 4.5 + 3.5 + 22 parts 7 
ARIST_CHROMunm 75.000 133.333 500.000 700.000 775.000 833.333 1200.0
#Phrygian octave species on E, 12 + 6 + 12 parts 7 
arist_diat 200.000 300.000 500.000 700.000 900.000 1000.000 1200.0
#PsAristo 2 Diatonic, 7 + 11 + 12 parts 7 
arist_diat2 116.667 300.000 500.000 700.000 816.667 1000.000 1200.0
#PsAristo Diat 3, 9.5 + 9.5 + 11 parts 7 
ARIST_DIAT3 158.333 316.667 500.000 700.000 858.333 1016.667 1200.0
#PsAristo Diatonic, 8 + 8 + 14 parts 7 
arist_diat4 133.333 266.667 500.000 700.000 833.333 966.667 1200.0
#PsAristo Redup. Diatonic, 14 + 2 + 14 parts 7 
arist_diatdor 233.333 266.667 500.000 700.000 933.333 966.667 1200.0
#Lydian octave species on E, Major Mode, 12 + 12 + 6 parts 7 
arist_diatinv 200.000 400.000 500.000 700.000 900.000 1100.000 1200.0
#Aristo Redup. Diatonic, Dorian Mode, 14 + 14 + 2 parts 7 
arist_diatred 233.333 466.667 500.000 700.000 933.333 1166.667 1200.0
#PsAristo 2 Redup. Diatonic 2, 4 + 13 + 13 parts 7 
ARIST_DIATRED2 66.667 283.333 500.000 700.000 766.667 983.333 1200.0
#PsAristo 3 Redup. Diatonic, 8 + 11 + 11 parts 7 
ARIST_DIATRED3 133.333 316.667 500.000 700.000 833.333 1016.667 1200.0
#Aristoxenos's Enharmonion, Dorian Mode 7 
arist_enh 50.000 100.000 500.000 700.000 750.000 800.000 1200.0
#PsAristo 2 Enharmonic, 3.5 + 3.5 + 23 parts 7 
arist_enh2 58.333 116.667 500.000 700.000 758.333 816.667 1200.0
#PsAristo Enharmonic, 2.5 + 2.5 + 25 parts 7 
arist_enh3 41.667 83.333 500.000 700.000 741.667 783.333 1200.0
#Aristoxenos's Chromatic Hemiolion, Dorian Mode 7 
arist_hemchrom 75.000 150.000 500.000 700.000 775.000 850.000 1200.0
#PsAristo C/H Chromatic, 4.5 + 7.5 + 18 parts 7 
ARIST_HEMCHROM2 75.000 200.000 500.000 700.000 775.000 900.000 1200.0
#Dorian mode of Aristoxenos' Hemiolic Chromatic according to Ptolemy's interpret 7 
ARIST_HEMCHROM3 80/77 40/37 4/3 3/2 120/77 60/37 2/1
#PsAristo 2nd Hyperenharmonic, 37.5 + 37.5 + 425 7 
arist_hypenh2 37.500 75.000 500.000 700.000 737.500 775.000 1200.0
#PsAristo 3 Hyperenharmonic, 1.5 + 1.5 + 27 parts 7 
arist_hypenh3 25.000 50.000 500.000 700.000 725.000 750.000 1200.0
#PsAristo 4 Hyperenharmonic, 2 + 2 + 26 parts 7 
arist_hypenh4 33.333 66.667 500.000 700.000 733.333 766.667 1200.0
#PsAristo Hyperenharmonic, 23 + 23 + 454 7 
ARIST_HYPENH5 23.000 46.000 500.000 700.000 723.000 746.000 1200.0
#Dorian mode of Aristoxenos's Intense Diatonic according to Ptolemy 7 
arist_intdiat 20/19 20/17 4/3 3/2 30/19 30/17 2/1
#Permuted Aristoxenos's Enharmonion, 3 + 24 + 3 parts 7 
ARIST_PENH2 50.000 450.000 500.000 700.000 750.000 1150.000 1200.0
#Permuted Aristoxenos's Enharmonion, 24 + 3 + 3 parts 7 
arist_penh3 400.000 450.000 500.000 700.000 1100.000 1150.000 1200.0
#PsAristo 2 Chromatic, 6.5 + 6.5 + 17 parts 7 
arist_pschrom2 108.333 216.667 500.000 700.000 808.333 916.667 1200.0
#Aristoxenos's Chromatic Malakon, Dorian Mode 7 
arist_softchrom 66.667 133.333 500.000 700.000 766.667 833.333 1200.0
#PsAristo S. Chromatic, 6 + 16.5 + 9.5 parts 7 
arist_softchrom2 100.000 375.000 500.000 700.000 800.000 1075.000 1200.0
#Aristoxenos's Chromatic Malakon, 9.5 + 16.5 + 6 parts 7 
arist_SOFTCHROM3 125.000 400.000 500.000 700.000 825.000 1100.000 1200.0
#PsAristo S. Chromatic, 6 + 7.5 + 16.5 parts 7 
ARIST_SOFTCHROM4 100.000 225.000 500.000 700.000 800.000 925.000 1200.0
#Dorian mode of Aristoxenos' Soft Chromatic according to Ptolemy's interpretati 7 
ARIST_SOFTCHROM5 30/29 15/14 4/3 3/2 45/29 45/28 2/1
#Aristoxenos's Diatonon Malakon, Dorian Mode 7 
arist_softdiat 100.000 250.000 500.000 700.000 800.000 950.000 1200.0
#Dorian Mode, 6 + 15 + 9 parts 7 
ARIST_SOFTDIAT2 100.000 350.000 500.000 700.000 800.000 1050.000 1200.0
#Dorian Mode, 9 + 15 + 6 parts 7 
arist_SOFTDIAT3 150.000 400.000 500.000 700.000 850.000 1000.000 1200.0
#Dorian Mode, 9 + 6 + 15 parts 7 
arist_softdiat4 150.000 250.000 500.000 700.000 850.000 950.000 1200.0
#Dorian Mode, 15 + 6 + 9 parts 7 
arist_softdiat5 250.000 350.000 500.000 700.000 950.000 1050.000 1200.0
#Dorian Mode, 15 + 9 + 6 parts 7 
arist_softdiat6 250.000 400.000 500.000 700.000 950.000 1100.000 1200.0
#Dorian mode of Aristoxenos's Soft Diatonic according to Ptolemy 7 
ARIST_SOFTDIAT7 20/19 8/7 4/3 3/2 30/19 12/7 2/1
#Aristoxenos's Chromatic Syntonon, Dorian Mode 7 
arist_synchrom 100.000 200.000 500.000 700.000 800.000 900.000 1200.0
#Aristoxenos's Diatonon Syntonon, Dorian Mode 7 
arist_syndiat 100.000 300.000 500.000 700.000 800.000 1000.000 1200.0
#Aristoxenos's Unnamed Chromatic, Dorian Mode 7 
arist_unchrom 66.667 200.000 500.000 700.000 766.667 900.000 1200.0
#Dorian Mode, a 1:2 Chromatic, 8 + 4 + 18 parts 7 
arist_unchrom2 133.333 200.000 500.000 700.000 833.333 900.000 1200.0
#Dorian Mode, a 1:2 Chromatic, 18 + 4 + 8 parts 7 
ARIST_UNCHROM3 300.000 366.667 500.000 700.000 1000.000 1066.667 1200.0
#Dorian Mode, a 1:2 Chromatic, 18 + 8 + 4 parts 7 
ARIST_UNCHROM4 300.000 433.333 500.000 700.000 1000.000 1133.333 1200.0
#Artificial Nam System 9 
art_nam 11/10 17/14 36/29 4/3 27/20 3/2 33/20 38/21 2/1
#Athanasopoulos's Byzantine Liturgical mode Chromatic 7 
ATHAN_CHROM 150.000 400.000 500.000 700.000 850.000 1100.000 1200.0
#Athanasopoulos's Byzantine Liturgical mode 2nd Chromatic 7 
athan_chrom2 100.000 400.000 500.000 700.000 800.000 1100.000 1200.0
#5/4 C.I. again 8 
auftetf 99/98 33/32 11/10 11/8 16/11 72/49 3/2 8/5
#Linear Division of the 11/8, duplicated on the 16/11 8 
augteta 44/41 22/19 44/35 11/8 16/11 64/41 32/19 64/35
#Linear Division of the 7/5, duplicated on the 10/7 8 
augtetaa 14/13 7/6 14/11 7/5 10/7 20/13 5/3 20/11
#Harmonic mean division of 11/8 8 
augtetb 88/85 44/41 22/19 11/8 16/11 96/85 64/41 32/19
#11/10 C.I. 8 
augtetc 15/14 15/13 5/4 11/8 16/11 120/77 240/143 20/11
#11/9 C.I. 8 
augtetd 27/26 27/25 9/8 11/8 16/11 216/143 432/275 18/11
#5/4 C.I. 8 
augtete 33/32 33/31 11/10 11/8 16/11 3/2 48/31 8/5
#9/8 C.I. 8 
augtetg 33/31 33/29 11/9 11/8 16/11 48/31 48/29 16/9
#9/8 C.I. A gapped version of this scale is called AugTetI 8 
augteth 33/31 11/10 11/9 11/8 16/11 48/31 8/5 16/9
#9/8 C.I. comprised of 11:10:9:8 subharmonic series on 1 and 8:9:10:11 on 16/11 6 
augtetj 11/10 11/9 11/8 16/11 18/11 20/11
#9/8 C.I. This is the converse form of AugTetJ 6 
augtetk 9/8 5/4 11/8 16/11 8/5 16/9
#9/8 C.I. This is the harmonic form of AugTetI 6 
augtetl 9/8 5/4 11/8 16/11 18/11 20/11
#Average Bac System 7 
average 10/9 20/17 4/3 3/2 5/3 30/17 2/1
#Avicenna's soft diatonic 7 
avicenna 10/9 8/7 4/3 3/2 5/3 12/7 2/1
#Dorian mode a chromatic genus of Avicenna 7 
AVICENNA_chrom 36/35 8/7 4/3 3/2 54/35 12/7 2/1
#Dorian Mode, a 1:2 Chromatic, 4 + 18 + 8 parts 7 
AVICENNA_CHROM2 66.667 366.667 500.000 700.000 766.667 1066.667 1200.0
#Avicenna's Chromatic permuted 7 
AVICENNA_CHROM3 10/9 35/27 4/3 3/2 5/3 35/18 2/1
#Dorian mode a soft diatonic genus of Avicenna 7 
AVICENNA_diat 14/13 7/6 4/3 3/2 21/13 7/4 2/1
#Dorian mode of Avicenna's (Ibn Sina) Enharmonic genus 7 
AVICENNA_enh 40/39 16/15 4/3 3/2 20/13 8/5 2/1
#Awraamoff Septimal Just 12 
awraamoff 9/8 8/7 6/5 5/4 21/16 4/3 3/2 8/5 12/7 7/4 15/8 2/1
#Bagpipe Tuning 12 
bagpipe 117/115 146/131 196/169 89/73 141/106 81/59 150/101 125/82 139/84 205/116 11/6 2/1
#Highland Bagpipe, from Acustica4: 231 (1954) J.M.A Lenihan and S. McNeill 7 
BAGPIPEA 9/8 5/4 27/20 3/2 5/3 9/5 2/1
#Pythagorean scale with fifth average from Chinese bamboo tubes 23 
bamboo 48.000 102.000 156.000 204.000 258.000 312.000 366.000 414.000 468.000 522.000 570.000 624.000 678.000 726.000 780.000 834.000 882.000 936.000 990.000 1044.000 1092.000 1146.000 1200.0
#Barbour's #1 Chromatic 7 
BARBOUR_chrom1 55/54 10/9 4/3 3/2 55/36 5/3 2/1
#Barbour's #2 Chromatic 7 
barbour_chrom2 40/39 10/9 4/3 3/2 20/13 5/3 2/1
#Barbour's #3 Chromatic 7 
BARBOUR_CHROM3 64/63 8/7 4/3 3/2 32/21 12/7 2/1
#permuted Barbour's #3 Chromatic 7 
BARBOUR_CHROM3p 9/8 8/7 4/3 3/2 27/16 12/7 2/1
#permuted Barbour's #3 Chromatic 7 
BARBOUR_CHROM3P2 7/6 32/27 4/3 3/2 7/4 16/9 2/1
#Barbour's #4 Chromatic 7 
BARBOUR_CHROM4 81/80 9/8 4/3 3/2 243/160 27/16 2/1
#permuted Barbour's #4 Chromatic 7 
BARBOUR_CHROM4p 10/9 9/8 4/3 3/2 5/3 27/16 2/1
#permuted Barbour's #4 Chromatic 7 
BARBOUR_CHROM4P2 32/27 6/5 4/3 3/2 16/9 9/5 2/1
#Barnes-Bach, variation of Young, likely meant for Das Wohltemperierte Klavier 12 
barnes 256/243 196.198 32/27 392.072 4/3 592.200 698.025 128/81 894.223 16/9 1090.245 1200.0
#Guitar scale for Partch's Barstow 18 
barstow 16/15 11/10 10/9 9/8 8/7 6/5 5/4 4/3 11/8 10/7 3/2 8/5 5/3 12/7 9/5 11/6 15/8 2/1
#1)7 7-any from 1.3.5.7.9.11.13 and Schlesinger's "Bastard" Hypodorian Harmonia 7 
bastard 8/7 16/13 4/3 16/11 8/5 16/9 2/1
#Belet, Brian 1992 Proceedings of the ICMC pp.158-161. 13 
belet 16/15 10/9 9/8 6/5 5/4 4/3 11/8 3/2 8/5 13/8 7/4 15/8 2/1
#Wendy Carlos' Beta scale with perfect fifth divided by eleven 22 
beta 63.800 127.600 191.400 255.200 319.000 382.800 446.600 510.400 574.200 638.000 701.800 765.600 829.400 893.200 957.000 1020.800 1084.600 1148.400 1212.200 1276.000 1339.800 1403.600
#Wendy Carlos' Beta prime scale with perfect fifth divided by twentytwo 44 
betap 31.900 63.800 95.700 127.600 159.500 191.400 223.300 255.200 287.100 319.000 350.900 382.800 414.700 446.600 478.500 510.400 542.300 574.200 606.100 638.000 669.900 701.800 733.700 765.600 797.500 829.400 861.300 893.200 925.100 957.000 988.900 1020.800 1052.700 1084.600 1116.500 1148.400 1180.300 1212.200 1244.100 1276.000 1307.900 1339.800 1371.700 1403.600
#Blue Farabi? 7 
bl-farabi 9/8 45/32 131/90 3/2 15/8 31/16 2/1
#Another tuning from Al Farabi, c700 AD 7 
blue_farabi 9/8 45/32 131/90 3/2 15/8 31/16 2
#Boethius's Chromatic. The CI is 19/16 7 
boeth_chrom 256/243 64/57 4/3 3/2 128/81 32/19 2/1
#Boethius's Enharmonic, with a CI of 81/64 and added 16/9 8 
boeth_enh 512/499 256/243 4/3 3/2 768/499 16/9 128/81 2/1
#Boomsliter & Creel basic set of their referential tuning. 12 
Boomsliter 9/8 7/6 6/5 5/4 4/3 7/5 3/2 8/5 5/3 7/4 9/5 2/1
#Bouzourk 8 
bouzourk 65536/59049 8192/6561 4/3 262144/177147 3/2 27/16 4096/2187 1200.0
#Bulgarian bagpipe tuning 12 
bulgarian 66.000 202.000 316.000 399.000 509.000 640.000 706.000 803.000 910.000 1011.000 1092.000 1200.0
#Warren Burt 19-tone Forks. Interval 5(3): pp. 13+23 Winter 1986-87 19 
burt-forks 28/27 16/15 10/9 9/8 6/5 5/4 9/7 4/3 7/5 10/7 3/2 14/9 8/5 5/3 16/9 9/5 15/8 27/14 2/1
#W. Burt's 13diatsub #1 12 
burt1 26/25 13/12 26/23 13/11 13/10 26/19 13/9 27/17 13/8 26/15 13/7 2/1
#W. Burt's 19enhsub #10 12 
burt10 76/75 38/37 76/73 19/18 19/14 38/27 19/13 152/103 76/51 152/101 38/25 2/1
#W. Burt's 19enhharm #11 12 
burt11 25/19 101/76 51/38 103/76 26/19 27/19 28/19 36/19 73/38 37/19 75/38 2/1
#W. Burt's 19diatharm #12 12 
burt12 22/19 23/19 24/19 25/19 26/19 27/19 28/19 32/19 34/19 36/19 37/19 2/1
#W. Burt's 23diatsub #13 12 
burt13 23/22 23/21 46/41 23/20 23/18 23/17 23/16 23/15 23/14 46/27 23/13 2/1
#W. Burt's 23enhsub #14 12 
burt14 92/91 46/45 92/89 23/22 23/18 23/17 23/16 92/63 46/31 92/61 23/15 2/1
#W. Burt's 23enhharm #15 12 
burt15 30/23 61/46 31/23 63/46 32/23 34/23 36/23 44/23 89/46 45/23 91/46 2/1
#W. Burt's 23diatharm #16 12 
burt16 26/23 27/23 28/23 30/23 32/23 34/23 36/23 40/23 41/23 42/23 44/23 2/1
#W. Burt's 13enhsub #2 12 
burt2 104/103 52/51 104/101 26/25 13/10 104/79 4/3 104/77 26/19 52/33 13/7 2/1
#W. Burt's 13enhharm #3 12 
burt3 14/13 33/26 19/13 77/52 3/2 79/52 20/13 25/13 101/52 51/26 103/52 2/1
#W. Burt's 13diatharm #4, see his post 3/30/94 in Tuning Digest #57 12 
burt4 14/13 15/13 16/13 17/13 18/13 19/13 20/13 22/13 23/13 24/13 25/13 2/1
#W. Burt's 17diatsub #5 12 
burt5 17/16 17/15 17/14 17/13 17/16 34/23 17/11 34/21 17/10 34/19 17/9 2/1
#W. Burt's 17enhsub #6 12 
burt6 68/67 34/33 68/65 17/16 17/12 34/23 17/11 136/87 68/43 8/5 34/21 2/1
#W. Burt's 17enhharm #7 12 
burt7 21/17 5/4 43/34 87/68 22/17 23/17 24/17 32/17 65/34 33/17 67/34 2/1
#W. Burt's 17diatharm #8 12 
burt8 18/17 19/17 20/17 21/17 22/17 23/17 24/17 26/17 28/17 30/17 32/17 2/1
#W. Burt's 19diatsub #9 12 
burt9 38/37 19/18 19/17 19/16 19/14 38/27 19/13 38/25 19/12 38/23 19/11 2/1
#Byzantine Palace mode 7 
byz_palace 18/17 9/7 4/3 3/2 18/11 9/5 2/1
#Carlos Harmonic 12 
carlos_harm 17/16 9/8 19/16 5/4 21/16 11/8 3/2 13/8 27/16 7/4 15/8 2/1
#Carlos Super Just 12 
carlos_super 17/16 9/8 6/5 5/4 4/3 11/8 3/2 13/8 5/3 7/4 15/8 2/1
#Catler 24-tone JI from "Over and Under the 13 Limit," 1/1 3(3) 24 
catler 33/32 16/15 9/8 8/7 7/6 6/5 128/105 16/13 5/4 21/16 4/3 11/8 45/32 16/11 3/2 8/5 13/8 5/3 27/16 7/4 16/9 24/13 15/8 2/1
#A 12-tone just tuning by the 17th c inventor and philosopher Salomon de Caus 12 
caus 126/121 10/9 75/64 5/4 4/3 25/18 3/2 25/16 5/3 16/9 15/8 2
#Equal temperament with very good 6/5 and 13/8 13 
cet105 105.000 210.001 315.001 420.001 525.002 630.002 735.002 840.003 945.003 1050.003 1155.004 1260.004 11/5
#13th root of e 13 
cet133 133.172 266.344 399.516 532.687 665.859 799.031 932.203 1065.375 1198.547 1331.719 1464.890 1598.062 1731.234
#24th root of 7 24 
cet140 140.368 280.736 421.103 561.471 701.839 842.207 982.574 1122.942 1263.310 1403.678 1544.045 1684.413 1824.781 1965.150 2105.517 2245.885 2386.253 2526.621 2666.988 2807.356 2947.724 3088.092 3228.459 7/1
#6.625 tET. The 16/3 is the so-called Kidjel Ratio promoted by Kidjel in 60's 16 
cet181 181.128 362.256 543.383 724.511 905.639 1086.767 1267.895 1449.023 1630.150 1811.278 1992.406 2173.534 2354.663 2535.790 2716.918 16/3
#7th root of 11/5 7 
cet195 195.001 390.001 585.002 780.002 975.003 1170.004 11/5
#11th root of 4/3 11 
cet45 45.277 90.554 135.830 181.107 226.384 271.661 316.938 362.215 407.491 452.768 4/3
#30th root of 3 or stretched 19-tET 30 
cet63 63.399 126.797 190.196 253.594 316.993 380.391 443.790 507.188 570.587 633.985 697.384 760.782 824.181 887.579 950.978 1014.376 1077.775 1141.173 1204.572 1267.970 1331.369 1394.767 1458.166 1521.564 1584.963 1648.361 1711.760 1775.158 1838.557 3/1
#88 steps by Gary Morrison 14 
cet88 88.000 176.000 264.000 352.000 440.000 528.000 616.000 704.000 792.000 880.000 968.000 1056.000 1144.000 1232.000
#Heavenly Chimes 3 
chimes 32/29 1/2 16/29
#A scale found on an ancient Chinese bronze instrument from the 3rd century BC 7 
chin_bronze 8/7 6/5 5/4 4/3 3/2 5/3 2/1
#Chinese Flute / Ellis 7 
chin_flute 178.000 339.000 448.000 662.000 888.000 1103.000 2/1
#Observed tuning from chinese sheng or mouth organ 7 
chin_sheng 210.000 338.000 4/3 715.000 908.000 1040.000 2/1
#Choquel/Barbour/Marpurg? 12 
choquel 25/24 9/8 6/5 5/4 4/3 45/32 3/2 25/16 5/3 20/11 15/8 2/1
#Chordal Notes S&H 40 
chordal 3/2 5/4 7/4 9/4 11/4 13/4 15/4 15/4 15/8 17/8 19/8 19/16 2/1 4/3 8/5 8/7 16/9 16/11 16/13 16/15 7/3 7/2 10/3 8/3 5/2 12/5 12/7 11/9 13/9 17/10 17/5 9/7 9/8 16/9 11/7 7/6 7/5 10/7 6/5 9/5
#Tonos-15 Chromatic 7 
CHROM15 15/14 15/13 15/11 3/2 30/19 5/3 2/1
#Inverted Chromatic Tonos-15 Harmonia 7 
chrom15_inv 6/5 19/15 4/3 22/15 26/15 28/15 2/1
#A harmonic form of the Chromatic Tonos-15 inverted 7 
CHROM15_INV2 16/15 17/15 4/3 22/15 23/15 8/5 2/1
#Tonos-17 Chromatic 7 
chrom17 17/16 17/15 17/12 17/11 34/21 17/10 2/1
#Conjunct Tonos-17 Chromatic 7 
chrom17_con 17/16 17/15 17/12 34/23 17/11 17/9 2/1
#Tonos-19 Chromatic 7 
chrom19 19/18 19/17 19/14 19/13 38/25 19/12 2/1
#Conjunct Tonos-19 Chromatic 7 
chrom19_con 19/18 19/17 19/14 38/27 19/13 19/11 2/1
#Tonos-21 Chromatic 7 
chrom21 21/20 21/19 21/16 3/2 14/9 21/13 2/1
#Inverted Chromatic Tonos-21 Harmonia 7 
chrom21_inv 26/21 9/7 4/3 32/21 38/21 40/21 2/1
#Inverted harmonic form of the Chromatic Tonos-21 7 
CHROM21_INV2 16/15 8/7 4/3 32/21 34/21 12/7 2/1
#Tonos-23 Chromatic 7 
chrom23 23/22 23/21 23/18 23/16 23/15 23/14 2/1
#Conjunct Tonos-23 Chromatic 7 
chrom23_con 23/22 23/21 23/18 23/17 23/16 23/13 2/1
#Tonos-25 Chromatic 7 
chrom25 50/47 25/22 25/18 25/16 5/3 25/14 2/1
#Conjunct Tonos-25 Chromatic 7 
chrom25_con 50/47 25/22 25/18 25/17 25/16 25/13 2/1
#Tonos-27 Chromatic 7 
chrom27 18/17 9/8 27/20 3/2 27/17 27/16 2/1
#Inverted Chromatic Tonos-27 Harmonia 7 
chrom27_inv 32/27 34/27 4/3 40/27 16/9 17/9 2/1
#Inverted harmonic form of the Chromatic Tonos-27 7 
chrom27_inv2 28/27 29/27 4/3 40/27 14/9 5/3 2/1
#Tonos-29 Chromatic 7 
chrom29 29/28 29/27 29/22 29/20 29/19 29/18 2/1
#Conjunct Tonos-29 Chromatic 7 
chrom29_con 29/28 29/27 29/22 29/21 29/20 29/16 2/1
#Tonos-31 Chromatic. Tone 24 alternates with 23 as MESE or A 8 
chrom31 31/29 31/27 31/24 31/23 31/22 31/21 31/20 2/1
#Conjunct Tonos-31 Chromatic 8 
chrom31_con 31/29 31/27 31/24 31/23 31/22 31/21 31/18 2/1
#Tonos-33 Chromatic. A variant is 66 63 60 48 7 
chrom33 33/31 33/29 11/8 3/2 11/7 33/20 2/1
#Conjunct Tonos-33 Chromatic 7 
chrom33_con 33/31 33/29 11/8 33/23 3/2 11/6 2/1
#Intense Chromatic genus 4 + 8 + 18 parts 7 
chrom_int 66.667 200.000 500.000 700.000 766.667 900.000 2/1
#New Chromatic genus 4.5 + 9 + 16.5 7 
chrom_new 75.000 225.000 500.000 700.000 775.000 925.000 2/1
#New Chromatic genus 14/3 + 28/3 + 16 parts 7 
chrom_new2 77.778 233.333 500.000 700.000 777.778 933.333 2/1
#100/81 Chromatic. This genus is a good approximation to the soft chromatic 7 
chrom_soft 27/26 27/25 4/3 3/2 81/52 81/50 2/1
#1:2 Soft Chromatic 7 
CHROM_SOFT2 44.444 133.333 500.000 700.000 744.444 833.333 2/1
#Soft chromatic genus is from K. Schlesinger's modified Mixolydian Harmonia 7 
chrom_soft3 28/27 14/13 4/3 3/2 14/9 21/13 2/1
#Strong 32/27 Chromatic 6 
CHROM_STR 14/13 16/13 4/3 56/39 3/2 2/1
#Double-tie circular mirroring with common pivot of 4:5:6:7 13 
CKRING1 8/7 7/6 6/5 5/4 4/3 7/5 10/7 3/2 8/5 5/3 12/7 7/4 2/1
#Double-tie circular mirroring with common pivot of 3:5:7:9 13 
ckring2 10/9 7/6 6/5 9/7 4/3 7/5 10/7 3/2 14/9 5/3 12/7 9/5 2/1
#13-tone 5-limit Tritriadic Cluster 13 
cluster 25/24 9/8 6/5 5/4 4/3 36/25 3/2 25/16 8/5 5/3 9/5 15/8 2/1
#Six-Tone Triadic Cluster 4:5:6 6 
cluster6a 5/4 4/3 3/2 5/3 15/8 2/1
#Six-Tone Triadic Cluster 4:6:5 6 
cluster6b 6/5 5/4 3/2 8/5 15/8 2/1
#Six-Tone Triadic Cluster 3:4:5 6 
cluster6c 10/9 6/5 4/3 8/5 5/3 2/1
#Six-Tone Triadic Cluster 3:5:4 6 
cluster6d 10/9 5/4 4/3 3/2 5/3 2/1
#Six-Tone Triadic Cluster 5:6:8 6 
CLUSTER6e 6/5 5/4 3/2 8/5 48/25 2/1
#Six-Tone Triadic Cluster 5:8:6 6 
CLUSTER6f 6/5 4/3 8/5 5/3 48/25 2/1
#Six-Tone Triadic Cluster 4:5:7 6 
CLUSTER6g 35/32 8/7 5/4 10/7 7/4 2/1
#Six-Tone Triadic Cluster 4:7:5 6 
CLUSTER6h 35/32 5/4 7/5 8/5 7/4 2/1
#Six-Tone Triadic Cluster 5:6:7 6 
CLUSTER6i 6/5 7/5 10/7 42/25 12/7 2/1
#Six-Tone Triadic Cluster 5:7:6 6 
CLUSTER6j 7/6 6/5 7/5 5/3 42/25 2/1
#Eight-Tone Triadic Cluster 4:5:6 8 
cluster8a 9/8 5/4 4/3 45/32 3/2 5/3 15/8 2/1
#Eight-Tone Triadic Cluster 4:6:5 8 
cluster8b 75/64 6/5 5/4 3/2 25/16 8/5 15/8 2/1
#Eight-Tone Triadic Cluster 3:4:5 8 
cluster8c 10/9 6/5 4/3 25/18 8/5 5/3 50/27 2/1
#Eight-Tone Triadic Cluster 3:5:4 8 
cluster8d 10/9 5/4 4/3 40/27 3/2 5/3 16/9 2/1
#Eight-Tone Triadic Cluster 5:6:8 8 
cluster8e 6/5 5/4 32/25 3/2 192/125 8/5 48/25 2/1
#Eight-Tone Triadic Cluster 5:8:6 8 
CLUSTER8f 144/125 6/5 4/3 36/25 8/5 5/3 48/25 2/1
#Eight-Tone Triadic Cluster 4:5:7 8 
CLUSTER8g 35/32 8/7 5/4 10/7 49/32 7/4 245/128 2/1
#Eight-Tone Triadic Cluster 4:7:5 8 
CLUSTER8h 35/32 5/4 175/128 7/5 25/16 8/5 7/4 2/1
#Eight-Tone Triadic Cluster 5:6:7 8 
CLUSTER8i 147/125 6/5 7/5 10/7 42/25 12/7 49/25 2/1
#Eight-Tone Triadic Cluster 5:7:6 8 
CLUSTER8j 126/125 7/6 6/5 7/5 36/25 5/3 42/25 2/1
#Colonna 1 12 
colonna1 25/24 10/9 85/72 5/4 4/3 25/18 3/2 55/36 5/3 85/48 15/8 2/1
#Colonna 2 12 
colonna2 25/24 9/8 6/5 5/4 4/3 7/5 3/2 8/5 5/3 9/5 11/6 2/1
#Cruciform Lattice 12 
cruciform 9/8 75/64 6/5 5/4 4/3 45/32 3/2 25/16 8/5 5/3 15/8 2/1
#This set of 19 ratios in 5-limit JI is for his megalyra family 19 
darreg 25/24 16/15 10/9 9/8 75/64 6/5 5/4 4/3 45/32 64/45 3/2 25/16 8/5 5/3 27/16 225/128 9/5 15/8 2/1
#Ivor Darreg's Mixed Enneatonic, a mixture of chromatic and enharmonic 9 
darreg_ennea 50.000 100.000 200.000 500.000 700.000 750.000 800.000 900.000 2/1
#Ivor Darreg's Mixed JI Genus (Archytas Enh, Ptolemy Soft Chrom, Didymos Chrom 9 
darreg_genus 28/27 16/15 10/9 4/3 3/2 14/9 8/5 5/3 2/1
#Darreg's Mixed JI Genus 2 (Archytas Enharmonic and Chromatic Genera) 9 
DARREG_GENUS2 28/27 16/15 9/8 4/3 3/2 14/9 8/5 27/16 2/1
#Ivor Darreg's Mixed Enh & Chrom Scale 9 
darreg_mix 50.000 100.000 200.000 500.000 700.000 750.000 800.000 900.000 2/1
#11-limit system from Gary David, 1967 22 
david11 33/32 21/20 12/11 9/8 7/6 77/64 5/4 14/11 21/16 11/8 7/5 63/44 3/2 14/9 77/48 18/11 27/16 7/4 11/6 15/8 21/11 2/1
#De Caus (a mode of Ellis's duodene) 12 
de_caus 25/24 10/9 75/64 5/4 4/3 25/18 3/2 25/16 5/3 16/9 15/8 2
#2)5 Dekany 1.3.5.7.11 (1.3 tonic) 10 
dekany 55/48 7/6 5/4 11/8 35/24 77/48 5/3 7/4 11/6 2/1
#3)5 Dekany 1.3.5.7.9 (1.3.5.7.9 tonic) 10 
dekany2 16/15 8/7 6/5 4/3 48/35 32/21 8/5 12/7 16/9 2/1
#Diacycle on 20/13, 13/10; there are also nodes at 3/2, 4/3; 13/9, 18/13 23 
diacycle13 40/39 20/19 40/37 10/9 8/7 20/17 40/33 5/4 40/31 4/3 40/29 10/7 40/27 20/13 30/19 60/37 5/3 12/7 30/17 20/11 15/8 60/31 2/1
#15-limit Diamond + 2nd ratios. See Novaro, 1927, Sistema Natural... 59 
diamond15 33/32 16/15 15/14 14/13 13/12 12/11 11/10 10/9 9/8 8/7 15/13 7/6 13/11 32/27 6/5 39/32 11/9 16/13 5/4 14/11 9/7 13/10 21/16 4/3 15/11 11/8 18/13 7/5 45/32 64/45 10/7 13/9 16/11 22/15 3/2 32/21 20/13 14/9 11/7 8/5 13/8 18/11 64/39 5/3 27/16 22/13 12/7 26/15 7/4 16/9 9/5 20/11 11/6 24/13 13/7 28/15 15/8 64/33 2/1
#9-limit Diamond 19 
diamond9 10/9 9/8 8/7 7/6 6/5 5/4 9/7 4/3 7/5 10/7 3/2 14/9 8/5 5/3 12/7 7/4 16/9 9/5 2/1
#13-tone Octave Modular Diamond, based on Archytas's Enharmonic 13 
diamond_mod 36/35 28/27 16/15 5/4 9/7 4/3 3/2 14/9 8/5 15/8 27/14 35/18 2/1
#Tetrachord Modular Diamond based on Archytas's Enharmonic 8 
diamond_tetr 28/27 16/15 5/4 9/7 35/27 4/3 48/35 2/1
#10-tone Diaphonic Cycle 10 
diaphonic_10 18/17 9/8 6/5 9/7 18/13 3/2 8/5 12/7 24/13 2/1
#12-tone Diaphonic Cycle, conjunctive form on 3/2 and 4/3 12 
diaphonic_12 21/20 21/19 7/6 21/17 21/16 7/5 3/2 30/19 5/3 30/17 15/8 2/1
#2nd 12-tone Diaphonic Cycle, conjunctive form on 10/7 and 7/5 12 
diaphonic12_2 21/20 21/19 7/6 21/17 21/16 7/5 28/19 14/9 28/17 7/4 28/15 2/1
#D5-tone Diaphonic Cycle 5 
diaphonic_5 8/7 4/3 3/2 12/7 2/1
#7-tone Diaphonic Cycle, disjunctive form on 4/3 and 3/2 7 
diaphonic_7 12/11 6/5 4/3 16/11 8/5 16/9 2/1
#This genus is from K.S's diatonic Hypodorian harmonia 7 
diat13 16/15 16/13 4/3 3/2 8/5 24/13 2/1
#Tonos-15 Diatonic and its own trite synemmenon Bb 8 
diat15 15/13 5/4 15/11 10/7 3/2 5/3 15/8 2/1
#Inverted Tonos-15 Harmonia, a harmonic series from 15 from 30. 8 
diat15_inv 16/15 6/5 4/3 7/5 22/15 8/5 26/15 2/1
#Tonos-17 Diatonic and its own trite synemmenon Bb 8 
diat17 17/15 17/13 17/12 34/23 17/11 17/10 17/9 2/1
#Tonos-19 Diatonic and its own trite synemmenon Bb 8 
diat19 19/18 19/16 19/14 38/27 19/13 19/12 19/11 2/1
#Tonos-21 Diatonic and its own trite synemmenon Bb 8 
diat21 21/19 7/6 21/16 7/5 3/2 21/13 7/4 2/1
#Inverted Tonos-21 Harmonia, a harmonic series from 21 from 42. 8 
diat21_inv 8/7 26/21 4/3 10/7 32/21 12/7 38/21 2/1
#Tonos-23 Diatonic and its own trite synemmenon Bb 8 
diat23 23/21 23/20 23/18 23/17 23/16 23/14 23/13 2/1
#Tonos-25 Diatonic and its own trite synemmenon Bb 8 
diat25 25/22 5/4 25/18 25/17 25/16 25/14 25/13 2/1
#Tonos-27 Diatonic and its own trite synemmenon Bb 8 
diat27 9/8 9/7 27/20 27/19 3/2 27/16 27/14 2/1
#Inverted Tonos-27 Harmonia, a harmonic series from 27 from 54 8 
diat27_inv 28/27 32/27 4/3 13/9 40/27 14/9 16/9 2/1
#Tonos-29 Diatonic and its own trite synemmenon Bb 8 
diat29 29/26 29/24 29/22 29/21 29/20 29/18 29/16 2/1
#Tonos-31 Diatonic. The disjunctive and conjunctive diatonic forms are the same 8 
diat31 31/28 31/26 31/24 31/23 31/22 31/20 31/18 2/1
#Tonos-33 Diatonic. The conjunctive form is 23 (Bb instead of B) 20 18 33/2 8 
diat33 11/10 11/9 11/8 33/23 3/2 33/20 11/6 2/1
#Diatonic- Chromatic, on the border between the chromatic and diatonic genera 7 
diat_chrom 15/14 15/13 4/3 3/2 45/28 45/26 2/1
#Dorian Diatonic, 2 part Diesis 7 
diat_dies2 33.333 300.000 500.000 700.000 733.333 1000.000 2/1
#Dorian Diatonic, 5 part Diesis 7 
diat_dies5 83.333 300.000 500.000 700.000 783.333 1000.000 2/1
#Diat. + Enharm. Diesis, Dorian Mode 7 
diat_enh 50.000 300.000 500.000 700.000 750.000 1000.000 2/1
#Diat. + Enharm. Diesis, Dorian Mode 3 + 12 + 15 parts 7 
DIAT_ENH2 50.000 250.000 500.000 700.000 750.000 950.000 2/1
#Diat. + Enharm. Diesis, Dorian Mode, 15 + 3 + 12 parts 7 
diat_enh3 250.000 300.000 500.000 700.000 950.000 1000.000 2/1
#Diat. + Enharm. Diesis, Dorian Mode, 15 + 12 + 3 parts 7 
diat_enh4 250.000 450.000 500.000 700.000 950.000 1150.000 2/1
#Dorian Mode, 12 + 15 + 3 parts 7 
DIAT_ENH5 200.000 450.000 500.000 700.000 900.000 1150.000 2/1
#Dorian Mode, 12 + 3 + 15 parts 7 
DIAT_ENH6 200.000 250.000 500.000 700.000 900.000 950.000 2/1
#Equal Diatonic, Islamic form, similar to 11/10 x 11/10 x 400/363 7 
diat_eq 166.667 333.333 500.000 700.000 866.667 1033.333 2/1
#Diatonic scale with ratio between whole and half tone the Golden Section 7 
diat_gold 192.429 384.858 503.785 696.215 888.644 1081.072 2
#Diat. + Hem. Chrom. Diesis, Another genus of Aristoxenos, Dorian Mode 7 
diat_hemchrom 75.000 300.000 500.000 700.000 775.000 1000.000 2/1
#Diat. + Soft Chrom. Diesis, Another genus of Aristoxenos, Dorian Mode 7 
diat_sofchrom 66.667 300.000 500.000 700.000 766.667 1000.000 2/1
#Soft Diatonic genus 5 + 10 + 15 parts 7 
diat_soft 83.333 250.000 500.000 700.000 783.333 950.000 2/1
#Soft Diatonic genus with equally divided Pyknon; Dorian Mode 7 
diat_soft2 125.000 250.000 500.000 700.000 825.000 950.000 2/1
#Dorian mode of a diatonic genus with reduplicated 11/10 7 
diatred11 11/10 121/100 4/3 3/2 33/20 363/200 2/1
#Didymus Chromatic 7 
didy_chrom 16/15 10/9 4/3 3/2 8/5 5/3 2/1
#permuted Didymus Chromatic 7 
DIDY_CHROM1 16/15 32/25 4/3 3/2 8/5 48/25 2/1
#Didymos's Chromatic, 6/5 x 25/24 x 16/15 7 
DIDY_CHROM2 6/5 5/4 4/3 3/2 9/5 15/8 2/1
#Didymos's Chromatic, 25/24 x 16/15 x 6/5 7 
DIDY_CHROM3 25/24 10/9 4/3 3/2 25/16 5/3 2/1
#Didymus Diatonic 7 
didy_diat 16/15 32/27 4/3 3/2 8/5 16/9 2/1
#Didymus Diatonic inverse 7 
didy_diatinv 9/8 5/4 4/3 3/2 27/16 15/8 2/1
#permuted Didymus Enharmonic 7 
DIDY_EN2 256/243 16/15 4/3 3/2 128/81 8/5 2/1
#Dorian mode of Didymos's Enharmonic 7 
didy_enh 32/31 16/15 4/3 3/2 48/31 8/5 2/1
#A heptatonic form on the 9/7 7 
dimteta 27/25 27/23 9/7 14/9 42/25 42/23 2/1
#A pentatonic form on the 9/7 5 
dimtetb 9/8 9/7 14/9 7/4 2/1
#Divided Fifth #1, From Schlesinger, see Chapter 8, p. 160 5 
div_fifth1 24/23 12/11 4/3 3/2 2/1
#Divided Fifth #2, From Schlesinger, see Chapter 8, p. 160 5 
div_fifth2 16/15 8/7 4/3 3/2 2/1
#Divided Fifth #3, From Schlesinger, see Chapter 8, p. 160 5 
div_fifth3 28/27 7/6 4/3 3/2 2/1
#Divided Fifth #4, From Schlesinger, see Chapter 8, p. 160 5 
div_fifth4 21/20 7/6 21/16 3/2 2/1
#Divided Fifth #5, From Schlesinger, see Chapter 8, p. 160 5 
div_fifth5 11/10 11/9 11/8 11/7 2/1
#Double-tie circular mirroring of 4:5:6:7 12 
dkring1 21/20 7/6 6/5 49/40 5/4 7/5 3/2 42/25 12/7 7/4 9/5 2/1
#Double-tie circular mirroring of 3:5:7:9 12 
dkring2 21/20 7/6 63/50 9/7 27/20 7/5 3/2 14/9 49/30 5/3 9/5 2/1
#Degenerate eikosany 3)6 from 1.3.5.9.15.45 tonic 1.3.15 12 
dodeceny 135/128 9/8 75/64 6/5 5/4 4/3 45/32 3/2 5/3 27/16 15/8 2/1
#Dorian Chromatic Tonos 24 
dorian_chrom 16/15 8/7 32/27 64/53 16/13 4/3 16/11 32/21 64/41 8/5 16/9 2/1 32/15 16/7 64/27 128/53 32/13 8/3 32/11 64/21 128/41 16/5 32/9 4/1
#Schlesinger's Dorian Harmonia in the chromatic genus 7 
dorian_chrom2 22/21 11/10 11/8 11/7 44/27 22/13 2/1
#A harmonic form of Schlesinger's Chromatic Dorian inverted 7 
dorian_chrominv 24/23 12/11 14/11 16/11 17/11 18/11 2/1
#Dorian Diatonic Tonos 24 
DORIAN_DIAT 16/15 8/7 16/13 32/25 4/3 32/23 16/11 8/5 32/19 16/9 32/17 2/1 32/15 16/7 32/13 64/25 8/3 64/23 32/11 16/5 64/19 32/9 64/17 4/1
#Schlesinger's Dorian Harmonia, a subharmonic series through 13 from 22 8 
dorian_diat2 11/10 11/9 11/8 22/15 11/7 22/13 11/6 2/1
#A Dorian Diatonic with its own trite synemmenon replacing paramese 7 
dorian_diatcon 11/10 11/9 11/8 22/15 11/7 11/6 2/1
#Dorian Enharmonic Tonos 24 
DORIAN_ENH 16/15 8/7 64/55 128/109 32/27 4/3 16/11 64/43 128/85 32/21 16/9 2/1 32/15 16/7 128/55 256/109 64/27 8/3 32/11 128/43 256/85 64/21 32/9 4/1
#Schlesinger's Dorian Harmonia in the enharmonic genus 7 
dorian_enh2 44/43 22/21 11/8 11/7 44/27 22/13 2/1
#A harmonic form of Schlesinger's Dorian enharmonic inverted 7 
DORIAN_ENHinv 48/47 24/23 14/11 16/11 3/2 17/11 2/1
#Inverted Schlesinger's Dorian Harmonia, a harmonic series from 11 from 22 8 
dorian_inv 12/11 13/11 14/11 15/11 16/11 18/11 20/11 2/1
#Schlesinger's Dorian Harmonia in the pentachromatic genus 7 
DORIAN_PENT 55/53 11/10 11/8 11/7 55/34 22/13 2/1
#Diatonic Perfect Immutable System in the Dorian Tonos, a non-rep. 16 tone gamut 15 
dorian_pis 8/7 16/13 4/3 16/11 8/5 16/9 2/1 32/15 16/7 32/13 8/3 32/11 16/5 32/9 4/1
#Schlesinger's Dorian Piano Tuning (Sub 22) 12 
dorian_schl 22/21 11/10 22/19 11/9 22/17 11/8 22/15 11/7 22/13 44/25 11/6 2/1
#Schlesinger's Dorian Harmonia in the first trichromatic genus 7 
dorian_tri1 33/32 33/31 11/8 11/7 66/41 33/20 2/1
#Schlesinger's Dorian Harmonia in the second trichromatic genus 7 
dorian_tri2 33/32 11/10 11/8 11/7 66/41 22/13 2/1
#Dowland lute tuning 12 
dowland 33/31 9/8 33/28 264/211 4/3 24/17 3/2 99/62 27/16 99/56 396/211 2/1
#Dudon Tetrachord A 7 
dudon_a 59/54 11/9 4/3 3/2 59/36 11/6 2/1
#Dudon Tetrachord B 7 
dudon_b 13/12 59/48 4/3 3/2 13/8 59/32 2/1
#Dudon Neutral Diatonic 7 
dudon_diat 9/8 27/22 59/44 3/2 18/11 81/44 2/1
#Dudley Duncan's Superparticular Scale 12 
duncan 17/16 9/8 6/5 5/4 4/3 7/5 3/2 8/5 5/3 7/4 15/8 2/1
#Ellis's Duodene : genus [33355] 12 
duodene 16/15 9/8 6/5 5/4 4/3 45/32 3/2 8/5 5/3 9/5 15/8 2
#14-18-21 Duodene 12 
duodene14-18-21 28/27 9/8 7/6 9/7 4/3 81/56 3/2 14/9 12/7 7/4 27/14 2/1
#3-11/9 Duodene 12 
duodene3-11_9 12/11 9/8 11/9 27/22 4/3 11/8 3/2 44/27 18/11 11/6 81/44 2/1
#3-7 Duodene 12 
DUODENE3-7 9/8 8/7 7/6 9/7 21/16 4/3 3/2 32/21 12/7 7/4 63/32 2/1
#6-7-9 Duodene 12 
DUODENE6-7-9 9/8 8/7 7/6 9/7 21/16 4/3 3/2 14/9 12/7 7/4 27/14 2/1
#Ellis's Duodene rotated : genus [33555] 12 
duodene_rot 1125/1024 9/8 75/64 5/4 45/32 375/256 3/2 25/16 225/128 15/8 125/64 2
#Rotated 6/5x3/2 duodene 12 
duodene_skew 27/25 10/9 6/5 5/4 4/3 36/25 3/2 8/5 5/3 9/5 48/25 2/1
#Genus bis-ultra-chromaticum [33335555] 25 
efg33335555 25/24 16/15 10/9 9/8 256/225 75/64 6/5 5/4 32/25 4/3 25/18 45/32 64/45 36/25 3/2 25/16 8/5 5/3 128/75 225/128 16/9 9/5 15/8 48/25 2/1
#Genus diatonico-hyperchromaticum [333555] 16 
efg333555 25/24 16/15 10/9 75/64 6/5 5/4 4/3 25/18 64/45 3/2 25/16 8/5 5/3 16/9 15/8 2/1
#Genus diatonico-enharmonicum [333557] 24 
efg333557 64/63 16/15 15/14 10/9 8/7 6/5 128/105 5/4 80/63 4/3 48/35 64/45 10/7 3/2 32/21 8/5 512/315 5/3 12/7 16/9 64/35 15/8 40/21 2/1
#Genus chromaticum septimis triplex [335577] 27 
efg335577 21/20 16/15 15/14 35/32 8/7 7/6 6/5 128/105 5/4 21/16 4/3 48/35 7/5 10/7 35/24 3/2 32/21 8/5 105/64 5/3 12/7 7/4 64/35 28/15 15/8 40/21 2/1
#Genus [55577] 12 
efg55577 35/32 125/112 8/7 5/4 175/128 10/7 25/16 875/512 7/4 25/14 125/64 2/1
#Genus [55777] 12 
efg55777 35/32 8/7 49/40 5/4 7/5 10/7 49/32 8/5 7/4 64/35 245/128 2/1
#3)6 1.3.5.7.9.11 Eikosany (1.3.5 tonic) 20 
Eikosany 33/32 21/20 11/10 9/8 7/6 99/80 77/60 21/16 11/8 7/5 231/160 3/2 63/40 77/48 33/20 7/4 9/5 11/6 77/40 2/1
#Single-tie circular mirroring of 3:4:5 12 
ekring1 9/8 6/5 5/4 27/20 45/32 36/25 25/16 8/5 5/3 9/5 15/8 2/1
#Single-tie circular mirroring of 6:7:8 12 
ekring2 9/8 8/7 7/6 9/7 21/16 72/49 49/32 12/7 7/4 27/14 63/32 2/1
#Single-tie circular mirroring of 4:5:7 12 
ekring3 50/49 8/7 400/343 5/4 125/98 64/49 25/16 8/5 80/49 7/4 25/14 2/1
#Single-tie circular mirroring of 4:5:6 12 
EKRING4 16/15 6/5 32/25 4/3 36/25 3/2 192/125 5/3 128/75 16/9 48/25 2/1
#Single-tie circular mirroring of 3:5:7 12 
ekring5 126/125 36/35 7/6 216/175 7/5 10/7 36/25 72/49 42/25 12/7 49/25 2/1
#Single-tie circular mirroring of 6:7:9 12 
ekring6 54/49 8/7 9/7 4/3 72/49 3/2 14/9 81/49 16/9 648/343 96/49 2/1
#Single-tie circular mirroring of 5:7:9 12 
ekring7 50/49 10/9 500/441 100/81 9/7 450/343 14/9 100/63 81/49 9/5 90/49 2/1
#Ellis's Just Harmonium 12 
ellis_harm 16/15 9/8 6/5 5/4 4/3 27/20 3/2 8/5 5/3 9/5 15/8 2
#14/11 Enharmonic 7 
enh14 44/43 22/21 4/3 3/2 66/43 11/7 2/1
#Tonos-15 Enharmonic 7 
enh15 30/29 15/14 15/11 3/2 20/13 30/19 2/1
#Inverted Enharmonic Tonos-15 Harmonia 7 
enh15_inv 19/15 13/10 4/3 22/15 28/15 29/15 2/1
#Inverted harmonic form of the enharmonic Tonos-15 7 
ENH15_INV2 31/30 16/15 4/3 22/15 3/2 23/15 2/1
#Tonos-17 Enharmonic 7 
enh17 34/33 17/16 17/12 17/11 68/43 34/21 2/1
#Conjunct Tonos-17 Enharmonic 7 
enh17_con 34/33 17/16 17/12 68/47 34/23 17/9 2/1
#Tonos-19 Enharmonic 7 
enh19 38/37 19/18 19/14 19/13 76/51 38/25 2/1
#Conjunct Tonos-19 Enharmonic 7 
enh19_con 38/37 19/18 19/14 76/55 38/27 19/11 2/1
#1:2 Enharmonic. New genus 2 + 4 + 24 parts 7 
enh2 33.333 100.000 500.000 700.000 733.333 800.000 2/1
#Tonos-21 Enharmonic 7 
enh21 42/41 21/20 21/16 3/2 84/55 14/9 2/1
#Inverted Enharmonic Tonos-21 Harmonia 7 
enh21_inv 9/7 55/42 4/3 32/21 40/21 41/21 2/1
#Inverted harmonic form of the enharmonic Tonos-21 7 
enh21_inv2 32/31 16/15 4/3 32/21 11/7 34/21 2/1
#Tonos-23 Enharmonic 7 
enh23 46/45 23/22 23/18 23/16 46/31 23/15 2/1
#Conjunct Tonos-23 Enharmonic 7 
enh23_con 46/45 23/22 23/18 46/35 23/17 23/13 2/1
#Tonos-25 Enharmonic 7 
enh25 100/97 50/47 25/18 25/16 50/31 5/3 2/1
#Conjunct Tonos-25 Enharmonic 7 
enh25_con 100/97 50/47 25/18 10/7 25/17 25/13 2/1
#Tonos-27 Enharmonic 7 
enh27 36/35 18/17 27/20 3/2 54/35 27/17 2/1
#Inverted Enharmonic Tonos-27 Harmonia 7 
enh27_inv 34/27 35/27 4/3 40/27 17/9 35/18 2/1
#Inverted harmonic form of the enharmonic Tonos-27 7 
enh27_inv2 56/55 28/27 4/3 40/27 41/27 14/9 2/1
#Tonos-29 Enharmonic 7 
enh29 58/57 29/28 29/22 29/20 58/39 29/19 2/1
#Conjunct Tonos-29 Enharmonic 7 
enh29_con 58/57 29/28 29/22 58/43 29/21 29/16 2/1
#Tonos-31 Enharmonic. Tone 24 alternates with 23 as MESE or A 8 
enh31 31/30 31/29 31/24 31/23 31/22 62/43 31/21 2/1
#Conjunct Tonos-31 Enharmonic 8 
enh31_con 31/30 31/29 31/24 31/23 62/45 31/22 31/18 2/1
#Tonos-33 Enharmonic 7 
enh33 33/32 33/31 11/8 3/2 66/43 11/7 2/1
#Conjunct Tonos-33 Enharmonic 7 
enh33_con 33/32 33/31 11/8 66/47 33/23 11/6 2/1
#Inverted Enharmonic Conjunct Phrygian Harmonia 7 
enh_invcon 13/12 17/12 35/24 3/2 23/12 47/24 2/1
#Enharmonic After Wilson's Purvi Modulations, See page 111 7 
enhmod 9/8 7/6 4/3 3/2 14/9 8/5 2/1
#Epimore (Scholz) 40 
epimore 4/1 5/1 6/1 7/1 8/1 9/1 10/1 11/1 12/1 13/1 14/1 15/1 16/1 18/1 20/1 21/1 22/1 24/1 25/1 26/1 27/1 28/1 32/1 33/1 35/1 36/1 39/1 40/1 42/1 44/1 45/1 48/1 49/1 50/1 54/1 55/1 56/1 63/1 64/1 65/1
#New Epimoric Enharmonic, Dorian mode of the 4th new Enharmonic on Hofmann's list 7 
epimore_enh 76/75 16/15 4/3 3/2 38/25 8/5 2/1
#20-tone mode of 31-tET 20 
eq_31_20 77.419 116.129 193.548 270.968 309.677 387.097 425.806 503.226 580.645 619.355 696.774 735.484 774.194 851.613 890.323 967.742 1006.452 1083.871 1161.290 2/1
#Quasi-Equal Enneatonic, each "tetrachord" has 125 + 125 + 125 + 125 9 
eq_ennea 125.000 250.000 375.000 500.000 700.000 825.000 950.000 1075.000 2/1
#Dorian mode of Eratosthenes's Chromatic. same as Ptol. Intense Chromatic 7 
eratos_chrom 20/19 10/9 4/3 3/2 30/19 5/3 2/1
#Dorian mode of Eratosthenes's Diatonic 7 
eratos_diat 256/243 32/27 4/3 3/2 128/81 16/9 2/1
#Dorian mode of Eratosthenes's Enharmonic 7 
eratos_enh 40/39 20/19 4/3 3/2 20/13 30/19 2/1
#Revised Erlangen 12 
erlangen 135/128 9/8 32/27 5/4 4/3 45/32 3/2 405/256 27/16 16/9 15/8 2
#Ethiopian Tunings from Fortuna 12 
ethiopian 15/14 32/29 97/83 26/21 41/31 55/39 53/36 19/12 21/13 310/117 37/20 2/1
#Euler-Fokker genus [3 5 7 11] 15 
eul_15 33/32 11/10 8/7 33/28 6/5 44/35 48/35 3/2 11/7 8/5 33/20 12/7 64/35 66/35 2/1
#Euler (a mode of Ellis's duodene) 12 
euler 25/24 9/8 75/64 5/4 4/3 45/32 3/2 25/16 5/3 225/128 15/8 2
#Euler's Old Enharmonic, From Tentamen Novae Theoriae Musicae 7 
euler_enh 128/125 256/243 4/3 3/2 192/125 128/81 2/1
#Euler's Genus Musicum, Octony based on Archytas's Enharmonic 8 
euler_gm 28/27 16/15 448/405 4/3 112/81 64/45 1792/1215 2/1
#Expanded hexany 1 3 5 7 9 11 32 
exphex 2079/2048 33/32 135/128 35/32 9/8 1155/1024 297/256 77/64 315/256 5/4 10395/8192 165/128 21/16 693/512 11/8 45/32 1485/1024 189/128 3/2 385/256 99/64 105/64 27/16 3465/2048 55/32 7/4 231/128 945/512 15/8 495/256 63/32 2/1
#Al Farabi's Chromatic c700 AD 7 
farabi 9/8 27/20 729/512 3/2 9/5 19/10 2
#Farnsworth's scale 7 
farnsworth 9/8 5/4 21/16 3/2 27/16 15/8 2/1
#Modified meantone tuning of Fisk organ in Memorial Church at Stanford 12 
Fisk-Vogel 79.470 194.530 309.580 389.050 502.740 582.890 697.260 776.050 891.790 1006.160 1086.310 2
#Fogliano 1 12 
fogliano1 25/24 10/9 6/5 5/4 4/3 25/18 3/2 25/16 5/3 16/9 15/8 2
#Fogliano 2, also Mandelbaum 12 
fogliano2 25/24 9/8 6/5 5/4 4/3 25/18 3/2 25/16 5/3 9/5 15/8 2
#Fokker's Just Scale 12 
fokker 15/14 9/8 7/6 5/4 4/3 45/32 3/2 45/28 5/3 7/4 15/8 2/1
#Fokker's 31-tone just system 31 
FOKKER_31 64/63 135/128 15/14 35/32 9/8 8/7 7/6 135/112 315/256 5/4 9/7 21/16 4/3 175/128 45/32 10/7 35/24 3/2 32/21 14/9 45/28 105/64 5/3 12/7 7/4 16/9 945/512 15/8 40/21 63/32 2/1
#Fokker's 31-tone first alternate septimal tuning 31 
FOKKER_31A 36/35 25/24 15/14 35/32 9/8 8/7 7/6 25/21 315/256 5/4 9/7 21/16 4/3 175/128 45/32 10/7 35/24 3/2 32/21 63/40 45/28 105/64 5/3 12/7 7/4 9/5 175/96 15/8 40/21 63/32 2/1
#Fokker's 31-tone second alternate septimal tuning 31 
FOKKER_31B 49/48 21/20 15/14 35/32 9/8 8/7 7/6 6/5 315/256 5/4 9/7 21/16 4/3 175/128 45/32 10/7 35/24 3/2 32/21 25/16 45/28 105/64 5/3 12/7 7/4 25/14 90/49 15/8 40/21 63/32 2/1
#Fokker's 53-tone system, degree 37 has alternatives 53 
fokker_53 126/125 525/512 25/24 21/20 16/15 27/25 35/32 10/9 9/8 8/7 147/128 7/6 189/160 6/5 243/200 315/256 5/4 63/50 32/25 125/96 21/16 4/3 27/20 175/128 441/320 7/5 10/7 36/25 35/24 189/128 3/2 32/21 49/32 384/245 63/40 8/5 81/50 105/64 5/3 42/25 12/7 441/256 7/4 16/9 9/5 175/96 147/80 15/8 40/21 48/25 35/18 63/32 2/1
#Fokker's suggestion for a shrinked octave by averaging approximations 31 
fokker_av 38.652 77.303 115.955 154.606 193.258 231.910 270.561 309.213 347.865 386.516 425.168 463.819 502.471 541.123 579.774 618.426 657.077 695.729 734.381 773.032 811.684 850.335 888.987 927.639 966.290 1004.942 1043.594 1082.245 1120.897 1159.548 1198.200
#11-limit scale from Clem Fortuna 12 
fortuna 21/20 8/7 7/6 14/11 21/16 10/7 32/21 11/7 12/7 7/4 40/21 2/1
#Mandinka balafon scale 7 
gambia 151.000 345.000 526.000 660.000 861.000 1025.000 1141.000
#from Clem Fortuna out of Helmholtz, Slendro on black, F A B C E F as Pelog 12 
gamelan 101.100 233.000 332.500 410.500 512.600 572.600 649.900 800.600 958.600 1056.800 1087.700 2/1
#Gamelan Udan Mas (approx) s6,p6,p7,s1,p1,s2,p2,p3,s3,p4,s5,p5 12 
gamelan_udan 1/1 10/9 7/6 32/25 47/35 32/23 3/2 20/13 16/9 16/9 23/12 2/1
#Wendy Carlos' Gamma scale with third divided by eleven or fifth by twenty 35 
gamma 35.100 70.200 105.300 140.400 175.500 210.600 245.700 280.800 315.900 351.000 386.100 421.200 456.300 491.400 526.500 561.600 596.700 631.800 666.900 702.000 737.100 772.200 807.300 842.400 877.500 912.600 947.700 982.800 1017.900 1053.000 1088.100 1123.200 1158.300 1193.400 1228.500
#Ganassi 12 
ganassi 20/19 10/9 20/17 5/4 4/3 24/17 3/2 30/19 5/3 30/17 15/8 2/1
#Gilson septimal 12 
gilson7 1/1 8/7 6/5 5/4 3/2 10/7 3/2 25/16 25/16 25/14 15/8 2/1
#Gilson septimal 2 12 
gilson7_2 1/1 15/14 8/7 6/5 9/7 10/7 10/7 3/2 8/5 9/5 9/5 2/1
#Gilson's 10-tone JI 10 
GILSON_10 75/64 6/5 5/4 32/25 3/2 25/16 8/5 15/8 48/25 2/1
#Golden pentatonic 5 
GOLDEN_5 5/4 21/16 3/2 13/8 2/1
#Kraig Grady, letter to Lou Harrison, published in 1/1 7 (1) 1991 p 5. 14 
grady 21/20 9/8 7/6 5/4 21/16 4/3 7/5 3/2 63/40 27/16 7/4 15/8 63/32 2/1
#1st Inverted Schlesinger's Enharmonic Dorian Harmonia 7 
harm-doreninv1 27/22 5/4 14/11 16/11 21/11 43/22 2/1
#1st Inverted Schlesinger's Chromatic Dorian Harmonia 7 
harm-dorinv1 13/11 27/22 14/11 16/11 20/11 21/11 2/1
#1st Inverted Schlesinger's Chromatic Lydian Harmonia 7 
harm-lydchrinv1 16/13 17/13 18/13 20/13 24/13 25/13 2/1
#1st Inverted Schlesinger's Enharmonic Lydian Harmonia 7 
harm-lydeninv1 17/13 35/26 18/13 20/13 25/13 51/26 2/1
#1st Inverted Schlesinger's Chromatic Mixolydian Harmonia 7 
harm-mixochrinv1 9/7 19/14 10/7 11/7 13/7 27/14 2/1
#1st Inverted Schlesinger's Enharmonic Mixolydian Harmonia 7 
HARM-MIXOeninv1 19/14 39/28 10/7 11/7 27/14 55/28 2/1
#6/7/8/9/10 harmonics 13 
harm10 35/32 9/8 5/4 81/64 21/16 45/32 3/2 49/32 25/16 27/16 7/4 63/32 2/1
#Fifth octave of the harmonic overtone series 15 
harm15 17/16 9/8 19/16 5/4 21/16 11/8 23/16 3/2 25/16 13/8 27/16 7/4 29/16 15/8 31/16
#Harm1C-15-Harmonia 7 
Harm1C-15 6/5 19/15 4/3 22/15 26/15 28/15 2/1
#Harm1C-Dorian 7 
Harm1C-Dorian 3/11 27/22 14/11 16/11 20/11 21/11 2/1
#HarmC-Hypodorian 8 
harm1c-hypod 5/4 21/16 11/8 23/16 3/2 7/4 15/8 2/1
#HarmC-Hypolydian 8 
harm1c-hypol 21/20 11/10 13/10 7/5 3/2 8/5 17/10 2/1
#Harm1C-Lydian 8 
Harm1C-Lydian 27/26 14/13 18/13 19/13 20/13 21/13 22/13 2/1
#Harm1C-Con Mixolydian 7 
Harm1C-Mix 8/7 10/7 3/2 11/7 13/7 27/14 2/1
#Harm1C-Mixolydian 7 
Harm1C-Mixolydian 15/14 8/7 10/7 11/7 23/14 12/7 2/1
#Harm1C-ConPhryg 7 
Harm1C-Phryg 13/12 4/3 17/12 3/2 11/6 23/12 2/1
#Harm1C-Phrygian 7 
Harm1C-Phrygian 7/6 5/4 4/3 3/2 11/6 23/12 2/1
#Harm1E-15-Harmonia 7 
Harm1E-15 19/15 13/10 4/3 22/15 28/15 29/15 2/1
#Third octave of the harmonic overtone series 3 
harm3 5/4 3/2 7/4
#First 30 subharmonics & harmonics 59 
harm30-30 16/15 32/29 8/7 32/27 16/13 32/25 4/3 32/23 32/21 8/5 32/19 16/9 32/17 2/1 32/15 16/7 32/13 8/3 32/11 16/5 32/9 4/1 32/7 16/3 32/5 8/1 32/3 16/1 32/1 33/1 34/1 35/1 36/1 37/1 38/1 39/1 40/1 41/1 42/1 43/1 44/1 45/1 46/1 47/1 48/1 49/1 50/1 51/1 52/1 53/1 54/1 55/1 56/1 57/1 58/1 59/1 60/1 61/1 62/1
#Fourth octave of the harmonic overtone series 7 
harm4 9/8 5/4 11/8 3/2 13/8 7/4 15/8
#harmonics 60 to 30 12 
harm60-30 15/14 10/9 6/5 5/4 4/3 10/7 3/2 30/19 5/3 12/7 15/8 2/1
#7-limit harmonics 47 
harm7lim 2/1 3/1 4/1 5/1 6/1 7/1 8/1 9/1 10/1 12/1 14/1 15/1 16/1 18/1 20/1 21/1 22/1 24/1 25/1 28/1 30/1 32/1 35/1 36/1 40/1 42/1 45/1 48/1 49/1 50/1 56/1 60/1 63/1 64/1 70/1 72/1 75/1 80/1 81/1 84/1 90/1 96/1 98/1 100/1 105/1 112/1 120/1
#6/7/8/9 harmonics, First 9 overtones of 5th through 9th harmonics 10 
harm9 9/8 7/6 5/4 4/3 49/36 3/2 14/9 7/4 16/9 2/1
#6)7 7-any from 1.3.5.7.9.11.13 and inversion of "Bastard" Hypodorian Harmonia 7 
harm_bastard 9/8 5/4 11/8 3/2 13/8 7/4 2/1
#Darreg Harmonics 4-15 24 
harm_darreg 4/1 5/1 6/1 7/1 8/1 9/1 10/1 11/1 12/1 13/1 14/1 15/1 16/1 20/1 24/1 28/1 32/1 36/1 40/1 44/1 48/1 52/1 56/1 60/1
#Harm. Mean 9-tonic 8/7 is HM of 1/1 and 4/3, etc. 9 
harm_mean 32/31 16/15 8/7 4/3 3/2 48/31 8/5 12/7 2/1
#HarmC-Hypophrygian 9 
harmc-hypop 11/9 23/18 4/3 25/18 13/9 14/9 16/9 17/9 2/1
#HarmD-15-Harmonia 7 
harmd-15 16/15 6/5 4/3 22/15 8/5 26/15 2/1
#HarmD-ConMixolydian 7 
harmd-conmix 8/7 9/7 3/2 11/7 12/7 13/7 2/1
#HarmD-Dorian 8 
harmd-dor 12/11 13/11 14/11 15/11 16/11 18/11 20/11 2/1
#HarmD-Hypodorian 9 
harmd-hypod 9/8 5/4 11/8 23/16 3/2 13/8 7/4 15/8 2/1
#HarmD-Hypolydian 8 
harmd-hypol 11/10 6/5 13/10 7/5 3/2 8/5 9/5 2/1
#HarmD-Hypophrygian 9 
HarmD-Hypop 10/9 11/9 4/3 25/18 13/9 14/9 5/3 16/9 2/1
#HarmD-Lydian 9 
harmd-lyd 14/13 15/13 16/13 18/13 19/13 20/13 22/13 24/13 2/1
#HarmD-Mixolydian 7 
harmd-mix 8/7 9/7 10/7 11/7 12/7 13/7 2/1
#HarmD-Phryg (with 5 extra tones) 12 
harmd-phr 25/24 13/12 9/8 7/6 4/3 5/4 3/2 19/12 5/3 7/4 11/6 2/1
#HarmE-Hypodorian 8 
harme-hypod 21/16 43/32 11/8 23/16 3/2 15/8 31/16 2/1
#HarmE-Hypolydian 8 
harme-hypol 43/40 21/20 13/10 7/5 3/2 31/20 8/5 2/1
#HarmE-Hypophrygian 9 
harme-hypop 23/18 47/36 4/3 25/18 13/9 14/9 17/9 35/18 2/1
#Harrison 16-tone 16 
harrison 16/15 10/9 8/7 7/6 6/5 5/4 4/3 17/12 3/2 8/5 5/3 12/7 7/4 9/5 15/8 2/1
#Harrison 8-tone from Serenade for Guitar 8 
HARRISON_8 16/15 6/5 5/4 45/32 3/2 5/3 16/9 2/1
#Helmholtz's Chromatic scale 7 
HELMHOLTZ 16/15 5/4 4/3 3/2 8/5 15/8 2/1
#Simplified Helmholtz 24 24 
helmholtz_24 135/128 16/15 10/9 9/8 75/64 32/27 5/4 81/64 675/512 4/3 45/32 729/512 6075/4096 3/2 25/16 405/256 5/3 27/16 225/128 3645/2048 15/8 243/128 2025/1024 2/1
#Helmholtz's two-keyboard harmonium tuning untempered 24 
helmholtz_pure 135/128 16/15 10/9 9/8 75/64 32/27 5/4 512/405 675/512 4/3 45/32 64/45 40/27 3/2 25/16 128/81 5/3 27/16 225/128 16/9 15/8 256/135 160/81 2/1
#Helmholtz's two-keyboard harmonium tuning 24 
helmholtz_temp 91.446 111.976 182.892 203.422 274.338 294.868 5/4 406.843 477.760 498.289 589.735 610.265 681.181 701.711 25/16 793.157 884.603 905.132 976.049 996.578 1088.025 1108.554 1179.471 2/1
#Hemiolic Chromatic genus has the strong or 1:2 division of the 12/11 pyknon 7 
hem_chrom 34/33 12/11 4/3 3/2 17/11 18/11 2/1
#11'al Hemiolic Chromatic genus with a CI of 11/9, Winnington-Ingram 7 
HEM_CHROM11 24/23 12/11 4/3 3/2 36/23 18/11 2/1
#13'al Hemiolic Chromatic or neutral-third genus has a CI of 16/13 7 
HEM_CHROM13 26/25 13/12 4/3 3/2 39/25 13/8 2/1
#1:2 Hemiolic Chromatic genus 3 + 6 + 21 parts 7 
HEM_CHROM2 50.000 150.000 500.000 700.000 750.000 850.000 2/1
#Inverted-Prime Heptatonic Diamond based on Archytas's Enharmonic 25 
hept_diamond 36/35 28/27 16/15 9/8 7/6 6/5 98/81 56/45 5/4 32/25 9/7 4/3 3/2 14/9 25/16 8/5 45/28 81/49 5/3 12/7 16/9 15/8 27/14 35/18 2/1
#Heptatonic Diamond based on Archytas's Enharmonic, 27 tones 27 
HEPT_DIAMONDp 36/35 28/27 16/15 9/8 7/6 6/5 5/4 9/7 35/27 4/3 48/35 112/81 45/32 64/45 81/56 35/24 3/2 54/35 14/9 8/5 5/3 12/7 16/9 15/8 27/14 35/18 2/1
#Star hexagonal 13-tone scale 13 
hexagonal13 25/24 16/15 10/9 6/5 5/4 4/3 3/2 8/5 5/3 9/5 15/8 48/25 2/1
#Star hexagonal 37-tone scale 37 
hexagonal37 25/24 16/15 27/25 625/576 10/9 9/8 256/225 144/125 75/64 6/5 100/81 5/4 32/25 125/96 4/3 27/20 25/18 45/32 64/45 36/25 40/27 3/2 192/125 25/16 8/5 81/50 5/3 128/75 125/72 225/128 16/9 9/5 1152/625 50/27 15/8 48/25 2/1
#Composed of 1.3.5.45, 1.3.5.75, 1.3.5.9, and 1.3.5.25 hexanies 11 
hexanic 16/15 9/8 6/5 5/4 4/3 3/2 25/16 8/5 15/8 48/25 2/1
#Hexany Cluster 1 12 
Hexany 9/8 144/125 6/5 5/4 4/3 27/20 36/25 3/2 8/5 9/5 48/25 2
#Two out of 1 3 5 7 hexany 6 
hexany1 35/32 5/4 21/16 3/2 7/4 15/8
#1.3.5.15 2)4 hexany (1.15 tonic) degenerate, symmetrical pentatonic 5 
hexany15 5/4 4/3 3/2 8/5 2/1
#Hexany Cluster 2 12 
hexany2 25/24 9/8 6/5 5/4 125/96 4/3 25/18 3/2 25/16 5/3 15/8 2
#Hexany Cluster 3 12 
hexany3 25/24 10/9 6/5 5/4 4/3 3/2 8/5 5/3 9/5 15/8 48/25 2
#Hexany Cluster 4 12 
hexany4 25/24 9/8 6/5 5/4 4/3 36/25 3/2 8/5 5/3 9/5 15/8 2
#1.3.21.49 2)4 hexany (1.21 tonic) 6 
hexany49 8/7 7/6 3/2 49/32 7/4 2/1
#Hexany Cluster 5 12 
hexany5 9/8 6/5 5/4 4/3 3/2 25/16 8/5 5/3 9/5 15/8 48/25 2
#Hexany Cluster 6 12 
hexany6 25/24 10/9 9/8 6/5 5/4 4/3 3/2 25/16 8/5 5/3 15/8 2
#Hexany Cluster 7 12 
hexany7 25/24 6/5 5/4 4/3 25/18 3/2 25/16 8/5 5/3 9/5 15/8 2
#Hexany Cluster 8 12 
Hexany8 25/24 6/5 5/4 125/96 4/3 3/2 25/16 8/5 5/3 15/8 48/25 2
#Complex 12 of p. 115, a hexany based on Archytas's Enharmonic 6 
hexany_tetr 36/35 16/15 9/7 4/3 48/35 2/1
#Complex 1 of p. 115, a hexany based on Archytas's Enharmonic 6 
hexany_trans 28/27 16/15 35/27 4/3 112/81 2/1
#Complex 2 of p. 115, a hexany based on Archytas's Enharmonic 6 
HEXANY_TRANS2 28/27 16/15 4/3 48/35 64/45 2/1
#Complex 9 of p. 115, a hexany based on Archytas's Enharmonic 6 
HEXANY_TRANS3 28/27 16/15 5/4 9/7 4/3 2/1
#Hexanys 13579 12 
hexanys 35/32 9/8 5/4 21/16 45/32 3/2 105/64 27/16 7/4 15/8 63/32 2/1
#Hexanys 1371113 12 
hexanys2 77/64 13/8 7/4 33/32 91/64 3/2 231/128 39/32 11/8 21/16 143/128 2/1
#Medieval Arabic scale 7 
Hhidjazi 65536/59049 32/27 4/3 262144/177147 32768/19683 16/9 2
#Medieval Arabic scale 7 
Hhosaini 65536/59049 32/27 4/3 262144/177147 27/16 16/9 2
#From Greg Higgs announcement of the formation of an Internet Tuning list 7 
higgs 3/2 8/5 21/13 34/21 13/8 5/3 2/1
#Hipkins' Chromatic 7 
hipkins 256/243 8/7 4/3 3/2 128/81 12/7 2/1
#Observed Japanese pentatonic koto scale 5 
Hiradoshi 185.000 337.000 683.000 790.000 2
#Another Japanese pentatonic koto scale 5 
HIRADOSHI2 9/8 6/5 3/2 8/5 2/1
#Ho Mai Nhi (Nam Hue) dan tranh scale 5 
ho_mai 11/10 4/3 3/2 33/20 2/1
#Hofmann's Enharmonic #1, Dorian mode 7 
hofmann1 256/255 16/15 4/3 3/2 128/85 8/5 2/1
#Hofmann's Enharmonic #2, Dorian mode 7 
hofmann2 136/135 16/15 4/3 3/2 68/45 8/5 2/1
#Hofmann's Chromatic 7 
hofmann_chrom 100/99 10/9 4/3 3/2 50/33 5/3 2/1
#13/10 HyperEnharmonic. This genus is at the limit of usable tunings 7 
HYPER_ENH 80/79 40/39 4/3 3/2 120/79 20/13 2/1
#Hyperenharmonic genus from Kathleen Schlesinger's enharmonic Phrygian Harmonia 7 
hyper_enh2 48/47 24/23 4/3 3/2 72/47 36/23 2/1
#Hypolydian Chromatic Tonos 12 
hypo_chrom 20/19 40/37 10/9 4/3 10/7 40/27 20/13 8/5 80/49 5/3 40/23 2/1
#Hypolydian Diatonic Tonos 12 
hypo_diat 10/9 20/17 5/4 4/3 10/7 40/27 20/13 5/3 40/23 20/11 40/21 2/1
#Hypolydian Enharmonic Tonos 12 
hypo_enh 40/39 80/77 20/19 4/3 10/7 40/27 20/13 80/51 160/101 8/5 16/9 2/1
#Hypodorian Chromatic Tonos 12 
hypod_chrom 16/15 32/29 8/7 16/13 4/3 32/23 16/11 32/21 64/41 8/5 16/9 2/1
#Schlesinger's Chromatic Hypodorian Harmonia 7 
hypod_chrom2 16/15 8/7 4/3 16/11 32/21 8/5 2/1
#Schlesinger's Hypodorian Harmonia in a mixed chromatic-enharmonic genus 7 
hypod_chromenh 32/31 16/15 4/3 16/11 32/21 8/5 2/1
#A harmonic form of Schlesinger's Chromatic Hypodorian Inverted 7 
HYPOD_CHROMinv 17/16 9/8 11/8 3/2 25/16 13/8 2/1
#Hypodorian Diatonic Tonos 12 
hypod_diat 16/15 8/7 16/13 32/25 4/3 32/23 16/11 8/5 32/19 16/9 32/17 2/1
#Schlesinger's Hypodorian Harmonia, a subharmonic series through 13 from 16 8 
hypod_diat2 16/15 16/13 4/3 32/23 16/11 8/5 16/9 2/1
#A Hypodorian Diatonic with its own trite synemmenon replacing paramese 7 
hypod_diatcon 16/15 16/13 4/3 32/23 8/5 16/9 2/1
#Inverted Schlesinger's Hypodorian Harmonia, a harmonic series from 8 from 16 9 
hypod_diatinv 9/8 5/4 11/8 23/16 3/2 13/8 7/4 15/8 2/1
#Hypodorian Enharmonic Tonos 12 
hypod_enh 32/31 64/61 16/15 32/27 4/3 32/23 16/11 64/43 128/85 32/21 64/37 2/1
#Inverted Schlesinger's Enharmonic Hypodorian Harmonia 7 
HYPOD_enhinv 21/16 43/32 11/8 3/2 15/8 31/16 2/1
#A harmonic form of Schlesinger's Hypodorian enharmonic inverted 7 
HYPOD_ENHINV2 33/32 17/16 11/8 3/2 49/32 25/16 2/1
#Inverted Schlesinger's Chromatic Hypodorian Harmonia 7 
hypod_inv 5/4 21/16 11/8 3/2 7/4 15/8 2/1
#Diatonic Perfect Immutable System in the Hypodorian Tonos 15 
hypodorian_pis 12/11 6/5 4/3 3/2 8/5 24/13 2/1 48/23 24/11 12/5 8/3 3/1 24/7 48/13 4/1
#Schlesinger's Hypolydian Harmonia in the chromatic genus 8 
hypol_chrom 20/19 10/9 4/3 10/7 20/13 8/5 5/3 2/1
#Inverted Schlesinger's Chromatic Hypolydian Harmonia 8 
HYPOL_CHROMINV 6/5 5/4 13/10 7/5 3/2 9/5 19/10 2/1
#harmonic form of Schlesinger's Chromatic Hypolydian inverted 7 
HYPOL_CHROMINV2 21/20 11/10 13/10 7/5 3/2 8/5 2/1
#A harmonic form of Schlesinger's Chromatic Hypolydian inverted 7 
HYPOL_CHROMINV3 21/20 11/10 13/10 3/2 8/5 17/10 2/1
#Schlesinger's Hypolydian Harmonia, a subharmonic series through 13 from 20 8 
hypol_diat 10/9 5/4 4/3 10/7 20/13 5/3 20/11 2/1
#A Hypolydian Diatonic with its own trite synemmenon replacing paramese 7 
hypol_diatcon 10/9 5/4 4/3 20/13 5/3 20/11 2/1
#Inverted Schlesinger's Hypolydian Harmonia, a harmonic series from 10 from 20 8 
hypol_diatinv 11/10 6/5 13/10 7/5 3/2 8/5 9/5 2/1
#Schlesinger's Hypolydian Harmonia in the enharmonic genus 8 
hypol_enh 40/39 20/19 4/3 10/7 20/13 8/5 5/3 2/1
#Inverted Schlesinger's Enharmonic Hypolydian Harmonia 8 
hypol_enhinv 5/4 51/40 13/10 7/5 3/2 19/10 39/20 2/1
#A harmonic form of Schlesinger's Hypolydian enharmonic inverted 7 
HYPOL_ENHINV2 41/40 21/20 13/10 7/5 29/20 3/2 2/1
#A harmonic form of Schlesinger's Hypolydian enharmonic inverted 7 
HYPOL_ENHINV3 41/40 21/20 13/10 3/2 31/20 8/5 2/1
#Schlesinger's Hypolydian Harmonia in the pentachromatic genus 8 
hypol_pent 25/24 10/9 4/3 10/7 20/13 100/63 5/3 2/1
#Schlesinger's Hypolydian Harmonia in the first trichromatic genus 8 
hypol_tri 30/29 15/14 4/3 10/7 20/13 30/19 60/37 2/1
#Schlesinger's Hypolydian Harmonia in the second trichromatic genus 8 
hypol_tri2 30/29 10/9 4/3 10/7 20/13 30/19 5/3 8/1
#The Diatonic Perfect Immutable System in the Hypolydian Tonos 15 
hypolydian_pis 14/13 7/6 14/11 7/5 14/9 7/4 28/15 2/1 28/13 7/3 28/11 14/5 28/9 7/2 4/1
#Hypophrygian Chromatic Tonos 12 
hypop_chrom 18/17 12/11 9/8 9/7 18/13 36/25 3/2 36/23 8/5 18/11 9/5 2/1
#Schlesinger's Hypophrygian Harmonia in a mixed chromatic-enharmonic genus 7 
hypop_chromenh 36/35 18/17 18/13 3/2 36/23 18/11 2/1
#Inverted Schlesinger's Chromatic Hypophrygian Harmonia 7 
hypop_chrominv 11/9 23/18 4/3 13/9 16/9 17/9 2/1
#A harmonic form of Schlesinger's Chromatic Hypophrygian inverted 7 
HYPOP_CHROMINV2 19/18 10/9 4/3 13/9 14/9 5/3 2/1
#Hypophrygian Diatonic Tonos 12 
hypop_diat 9/8 36/31 6/5 9/7 18/13 36/25 3/2 18/11 12/7 9/5 36/19 2/1
#Schlesinger's Hypophrygian Harmonia 8 
hypop_diat2 9/8 6/5 18/13 36/25 3/2 18/11 9/5 2/1
#A Hypophrygian Diatonic with its own trite synemmenon replacing paramese 7 
hypop_diatcon 9/8 6/5 18/13 36/25 18/11 9/5 2/1
#Inverted Schlesinger's Hypophrygian Harmonia, a harmonic series from 9 from 18 8 
hypop_diatinv 10/9 11/9 4/3 25/18 13/9 5/3 16/9 2/1
#Hypophrygian Enharmonic Tonos 12 
hypop_enh 36/35 24/23 18/17 6/5 18/13 36/25 3/2 72/47 48/31 36/23 9/5 2/1
#Inverted Schlesinger's Enharmonic Hypophrygian Harmonia 7 
hypop_enhinv 23/18 47/36 4/3 13/9 17/9 35/18 2/1
#A harmonic form of Schlesinger's Hypophrygian enharmonic inverted 7 
HYPOP_ENHINV2 37/36 19/18 4/3 13/9 3/2 14/9 2/1
#The Diatonic Perfect Immutable System in the Hypophrygian Tonos 15 
hypophryg_pis 13/12 13/11 13/10 13/9 13/8 26/15 2/1 52/25 13/6 26/11 13/5 26/9 13/4 26/7 4/1
#Iasti-aiolika, kithara tuning: tonic diatonic and ditonic diatonic 7 
iasti 28/27 32/27 4/3 3/2 27/16 16/9 2
#Iastia or Lydia, kithara tuning: intense diatonic and tonic diatonic 7 
iastia 28/27 32/27 4/3 3/2 8/5 9/5 2
#17-limitIIVV 21 
iivv17 33/32 17/16 13/12 9/8 7/6 39/32 5/4 21/16 4/3 11/8 45/32 17/12 3/2 51/32 13/8 5/3 27/16 7/4 11/6 15/8 2/1
#Indian shruti scale 22 
indian 256/243 16/15 10/9 9/8 32/27 6/5 5/4 81/64 4/3 27/20 45/32 729/512 3/2 128/81 8/5 5/3 27/16 16/9 9/5 15/8 243/128 2/1
#Indian shruti scale 22 
indian2 256/243 16/15 10/9 9/8 32/27 6/5 5/4 81/64 4/3 27/20 45/32 64/45 3/2 128/81 8/5 5/3 27/16 16/9 9/5 15/8 243/128 2/1
#North Indian Gamut, modern Hindustani gamut out of 22 or more shrutis 12 
INDIAN_12 16/15 9/8 6/5 5/4 4/3 45/32 3/2 8/5 27/16 9/5 15/8 2/1
#One observed indian mode 7 
indian_a 183.000 342.000 533.000 685.000 871.000 1074.000 2
#Observed Indian mode 7 
indian_b 183.000 271.000 534.000 686.000 872.000 983.000 2
#Observed Indian mode 7 
indian_c 111.000 314.000 534.000 686.000 828.000 1017.000 2
#Indian D (Ellis, correct) 7 
INDIAN_D 174.000 350.000 477.000 697.000 908.000 1070.000 2/1
#Observed Indian Mode 7 
indian_e 90.000 366.000 493.000 707.000 781.000 1080.000 2
#Indian shrutis Paul Hahn proposal 22 
indian_hahn 25/24 16/15 10/9 9/8 75/64 6/5 5/4 32/25 4/3 27/20 45/32 36/25 3/2 25/16 8/5 5/3 27/16 16/9 9/5 15/8 48/25 2/1
#Inv. Rot. North Indian Gamut 12 
indian_invrot 128/125 16/15 6/5 5/4 32/25 4/3 3/2 8/5 128/75 15/8 48/25 2/1
#Indian 22 Perkis 22 
indian_perk 36/35 18/17 12/11 9/8 36/31 6/5 5/4 9/7 4/3 26/19 600.000 13/9 52/35 26/17 167/106 13/8 99/59 26/15 52/29 115/62 52/27 2/1
#Indian Raga, From Fortuna, after Helmholtz, ratios by JC 22 
indian_rat 34/33 35/33 12/11 9/8 22/19 35/29 5/4 40/31 4/3 11/8 17/12 16/11 3/2 17/11 35/22 59/36 27/16 7/4 38/21 15/8 60/31 2/1
#Rotated North Indian Gamut 12 
indian_rot 25/24 16/15 75/64 5/4 4/3 3/2 25/16 8/5 5/3 15/8 125/64 2/1
#Ancient greek Ionic 7 
ionic 9/8 5/4 4/3 3/2 5/3 9/5 2
#Iranian Diatonic from Dariush Anooshfar, Safi-a-ddin Armavi's scale from 125 ET 7 
iran_diat 220.800 441.600 489.600 710.400 931.200 979.200 2/1
#Iraq 8-tone scale, Ellis 8 
iraq 394/355 8192/6561 4/3 623/421 591/355 16/9 513/260 2/1
#Isfahan 8 
Isfahan 394/355 8192/6561 4/3 3/2 591/355 16/9 513/260 2/1
#Isfahan (IG #2, DF #8) From Rouanet 5 
isfahan2 13/12 7/6 5/4 4/3 2/1
#Medieval Islamic scale of Zalzal 7 
islam 9/8 81/64 4/3 40/27 130/81 16/9 2
#Islamic Genus #1 (DF#7), From Rouanet 5 
islam2 13/12 7/6 91/72 4/3 2/1
#Iterated 3/2 Scale, IE=3/2, PD=3, SD=2 10 
iter_fifth 207.987 311.980 381.309 415.973 467.970 571.963 623.960 658.624 675.957 3/2
#Basic JI with 7-limit tritone 12 
ji 16/15 9/8 6/5 5/4 4/3 7/5 3/2 8/5 5/3 9/5 15/8 2/1
#Ben Johnston's combined otonal-utonal scale 12 
johnston 135/128 9/8 135/112 5/4 11/8 45/32 3/2 135/88 27/16 7/4 15/8 2/1
#Jorgensen's 5&7 temperament 12 
jorgensen 51.429 171.429 291.429 342.857 514.286 531.429 685.714 771.429 857.143 1011.429 1028.571 2/1
#Lou Harrison's Joyous 6 6 
joyous 9/8 5/4 3/2 5/3 15/8 2/1
#Johnston 21-note just enharmonic scale 21 
just_enh_21 25/24 27/25 9/8 75/64 6/5 5/4 32/25 125/96 4/3 25/18 36/25 3/2 25/16 8/5 5/3 125/72 9/5 15/8 48/25 125/64 2/1
#Johnston 25-note just enharmonic scale 25 
just_enh_25 25/24 135/128 16/15 10/9 9/8 75/64 6/5 5/4 81/64 32/25 4/3 27/20 45/32 36/25 3/2 25/16 8/5 5/3 27/16 225/128 16/9 9/5 15/8 48/25 2/1
#Bruce Kanzelmeyer, 11 harmonics from 16 to 32. Base 388.3614815 Hz 11 
Kanzelmeyer11 17/16 19/16 5/4 11/8 23/16 3/2 13/8 7/4 29/16 31/16 2/1
#Kanzelmeyer, 18 harmonics from 32 to 64. Base 388.3614815 Hz 18 
Kanzelmeyer18 17/16 37/32 19/16 5/4 41/32 43/32 11/8 23/16 47/32 3/2 13/8 53/32 7/4 29/16 59/32 61/32 31/16 2/1
#Kanzelmeyer, 32 harmonics from 32 to 64. Base 388.3614815 Hz 32 
Kanzelmeyer32 33/32 17/16 35/32 9/8 37/32 19/16 39/32 5/4 41/32 21/16 43/32 11/8 45/32 23/16 47/32 3/2 49/32 25/16 51/32 13/8 53/32 27/16 55/32 7/4 57/32 29/16 59/32 15/8 61/32 31/16 63/32 2/1
#19-tone 5-limit scale of the Kayenian Imperium on Kayolonia 19 
Kayolonian 128/125 16/15 9/8 75/64 6/5 5/4 32/25 4/3 512/375 64/45 3/2 25/16 8/5 5/3 128/75 16/9 15/8 125/64 2/1
#Kayolonian scale F 9 
Kayolonian_f 16/15 75/64 5/4 4/3 3/2 8/5 128/75 15/8 2/1
#Kayolonian scale P 9 
Kayolonian_p 16/15 75/64 5/4 4/3 3/2 8/5 225/128 15/8 2/1
#Kayolonian scale S 9 
kayolonian_s 1125/1024 75/64 5/4 5625/4096 3/2 8/5 225/128 15/8 2/1
#Kayolonian scale T 9 
Kayolonian_T 16/15 256/225 4096/3375 4/3 8192/5625 8/5 128/75 2048/1125 2/1
#Kayolonian scale Z 9 
Kayolonian_Z 16/15 256/225 5/4 4/3 3/2 8/5 128/75 2048/1125 2/1
#Kepler 1 12 
kepler1 135/128 9/8 6/5 5/4 4/3 45/32 3/2 405/256 27/16 9/5 15/8 2
#Kepler 2 12 
kepler2 135/128 9/8 6/5 5/4 4/3 45/32 3/2 8/5 27/16 9/5 15/8 2
#Kilroy 12 
kilroy 9/8 6/5 5/4 4/3 45/32 3/2 8/5 5/3 27/16 16/9 15/8 2/1
#Buzz Kimball 18-note just scale 18 
kimball 25/24 135/128 10/9 9/8 75/64 5/4 81/64 4/3 25/18 45/32 3/2 25/16 5/3 27/16 225/128 16/9 15/8 2/1
#Buzz Kimball 53-note just scale 53 
KIMBALL_53 18/17 17/16 16/15 14/13 13/12 12/11 11/10 17/15 8/7 7/6 20/17 13/11 6/5 17/14 11/9 16/13 5/4 14/11 22/17 13/10 17/13 4/3 11/8 18/13 7/5 24/17 17/12 10/7 13/9 16/11 3/2 26/17 20/13 17/11 11/7 8/5 13/8 18/11 28/17 5/3 22/13 17/10 12/7 7/4 30/17 20/11 11/6 24/13 13/7 15/8 32/17 17/9 2/1
#Kirnberger's scale 12 
kirnberg 256/243 193.849 32/27 386.314 4/3 45/32 696.663 128/81 889.650 16/9 15/8 2/1
#Kirnberger 1 12 
kirnberg1 256/243 9/8 32/27 5/4 4/3 45/32 3/2 128/81 895.112 16/9 15/8 2/1
#Scale by Johnny Klonaris 12 
klonaris 17/16 9/8 19/16 5/4 21/16 11/8 3/2 25/16 13/8 7/4 15/8 2/1
#According to Lou Harrison, called " the Delightful" in Korea 5 
korea_5 9/8 4/3 3/2 9/5 2
#Double-tie circular mirroring of 4:5:6 and Partch's 5-limit tonality Diamond 7 
KRING1 6/5 5/4 4/3 3/2 8/5 5/3 2/1
#Double-tie circular mirroring of 6:7:8 7 
kring2 8/7 7/6 4/3 3/2 12/7 7/4 2/1
#Double-tie circular mirroring of 3:5:7 7 
kring3 7/6 6/5 7/5 10/7 5/3 12/7 2/1
#Double-tie circular mirroring of 4:5:7 7 
kring4 8/7 5/4 7/5 10/7 8/5 7/4 2/1
#Double-tie circular mirroring of 5:6:7 7 
kring5 7/6 6/5 7/5 10/7 5/3 12/7 2/1
#Double-tie circular mirroring of 6:7:9 7 
kring6 7/6 9/7 4/3 3/2 14/9 12/7 2/1
#Double-tie circular mirroring of 5:7:9 7 
kring7 10/9 9/7 7/5 10/7 14/9 9/5 2/1
#5x12 Lambdoma 42 
lambdoma5_12 1/12 1/11 1/10 1/9 1/8 1/7 1/6 2/11 1/5 2/9 1/4 3/11 2/7 3/10 1/3 4/11 3/8 2/5 5/12 3/7 4/9 5/11 1/2 5/9 4/7 3/5 5/8 2/3 5/7 3/4 4/5 5/6 1/1 5/4 4/3 3/2 5/3 2/1 5/2 3/1 4/1 5/1
#Prime Lambdoma 56 
LAMBDOMA_prim 1/31 1/29 1/23 1/19 1/17 2/31 2/29 1/13 2/23 1/11 3/31 3/29 2/19 2/17 3/23 1/7 2/13 3/19 5/31 5/29 3/17 2/11 1/5 5/23 7/31 3/13 7/29 5/19 3/11 2/7 5/17 7/23 1/3 7/19 5/13 2/5 7/17 3/7 5/11 1/2 7/13 3/5 7/11 2/3 5/7 1/1 7/5 3/2 5/3 2/1 7/3 5/2 3/1 7/2 5/1 7/1
#Lambert's temperament (1774) 12 
lambert 93.576 197.207 297.486 394.414 501.396 591.621 698.604 795.531 895.811 999.441 1093.018 2/1
#LaMonte Young, Tuning of For Guitar(1958). See 1/1 March 1992 12 
lamonte 16/15 10/9 6/5 5/4 4/3 45/32 3/2 8/5 5/3 9/5 15/8 2/1
#Left Pistol 12 
leftpistol 135/128 16/15 9/8 5/4 4/3 45/32 3/2 8/5 5/3 27/16 15/8 2/1
#Lou Harrison mid mode 7 
lh_mid 9/8 6/5 4/3 3/2 5/3 7/4 2/1
#Lou Harrison mid mode 2 7 
lh_mid2 9/8 6/5 4/3 3/2 12/7 9/5 2/1
#Scale of Ling Lun from C 12 
ling-lun 2187/2048 9/8 19683/16384 81/64 177147/131072 729/512 3/2 6561/4096 27/16 59049/32768 243/128 2/1
#Linus Liu's Major Scale, see his 1978 book, "Intonation Theory" 7 
liu_maj 10/9 100/81 4/3 3/2 5/3 50/27 2/1
#Linus Liu's Melodic Minor, use 5 and 7 descending and 6 and 8 ascending 9 
liu_mel 10/9 6/5 4/3 3/2 81/50 5/3 9/5 50/27 2/1
#Linus Liu's Harmonic Minor 7 
liu_min 10/9 6/5 4/3 40/27 8/5 50/27 2/1
#Young's Well-Tempered Piano 12 
lmyoung 567/512 9/8 147/128 21/16 1323/1024 189/128 3/2 49/32 7/4 441/256 63/32 2/1
#Lorina 12 
lorina 28/27 28/25 7/6 6/5 4/3 4/3 28/19 14/9 7/4 7/4 16/9 2/1
#From Lou Harrison, a pelog style pentatonic 5 
lpl_5 16/15 6/5 3/2 8/5 2
#From Lou Harrison, a pelog style pentatonic 5 
lpl_5_2 12/11 6/5 3/2 8/5 2
#From Lou Harrison, a pelog style pentatonic 5 
lpl_5_3 28/27 4/3 3/2 14/9 2
#From Lou Harrison, a pelog style pentatonic 5 
lpl_5_4 16/15 6/5 3/2 15/8 2
#Charles Lucy's scale 21 
lucy 68.750 121.875 190.625 245.313 259.375 314.063 381.250 435.938 504.688 573.438 626.563 704.688 750.000 764.063 818.750 885.938 940.625 1009.375 1078.125 1131.250 2/1
#Lucy's 19-tone scale 19 
lucy_19 68.451 122.535 190.986 245.070 313.521 381.972 436.056 504.507 572.958 627.042 695.493 763.944 818.028 886.479 940.563 1009.014 1077.465 1131.549 2/1
#Diatonic Lucy's scale 7 
lucy_7 190.986 381.972 504.507 695.493 886.479 1077.465 2/1
#Scale on the "Scholar's Lute" 7 
lute 8/7 6/5 5/4 4/3 3/2 5/3 2/1
#Lydian Chromatic Tonos 24 
LYDIAN_CHROM 20/19 10/9 20/17 40/33 5/4 10/7 20/13 8/5 80/49 5/3 20/11 2/1 40/19 20/9 40/17 80/33 5/2 20/7 40/13 16/5 160/49 10/3 40/11 4/1
#Schlesinger's Lydian Harmonia in the chromatic genus 7 
lydian_chrom2 26/25 13/12 13/10 13/9 26/17 13/8 2/1
#A harmonic form of Schlesinger's Chromatic Lydian inverted 7 
LYDIAN_CHROMinv 27/26 14/13 18/13 20/13 21/13 22/13 2/1
#Lydian Diatonic Tonos 24 
lydian_diat 20/19 10/9 5/4 4/3 10/7 40/27 20/13 5/3 40/23 20/11 40/21 2/1 40/19 20/9 5/2 8/3 20/7 88/27 40/13 10/3 80/23 40/11 80/21 4/1
#Schlesinger's Lydian Harmonia, a subharmonic series through 13 from 26 8 
LYDIAN_DIAT2 13/12 13/11 13/10 26/19 13/9 13/8 13/7 2/1
#A Lydian Diatonic with its own trite synemmenon replacing paramese 7 
lydian_diatcon 13/12 13/11 13/10 26/19 13/8 13/7 2/1
#Inverted Schlesinger's Lydian Harmonia, a harmonic series from 13 from 26 8 
LYDIAN_DIATinv 14/13 16/13 18/13 19/13 20/13 22/13 24/13 2/1
#Lydian Enharmonic Tonos 24 
lydian_enh 20/19 10/9 8/7 80/69 20/17 10/7 20/13 80/51 160/101 8/5 20/11 2/1 40/19 20/9 16/7 160/69 40/17 20/7 40/13 160/51 320/101 16/5 40/11 4/1
#Schlesinger's Lydian Harmonia in the enharmonic genus 7 
lydian_enh2 52/51 26/25 13/10 13/9 52/35 26/17 2/1
#A harmonic form of Schlesinger's Enharmonic Lydian inverted 7 
LYDIAN_ENHinv 53/52 27/26 18/13 20/13 41/26 21/13 2/1
#Schlesinger's Lydian Harmonia in the pentachromatic genus 7 
lydian_pent 65/63 13/12 13/10 13/9 65/43 13/8 2/1
#The Diatonic Perfect Immutable System in the Lydian Tonos 15 
lydian_pis 10/9 5/4 10/7 20/13 5/3 20/11 2/1 40/19 20/9 5/2 20/7 40/13 10/3 40/11 4/1
#Schlesinger's Lydian Harmonia in the first trichromatic genus 7 
lydian_tri 39/38 39/37 13/10 13/9 3/2 39/25 2/1
#Schlesinger's Lydian Harmonia in the second trichromatic genus 7 
lydian_tri2 39/38 13/12 13/10 13/9 3/2 13/8 2/1
#Mayumi Reinhard's Harmonic-13 scale. 1/1=440Hz. 12 
m-reinhard 14/13 13/12 16/13 13/10 18/13 13/9 20/13 13/8 22/13 13/7 208/105 2/1
#Chalmers' Major Mode Cluster 12 
major_clus 135/128 10/9 9/8 5/4 4/3 45/32 3/2 5/3 27/16 16/9 15/8 2/1
#Chalmers' Major Wing with 7 major and 6 minor triads 12 
major_wing 25/24 9/8 6/5 5/4 4/3 3/2 25/16 8/5 5/3 9/5 15/8 2/1
#Malaka, lyra tuning: soft or intense chromatic and tonic diatonic 7 
malaka 28/27 10/9 4/3 3/2 14/9 16/9 2
#Malcolm's Monochord 12 
malcolm 16/15 9/8 6/5 5/4 4/3 45/32 3/2 8/5 5/3 16/9 15/8 2
#Malcolm 2 12 
malcolm2 17/16 9/8 19/16 5/4 4/3 17/12 3/2 19/12 5/3 85/48 15/8 2/1
#Malcolm's Mid-East 7 
malcolm_me 9/8 5/4 11/8 3/2 7/4 15/8 2/1
#Mandelbaum's septimal 19-tone scale 19 
MANDELBAUM_19 25/24 15/14 9/8 7/6 6/5 5/4 9/7 4/3 7/5 36/25 3/2 14/9 8/5 5/3 7/4 9/5 15/8 27/14 2/1
#scale with two different ET step sizes 19 
marion 53.996 107.993 161.990 215.986 269.983 323.979 377.976 431.972 485.969 539.965 593.962 647.959 3/2 784.963 867.970 950.978 1033.985 1116.993 2
#Marion's 7-limit Scale # 1 24 
marion1 225/224 25/24 15/14 35/32 9/8 7/6 25/21 5/4 9/7 21/16 75/56 45/32 10/7 35/24 3/2 25/16 45/28 5/3 7/4 25/14 175/96 15/8 63/32 2/1
#Marion's 7-limit Scale # 10 25 
marion10 49/48 25/24 35/32 10/9 245/216 7/6 175/144 5/4 35/27 49/36 25/18 1225/864 35/24 49/32 14/9 25/16 175/108 5/3 245/144 7/4 49/27 175/96 50/27 35/18 2/1
#Marion's 7-limit Scale # 15 24 
marion15 36/35 15/14 54/49 8/7 6/5 60/49 5/4 9/7 27/20 48/35 135/98 10/7 72/49 3/2 54/35 8/5 45/28 80/49 12/7 432/245 9/5 90/49 27/14 2/1
#Marion's 7-limit Scale #19 25 
marion19 21/20 15/14 35/32 9/8 189/160 6/5 135/112 5/4 9/7 21/16 27/20 7/5 45/32 10/7 3/2 54/35 63/40 45/28 27/16 7/4 9/5 15/8 27/14 63/32 2/1
#Marion's 7-limit Scale # 26 24 
marion26 28/27 16/15 49/45 28/25 784/675 7/6 32/27 56/45 32/25 98/75 4/3 7/5 196/135 112/75 14/9 8/5 49/30 224/135 392/225 16/9 49/27 28/15 49/25 2/1
#Marpurg 1 12 
marpurg1 25/24 9/8 6/5 5/4 4/3 45/32 3/2 25/16 5/3 9/5 15/8 2
#Marpurg 3 12 
marpurg3 25/24 9/8 6/5 5/4 4/3 45/32 3/2 25/16 27/16 16/9 15/8 2
#Marpurg 4, also Yamaha Pure Minor 12 
MARPURG4 25/24 10/9 6/5 5/4 4/3 25/18 3/2 25/16 5/3 9/5 15/8 2/1
#Mubayiwa Bandambira's tuning of keys R2-R9 from Berliner: The soul of mbira. 7 
mbira_banda 185.000 389.000 593.000 756.000 914.000 1051.000 1302.000
#Mubayiwa Bandambira's Mbira DzaVadzimu tuning B1=114 Hz 21 
mbira_banda2 355.000 554.000 650.000 829.000 982.000 1400.000 1169.000 1850.000 1732.000 2038.000 2207.000 2400.001 1531.000 2415.001 2600.001 2804.001 3008.001 3171.001 3329.001 3466.001 3717.001
#John Gondo's Mbira DzaVadzimu tuning B1=122 Hz 21 
mbira_gondo 323.000 480.000 644.000 830.000 981.000 1330.000 1179.000 1888.000 1697.000 2025.000 2189.000 2371.001 1517.000 2390.001 2569.001 2787.001 2923.001 3105.001 3256.001 3417.001 3609.001
#John Kunaka's mbira tuning of keys R2-R9 7 
mbira_kunaka 196.000 377.000 506.000 676.000 877.000 1050.000 1148.000
#John Kunaka's Mbira DzaVadzimu tuning B1=113 Hz 21 
mbira_kunaka2 455.000 547.000 757.000 935.000 1089.000 1501.000 1260.000 1972.000 1763.000 2153.000 2317.001 2478.001 1638.000 2464.001 2660.001 2841.001 2970.001 3140.001 3341.001 3514.001 3612.001
#Hakurotwi Mude's Mbira DzaVadzimu tuning B1=132 Hz 21 
mbira_mude 174.000 289.000 575.000 612.000 770.000 1146.000 976.000 1678.000 1467.000 1848.000 1987.000 2115.000 1326.000 2117.000 2348.001 2528.001 2646.001 2860.001 3032.001 3205.001 3465.001
#Ephat Mujuru's Mbira DzaVadzimu tuning, B1=106 Hz 21 
mbira_mujuru 126.000 243.000 399.000 713.000 818.000 1232.000 1082.000 1706.000 1443.000 1858.000 1955.000 2219.000 1371.000 2210.000 2400.001 2556.001 2699.001 2918.001 3069.001 3197.001 3437.001
#Shona mbira scale 7 
mbira_zimb 98.000 271.000 472.000 642.000 771.000 952.000 1148.000
#McClain's 12-tone scale, see page 119 of The Myth of Invariance 12 
mcclain 135/128 9/8 75/64 5/4 81/64 45/32 3/2 25/16 27/16 15/8 125/64 2/1
#McClain's 18-tone scale, see page 143 of The Myth of Invariance 18 
MCCLAIN_18 135/128 9/8 75/64 625/512 5/4 81/64 675/512 45/32 375/256 3/2 25/16 405/256 27/16 225/128 15/8 243/128 125/64 2/1
#McClain's 8-tone scale, see page 51 of The Myth of Invariance 8 
MCCLAIN_8 9/8 5/4 45/32 3/2 25/16 27/16 15/8 2/1
#3/10-comma mean-tone scale 12 
mean10 68.522 191.006 259.528 382.012 504.497 573.019 695.503 764.025 886.509 125/72 1077.516 2/1
#3/11-comma mean-tone scale 12 
mean11 72.628 192.179 264.807 384.359 125/96 576.538 696.090 768.717 888.269 960.897 1080.448 2/1
#4/17-comma mean-tone scale, least square error of 5/4 and 3/2 19 
mean17 78.263 156.526 193.789 272.052 350.315 387.579 465.842 503.105 581.368 659.631 696.895 775.158 853.420 890.684 968.947 1875/1024 1084.474 1162.736 2/1
#2/9-comma mean-tone scale 12 
mean9 80.231 194.352 75/64 388.703 502.824 583.055 697.176 777.407 891.528 1005.648 1085.879 2/1
#1/5-comma mean-tone scale 12 
MEANFIFTH 83.577 195.308 307.039 390.615 502.347 585.923 697.654 781.230 892.962 1004.693 15/8 2/1
#Complete 1/5-comma mean-tone scale 27 
meanfifth_27 83.576 16/15 167.152 195.307 256/225 278.884 307.039 390.615 418.770 474.191 502.346 585.922 614.078 669.499 697.654 725.809 781.230 809.385 3375/2048 892.961 921.116 225/128 1004.693 15/8 1116.424 1171.845 2/1
#1/9-Harrison's comma mean-tone scale 12 
meanhar2 74.233 192.638 7/6 385.276 503.681 577.914 696.319 770.552 888.957 963.190 1081.595 2/1
#1/11-Harrison's comma mean-tone scale 12 
MEANHAR3 81.406 194.687 276.093 389.375 21/16 584.062 697.344 778.750 892.031 973.437 1086.719 2/1
#1/4-Harrison's comma mean-tone scale 12 
meanharris 78.178 193.765 271.943 387.530 503.117 581.296 696.883 775.061 890.648 7/4 1084.413 2/1
#Pi-based meantone with Harrison's major third by Erv Wilson 12 
meanpi 88.733 204.507 293.240 381.972 497.747 586.479 702.254 790.986 879.718 995.493 1084.225 2/1
#Pi-based meantone by Erv Wilson analogous to 22-tET 12 
meanpi2 163.756 218.216 381.972 436.432 600.188 654.648 709.108 872.864 927.324 1091.080 1145.540 2/1
#1/4-comma mean-tone scale 12 
meanquar 76.049 193.157 310.265 5/4 503.421 579.470 696.578 25/16 889.735 1006.843 1082.892 2/1
#Complete 1/4-comma mean-tone scale 27 
meanquar_27 76.049 117.108 152.098 193.157 234.216 269.206 310.265 5/4 32/25 462.363 503.422 579.471 620.529 655.520 696.578 737.637 25/16 8/5 848.676 889.735 930.794 965.784 1006.843 1082.892 1123.951 125/64 2/1
#1/9-schisma mean-tone scale Sabat-Garibaldi's 12 
meansabat 112.165 203.476 6/5 406.952 498.262 610.428 701.738 813.903 905.214 1017.379 1108.690 2/1
#1/8-schisma mean-tone scale Helmholtz 12 
meanschis 91.446 203.422 294.868 5/4 498.289 589.735 701.711 793.157 884.603 996.578 1088.025 2/1
#1/7-schisma mean-tone scale 12 
meanschis7 91.621 203.352 294.972 386.593 498.324 589.945 701.676 793.296 884.917 996.648 15/8 2/1
#Mean-tone scale with septimal diminished fifth 12 
meansept 79.598 194.171 273.769 388.342 502.915 7/5 697.085 776.683 891.256 970.854 1085.427 2/1
#Mean-tone scale with septimal neutral second 19 
meansept2 77.570 35/32 193.591 271.161 348.730 387.183 464.752 503.204 580.774 658.344 696.796 774.365 851.935 890.387 967.957 1045.526 1083.978 1161.548 2/1
#Mean-tone scale with septimal minor third 41 
MEANSEPT3 35.950 62.453 88.957 124.907 151.410 177.914 213.864 240.367 7/6 293.374 329.324 355.828 382.331 418.281 444.785 471.288 497.791 49/36 560.245 586.748 622.698 649.202 675.705 711.655 738.159 764.662 791.166 827.116 853.619 880.122 916.073 942.576 969.079 995.583 1031.533 1058.036 1084.540 1120.490 1146.993 1173.497 2/1
#Mean-tone scale with septimal narrow fourth 41 
meansept4 34.820 61.791 88.762 123.582 150.553 177.524 212.344 239.315 266.286 293.257 328.077 355.048 382.019 416.839 443.810 21/16 497.752 532.572 559.543 586.514 621.334 648.305 675.277 710.096 737.068 764.039 791.010 825.830 852.801 879.772 914.592 441/256 968.534 995.505 1030.325 1057.296 1084.267 1119.087 1146.058 1173.029 2/1
#Mean-tone scale with septimal diminished fifth 29 
meansept5 50.451 85.427 135.878 170.854 221.305 256.280 291.256 341.707 376.683 427.134 462.110 497.085 547.536 7/5 632.963 667.939 718.390 753.366 788.341 838.793 873.768 924.219 959.195 994.171 1044.622 1079.598 1130.049 49/25 2/1
#Mean-tone scale with septimal neutral second 41 
meansept6 40.866 65.335 89.805 130.671 35/32 179.609 220.475 244.944 269.414 293.883 334.749 359.218 383.687 424.554 449.023 473.492 497.961 538.827 563.296 587.765 628.632 653.101 677.570 718.436 742.905 767.375 791.844 832.710 857.179 881.648 922.514 946.984 971.453 995.922 1036.788 1061.257 1085.726 1126.593 1151.062 1175.531 2/1
#Mean-tone scale with harmonic seventh 41 
meansev 35.425 62.146 88.866 124.292 151.012 177.733 213.158 239.879 266.599 293.320 328.745 355.466 382.186 417.612 444.332 471.053 497.773 533.199 559.919 586.640 622.065 648.786 675.506 710.931 49/32 764.373 791.093 826.518 853.239 879.960 915.385 942.105 7/4 995.547 1030.972 1057.692 1084.413 1119.838 1146.559 1173.279 2/1
#Complete 1/6-comma mean-tone scale 27 
meansixth_27 88.594 108.147 177.189 196.741 216.294 285.336 304.888 393.482 413.035 482.077 501.629 45/32 64/45 678.818 698.371 717.923 786.965 806.518 875.559 895.112 914.664 983.706 1003.259 1091.853 1111.406 2025/1024 2/1
#1/3-comma mean-tone scale 12 
MEANTHIRD 63.504 189.573 6/5 379.145 505.214 25/18 694.787 758.290 5/3 1010.428 1073.932 2/1
#Complete 1/3-comma mean-tone scale 19 
meanthird_19 63.504 126.069 189.572 125/108 6/5 379.145 442.649 505.214 25/18 36/25 694.786 758.290 820.855 5/3 947.862 1010.428 1073.931 1136.496 2/1
#Mersenne Lute 1 12 
mersen_l1 16/15 10/9 6/5 5/4 4/3 64/45 3/2 8/5 5/3 9/5 15/8 2
#Mersenne lute 2 12 
mersen_l2 16/15 9/8 6/5 5/4 4/3 64/45 3/2 8/5 5/3 9/5 15/8 2
#Mersenne spinet 1 12 
mersen_s1 16/15 10/9 6/5 5/4 4/3 64/45 3/2 8/5 5/3 16/9 15/8 2
#Mersenne spinet 2 12 
mersen_s2 25/24 9/8 75/64 5/4 4/3 25/18 3/2 25/16 5/3 16/9 15/8 2
#Metabolika, lyra tuning: soft diatonic and tonic diatonic 7 
metabolika 21/20 7/6 4/3 3/2 14/9 16/9 2
#Erv Wilson's Meta-Meantone tuning 12 
metamean 69.413 191.261 260.674 382.522 504.370 573.783 695.630 765.043 886.891 956.304 1078.152 2/1
#Max Meyer, see Doty, David, 1/1 August 1992 (7:4) p.1 and 10-14 19 
meyer 16/15 10/9 9/8 8/7 7/6 6/5 5/4 4/3 7/5 10/7 3/2 8/5 5/3 12/7 7/4 16/9 9/5 15/8 2/1
#Max Meyer, see Doty, David, 1/1 August 1992 (7:4) p.1 and 10-14 29 
MEYER_29 525/512 135/128 35/32 567/512 9/8 75/64 315/256 5/4 81/64 21/16 675/512 175/128 45/32 729/512 375/256 189/128 3/2 25/16 405/256 105/64 27/16 7/4 225/128 945/512 15/8 243/128 125/64 63/32 2/1
#Mid-Mode1 Enharmonic, permutation of Archytas's with the 5/4 lying medially 7 
mid_enh1 36/35 9/7 4/3 3/2 54/35 27/14 2/1
#permutation of Archytas's Enharmonic with the 5/4 medially and 28/27 first 7 
mid_enh2 28/27 35/27 4/3 3/2 14/9 35/18 2/1
#From Lou Harrison, a symmetrical pentatonic with minor thirds 5 
minor 6/5 4/3 3/2 5/3 2
#A minor pentatonic 5 
minor2 8/7 4/3 8/5 16/9 2/1
#Chalmers' Minor Mode Cluster 12 
minor_clus 16/15 9/8 6/5 4/3 27/20 64/45 3/2 8/5 27/16 16/9 9/5 2
#Minor Duodene 12 
minor_duo 10/9 9/8 6/5 5/4 4/3 27/20 3/2 8/5 5/3 9/5 15/8 2
#Chalmers' Minor Wing with 7 minor and 6 major triads 12 
minor_wing 9/8 6/5 5/4 4/3 36/25 3/2 8/5 5/3 9/5 15/8 48/25 2
#21/20 x 20/19 x 19/18=7/6 7/6 x 8/7=4/3 9 
misca 21/20 21/19 7/6 4/3 3/2 63/40 63/38 7/4 2/1
#33/32 x 32/31x 31/27=11/9 11/9 x 12/11=4/3 9 
miscb 33/32 33/31 11/9 4/3 3/2 99/64 99/62 11/6 2/1
#96/91 x 91/86 x 86/54=32/27. 32/27 x 9/8=4/3. 9 
MISCC 96/91 48/43 32/27 4/3 3/2 144/91 72/43 16/9 2/1
#27/26 x 26/25 x 25/24=9/8. 9/8 x 32/27=4/3. 9 
miscd 27/26 27/25 9/8 4/3 3/2 81/52 81/50 27/16 2/1
#15/14 x 14/13 x 13/12=5/4. 5/4 x 16/15= 4/3. 9 
misce 15/14 15/13 5/4 4/3 3/2 45/28 45/26 15/8 2/1
#SupraEnh1 9 
miscf 28/27 16/15 4/3 81/56 3/2 14/9 8/5 27/14 2/1
#SupraEnh 2 9 
miscg 28/27 16/15 9/7 4/3 3/2 14/9 8/5 27/14 2/1
#SupraEnh 3 9 
misch 28/27 16/15 9/7 4/3 3/2 14/9 15/8 27/14 2/1
#A mixture of the hemiolic chromatic and diatonic genera, 75 + 75 + 150 + 200 c 9 
mix_ennea3 75.000 150.000 300.000 500.000 700.000 775.000 850.000 1000.000 2/1
#Each 'tetrachord" contains 67 + 67 + 133 + 233 9 
mix_ennea4 66.667 133.333 266.667 500.000 700.000 766.667 833.333 966.667 2/1
#A mixture of the intense chromatic genus and the permuted intense diatonic 9 
mix_ennea5 100.000 200.000 400.000 500.000 700.000 800.000 900.000 1100.000 2/1
#A " Mixed type" pentatonic, from Lou Harrison 5 
mixed 12/11 6/5 3/2 13/8 2
#A mixture of the hemiolic chromatic and diatonic genera, 75 + 75 + 150 + 200 c 9 
mixed9_3 75.000 150.000 300.000 500.000 700.000 775.000 850.000 1000.000 2/1
#Mixed Enneatonic 4, Each 'tetrachord" contains 67 + 67 + 133 + 233 . 9 
mixed9_4 66.667 133.333 266.667 500.000 700.000 766.667 833.333 966.667 2/1
#A mixture of the intense chromatic genus and the permuted intense diatonic 9 
mixed9_5 100.000 200.000 400.000 500.000 700.000 800.000 900.000 1100.000 2/1
#Mixed 9-tonic 6, Mixture of Chromatic and Diatonic 9 
mixed9_6 100.000 200.000 300.000 500.000 700.000 800.000 900.000 1000.000 2/1
#Mixed 9-tonic 7, Mixture of Chromatic and Diatonic 9 
mixed9_7 100.000 300.000 400.000 500.000 700.000 800.000 1000.000 1100.000 2/1
#Mixed 9-tonic 8, Mixture of Chromatic and Diatonic 9 
mixed9_8 200.000 300.000 400.000 500.000 700.000 900.000 1000.000 1100.000 2/1
#A " Mixed type" pentatonic, from Lou Harrison 5 
mixed_2 6/5 4/3 3/2 15/8 2
#A " Mixed type" pentatonic, from Lou Harrison 5 
mixed_3 6/5 9/7 3/2 8/5 2
#A " Mixed type" pentatonic, from Lou Harrison 5 
mixed_4 15/14 5/4 3/2 12/7 2
#MIXOLYDIAN CHROMATIC TONOS 24 
mixol_chrom 22/21 11/10 22/19 44/37 11/9 11/8 11/7 44/27 88/53 22/13 11/6 2/1 44/21 11/5 44/19 88/37 22/9 11/4 22/7 88/27 176/53 44/13 11/3 4/1
#Schlesinger's Mixolydian Harmonia in the chromatic genus 7 
MIXOL_CHROM2 28/27 14/13 14/11 7/5 28/19 14/9 2/1
#A harmonic form of Schlesinger's Chromatic Mixolydian inverted 7 
MIXOL_CHROMinv 16/15 8/7 10/7 11/7 23/14 12/7 2/1
#MIXOLYDIAN DIATONIC TONOS 24 
mixol_diat 22/21 11/10 11/9 22/17 11/8 22/15 11/7 22/13 44/25 11/6 44/23 2/1 44/21 11/5 22/9 44/17 11/4 44/15 22/7 44/13 88/25 11/3 88/23 4/1
#Schlesinger's Mixolydian Harmonia, a subharmonic series though 13 from 28 8 
mixol_diat2 14/13 7/6 14/11 4/3 7/5 14/9 7/4 2/1
#A Mixolydian Diatonic with its own trite synemmenon replacing paramese 7 
mixol_diatcon 14/13 7/6 14/11 3/2 14/9 7/4 2/1
#A Mixolydian Diatonic with its own trite synemmenon replacing paramese 7 
mixol_diatinv 8/7 9/7 4/3 11/7 12/7 13/7 2/1
#Inverted Schlesinger's Mixolydian Harmonia, a harmonic series from 14 from 28 8 
mixol_diatinv2 8/7 9/7 4/3 10/7 11/7 12/7 13/7 2/1
#MIXOLYDIAN ENHARMONIC TONOS 24 
mixol_enh 22/21 11/10 44/39 8/7 22/19 4/3 11/7 8/5 176/109 44/27 88/49 2/1 44/21 11/5 88/39 16/7 44/19 8/3 22/7 16/5 352/109 88/27 176/49 4/1
#Schlesinger's Mixolydian Harmonia in the enharmonic genus 7 
mixol_enh2 56/55 28/27 14/11 7/5 56/39 28/19 2/1
#A harmonic form of Schlesinger's Mixolydian inverted 7 
MIXOL_ENHinv 31/30 16/15 10/7 11/7 45/28 23/14 2/1
#Schlesinger's Mixolydian Harmonia in the pentachromatic genus 7 
mixol_penta 35/34 14/13 14/11 7/5 35/24 14/9 2/1
#The Diatonic Perfect Immutable System in the Mixolydian Tonos 15 
mixol_pis 11/10 11/9 11/8 11/7 22/13 11/6 2/1 44/21 11/5 22/9 11/4 22/7 44/13 11/3 4/1
#Schlesinger's Mixolydian Harmonia in the first trichromatic genus 7 
mixol_tri1 42/41 21/20 14/11 7/5 42/29 3/2 2/1
#Schlesinger's Mixolydian Harmonia in the second trichromatic genus 7 
mixol_tri2 42/41 14/13 14/11 7/5 42/29 14/9 2/1
#Mohajira + Bayati (Dudon) 3 + 4 + 3 Mohajira and 3 + 3 + 4 Bayati tetrachords 7 
moha_baya 150.000 350.000 500.000 700.000 850.000 1000.000 2/1
#Mohajira (Dudon) Two 3 + 4 + 3 Mohajira tetrachords 7 
mojahira 150.000 350.000 500.000 700.000 850.000 1050.000 2/1
#Montford's Spondeion, a mixed septimal and undecimal pentatonic 5 
montford 28/27 4/3 3/2 18/11 2/1
#Montvallon 12 
montvallon 135/128 9/8 6/5 5/4 4/3 45/32 3/2 405/256 5/3 16/9 15/8 2
#Wilson 11 of 34-tET, G=9, Chain of minor & major thirds with Kleismatic fusion 11 
mos11-34 70.588 247.059 317.647 494.118 564.706 635.294 811.765 882.353 952.941 1129.412 2/1
#MOS 12 of 17, generator 7 12 
mos12-17 70.588 141.176 282.353 352.941 494.118 564.706 635.294 776.471 847.059 988.235 1058.824 2/1
#MOS 12 of 22, contains nearly just, recognizable diatonic, and pentatonic scales 12 
mos12-22 163.636 218.182 381.818 436.364 490.909 654.545 709.091 872.727 927.273 1090.909 1145.455 2/1
#MOS 13 of 22, contains 5 and 9 tone MOS as well. G= 5 or 17 13 
mos13-22 109.091 218.182 327.273 381.818 490.909 600.000 654.545 763.636 872.727 927.273 1036.364 1145.455 2/1
#MOS 15 in 22, contains 7 and 8 tone MOS as well. G= 3 or 19 15 
mos15-22 109.091 163.636 272.727 327.273 436.364 490.909 600.000 654.545 763.636 818.182 927.273 981.818 1090.909 1145.455 2/1
#Egyptian scale by Miha'il Musaqa 7 
musaqa 200.000 350.000 500.000 700.000 850.000 1000.000 2
#Neidhardt temperament (1724) 12 
neidhardt 96.090 196.090 298.045 394.135 500.000 596.090 698.045 796.090 894.135 1000.000 1096.090 2/1
#Neutral Diatonic, 9 + 9 + 12 parts 7 
NEUTR_DIAT 150.000 300.000 500.000 700.000 850.000 1000.000 2/1
#Neutral Diatonic 9 + 12 + 9 parts 7 
NEUTR_DIAT2 150.000 350.000 500.000 700.000 850.000 1050.000 2/1
#Quasi-Neutral Pentatonic 1, 15/13 x 52/45 in each trichord, after Dudon 5 
neutr_pent1 52/45 4/3 3/2 26/15 2/1
#Quasi-Neutral Pentatonic 2, 15/13 x 52/45 in each trichord, after Dudon 5 
neutr_pent2 15/13 4/3 3/2 45/26 2/1
#New Soft Diatonic genus with equally divided Pyknon; Dorian Mode; 1:1 pyknon 7 
new_diatsoft 250.000 375.000 500.000 700.000 950.000 1075.000 2/1
#New Enharmonic 7 
new_enh 81/80 16/15 4/3 3/2 243/160 8/5 2/1
#P2 New Enharmonic 7 
NEW_ENH2 5/4 81/64 4/3 3/2 15/8 243/128 2/1
#9-limit diamond with 21/20, 16/15, 15/8 and 40/21 added for evenness 23 
novaro 21/20 16/15 10/9 9/8 8/7 7/6 6/5 5/4 9/7 4/3 7/5 10/7 3/2 14/9 8/5 5/3 12/7 7/4 16/9 9/5 15/8 40/21 2/1
#1-15 diamond, see Novaro, 1927, Sistema Natural base del Natural-Aproximado, p 49 
novaro15 16/15 15/14 14/13 13/12 12/11 11/10 10/9 9/8 8/7 15/13 7/6 13/11 6/5 11/9 16/13 5/4 14/11 9/7 13/10 4/3 15/11 11/8 18/13 7/5 10/7 13/9 16/11 22/15 3/2 20/13 14/9 11/7 8/5 13/8 18/11 5/3 22/13 12/7 26/15 7/4 16/9 9/5 20/11 11/6 24/13 13/7 28/15 15/8 2/1
#1)8 octany from 1.3.5.7.9.11.13.15, 1.3 tonic 8 
octany1 9/8 5/4 11/8 3/2 13/8 7/4 15/8 2/1
#7)8 octany from 1.3.5.7.9.11.13.15, 1.3.5.7.9.11.13 tonic 8 
octany7 15/14 15/13 5/4 15/11 3/2 5/3 15/8 2/1
#Octony on Harmonic Minor, from Palmer on an album of Turkish music 8 
octony 9/8 6/5 5/4 4/3 3/2 8/5 15/8 2/1
#7-limit Octony. See Ch.6 p.118 an Euler Genus Musicum on white keys + Bb 8 
octony7 35/32 5/4 21/16 3/2 105/64 7/4 15/8 7/1
#Rotated Octony on Harmonic Minor 8 
octony_rot 5/4 4/3 3/2 25/16 8/5 5/3 15/8 2/1
#Complex 10 of p. 115, an Octony based on Archytas's Enharmonic, 8 
OCTONY_trans 28/27 16/15 5/4 4/3 25/16 45/28 5/3 2/1
#Complex 6 of p. 115 based on Archytas's Enharmonic, an Octony 8 
OCTONY_trans2 28/27 16/15 135/112 243/196 9/7 4/3 27/14 2/1
#Complex 5 of p. 115 based on Archytas's Enharmonic, an Octony 8 
octony_trans3 28/27 16/15 75/64 135/112 5/4 4/3 15/8 2/1
#Complex 11 of p. 115, an Octony based on Archytas's Enharmonic, 8 tones 8 
OCTONY_TRANS4 28/27 16/15 9/7 4/3 45/28 81/49 12/7 2/1
#Complex 15 of p. 115, an Octony based on Archytas's Enharmonic, 8 tones 8 
OCTONY_TRANS5 28/27 16/15 175/144 5/4 35/27 4/3 35/18 2/1
#Complex 14 of p. 115, an Octony based on Archytas's Enharmonic, 8 tones 8 
OCTONY_TRANS6 36/35 28/27 16/15 9/7 324/245 4/3 48/35 2/1
#ODD-1 12 
odd1 25/24 6/5 5/4 36/25 3/2 25/16 8/5 5/3 9/5 15/8 48/25 2/1
#ODD-2 12 
odd2 10/9 9/8 75/64 6/5 5/4 4/3 25/18 3/2 5/3 9/5 15/8 2/1
#von Oettingen's Orthotonophonium tuning 53 
oettingen 81/80 128/125 25/24 135/128 16/15 27/25 1125/1024 10/9 9/8 729/640 144/125 75/64 1215/1024 6/5 243/200 10125/8192 5/4 81/64 32/25 162/125 675/512 4/3 27/20 512/375 25/18 45/32 729/512 36/25 375/256 6075/4096 3/2 243/160 192/125 25/16 405/256 8/5 81/50 3375/2048 5/3 27/16 128/75 216/125 225/128 16/9 9/5 729/400 30375/16384 15/8 243/128 48/25 125/64 2025/1024 2/1
#von Oettingen's Orthotonophonium tuning with central 1/1 53 
OETTINGEN2 81/80 128/125 25/24 135/128 16/15 27/25 1125/1024 10/9 9/8 256/225 144/125 75/64 32/27 6/5 4096/3375 100/81 5/4 81/64 32/25 125/96 675/512 4/3 27/20 512/375 25/18 45/32 64/45 36/25 375/256 40/27 3/2 1024/675 192/125 25/16 128/81 8/5 81/50 3375/2048 5/3 27/16 128/75 125/72 225/128 16/9 9/5 2048/1125 50/27 15/8 256/135 48/25 125/64 160/81 2/1
#This scale by Norbert. L. Oldani appeared in Interval 5(3):10-11 12 
oldani 25/24 9/8 32/27 5/4 4/3 45/32 3/2 25/16 5/3 16/9 15/8 2/1
#Scale of ancient Greek flutist Olympos, 6th century BC as reported by Partch 5 
Olympos 16/15 4/3 64/45 16/9 2/1
#Other Music (7 limit black keys) 12 
other 15/14 9/8 7/6 5/4 4/3 7/5 3/2 14/9 5/3 7/4 15/8 2/1
#Other Music gamelan 12 
other_gamelan 15/14 9/8 7/6 5/4 4/3 7/5 3/2 14/9 5/3 7/4 15/8 2/1
#over/under16 30 
over-under16 2/1 3/1 4/1 5/1 6/1 7/1 8/1 9/1 10/1 11/1 12/1 13/1 14/1 15/1 16/1 8/1 16/3 4/1 16/5 8/3 16/7 2/1 16/9 8/5 16/11 4/3 16/13 8/7 16/15 1/1
#Overtones 1-23 reduced within one octave 12 
overtone 17/16 9/8 19/16 5/4 21/16 11/8 23/16 3/2 13/8 7/4 15/8 2/1
#Overtones 1-12 12 
overtones 1/1 2/1 3/1 4/1 5/1 6/1 7/1 8/1 9/1 10/1 11/1 12/1
#Observed south pacific pentatonic xylophone tuning 5 
pacific 202.000 370.000 685.000 903.000 2
#Palace mode+ 12 
palace 18/17 9/8 8/7 9/7 4/3 10/7 3/2 36/23 18/11 12/7 9/5 2/1
#Parachromatic, new genus 5 + 5 + 20 parts 7 
parachrom 83.333 166.667 500.000 700.000 783.333 866.667 2/1
#Ramis de Pareja 12 
pareja 135/128 10/9 32/27 5/4 4/3 45/32 3/2 128/81 5/3 16/9 15/8 2
#Partch 11-limit Diamond 29 
PARTCH_29 12/11 11/10 10/9 9/8 8/7 7/6 6/5 11/9 5/4 14/11 9/7 4/3 11/8 7/5 10/7 16/11 3/2 14/9 11/7 8/5 18/11 5/3 12/7 7/4 16/9 9/5 20/11 11/6 2/1
#13-limit Diamond after Partch, Genesis of a Music, p 454, 2nd edition 41 
PARTCH_41 14/13 13/12 12/11 11/10 10/9 9/8 8/7 7/6 13/11 6/5 11/9 16/13 5/4 14/11 9/7 13/10 4/3 11/8 18/13 7/5 10/7 13/9 16/11 3/2 20/13 14/9 11/7 8/5 13/8 18/11 5/3 22/13 12/7 7/4 16/9 9/5 20/11 11/6 24/13 13/7 2/1
#Harry Partch's 43-tone pure scale 43 
PARTCH_43 81/80 33/32 21/20 16/15 12/11 11/10 10/9 9/8 8/7 7/6 32/27 6/5 11/9 5/4 14/11 9/7 21/16 4/3 27/20 11/8 7/5 10/7 16/11 40/27 3/2 32/21 14/9 11/7 8/5 18/11 5/3 27/16 12/7 7/4 16/9 9/5 20/11 11/6 15/8 40/21 64/33 160/81 2/1
#Partch Greek scales from "Two Studies on Ancient Greek Scales" on black/white 12 
partch_greek 1/1 28/27 9/8 16/15 4/3 6/5 3/2 3/2 14/9 8/5 8/5 2/1
#Observed Javanese Pelog scale 7 
pelog 137.000 446.000 575.000 687.000 820.000 1098.000 2
#Chalmers' PELOG/BH SLENDRO 12 
pelog_jc 1/1 8/7 8/7 9/8 64/49 6/5 3/2 3/2 3/2 12/7 8/5 2/1
#Modern Pelog designed by Dan Schmidt and used by Berkeley Gamelan 7 
pelog_usa 11/10 6/5 7/5 3/2 8/5 9/5 2
#Pentagonal scale 9/8 3/2 16/15 4/3 5/3 12 
penta1 27/25 9/8 6/5 81/64 729/512 36/25 243/160 81/50 27/16 9/5 243/128 2
#Pentagonal scale 7/4 4/3 15/8 32/21 6/5 12 
penta3 49/48 35/32 7/6 1225/1024 245/192 49/36 25/18 49/32 5/3 7/4 175/96 2
#2)6 1.3.5.7.11.13 Pentadekany 15 
pentadekany 13/12 55/48 7/6 5/4 65/48 11/8 35/24 143/96 77/48 13/8 5/3 7/4 11/6 91/48 2/1
#2)6 1.3.5.7.9.11 Pentadekany (1.3 tonic) 15 
PENTADEKANY2 33/32 9/8 55/48 7/6 5/4 21/16 11/8 35/24 3/2 77/48 5/3 7/4 11/6 15/8 2/1
#4:5:6 Pentatriadic scale 11 
pentatriad 10/9 9/8 5/4 4/3 45/32 3/2 5/3 27/16 16/9 15/8 2/1
#PERKIS 60-30 12 
perkis 15/14 10/9 6/5 5/4 4/3 10/7 3/2 30/19 5/3 12/7 15/8 2/1
#Permuted Enharmonic, After Wilson's Marwa Permutations, See page 110. 7 
perm_enh 28/27 16/15 4/3 3/2 14/9 16/9 2/1
#Perrett Tierce-Tone 19 
perrett-tt 21/20 35/32 9/8 7/6 6/5 5/4 21/16 4/3 7/5 35/24 3/2 63/40 8/5 5/3 7/4 9/5 15/8 63/32 2/1
#Perrett / Tartini / Pachymeres Enharmonic 7 
perrett 21/20 16/15 4/3 3/2 63/40 8/5 2/1
#Perrett's 14-tone system (subscale of tierce-tone) 14 
perrett_14 21/20 9/8 7/6 5/4 21/16 4/3 7/5 3/2 63/40 5/3 7/4 15/8 63/32 2/1
#Perrett's Chromatic 7 
perrett_chrom 21/20 9/8 4/3 3/2 63/40 27/16 2/1
#Persian Tar Scale, from Dariush Anooshfar, Internet Tuning List 2/10/94 17 
persian 256/243 27/25 9/8 32/27 243/200 81/64 4/3 25/18 36/25 3/2 128/81 81/50 27/16 16/9 729/400 243/128 2/1
#Phi + 1 equal division by 17 17 
phi_17 98.011 196.021 294.032 392.042 490.053 588.064 686.074 784.085 882.096 980.106 1078.117 1176.128 1274.138 1372.149 1470.159 1568.170 1666.181
#Inverted Conjunct Chromatic Phrygian 7 
phryg_chromcon 13/12 4/3 17/12 3/2 11/6 23/12 2/1
#Harmonic Conjunct Chromatic Phrygian 7 
PHRYG_CHROMcon2 13/12 9/8 7/6 3/2 19/12 5/3 2/1
#Inverted Schlesinger's Chromatic Phrygian 7 
PHRYG_CHROMinv 25/24 13/12 4/3 3/2 19/12 5/3 2/1
#Schlesinger's Phrygian Harmonia, a subharmonic series through 13 from 24 8 
PHRYG_DIAT 12/11 6/5 4/3 24/17 3/2 12/7 24/13 2/1
#A Phrygian Diatonic with its own trite synemmenon replacing paramese 7 
phryg_diatcon 12/11 6/5 4/3 24/17 12/7 24/13 2/1
#Inverted Schlesinger's Phrygian Harmonia, a harmonic series from 12 from 24 8 
PHRYG_DIATinv 13/12 7/6 4/3 17/12 3/2 5/3 11/6 2/1
#Schlesinger's Phrygian Harmonia in the enharmonic genus 7 
PHRYG_ENH 48/47 24/23 4/3 3/2 48/31 8/5 2/1
#Harmonic Conjunct Enharmonic Phrygian 7 
PHRYG_ENHcon 13/12 53/48 9/8 3/2 37/24 19/12 2/1
#Inverted Schlesinger's Enharmonic Phrygian Harmonia 7 
phryg_enhinv 5/4 31/24 4/3 3/2 23/12 47/24 2/1
#Inverted harmonic form of Schlesinger's Enharmonic Phrygian 7 
PHRYG_ENHINV2 49/48 25/24 4/3 3/2 37/24 19/12 2/1
#Inverted Schlesinger's Chromatic Phrygian Harmonia 7 
phryg_inv 7/6 5/4 4/3 3/2 11/6 23/12 2/1
#Inverted Conjunct Phrygian Harmonia with 17, the local Trite Synemmenon 7 
phryg_invcon 13/12 7/6 17/12 3/2 5/3 11/6 2/1
#Schlesinger's Phrygian Harmonia in the pentachromatic genus 7 
phryg_penta 30/29 12/11 4/3 3/2 30/19 12/7 2/1
#The Diatonic Perfect Immutable System in the Phrygian Tonos 15 
phryg_pis 9/8 9/7 18/13 3/2 18/11 9/5 2/1 36/17 9/4 18/7 36/13 3/1 36/11 18/5 4/1
#Schlesinger's Phrygian Harmonia in the chromatic genus 7 
phryg_tri1 24/23 12/11 4/3 3/2 8/5 12/7 2/1
#Schlesinger's Phrygian Harmonia in the second trichromatic genus 7 
phryg_tri2 36/35 12/11 4/3 3/2 36/23 12/7 2/1
#Schlesinger's Phrygian Harmonia in the first trichromatic genus 7 
phryg_tri3 36/35 18/17 4/3 3/2 36/23 18/11 2/1
#Old Phrygian ?? 12 
phrygian 10/9 6/5 5/4 4/3 27/20 40/27 3/2 8/5 5/3 16/9 9/5 2
#Old Phrygian?, also McClain's 7-tone scale 7 
PHRYGIAN7 10/9 6/5 4/3 3/2 5/3 9/5 2/1
#Phrygian Chromatic Tonos 24 
PHRYGIAN_CHROM 18/17 9/8 6/5 36/29 9/7 18/13 3/2 36/23 8/5 18/11 9/5 2/1 36/17 9/4 12/5 72/29 18/7 36/13 3/1 72/23 16/5 36/11 18/5 4/1
#Phrygian Diatonic Tonos 24 
PHRYGIAN_DIAT 18/17 9/8 9/7 4/3 18/13 36/25 3/2 18/11 12/7 9/5 36/19 2/1 36/17 9/4 18/7 8/3 36/13 72/25 3/1 36/11 24/7 18/5 72/19 4/1
#Phrygian Enharmonic Tonos 12 
phrygian_enh 18/17 9/8 36/31 72/61 6/5 4/3 3/2 72/47 48/31 36/23 72/41 2/1
#Phrygian Harmonia-Aliquot 24 (flute tuning) 12 
phrygian_harm 24/23 12/11 8/7 6/5 24/19 4/3 24/17 3/2 8/5 12/7 24/13 2/1
#13th root of pi 13 
pi 152.446 304.892 457.337 609.783 762.229 914.675 1067.121 1219.566 1372.012 1524.458 1676.904 1829.350 1981.796
#Enhanced Piano -Total Gamut, see 1/1 vol 8:2 January 1994 19 
piano 135/128 16/15 9/8 7/6 6/5 5/4 4/3 45/32 64/45 3/2 14/9 8/5 5/3 27/16 7/4 16/9 15/8 63/32 2/1
#Enhanced piano 7-limit 12 
piano7 135/128 9/8 7/6 5/4 4/3 45/32 3/2 14/9 27/16 7/4 15/8 2/1
#Pierce-Bohlen scale. 13-tone equal division of 3 13 
pierce 146.304 292.608 438.913 585.217 731.521 877.825 1024.130 1170.434 1316.738 1463.042 1609.347 1755.651 3/1
#Three interlocking harmonic series on 1:5:3 by Larry Polansky in Psaltery 50 
polansky_ps 2/1 3/1 4/1 5/1 6/1 7/1 8/1 9/1 10/1 11/1 12/1 13/1 14/1 15/1 16/1 17/1 5/4 5/2 15/4 5/1 25/4 15/2 35/4 10/1 45/4 25/2 55/4 15/1 65/4 35/2 75/4 20/1 85/4 3/2 3/1 9/2 6/1 15/2 9/1 21/2 12/1 27/2 15/1 33/2 18/1 39/2 21/1 45/2 24/1 51/2
#Poole's double diatonic or dichordal scale 7 
poole 9/8 5/4 4/3 3/2 5/3 7/4 2/1
#Portugese bagpipe tuning 7 
PORTBAG1 14/13 81/68 32/25 36/25 128/81 7/4 2/1
#Portugese bagpipe tuning 2 10 
portbag2 21/20 14/13 32/27 17/14 21/16 64/45 3/2 25/16 59/32 2/1
#What Lou Harrison calls " the Prime Pentatonic"; A widely used scale 5 
prime_5 9/8 5/4 3/2 5/3 2
#Progressive Enneatonic, 50+100+150+200 in each half (500 ) 9 
prog_ennea 50.000 150.000 300.000 500.000 700.000 750.000 850.000 1000.000 2/1
#Progressive Enneatonic, appr. 50+100+150+200 in each half (500 ) 9 
PROG_ENNEA1 36/35 12/11 19/16 4/3 3/2 17/11 18/11 16/9 2/1
#Progressive Enneatonic, appr. 50+100+200+150 in each half (500 ) 9 
prog_ennea2 34/33 12/11 27/22 4/3 3/2 17/11 18/11 81/44 2/1
#Progressive Enneatonic, appr. 50+100+150+200 in each half (500 ) 9 
prog_ennea3 34/33 12/11 32/27 4/3 3/2 17/11 18/11 16/9 2/1
#Complex 4 of p. 115 based on Archytas's Enharmonic 7 
ps-dorian 28/27 16/15 4/3 3/2 15/8 27/14 2/1
#Dorian mode of an Enharmonic genus found in Ptolemy's Harmonics 7 
ps-enh 56/55 16/15 4/3 3/2 84/55 8/5 2/1
#Complex 7 of p. 115 based on Archytas's Enharmonic 7 
ps-hypod 9/8 45/32 81/56 3/2 14/9 8/5 2/1
#Complex 7 of p. 115 based on Archytas's Enharmonic 7 
PS-HYPOD1 9/8 45/32 81/56 3/2 14/9 8/5 2/1
#Complex 8 of p. 115 based on Archytas's Enharmonic 7 
PS-HYPOD2 9/8 7/6 6/5 3/2 15/8 27/14 2/1
#Complex 3 of p. 115 based on Archytas's Enharmonic 7 
ps-mixol 28/27 16/15 4/3 5/3 12/7 16/9 2/1
#Intense Diatonic Systonon 7 
ptolemy 9/8 5/4 4/3 3/2 5/3 15/8 2
#Ptolemy's kithara tuning, mixture of Tonic Diatonic and Ditone Diatonic 7 
PTOLEMY_Aiolika 28/27 32/27 4/3 3/2 27/16 16/9 2/1
#Ptolemy Soft Chromatic 7 
ptolemy_chrom 28/27 10/9 4/3 3/2 14/9 5/3 2/1
#Ptolemy's Diatonon Ditoniaion 7 
ptolemy_ditonian 28/27 32/27 4/3 3/2 14/9 16/9 2
#Dorian mode of a permutation of Ptolemy's Tonic Diatonic 7 
ptolemy_diat2 28/27 7/6 4/3 3/2 14/9 7/4 2/1
#Dorian mode of the remaining permutation of Ptolemy's Intense Diatonic 7 
PTOLEMY_DIAT3 9/8 6/5 4/3 3/2 27/16 9/5 2/1
#permuted Ptolemy's diatonic 7 
PTOLEMY_DIAT4 8/7 32/27 4/3 3/2 12/7 16/9 2/1
#Dorian mode of Ptolemy's Intense Diatonic (Diatonon Syntonon) 7 
PTOLEMY_dor 16/15 6/5 4/3 3/2 8/5 9/5 2/1
#Dorian mode of Ptolemy's Enharmonic 7 
PTOLEMY_enh 46/45 16/15 4/3 3/2 23/15 8/5 2/1
#Dorian mode of Ptolemy's Equable Diatonic or Diatonon Homalon 7 
PTOLEMY_hom 12/11 6/5 4/3 3/2 18/11 9/5 2/1
#Ptolemy's Iastia or Lydia tuning, mixture of Tonic Diatonic & Intense Diatonic 7 
ptolemy_iast 28/27 32/27 4/3 3/2 8/5 9/5 2/1
#Dorian mode of Ptolemy's Intense Chromatic 7 
PTOLEMY_intchrom 22/21 8/7 4/3 3/2 11/7 12/7 2/1
#Ptolemy's Malaka lyra tuning, a mixture of Intense Chrom. & Tonic Diatonic 7 
PTOLEMY_malak 22/21 8/7 4/3 3/2 14/9 16/9 2/1
#Malaka lyra, mixture of his Soft Chromatic and Tonic Diatonic. 7 
PTOLEMY_MALAK2 28/27 10/9 4/3 3/2 14/9 16/9 2/1
#Ptolemy soft diatonic 7 
ptolemy_maldiat 21/20 7/6 4/3 3/2 63/40 7/4 2/1
#permuted Ptolemy soft diatonic 7 
PTOLEMY_MALDIAT2 10/9 7/6 4/3 3/2 5/3 7/4 2/1
#permuted Ptolemy soft diatonic 7 
PTOLEMY_MALDIAT3 8/7 6/5 4/3 3/2 12/7 9/5 2/1
#Metabolika lyra tuning, mixture of Soft Diatonic & Tonic Diatonic 7 
ptolemy_meta 21/20 7/6 4/3 3/2 14/9 16/9 2/1
#5-limit 19-tone scale 19 
pure_19 25/24 135/128 16/15 9/8 75/64 6/5 5/4 4/3 27/20 45/32 3/2 25/16 8/5 5/3 27/16 225/128 9/5 15/8 2/1
#Pure (just) C major, see Wilkinson: Tuning In 12 
PURMAJ 16/15 9/8 6/5 5/4 4/3 45/32 3/2 8/5 5/3 16/9 15/8 2/1
#Pure (just) C minor, see Wilkinson: Tuning In 12 
purmin 25/24 10/9 6/5 5/4 4/3 45/32 3/2 8/5 5/3 16/9 15/8 2/1
#This scale may also be called the "Wedding Cake" 12 
pyramid 9/8 75/64 5/4 4/3 45/32 3/2 25/16 5/3 27/16 16/9 15/8 2/1
#Upside-Down Wedding Cake (divorce cake) 12 
pyramid_down 16/15 9/8 6/5 32/25 4/3 3/2 8/5 27/16 16/9 9/5 48/25 2/1
#12-tone Pythagorean scale 12 
pyth_12 2187/2048 9/8 32/27 81/64 4/3 729/512 3/2 6561/4096 27/16 16/9 243/128 2/1
#17-tone Pythagorean scale 17 
pyth_17 256/243 2187/2048 9/8 32/27 19683/16384 81/64 4/3 1024/729 729/512 3/2 128/81 6561/4096 27/16 16/9 59049/32768 243/128 2/1
#Pythagorean shrutis 22 
pyth_22 256/243 2187/2048 65536/59049 9/8 32/27 19683/16384 8192/6561 81/64 4/3 177147/131072 1024/729 729/512 3/2 128/81 6561/4096 32768/19683 27/16 16/9 59049/32768 4096/2187 243/128 2/1
#27-tone Pythagorean scale 27 
pyth_27 531441/524288 256/243 2187/2048 65536/59049 9/8 4782969/4194304 32/27 19683/16384 8192/6561 81/64 4/3 177147/131072 1024/729 729/512 262144/177147 3/2 1594323/1048576 128/81 6561/4096 32768/19683 27/16 14348907/8388608 16/9 59049/32768 4096/2187 243/128 2/1
#31-tone Pythagorean scale 31 
pyth_31 128/125 135/128 27/25 1125/1024 9/8 144/125 75/64 6/5 625/512 5/4 32/25 675/512 27/20 5625/4096 45/32 36/25 375/256 3/2 192/125 25/16 8/5 3375/2048 27/16 216/125 225/128 9/5 1875/1024 15/8 48/25 125/64 2/1
#Pythagorean diatonic scale 7 
pyth_7 256/243 32/27 4/3 3/2 128/81 16/9 2/1
#Dorian mode of the so-called Pythagorean chromatic, recorded by Gaudentius 8 
pyth_chrom 256/243 9/8 4/3 3/2 128/81 27/16 16/9 2/1
#Quasi-Equal 5-Tone in 24-tET, 5 5 4 5 5 steps 5 
quasi_5 250.000 500.000 700.000 950.000 2/1
#Quasi-Equal Enneatonic, Each "tetrachord" has 125 + 125 + 125 + 125 9 
quasi_9 125.000 250.000 375.000 500.000 700.000 825.000 950.000 1075.000 2/1
#Aristides Quintilianus' Chromatic genus 7 
quint_chrom 18/17 9/8 4/3 3/2 27/17 27/16 2/1
#Medieval Arabic scale 7 
rahawi 65536/59049 8192/6561 4/3 262144/177147 128/81 16/9 2
#A folk scale from Rajasthan, India 6 
raja_6 9/8 5/4 4/3 3/2 15/8 2
#Rameau scale (1725) 12 
rameau 86.803 193.157 297.801 386.314 503.421 584.848 696.579 788.758 889.735 1006.843 1082.892 2
#Ramis's Monochord 12 
ramis 135/128 10/9 32/27 5/4 4/3 45/32 3/2 8/5 5/3 16/9 15/8 2/1
#Medieval arabic scale 7 
rast 9/8 8192/6561 4/3 3/2 32768/19683 16/9 2
#Rast + Mohajira (Dudon) 4 + 3 + 3 Rast and 3 + 4 + 3 Mohajira tetrachords 7 
rast_moha 200.000 350.000 500.000 700.000 850.000 1050.000 2/1
#Rationalized Schlesinger's Dorian Harmonia in the enharmonic genus 7 
rat_dorenh 44/43 22/21 11/8 11/7 8/5 44/27 2/1
#1+1 rationalized enharmonic genus derived from K.S.'s 'Bastard' Hypodorian 7 
rat_hypodenh 32/31 16/15 4/3 16/11 64/43 32/21 2/1
#1+2 rationalized enharmonic genus derived from K.S.'s 'Bastard' Hypodorian 7 
rat_hypodenh2 32/31 32/29 4/3 16/11 64/43 64/41 2/1
#1+3 rationalized enharmonic genus derived from K.S.'s 'Bastard' Hypodorian 7 
rat_hypodenh3 32/31 8/7 4/3 16/11 64/43 8/5 2/1
#1+1 rationalized hexachromatic/hexenharmonic genus derived from K.S.'Bastard' 7 
rat_hypodhex 48/47 24/23 4/3 16/11 96/65 3/2 2/1
#1+2 rat. hexachromatic/hexenharmonic genus derived from K.S.'s 'Bastard' Hypodo 7 
RAT_HYPODHEX2 48/47 16/15 4/3 16/11 96/65 32/21 2/1
#1+3 rat. hexachromatic/hexenharmonic genus from K.S.'s 'Bastard' Hypodorian 7 
RAT_HYPODHEX3 48/47 12/11 4/3 16/11 96/65 48/31 2/1
#1+4 rat. hexachromatic/hexenharmonic genus from K.S.'s 'Bastard' Hypodorian 7 
RAT_HYPODHEX4 48/47 48/43 4/3 16/11 96/65 96/61 2/1
#1+5 rat. hexachromatic/hexenharmonic genus from K.S.'s 'Bastard' Hypodorian 7 
RAT_HYPODHEX5 48/47 8/7 4/3 16/11 96/65 8/5 2/1
#2+3 rationalized hexachromatic/hexenharmonic genus from K.S.'s 'Bastard' hypod 7 
RAT_HYPODHEX6 24/23 48/43 4/3 16/11 3/2 96/61 2/1
#1+1 rationalized pentachromatic/pentenharmonic genus derived from K.S.'s 'Bastar 7 
RAT_HYPODpen 40/39 20/19 4/3 16/11 40/27 80/53 2/1
#1+2 rationalized pentachromatic/pentenharmonic genus from K.S.'s 'Bastard' hyp 7 
RAT_HYPODPEN2 40/39 40/37 4/3 16/11 40/27 20/13 2/1
#1+3 rationalized pentachromatic/pentenharmonic genus from 'Bastard' Hypodorian 7 
RAT_HYPODPEN3 40/39 10/9 4/3 16/11 40/27 80/51 2/1
#1+4 rationalized pentachromatic/pentenharmonic genus from 'Bastard' Hypodorian 7 
RAT_HYPODPEN4 40/39 8/7 4/3 16/11 40/27 8/5 2/1
#2+3 rationalized pentachromatic/pentenharmonic genus from 'Bastard' Hypodorian 7 
RAT_HYPODPEN5 20/19 10/9 4/3 16/11 80/53 80/51 2/1
#2+3 rationalized pentachromatic/pentenharmonic genus from 'Bastard' Hypodorian 7 
RAT_HYPODPEN6 40/39 8/7 4/3 16/11 80/53 8/5 2/1
#rationalized first (1+1) trichromatic genus derived from K.S.'s 'Bastard' hyp 7 
RAT_HYPODTRI 24/23 12/11 4/3 16/11 3/2 48/31 2/1
#rationalized second (1+2) trichromatic genus derived from K.S.'s 'Bastard' hyp 7 
RAT_HYPODTRI2 24/23 8/7 4/3 16/11 3/2 8/5 2/1
#Rationalized Schlesinger's Hypolydian Harmonia in the enharmonic genus 8 
rat_hypolenh 40/39 20/19 4/3 10/7 20/13 80/51 8/5 2/1
#Rationalized Schlesinger's Hypophrygian Harmonia in the chromatic genus 7 
rat_hypopchrom 18/17 9/8 18/13 3/2 36/23 18/11 2/1
#Rationalized Schlesinger's Hypophrygian Harmonia in the enharmonic genus 7 
rat_hypopenh 36/35 18/17 18/13 3/2 72/47 36/23 2/1
#Rationalized Schlesinger's Hypophrygian Harmonia in the pentachromatic genus 7 
rat_hypoppen 45/43 9/8 18/13 3/2 45/29 18/11 2/1
#Rationalized Schlesinger's Hypophrygian Harmonia in first trichromatic genus 7 
rat_hypoptri 27/26 27/25 18/13 3/2 54/35 27/17 2/1
#Rationalized Schlesinger's Hypophrygian Harmonia in second trichromatic genus 7 
RAT_HYPOPTRI2 27/26 9/8 18/13 3/2 54/35 18/11 2/1
#Redfield New Diatonic 7 
redfield 10/9 5/4 4/3 3/2 5/3 15/8 2/1
#Reinhard 12 
reinhard 18/17 9/8 45/38 5/4 4/3 24/17 3/2 30/19 5/3 30/17 15/8 2/1
#Dead Robot (see lattice) 12 
robot 25/24 16/15 9/8 75/64 6/5 5/4 4/3 45/32 3/2 5/3 15/8 2/1
#Live Robot 12 
robot_live 9/8 6/5 5/4 32/25 4/3 36/25 3/2 8/5 128/75 15/8 48/25 2/1
#Romieu 12 
romieu 25/24 9/8 6/5 5/4 4/3 45/32 3/2 25/16 5/3 16/9 15/8 2
#Rousseau 12 
rousseau 25/24 9/8 6/5 5/4 4/3 25/18 3/2 8/5 5/3 125/72 15/8 2
#RSR - 7 limit JI 12 
rsr 16/15 8/7 6/5 5/4 4/3 7/5 3/2 8/5 5/3 9/5 15/8 2/1
#Safiyu-D-Din's Diatonic, also the strong form of Avicenna's 8/7 diatonic 7 
Safiyu_diat 19/18 7/6 4/3 3/2 19/12 7/4 2/1
#Safiyu-D-Din #2 Diatonic, a 3/4 tone diatonic like Ptolemy's Equable Diatonic 7 
Safiyu_diat2 64/59 32/27 4/3 3/2 96/59 16/9 2/1
#Singular Major (DF #6), from Safiyu-d-Din 6 
Safiyu_major 14/13 16/13 4/3 56/39 3/2 2/1
#Tritonic temperament of Salinas 12 
salinas 88.594 196.741 304.888 393.482 501.629 45/32 698.371 786.965 895.112 1003.259 1091.853 2/1
#Salinas's Enharmonic 7 
salinas_enh 25/24 16/15 4/3 3/2 25/16 8/5 2/1
#Savas's Byzantine Liturgical mode, 8 + 12 + 10 parts 7 
savas_bardiat 133.333 333.333 500.000 700.000 833.333 1033.333 2/1
#Savas's Byzantine Liturgical mode, 8 + 16 + 6 parts 7 
savas_barenh 133.333 400.000 500.000 700.000 833.333 1100.000 2/1
#Savas's Chromatic, Byzantine Liturgical mode, 8 + 14 + 8 parts 7 
savas_chrom 133.333 366.667 500.000 700.000 833.333 1066.667 2/1
#Savas's Diatonic, Byzantine Liturgical mode, 10 + 8 + 12 parts 7 
savas_diat 166.667 300.000 500.000 700.000 866.667 1000.000 2/1
#Savas's Byzantine Liturgical mode, 6 + 20 + 4 parts 7 
savas_palace 100.000 433.333 500.000 700.000 800.000 1133.333 2/1
#Schidlof 21 
schidlof 81/80 21/20 15/14 9/8 7/6 135/112 100/81 5/4 4/3 27/20 7/5 10/7 3/2 14/9 45/28 5/3 7/4 25/14 50/27 15/8 2/1
#Scale with major thirds flat by a schisma 12 
schismic 2187/2048 9/8 19683/16384 8192/6561 4/3 1024/729 3/2 6561/4096 32768/19683 59049/32768 4096/2187 2/1
#Simple Tune #1 Carter Scholz 8 
scholz 28/27 8/7 7/6 4/3 3/2 14/9 7/4 2/1
#Scottish bagpipe tuning 7 
scotbag 10/9 5/4 15/11 40/27 5/3 11/6 2/1
#Scottish bagpipe tuning 2 7 
scotbag2 10/9 11/9 4/3 3/2 18/11 9/5 2/1
#Scottish bagpipe tuning 3 7 
scotbag3 9/8 5/4 11/8 3/2 27/16 11/6 2/1
#Scottish Bagpipe Ellis/Land 7 
SCOTBAG4 197.000 341.000 495.000 703.000 853.000 1009.000 2/1
#George Secor's well temperament with 5 pure 11/7 and 3 near just 11/6 17 
secor 66.7425 144.855 214.440 278.340 353.610 428.880 492.780 562.365 640.4775 707.220 771.120 849.2325 921.660 985.560 1057.9875 1136.10 2/1
#Arabic SEGAH (Dudon) Two 4 + 3 + 3 tetrachords 7 
segah 200.000 350.000 500.000 700.000 900.000 1050.000 2/1
#Persian SEGAH (Dudon) 4 + 3 + 3 and 3 + 4 + 3 degrees of 24-tet 7 
segah_pers 200.000 350.000 500.000 700.000 850.000 1050.000 2/1
#Seikilos Tuning 12 
seikilos 28/27 9/8 7/6 9/7 4/3 49/36 3/2 14/9 27/16 7/4 27/14 2/1
#Septimal Slendro 1, From HMSL Manual, also Lou Harrison, Jacques Dudon 5 
sept_slendro1 8/7 64/49 3/2 12/7 2/1
#Septimal Slendro 2, From Lou Harrison, Jacques Dudon's APTOS 5 
SEPT_SLENDRO2 9/8 21/16 3/2 12/7 2/1
#Septimal Slendro 3, Harrison, Dudon, called "MILLS" after Mills Gamelan 5 
SEPT_SLENDRO3 9/8 9/7 3/2 12/7 2/1
#Septimal Slendro 4, from Lou Harrison, Jacques Dudon, called "NAT" 5 
SEPT_SLENDRO4 9/8 21/16 3/2 7/4 2/1
#Septimal Slendro 5, from Jacques Dudon 5 
SEPT_SLENDRO5 7/6 21/16 49/32 343/192 2/1
#A slendro type pentatonic which is based on intervals of 7; from Lou Harrison 5 
septro1 8/7 9/7 3/2 12/7 2
#A slendro type pentatonic which is based on intervals of 7, no. 2 5 
septro2 7/6 4/3 3/2 7/4 2/1
#A slendro type pentatonic which is based on intervals of 7, no. 4 5 
septro4 9/8 4/3 3/2 12/7 2/1
#Dorian mode of the Serre's Enharmonic 7 
serre_enh 64/63 16/15 4/3 3/2 32/21 8/5 2/1
#Subharm1C-ConMixolydian 7 
sharm1c-conm 7/6 28/23 14/11 14/9 28/17 7/4 2/1
#Subharm1C-ConPhryg 7 
sharm1c-conp 6/5 24/19 4/3 8/5 12/7 24/13 2/1
#Subharm1C-Dorian 8 
sharm1c-dor 11/9 22/17 11/8 22/15 11/7 11/6 23/11 2/1
#Subharm1C-Lydian 8 
sharm1c-lyd 13/11 26/21 13/10 19/13 13/9 13/7 52/27 2/1
#Subharm1C-Mixolydian 7 
sharm1c-mix 7/6 28/23 14/11 7/5 7/4 28/15 2/1
#Subharm1C-Phrygian 7 
sharm1c-phr 6/5 24/19 4/3 3/2 24/13 48/25 2/1
#Subharm1E-ConMixolydian 7 
SHARM1E-CONM 28/23 56/45 14/11 28/17 56/33 7/4 2/1
#Subharm1E-ConPhrygian 7 
sharm1e-conp 24/19 48/37 4/3 12/7 16/9 24/13 2/1
#Subharm1E-Dorian 8 
sharm1e-dor 22/17 4/3 11/8 22/15 11/7 44/23 88/45 2/1
#Subharm1E-Lydian 8 
SHARM1E-lyd 26/21 52/41 13/10 19/13 13/9 52/27 104/53 2/1
#Subharm1E-Mixolydian 7 
sharm1e-mix 28/23 56/45 14/11 7/5 28/15 56/29 2/1
#Subharm1E-Phrygian 7 
sharm1e-phr 24/19 48/37 4/3 3/2 48/25 96/49 2/1
#Subharm2C-15-Harmonia 7 
SHARM2C-15 5/4 30/23 15/11 3/2 30/17 15/8 2/1
#SHarm2C-Hypodorian 8 
sharm2c-hypod 16/13 32/25 4/3 32/23 16/11 16/9 32/17 2/1
#SHarm2C-Hypolydian 8 
SHarm2C-Hypol 20/17 5/4 4/3 10/7 20/13 20/11 40/21 2/1
#SHarm2C-Hypophrygian 8 
SHarm2C-Hypop 9/7 4/3 18/13 36/25 3/2 9/5 36/19 2/1
#Subharm2E-15-Harmonia 7 
sharm2e-15 30/23 4/3 15/11 3/2 15/8 60/31 2/1
#SHarm2E-Hypodorian 8 
SHarm2E-Hypod 32/25 64/49 4/3 32/23 16/11 32/17 64/33 2/1
#SHarm2E-Hypolydian 8 
SHarm2E-Hypol 5/4 40/31 4/3 10/7 20/13 40/21 80/41 2/1
#SHarm2E-Hypophrygian 8 
SHarm2E-Hypop 4/3 72/53 18/13 36/25 3/2 36/19 72/37 2/1
#Sheng scale on naturals starting on d, from Fortuna 12 
sheng 141/134 34/31 55/46 71/58 4/3 80/57 117/80 107/67 63/38 59/33 63/34 2/1
#Sherwood's improved meantone temperament 12 
sherwood 114.420 194.501 308.921 389.002 503.422 583.503 697.923 812.342 892.424 1006.843 1086.925 1201.344
#Siamese Tuning, after Clem Fortuna's Microtonal Guide 12 
siamese 49.800 172.000 215.000 344.000 515.000 564.800 685.800 735.800 857.800 914.800 1028.800 2/1
#Simonton Integral Ratio Scale, see JASA: A new integral ratio scale 12 
simonton 17/16 9/8 19/16 5/4 4/3 17/12 3/2 19/12 5/3 16/9 17/9 2/1
#Ezra Sims' 18-tone mode 18 
sims 25/24 13/12 9/8 7/6 29/24 5/4 21/16 11/8 23/16 3/2 25/16 13/8 27/16 7/4 29/16 15/8 31/16 2/1
#Sims II 20 
sims2 33/32 17/16 35/32 9/8 37/32 19/16 39/32 5/4 21/16 11/8 23/16 3/2 25/16 13/8 27/16 7/4 29/16 15/8 31/16 2/1
#An observed xylophone tuning from Singapore 7 
singapore 187.000 356.000 526.000 672.000 856.000 985.000 2
#Pelog white, Slendro black 12 
SLEN_PEL 1/1 137.000 228.000 446.000 575.000 484.000 687.000 728.000 820.000 960.000 1098.000 2/1
#16-tET Slendro and Pelog 12 
slen_pel16 1/1 150.000 150.000 225.000 300.000 450.000 675.000 675.000 750.000 825.000 900.000 2/1
#23-tET Slendro and Pelog 12 
SLEN_PEL23 1/1 208.696 208.696 156.522 469.565 313.043 730.435 730.435 678.261 939.130 834.783 2/1
#Slendro/JC PELOG S1c,P1c#,S2d,eb,P2e,S3f,P3f#,S4g,ab,P4a,S5bb,P5b 12 
SLEN_PEL_jc 1/1 8/7 8/7 16/15 64/49 4/3 3/2 3/2 3/2 12/7 8/5 2/1
#Dan Schmidt (Pelog white, Slendro black) 12 
slen_pel_schmidt 1/1 9/8 7/6 5/4 4/3 11/8 3/2 3/2 7/4 7/4 15/8 2/1
#Schmidt with 13,17,19,21,27 12 
slen_pel_schmidt2 17/16 9/8 19/16 5/4 21/16 11/8 3/2 13/8 27/16 7/4 15/8 2/1
#Observed Javanese Slendro scale 5 
slendro 228.000 484.000 728.000 960.000 2
#Dudon's Slendro A1 from "Seven-Limit Slendro Mutations," 1/1 8:2 Jan 1994 5 
slendro_a1 8/7 4/3 3/2 7/4 2/1
#Dudon's Slendro A2 from "Seven-Limit Slendro Mutations," 1/1 8:2 Jan 1994 5 
slendro_a2 8/7 64/49 32/21 12/7 2/1
#Dudon's Slendro M from "Seven-Limit Slendro Mutations," 1/1 8:2 Jan 1994 5 
slendro_m 8/7 4/3 3/2 12/7 2/1
#Dudon's Slendro Matrix from "Seven-Limit Slendro Mutations," 1/1 8:2 Jan 1994 12 
slendro_mat 1/1 8/7 8/7 64/49 21/16 4/3 3/2 32/21 12/7 256/147 7/4 2/1
#Dudon's Slendro S1 from "Seven-Limit Slendro Mutations," 1/1 8:2 Jan 1994 5 
slendro_s1 8/7 4/3 32/21 7/4 2/1
#Dudon's Slendro S2 5 
slendro_s2 8/7 64/49 32/21 256/147 2/1
#Slendro Udan Mas (approx) 5 
slendro_udan 7/6 47/35 20/13 16/9 2/1
#From Lou Harrison, a soft diatonic 7 
softdiat 21/20 6/5 4/3 3/2 63/40 9/5 2
#New Soft Diatonic genus with equally divided Pyknon; Dorian Mode; 1:1 pyknon 7 
SOFTDIAT2 125.000 375.000 500.000 700.000 825.000 1075.000 2/1
#Solemn 6 6 
solemn 6/5 4/3 3/2 8/5 9/5 2/1
#Songlines.DEM, Bill Thibault and Scott Gresham-Lancaster. 1992 ICMC 12 
songlines 7/6 6/5 5/4 4/3 7/5 3/2 8/5 5/3 7/4 9/5 11/6 2/1
#This is a subharmonic six-tone series, notated as a whole-tone scale. 6 
spondeion 11/10 11/9 11/8 11/7 11/6 2/1
#Tonality square with generators 1 3 5 7 13 
square 8/7 7/6 6/5 5/4 4/3 7/5 10/7 3/2 8/5 5/3 12/7 7/4 2/1
#Well temperament of Charles, third earl of Stanhope, 1806 12 
stanhope 91.202 196.741 295.112 5/4 4/3 589.247 3/2 793.157 891.527 16/9 15/8 2
#Stellated Eikosany 3 out of 1 3 5 7 9 11 70 
steleiko 385/384 49/48 45/44 33/32 25/24 135/128 77/72 693/640 35/32 847/768 495/448 9/8 1155/1024 55/48 147/128 297/256 7/6 75/64 105/88 77/64 315/256 99/80 5/4 121/96 81/64 245/192 165/128 21/16 385/288 693/512 11/8 539/384 45/32 363/256 63/44 275/192 231/160 35/24 165/112 189/128 3/2 385/256 55/36 49/32 99/64 25/16 63/40 605/384 35/22 77/48 45/28 105/64 5/3 27/16 55/32 7/4 99/56 385/216 315/176 231/128 175/96 11/6 15/8 121/64 77/40 495/256 35/18 55/28 63/32 2/1
#Stellated two out of 1 3 5 7 hexany, also dekatesserany, mandala, tetradekany 14 
STELHEX1 21/20 15/14 35/32 9/8 5/4 21/16 35/24 3/2 49/32 25/16 105/64 7/4 15/8 2/1
#Stellated two out of 1 3 5 9 hexany 12 
stelhex2 135/128 9/8 5/4 81/64 27/20 45/32 3/2 25/16 5/3 27/16 15/8 2/1
#Stellated Tetrachordal Hexany based on Archytas's Enharmonic 14 
stelhex3 28/27 16/15 784/729 448/405 256/225 35/27 4/3 48/35 112/81 64/45 1792/1215 224/135 16/9 2/1
#Stellated Tetrachordal Hexany based on the 1/1 35/36 16/15 4/3 tetrachord 14 
STELHEX4 36/35 1296/1225 16/15 192/175 256/225 9/7 4/3 48/35 112/81 64/45 256/175 288/175 16/9 2/1
#Stockhausen's 25-note ET scale 25 
stockhausen 111.453 222.905 334.358 445.810 557.263 668.715 780.168 891.620 1003.073 1114.526 1225.978 1337.431 1448.883 1560.336 1671.788 1783.241 1894.694 2006.146 2117.600 2229.052 2340.505 2451.957 2563.410 2674.862 5
#Tom Stone's Guitar Scale 16 
stone 17/16 9/8 19/16 5/4 21/16 11/8 23/16 3/2 25/16 13/8 27/16 7/4 29/16 15/8 31/16 2/1
#Tuning used in John Chowning's STRIA, 9th root of Phi 9 
stria 92.566 185.131 277.697 370.262 462.828 555.394 647.959 740.525 833.090
#Subharmonics 24-1 24 
sub24 1/24 1/23 1/22 1/21 1/20 1/19 1/18 1/17 1/16 1/15 1/14 1/13 1/12 1/11 1/10 1/9 1/8 1/7 1/6 1/5 1/4 1/3 1/2 1/1
#sub 40-20 12 
sub40 20/19 10/9 20/17 5/4 4/3 10/7 20/13 8/5 5/3 20/11 40/21 2/1
#12 of sub 48 (Leven) 12 
SUB48 16/15 8/7 6/5 24/19 4/3 24/17 3/2 8/5 12/7 16/9 48/25 2/1
#12 of sub 50 12 
sub50 25/24 10/9 25/21 5/4 25/19 10/7 25/17 25/16 5/3 25/14 50/27 2/1
#Subharmonic series 1/16 - 1/8 8 
sub8 16/15 8/7 16/13 4/3 16/11 8/5 16/9 2/1
#Surupan Melog.S&P? 12 
surupan 1/1 270.000 270.000 150.000 540.000 270.000 690.000 720.000 690.000 960.000 810.000 2/1
#Tau-on-Side 12 
t-side 25/24 16/15 9/8 5/4 4/3 45/32 3/2 25/16 8/5 5/3 15/8 2/1
#Sub-40 tanbur scale 12 
tanbur 40/39 20/19 40/37 10/9 8/7 320/273 160/133 320/259 80/63 64/49 160/119 2/1
#TEMES'S 5-TONE PHI SCALE/2cycle 10 
temes 273.000 366.910 466.181 560.090 833.090 1100.729 2/1 1299.271 1393.181 1666.181
#One modern guess at the scale of the ancient greek poet Terpander, 6th c BC 6 
terpander 11/10 11/9 11/8 11/7 11/6 2
#Tetragam Dia2 12 
tetragam-di 16/15 10/9 10/9 5/4 4/3 64/45 3/2 8/5 5/3 5/3 7/4 2/1
#Tetragam Enharm. 12 
tetragam-en 28/27 16/15 16/15 5/4 4/3 7/5 3/2 14/9 8/5 8/5 7/4 2/1
#Tetragam/Hexgam 12 
tetragam-hex 28/27 9/8 7/6 5/4 21/16 35/24 3/2 14/9 5/3 7/4 15/8 2/1
#Tetragam Pyth. 12 
tetragam-py 256/243 9/8 9/8 81/64 4/3 729/512 3/2 128/81 27/16 27/16 16/9 2/1
#Tetragam Slendro as 5-tET, Pelog-like pitches on C# E F# A B 12 
tetragam-slpe 1/1 240.000 240.000 16/15 480.000 4/3 720.000 960.000 3/2 960.000 8/5 2/1
#Tetragam Slendro as 5-tET, Pelog-like pitches on C# E F# A B 12 
tetragam-slpe2 1/1 240.000 240.000 156.000 480.000 312.000 720.000 720.000 678.000 960.000 834.000 2/1
#Tetragam Septimal 12 
tetragam-sp 28/27 28/27 28/27 9/7 4/3 7/5 3/2 14/9 14/9 14/9 7/4 2/1
#Tetragam Undecimal 12 
tetragam-un 33/32 12/11 12/11 11/9 4/3 11/8 3/2 99/64 18/11 18/11 11/6 2/1
#Tetragam (13-tET) 12 
tetragam13 92.308 276.923 276.923 461.538 461.538 738.462 738.462 923.077 923.077 923.077 1107.692 2/1
#Tetragam (5-tET) 12 
tetragam5 240.000 240.000 240.000 240.000 480.000 480.000 720.000 960.000 960.000 960.000 960.000 2/1
#Tetragam (6-tET) 12 
tetragam6 240.000 200.000 200.000 400.000 400.000 600.000 600.000 800.000 800.000 800.000 960.000 2/1
#Tetragam (7-tET) 12 
tetragam7 171.429 171.429 171.429 342.857 514.286 514.286 685.714 857.143 857.143 857.143 1028.571 2/1
#Tetragam (8-tET) 12 
TETRAGAM8 150.000 300.000 300.000 450.000 450.000 750.000 750.000 900.000 900.000 900.000 900.000 2/1
#Tetragam (9-tET) A 12 
tetragam9a 133.333 266.667 266.667 400.000 533.333 800.000 800.000 933.333 933.333 933.333 1066.667 2/1
#Tetragam (9-tET) B 12 
tetragam9b 133.333 133.333 133.333 266.667 266.667 666.667 666.667 800.000 800.000 800.000 933.333 2/1
#31-tone Tetraphonic Cycle, conjunctive form on 5/4, 6/5, 7/6 and 8/7 31 
tetraphonic_31 50/49 25/24 50/47 25/23 10/9 25/22 50/43 25/21 50/41 5/4 60/47 30/23 4/3 15/11 60/43 10/7 60/41 3/2 49/32 147/94 147/92 49/30 147/88 147/86 7/4 84/47 42/23 28/15 21/11 84/43 2/1
#Observed scale from Thailand 7 
thai 129.000 277.000 508.000 726.000 771.000 1029.000 2
#Chinese flute scale 7 
ti-tsu 178.000 339.000 448.000 662.000 888.000 1103.000 1196.000
#Tiby's 1st Byzantine Liturgical genus, 12 + 13 + 3 parts 7 
tiby1 211.765 441.176 494.118 705.882 917.647 1147.059 2/1
#Tiby's second Byzantine Liturgical genus, 12 + 5 + 11 parts 7 
tiby2 211.765 300.000 494.118 705.882 917.647 1005.882 2/1
#Tiby's third Byzantine Liturgical genus, 12 + 9 + 7 parts 7 
tiby3 211.765 370.588 494.118 705.882 917.647 1076.471 2/1
#Tiby's fourth Byzantine Liturgical genus, 9 + 12 + 7 parts 7 
tiby4 158.824 370.588 494.118 705.882 864.706 1076.471 2/1
#Diatonic Perfect Immutable System in the new Tonos-15 15 
tonos15_pis 11/10 11/9 11/8 22/15 22/13 11/6 2/1 44/21 11/5 22/9 11/4 44/15 44/13 11/3 4/1
#Diatonic Perfect Immutable System in the new Tonos-17 15 
tonos17_pis 12/11 6/5 4/3 24/17 8/5 24/13 2/1 48/23 24/11 12/5 8/3 48/17 3/1 24/7 4/1
#Diatonic Perfect Immutable System in the new Tonos-19 15 
tonos19_pis 14/13 7/6 14/11 28/19 14/9 7/4 2/1 56/27 28/13 7/3 28/11 56/19 28/9 7/2 4/1
#Diatonic Perfect Immutable System in the new Tonos-21 15 
tonos21_pis 8/7 16/13 4/3 32/21 32/19 16/9 2/1 32/15 16/7 32/13 8/3 64/21 64/19 32/9 4/1
#Diatonic Perfect Immutable System in the new Tonos-23 15 
tonos23_pis 9/8 9/7 18/13 36/23 12/7 9/5 2/1 36/17 9/4 18/7 36/13 72/23 24/7 18/5 4/1
#Diatonic Perfect Immutable System in the new Tonos-25 15 
tonos25_pis 9/8 9/7 18/13 36/25 18/11 9/5 2/1 36/17 9/4 18/7 36/13 72/25 36/11 18/5 4/1
#Diatonic Perfect Immutable System in the new Tonos-27 15 
tonos27_pis 10/9 5/4 10/7 40/27 5/3 40/21 2/1 40/19 20/9 5/2 20/7 80/27 10/3 80/21 4/1
#Diatonic Perfect Immutable System in the new Tonos-29 15 
tonos29_pis 11/10 11/9 11/8 44/29 22/13 11/6 2/1 44/21 11/5 22/9 11/4 88/29 44/13 11/3 4/1
#Diatonic Perfect Immutable System in the new Tonos-31 15 
tonos31_pis 23/22 23/20 23/18 46/31 23/14 23/13 23/12 2/1 23/11 23/10 23/9 92/31 23/7 46/13 4/1
#Diatonic Perfect Immutable System in the new Tonos-31B 15 
tonos31_pis2 12/11 6/5 4/3 48/31 12/7 24/13 2/1 48/23 24/11 12/5 8/3 96/31 24/7 48/13 4/1
#Diatonic Perfect Immutable System in the new Tonos-33 15 
tonos33_pis 12/11 6/5 4/3 16/11 8/5 16/9 2/1 48/23 24/11 12/5 8/3 32/11 16/5 32/9 4/1
#Bac Dan Tranh scale 5 
tranh 10/9 4/3 3/2 5/3 2/1
#Dan Ca Dan Tranh Scale 5 
tranh2 10/9 20/17 3/2 5/3 2/1
#Sa Mac Dan Tranh scale 6 
tranh3 17/14 4/3 3/2 38/21 51/28 2/1
#12-tone Tritriadic of 7:9:11 12 
TRI12-1 99/98 81/77 11/9 121/98 14/11 9/7 14/9 11/7 18/11 81/49 121/63 2/1
#3:5:7 Tritriadic 19-Tone Matrix 19 
tri19-1 50/49 36/35 7/6 25/21 6/5 60/49 49/36 25/18 7/5 10/7 36/25 72/49 49/30 5/3 42/25 12/7 35/18 49/25 2/1
#3:5:9 Tritriadic 19-Tone Matrix 19 
tri19-2 27/25 10/9 9/8 6/5 100/81 5/4 4/3 27/20 25/18 36/25 40/27 3/2 8/5 81/50 5/3 16/9 9/5 50/27 2/1
#4:5:6 Tritriadic 19-Tone Matrix 19 
tri19-3 25/24 16/15 10/9 9/8 6/5 5/4 32/25 4/3 25/18 36/25 3/2 25/16 8/5 5/3 16/9 9/5 15/8 48/25 2/1
#4:5:9 Tritriadic 19-Tone Matrix 19 
tri19-4 81/80 10/9 9/8 100/81 5/4 81/64 32/25 25/18 45/32 64/45 36/25 25/16 128/81 8/5 81/50 16/9 9/5 160/81 2/1
#5:7:9 Tritriadic 19-Tone Matrix 19 
tri19-5 50/49 49/45 10/9 81/70 98/81 100/81 63/50 9/7 7/5 10/7 14/9 100/63 81/50 81/49 140/81 9/5 90/49 49/25 2/1
#6:7:8 Tritriadic 19-Tone Matrix 19 
tri19-6 49/48 9/8 8/7 7/6 9/7 64/49 21/16 4/3 49/36 72/49 3/2 32/21 49/32 14/9 12/7 7/4 16/9 96/49 2/1
#6:7:9 Tritriadic 19-Tone Matrix 19 
tri19-7 28/27 54/49 9/8 8/7 7/6 98/81 9/7 4/3 49/36 72/49 3/2 14/9 81/49 12/7 7/4 16/9 49/27 27/14 2/1
#7:9:11 Tritriadic 19-Tone Matrix 19 
TRI19-8 99/98 126/121 81/77 98/81 11/9 121/98 14/11 9/7 162/121 121/81 14/9 11/7 196/121 18/11 81/49 154/81 121/63 196/99 2/1
#4:5:7 Tritriadic 19-Tone Matrix 19 
tri19-9 50/49 35/32 28/25 8/7 49/40 5/4 32/25 64/49 7/5 10/7 49/32 25/16 8/5 80/49 7/4 25/14 64/35 49/25 2/1
#12-tone Triaphonic Cycle, conjunctive form on 4/3, 5/4 and 6/5 12 
triaphonic_12 20/19 10/9 20/17 5/4 4/3 80/57 40/27 80/51 5/3 30/17 15/8 2/1
#17-tone Triaphonic Cycle, conjunctive form on 4/3, 7/6 and 9/7 17 
triaphonic_17 28/27 14/13 28/25 7/6 28/23 14/11 4/3 112/81 56/39 112/75 14/9 21/13 42/25 7/4 42/23 21/11 2/1
#Trichordal Undecatonic 11 
trichord 9/8 7/6 5/4 21/16 4/3 3/2 5/3 27/16 7/4 15/8 2/1
#Sub-(6-7-8) Tritriadic 7 
trisub1 8/7 4/3 3/2 32/21 12/7 16/9 2/1
#Tritriadic scale of the 10:12:15 triad, natural minor mode 7 
TRITRIAD 9/8 6/5 4/3 3/2 8/5 9/5 2/1
#Tritriadic scale of the 10:14:15 triad 7 
TRITRIAD10 21/20 9/8 4/3 7/5 3/2 28/15 2/1
#Tritriadic scale of the 11:13:15 triad 7 
TRITRIAD11 13/11 15/11 22/15 195/121 26/15 225/121 2/1
#Tritriadic scale of the 10:13:15 triad 7 
tritriad13 9/8 13/10 4/3 3/2 26/15 39/20 2/1
#14.18.21 Tritriadic. Primary triads 1/1 9/7 3/2, secondary are 1/1 7/6 3/2 7 
TRITRIAD14 9/8 9/7 4/3 3/2 12/7 27/14 2/1
#Tritriadic scale of the 18:22:27 triad 7 
TRITRIAD18 9/8 11/9 4/3 3/2 44/27 11/6 2/1
#Tritriadic scale of the 22:27:33 triad 7 
TRITRIAD22 9/8 27/22 4/3 3/2 18/11 81/44 2/1
#Tritriadic scale of the 26:30:39 triad 7 
TRITRIAD26 9/8 15/13 4/3 3/2 20/13 45/26 2/1
#Tritriadic scale of the 26:32:39 triad 7 
TRITRIAD32 9/8 16/13 4/3 3/2 64/39 24/13 2/1
#Tritriadic scale of the 54:64:81 triad 7 
TRITRIAD54 9/8 32/27 4/3 3/2 128/81 16/9 2/1
#Tritriadic scale of the 6:7:9 triad 7 
TRITRIAD6 9/8 7/6 4/3 3/2 14/9 7/4 2/1
#Tritriadic scale of the 64:81:96 triad 7 
TRITRIAD64 9/8 81/64 4/3 3/2 27/16 243/128 2/1
#Tritriadic scale of the 7:9:11 triad 7 
TRITRIAD7 99/98 121/98 14/11 9/7 11/7 18/11 2/1
#Tritriadic scale of the 9:11:13 triad 7 
tritriad9 169/162 11/9 18/13 13/9 22/13 143/81 2/1
#TT456DTDMT 12 
TT456DTDMT 25/24 9/8 6/5 5/4 4/3 25/16 3/2 8/5 5/3 9/5 15/8 2/1
#TT679DTDMMT 12 
TT679DTDMMT 9/8 7/6 9/7 4/3 49/36 3/2 14/9 12/7 7/4 49/27 27/14 2/1
#Turkish Scale, 5-limit From Palmer on an album of Turkish music 7 
turkish 16/15 5/4 4/3 3/2 5/3 16/9 2/1
#Ur-Partch curved keyboard, published in Interval 39 
ur-partch 49/48 33/32 22/21 16/15 12/11 10/9 9/8 8/7 7/6 6/5 11/9 5/4 14/11 9/7 21/16 4/3 15/11 11/8 7/5 10/7 16/11 22/15 3/2 32/21 14/9 11/7 8/5 18/11 5/3 12/7 7/4 16/9 9/5 11/6 15/8 21/11 64/33 96/49 2/1
#Ur-Temes's 5-tone phi scale 5 
ur-temes 273.000 366.910 466.181 560.090 833.090
#A vertex tetrachord from Chapter 5, 66.7 + 266.7 + 166.7 7 
vertex_chrom 66.667 333.333 500.000 700.000 766.667 933.333 2/1
#A vertex tetrachord from Chapter 5, 83.3 + 283.3 + 133.3 7 
vertex_chrom2 83.333 366.667 500.000 700.000 783.333 1066.667 2/1
#A vertex tetrachord from Chapter 5, 87.5 + 287.5 + 125 7 
vertex_chrom3 87.500 375.000 500.000 700.000 787.500 1075.000 2/1
#A vertex tetrachord from Chapter 5, 88.9 + 288.9 + 122.2 7 
VERTEX_CHROM4 88.900 377.800 500.000 700.000 788.900 1077.800 2/1
#A vertex tetrachord from Chapter 5, 133.3 + 266.7 + 100 7 
vertex_chrom5 133.333 400.000 500.000 700.000 833.333 1100.000 2/1
#A vertex tetrachord from Chapter 5, 233.3 + 133.3 + 133.3 7 
vertex_diat 233.333 366.667 500.000 700.000 933.333 1066.667 2/1
#A vertex tetrachord from Chapter 5, 212.5 + 162.5 + 125 7 
vertex_diat10 212.500 375.000 500.000 700.000 912.500 1075.000 2/1
#A vertex tetrachord from Chapter 5, 212.5 + 62.5 + 225 7 
VERTEX_DIAT11 212.500 275.000 500.000 700.000 912.500 975.000 2/1
#A vertex tetrachord from Chapter 5, 200 + 125 + 175 7 
vertex_diat12 200.000 325.000 500.000 700.000 900.000 1025.000 2/1
#A vertex tetrachord from Chapter 5, 233.3 + 166.7 + 100 7 
vertex_diat2 233.333 400.000 500.000 700.000 933.333 1100.000 2/1
#A vertex tetrachord from Chapter 5, 75 + 225 + 200 7 
vertex_diat3 75.000 300.000 500.000 700.000 775.000 1000.000 2/1
#A vertex tetrachord from Chapter 5, 225 + 175 + 100 7 
vertex_diat4 225.000 400.000 500.000 700.000 925.000 1100.000 2/1
#A vertex tetrachord from Chapter 5, 87.5 + 237.5 + 175 7 
vertex_diat5 87.500 325.000 500.000 700.000 787.500 1025.000 2/1
#A vertex tetrachord from Chapter 5, 200 + 75 + 225 7 
vertex_diat7 200.000 275.000 500.000 700.000 900.000 975.000 2/1
#A vertex tetrachord from Chapter 5, 100 + 175 + 225 7 
vertex_diat8 100.000 275.000 500.000 700.000 800.000 975.000 2/1
#A vertex tetrachord from Chapter 5, 212.5 + 137.5 + 150 7 
vertex_diat9 212.500 350.000 500.000 700.000 912.500 1050.000 2/1
#A vertex tetrachord from Chapter 5, 87.5 + 187.5 + 225 7 
vertex_sdiat 87.500 275.000 500.000 700.000 787.500 975.000 2/1
#A vertex tetrachord from Chapter 5, 75 + 175 + 250 7 
vertex_sdiat2 75.000 250.000 500.000 700.000 775.000 950.000 2/1
#A vertex tetrachord from Chapter 5, 25 + 225 + 250 7 
vertex_sdiat3 25.000 250.000 500.000 700.000 725.000 950.000 2/1
#A vertex tetrachord from Chapter 5, 66.7 + 183.3 + 250 7 
vertex_sdiat4 66.667 250.000 500.000 700.000 766.667 950.000 2/1
#A vertex tetrachord from Chapter 5, 233.33 + 16.67 + 250 7 
vertex_sdiat5 233.333 250.000 500.000 700.000 933.333 950.000 2/1
#Vogel's 21-tone Archytas system, see Divisions of the tetrachord 21 
vogel 28/27 16/15 9/8 7/6 32/27 6/5 896/729 512/405 4/3 112/81 64/45 3/2 14/9 128/81 8/5 3584/2187 2048/1215 16/9 448/243 256/135 2/1
#African scale according to Volans 0=G 7 
volans 171.000 360.000 514.000 685.000 860.000 1060.000 2/1
#Vong Co Dan Tranh scale 7 
vong 11/10 36/29 27/20 3/2 33/20 51/28 2/1
#Andreas Werckmeister's scale 12 
werck 256/243 192.465 32/27 389.652 4/3 1024/729 695.801 128/81 888.266 16/9 1091.607 2/1
#Andreas Werckmeister's temperament (1681) 12 
werckmeister 256/243 192.180 32/27 390.225 4/3 588.270 696.090 128/81 888.270 16/9 1092.180 2/1
#Wilson 19-tone 19 
wilson 21/20 35/32 9/8 7/6 6/5 5/4 21/16 4/3 7/5 35/24 3/2 63/40 105/64 27/16 7/4 9/5 15/8 63/32 2/1
#Wilson's 22-tone 5-limit scale 22 
wilson5 25/24 16/15 10/9 9/8 75/64 6/5 5/4 32/25 4/3 27/20 45/32 36/25 3/2 25/16 8/5 5/3 27/16 225/128 9/5 15/8 48/25 2/1
#Wilson's 22-tone 7-limit 'marimba' scale 22 
wilson7 28/27 16/15 10/9 9/8 7/6 6/5 5/4 35/27 4/3 27/20 45/32 35/24 3/2 14/9 8/5 5/3 27/16 7/4 9/5 15/8 35/18 2/1
#Wilson 7-limit scale 22 
wilson7_2 126/125 21/20 35/32 9/8 7/6 6/5 5/4 63/50 21/16 27/20 7/5 36/25 3/2 25/16 63/40 5/3 42/25 7/4 9/5 15/8 189/100 2/1
#Wilson 7-limit scale 22 
wilson7_3 128/125 16/15 10/9 9/8 32/27 6/5 5/4 32/25 4/3 27/20 64/45 36/25 3/2 25/16 8/5 5/3 128/75 16/9 9/5 15/8 48/25 2/1
#Wilson Diaphonic cycles, tetrachordal form 22 
wilson_dia1 36/35 18/17 12/11 9/8 36/31 6/5 36/29 9/7 4/3 18/13 27/19 54/37 3/2 54/35 27/17 18/11 27/16 54/31 9/5 54/29 27/14 2/1
#Wilson Diaphonic cycle, conjunctive form 22 
WILSON_DIA2 39/38 39/37 13/12 39/35 39/34 13/11 39/32 39/31 13/10 39/29 39/28 13/9 52/35 26/17 52/33 13/8 52/31 26/15 52/29 13/7 52/27 2/1
#Wilson Diaphonic cycle on 3/2 22 
WILSON_DIA3 39/38 39/37 13/12 39/35 39/34 13/11 39/32 39/31 13/10 39/29 39/28 13/9 3/2 54/35 27/17 18/11 27/16 54/31 9/5 54/29 27/14 2/1
#Wilson Diaphonic cycle on 4/3 22 
WILSON_DIA4 36/35 18/17 12/11 9/8 36/31 6/5 36/29 9/7 4/3 26/19 54/37 13/9 52/35 26/17 52/33 13/8 52/31 26/15 52/29 13/7 52/27 2/1
#Wilson 'duovigene' 22 
wilson_duo 28/27 16/15 35/32 9/8 7/6 6/5 5/4 35/27 4/3 112/81 45/32 35/24 3/2 14/9 8/5 5/3 27/16 7/4 9/5 15/8 35/18 2/1
#Wilson's Enharmonic & 3rd new Enharmonic on Hofmann's list of superp. 4chords 7 
wilson_enh 96/95 16/15 4/3 3/2 144/95 8/5 2/1
#Wilson's 81/64 Enharmonic, a strong division of the 256/243 pyknon 7 
wilson_enh2 64/63 256/243 4/3 3/2 32/21 128/81 2/1
#Wilson study in 'conjunct facets', Hexany based 22 
wilson_facet 28/27 21/20 10/9 9/8 7/6 6/5 5/4 35/27 4/3 27/20 7/5 40/27 3/2 14/9 63/40 5/3 140/81 7/4 9/5 28/15 35/18 2/1
#Wilson's Helix Song, see David Rosenthal, Helix Song, XH 7&8, 1979 12 
wilson_helix 13/12 9/8 7/6 5/4 4/3 11/8 3/2 13/8 5/3 7/4 11/6 2/1
#Wilson's Hyperenharmonic, this genus has a CI of 9/7 7 
wilson_hypenh 56/55 28/27 4/3 3/2 84/55 14/9 2/1
#Wilson 11-limit scale 22 
wilson_l1 33/32 21/20 35/32 9/8 7/6 77/64 5/4 165/128 21/16 11/8 7/5 231/160 3/2 99/64 77/48 33/20 55/32 7/4 231/128 15/8 77/40 2/1
#Wilson 11-limit scale 22 
wilson_l2 49/48 77/72 11/10 9/8 7/6 77/64 5/4 77/60 4/3 11/8 77/54 35/24 3/2 11/7 77/48 5/3 77/45 7/4 11/6 15/8 77/40 2/1
#Wilson 11-limit scale 22 
wilson_l3 33/32 21/20 35/32 9/8 7/6 6/5 5/4 14/11 21/16 11/8 7/5 35/24 3/2 14/9 8/5 105/64 27/16 7/4 9/5 15/8 21/11 2/1
#Wilson 11-limit scale 22 
wilson_l4 49/48 21/20 10/9 8/7 7/6 6/5 5/4 35/27 4/3 49/36 7/5 35/24 3/2 14/9 8/5 5/3 12/7 7/4 9/5 28/15 35/18 2/1
#Wilson 11-limit scale 22 
wilson_l5 49/48 77/72 12/11 8/7 7/6 6/5 5/4 14/11 4/3 49/36 7/5 35/24 3/2 14/9 8/5 5/3 12/7 7/4 11/6 28/15 35/18 2/1
#Winnington-Ingram's Spondeion 5 
winnington 12/11 4/3 3/2 18/11 2/1
#Wuerschmidt's normalised 12-tone system 12 
wurschmidt 135/128 9/8 6/5 81/64 27/20 45/32 3/2 405/256 27/16 9/5 15/8 2/1
#Wuerschmidt's 31-tone system 31 
WURSCHMIDT_31 128/125 25/24 16/15 1125/1024 9/8 144/125 75/64 6/5 625/512 5/4 32/25 125/96 4/3 512/375 25/18 36/25 375/256 3/2 192/125 25/16 8/5 1024/625 5/3 128/75 125/72 16/9 2048/1125 15/8 48/25 125/64 2/1
#Wuerschmidt's 31-tone system with alternative tritone 31 
WURSCHMIDT_31a 128/125 25/24 16/15 1125/1024 9/8 144/125 75/64 6/5 625/512 5/4 32/25 125/96 4/3 512/375 25/18 64/45 375/256 3/2 192/125 25/16 8/5 1024/625 5/3 128/75 125/72 16/9 2048/1125 15/8 48/25 125/64 2/1
#Wuerschmidt's 53-tone system 53 
wurschmidt_53 81/80 128/125 25/24 135/128 16/15 27/25 1125/1024 10/9 9/8 256/225 144/125 75/64 32/27 6/5 625/512 768/625 5/4 81/64 32/25 125/96 675/512 4/3 27/20 512/375 25/18 45/32 64/45 36/25 375/256 40/27 3/2 1024/675 192/125 25/16 128/81 8/5 625/384 1024/625 5/3 27/16 128/75 125/72 225/128 16/9 9/5 2048/1125 50/27 15/8 256/135 48/25 125/64 160/81 2/1
#Xenakis's Byzantine Liturgical mode, 5 + 19 + 6 parts 7 
xenakis_chrom 83.333 400.000 500.000 700.000 783.333 1100.000 2/1
#Xenakis's Byzantine Liturgical mode, 12 + 11 + 7 parts 7 
xenakis_diat 200.000 383.333 500.000 700.000 900.000 1083.333 2/1
#Xenakis's Byzantine Liturgical mode, 7 + 16 + 7 parts 7 
xenakis_schrom 116.667 383.333 500.000 700.000 816.667 1083.333 2/1
#Yasser Hexad, 6 of 19 as whole tone scale 6 
yasser_6 189.474 378.947 568.421 757.895 947.368 2/1
#Yasser's Supra-Diatonic, the flat notes are V,W,X,Y,and Z 12 
yasser_diat 126.316 189.474 6/5 378.947 505.263 631.579 694.737 821.053 5/3 1010.526 1073.684 2/1
#Yasser's JI Scale, 2 Yasser hexads, a 121/91 apart 12 
yasser_ji 121/112 9/8 121/104 5/4 121/91 11/8 1089/728 13/8 605/364 7/4 1331/728 2/1
#Vallotti & Young scale (Young version) 12 
young 256/243 196.090 32/27 392.180 4/3 1024/729 698.045 128/81 894.135 16/9 1090.225 2/1
#Yugoslavian Bagpipe 12 
YUGOBAG 99.000 202.000 362.000 463.000 655.000 754.000 861.000 949.000 991.000 1047.000 1129.000 2/1
#Modern Arabic scale 7 
zalzal 9/8 27/22 4/3 3/2 18/11 16/9 2
#Zalzal's Scale, a medieval Islamic with Ditone Diatonic & 10/9 x 13/12 x 72/65 7 
zalzal2 9/8 81/64 4/3 40/27 130/81 16/9 2/1
#2/7th comma temperament of Zarlino 12 
zarlino 25/24 191.621 312.569 383.241 504.190 574.862 695.810 766.483 887.431 1008.379 1079.052 2/1
#Medieval Arabic scale 7 
zenkouleh 9/8 8192/6561 4/3 262144/177147 32768/19683 16/9 2
#Harmonic six-star, group A, from Fokker 8 
zesster_a 16/15 6/5 32/25 4/3 3/2 8/5 48/25 2/1
#Harmonic six-star, group B, from Fokker 8 
zesster_b 28/25 8/7 32/25 7/5 8/5 7/4 64/35 2/1
#Harmonic six-star, group C on Eb, from Fokker 8 
zesster_c 8/7 7/6 4/3 32/21 14/9 7/4 16/9 2/1
#Harmonic six-star, groups A, B and C mixed, from Fokker 16 
zesster_mix 21/20 16/15 28/25 8/7 6/5 32/25 4/3 48/35 7/5 3/2 8/5 7/4 64/35 28/15 48/25 2/1
#Zirafkend Bouzourk (IG #3, DF #9), from both Rouanet and Safiyu-d-Din 6 
zir_Bouzourk 14/13 7/6 6/5 27/20 3/2 2/1
#Arabic Zirafkend mode 8 
zirafkend 65536/59049 32/27 4/3 262144/177147 128/81 32768/19683 4096/2187 2/1
