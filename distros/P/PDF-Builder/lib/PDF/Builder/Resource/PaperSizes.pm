package PDF::Builder::Resource::PaperSizes;

use strict;
use warnings;

our $VERSION = '3.025'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::PaperSizes - list of standard paper sizes and their dimensions

=head2 Information and Usage

This is a list of standard page (media) sizes by I<name> (e.g., 'A4' or 
'Legal'), given by width and height in Big Points (72 per inch). See the code 
in PaperSizes.pm for the actual entries. You do B<not> have to use these names; 
they are merely provided as convenient shortcuts. You can always specify the 
desired dimensions (in points) yourself.

The PDF specification (and PDF readers) default to US Letter size (portrait
orientation, 8.5 inches wide by 11 inches high). If you want to use anything
else, you will have to make a C<mediabox()> call to specify the media (paper)
size. For named sizes, capitalization doesn't matter (all entries are folded 
to lower case, so 'A4' and 'a4' work the same).

Different sources give somewhat different paper dimensions, especially for
archaic or unusual sizes, so take care and measure your actual paper before
printing, so you can avoid wasting paper and time printing to the wrong 
mediabox! Also keep in mind that many printers cannot print all the way to the
edge (don't want to get ink or toner on the paper rollers), so set your margins
accordingly.

=head2 Available named media sizes, and size

You can certainly edit this module to add more named sizes, if you wish to.
Or, you can directly give the desired size in Points, in a "box" method.

B<CAUTION:> Before using one of the larger sizes, check if your PDF reader
and/or printer will be able to handle it. The official PDF definition only 
allows up to 200 inches square (14400 Points square), requiring the use of 
User Units to handle larger media. Many non-Adobe systems ignore this 
limitation and support much larger sizes, but you should check before doing a 
lot of work!

=head3 Metric sizes

=over

      4a0 --  4760 x 6716 (1679 mm x 2639 mm)

      2a0 --  3368 x 4760 (1188 mm x 1679 mm)

      a0 --   2380 x 3368 (840 mm x 1188 mm)

      a1 --   1684 x 2380 (594 mm x 840 mm)

      a2 --   1190 x 1684 (420 mm x 594 mm)

      a3 --   842 x 1190 (297 mm x 420 mm)

      a4 --   595 x 842 (210 mm x 297 mm)

      a5 --   421 x 595 (149 mm x 210 mm)

      a6 --   297 x 421 (105 mm x 149 mm)

      a7 --   210 x 297 (74 mm x 105 mm)

      a8 --   147 x 210 (52 mm x 74 mm)

      a9 --   105 x 147 (37 mm x 52 mm)

      a10 --  74 x 105 (26 mm x 37 mm)

      4b0 --  5656 x 8000 (1995 mm x 2822 mm)

      2b0 --  4000 x 5656 (1411 mm x 1995 mm)

      b0 --   2828 x 4000 (998 mm x 1411 mm)

      b1 --   2000 x 2828 (706 mm x 998 mm)

      b2 --   1414 x 2000 (499 mm x 706 mm)

      b3 --   1000 x 1414 (353 mm x 499 mm)

      b4 --   707 x 1000 (249 mm x 353 mm)

      b5 --   500 x 707 (176 mm x 249 mm)

      b6 --   353 x 500 (125 mm x 176 mm)

      b7 --   250 x 353 (88 mm x 125 mm)

      b8 --   176 x 250 (62 mm x 88 mm)

      b9 --   125 x 176 (44 mm x 62 mm)

      b10 --  88 x 125 (31 mm x 44 mm)

      c0 --   2600 x 3677 (917 mm x 1297 mm)  Envelope sizes

      c1 --   1837 x 2600 (648 mm x 917 mm)

      c2 --   1298 x 1837 (458 mm x 648 mm)

      c3 --   918 x 1298 (324 mm x 458 mm)

      c4 --   649 x 918 (229 mm x 324 mm)

      c5 --   459 x 649 (162 mm x 229 mm)

      c6 --   323 x 459 (114 mm x 162 mm)

      c7 --   230 x 323 (81 mm x 114 mm)

      c8 --   162 x 230 (57 mm x 81 mm)

      c9 --   113 x 162 (40 mm x 57 mm)

      c10 --  79 x 113 (28 mm x 40 mm)

      jis-b5 --  516 x 729 (182 mm x 257 mm)

      folio --   595 x 935 (210 mm x 330 mm)

      chinese-16k --  524 x 737 (185 mm x 260 mm)

      chinese-32k --  369 x 524 (130 mm x 185 mm)

      16k --  553 x 765 (195 mm x 270 mm)

      jp-postcard --  283 x 420 (100 mm x 148 mm)

      dbl-postcard --  420 x 567 (148 mm x 200 mm)

      env-c5 --  459 x 649 (162 mm x 229 mm)

      env-dl --  312 x 624 (110 mm x 220 mm)

      env-c6 --  323 x 459 (114 mm x 162 mm)

      env-cho-3 --  340 x 666 (120 mm x 235 mm)

      env-cho-4 --  255 x 581 (90 mm x 205 mm)

      p1 --  1587 x 2438 (560 mm x 860 mm)  Canadian correspondence

      p2 --  1219 x 1587 (430 mm x 560 mm) 

      p3 --  794 x 1219 (280 mm x 430 mm)

      p4 --  609 x 794 (215 mm x 280 mm)

      p5 --  397 x 609 (140 mm x 215 mm)

      p6 --  303 x 397 (107 mm x 140 mm)

=back

=head3 Mixed sizes

=over

      universal --  595 x 792 (210 mm x 11 in)

This is not a standard or official size, but a PDF::Builder size, which should 
print OK on either A4 or US Letter paper size. It is narrow (like A4) and short 
(like letter).

=back

=head3 US/British (non-metric) sizes

=over

      broadsheet --  1296 x 1584 (18 in x 22 in) sometimes 1224 x 1584!

      executive --  522 x 756 (7.25 in x 10.5 in)

      foolscap --  576 x 936 (8 in x 13 in) sometimes 360 x 486!

      gov-legal --  612 x 936 (8.5 in x 13 in)

      gov-letter --  576 x 756 (8 in x 10.5 in)

      jr-legal --  360 x 576 (5 in x 8 in)

      ledger --  1224 x 792 (17 in x 11 in)

      legal --  612 x 1008 (8.5 in x 14 in)

      letter --  612 x 792 (8.5 in x 11 in)

      letter-plus --  612 x 914 (8.5 in x 12.7 in)

      quarto --  576 x 720 (8 in x 10 in)

      student --  396 x 612 (5.5 in x 8.5 in) a.k.a. statement, half-letter

      tabloid --  792 x 1224 (11 in x 17 in) ledger rotated (portrait mode)

      36x36 --  2592 x 2592 (36 in x 36 in)

      dbill --  216 x 504 (3 in x 7 in)

      old-paper --  648 x 864 (9 in x 12 in)

      env-10 --  297 x 684 (4.125 in x 9.5 in)

      env-monarch --  279 x 540 (3.875 in x 7.5 in)

      a --  612 x 791 (8.5 in x 11 in) ANSI technical drawing paper

      b --  791 x 1225 (11 in x 17 in)

      c --  1225 x 1585 (17 in x 22 in)

      d --  1585 x 2449 (22 in x 34 in)

      e --  2449 x 3169 (34 in x 44 in)

      f --  2016 x 2880 (28 in x 40 in)

      b-plus --  936 x 1368 (13 in x 19 in)  a.k.a. super-B, A3+, super-A3

      arch-a --  648 x 864 (9 in x 12 in)

      arch-b --  864 x 1296 (12 in x 18 in)

      arch-c --  1296 x 1728 (18 in x 24 in)

      arch-d --  1728 x 2592 (24 in x 36 in)

      arch-e --  2592 x 3456 (36 in x 48 in)

      arch-e1 --  2160 x 3024 (30 in x 42 in)

      pott --  288 x 450 (3.9 in x 6.25 in)  British sizes

      post --  360 x 576 (5 in x 8 in)

      large-post --  378 x 594 (5.25 in x 8.25 in)

      crown --  360 x 540 (5 in x 7.5 in)

      large-crown --  378 x 576 (5.25 in x 8 in)

      demy --  409 x 630 (5.68 in x 8.75 in)

      small-demy --  409 x 612 (5.68 in x 8.5 in)

      medium --  414 x 648 (5.75 in x 9 in)

      royal --  450 x 720 (6.25 in x 10 in)

      small-royal --  445 x 666 (6.18 in x 9.25 in)

      super-royal --  486 x 738 (6.75 in x 10.25 in)

      imperial --  540 x 792 (7.5 in x 11 in)

=back

=cut

# see sites such as https://www.papersizes.org/ for all the paper size
# information you would ever want to know
# http://tug.ctan.org/macros/latex/contrib/memoir/memman.pdf pg 39

sub get_paper_sizes {

    # dimensions are Width and Height in Big Points. divide by 72 to get
    # inches, or divide by 2.83 (72/25.4) to get mm. use page and coordinate
    # rotations to rotate into landscape mode and vice-versa.

    return (
        # Metric sizes
	# non-standard names 4a, 2a, 4b, 2b have been removed
	# (use standard 4a0, 2a0, 4b0, 2b0 instead)
        '4a0'        => [ 4760, 6716 ],
        '2a0'        => [ 3368, 4760 ],
        'a0'         => [ 2380, 3368 ],
        'a1'         => [ 1684, 2380 ],
        'a2'         => [ 1190, 1684 ],
        'a3'         => [  842, 1190 ],
        'a4'         => [  595,  842 ],
        'a5'         => [  421,  595 ],
        'a6'         => [  297,  421 ],
        'a7'         => [  210,  297 ],
        'a8'         => [  147,  210 ],
        'a9'         => [  105,  147 ],
        'a10'        => [   74,  105 ],
        '4b0'        => [ 5656, 8000 ],
        '2b0'        => [ 4000, 5656 ],
        'b0'         => [ 2828, 4000 ],
        'b1'         => [ 2000, 2828 ],
        'b2'         => [ 1414, 2000 ],
        'b3'         => [ 1000, 1414 ],
        'b4'         => [  707, 1000 ],
        'b5'         => [  500,  707 ],
        'b6'         => [  353,  500 ],
        'b7'         => [  250,  353 ], 
        'b8'         => [  176,  250 ],
        'b9'         => [  125,  176 ],
        'b10'        => [   88,  125 ],
        'c0'         => [ 2600, 3677 ],  # C series envelopes
        'c1'         => [ 1837, 2600 ],
        'c2'         => [ 1298, 1837 ],
        'c3'         => [  918, 1298 ],
        'c4'         => [  649,  918 ],
        'c5'         => [  459,  649 ],
        'c6'         => [  323,  459 ],
        'c7'         => [  230,  323 ],
        'c8'         => [  162,  230 ],
        'c9'         => [  113,  162 ],
        'c10'        => [   79,  113 ],
        'jis-b5'     => [  516,  729 ],
        'folio'      => [  595,  935 ],
        'chinese-16k' => [  524,  737 ],
        'chinese-32k' => [  369,  524 ],
        '16k'        => [  553,  765 ],
        'jp-postcard' => [  283,  420 ],
        'dbl-postcard' => [  420,  567 ],
        'env-c5'     => [  459,  649 ],
        'env-dl'     => [  312,  624 ],
        'env-c6'     => [  323,  459 ],
        'env-cho-3'  => [  340,  666 ],
        'env-cho-4'  => [  255,  581 ],
        'p1'         => [ 1587, 2438 ],  # Canadian correspondence sizes
        'p2'         => [ 1219, 1587 ],
        'p3'         => [  794, 1219 ],
        'p4'         => [  609,  794 ],
        'p5'         => [  397,  609 ],
        'p6'         => [  303,  397 ],

        # mixed
        'universal'  => [  595,  792 ],  # smaller of A4 and US Letter,
	                                 # will print on either paper size

        # US sizes
        'broadsheet'   => [ 1296, 1584 ],  # varies, sometimes 1224 x 1584
        'executive'    => [  522,  756 ],
        'foolscap'     => [  576,  936 ],  # also listed as 360x486
        'gov-legal'    => [  612,  936 ],
        'gov-letter'   => [  576,  756 ],
        'jr-legal'     => [  360,  576 ], 
        'ledger'       => [ 1224,  792 ],  # = tabloid in landscape orientation
        'legal'        => [  612, 1008 ],
        'letter'       => [  612,  792 ],
        'letter-plus'  => [  612,  914 ],
        'quarto'       => [  576,  720 ],
        'student'      => [  396,  612 ],
        'tabloid'      => [  792, 1224 ],
        '36x36'        => [ 2592, 2592 ],
	'dbill'        => [  216,  504 ],
	'statement'    => [  396,  612 ],  # = student
	'old-paper'    => [  648,  864 ],
	'half-letter'  => [  396,  612 ],  # = student
        'env-10'       => [  297,  684 ],
        'env-monarch'  => [  279,  540 ],
        'a'            => [  612,  791 ],  # ANSI technical drawing paper
        'b'            => [  791, 1225 ],
        'c'            => [ 1225, 1585 ],
        'd'            => [ 1585, 2449 ],
        'e'            => [ 2449, 3169 ],
        'f'            => [ 2016, 2880 ],
        'b-plus'       => [  936, 1368 ],  # aka super-B, A3+, super-A3
        'arch-a'       => [  648,  864 ],
        'arch-b'       => [  864, 1296 ],
        'arch-c'       => [ 1296, 1728 ],
        'arch-d'       => [ 1728, 2592 ],
        'arch-e'       => [ 2592, 3456 ],
        'arch-e1'      => [ 2160, 3024 ],
        'pott'         => [  288,  450 ],  # British sizes
        'post'         => [  360,  576 ],
        'large-post'   => [  378,  594 ],
	'crown'        => [  360,  540 ],
	'large-crown'  => [  378,  576 ],
	'demy'         => [  409,  630 ],
	'small-demy'   => [  409,  612 ],
	'medium'       => [  414,  648 ],
	'royal'        => [  450,  720 ],
	'small-royal'  => [  445,  666 ],
	'super-royal'  => [  486,  738 ],
	'imperial'     => [  540,  792 ],
    );
}

1;
