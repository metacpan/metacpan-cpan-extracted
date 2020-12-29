package PDF::Builder::Resource::PaperSizes;

use strict;
use warnings;

our $VERSION = '3.021'; # VERSION
my $LAST_UPDATE = '3.020'; # manually update whenever code is changed

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
