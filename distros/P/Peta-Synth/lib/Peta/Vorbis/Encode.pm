package Peta::Vorbis::Encode;
# ABSTRACT: Ogg Vorbis encoder

# An Ogg Vorbis encoder: samples go in, Ogg pages come out. The work is
# shared out like this:
#
#   MDCT    blocks of 2048 samples (256 around attacks), half overlapped,
#           in Vorbis' window (::PDL does the same with PDL, faster)
#   Psy     the quantization step each bin may have
#   Book    the codebooks: this encoder's own, sent in the setup header
#   Ogg     the pages
#
# This module makes the headers and the audio packets. A block's spectrum
# is divided by a floor (Vorbis' floor 1: straight lines in decibels
# between some 32 points, fitted below the steps the model allows) and
# rounded: that is the residue. The residue is coded in partitions of 16
# bins, each of a class by its largest value: nothing for zeros, small
# vectors for small values, and for large ones a cascade, a coarse value (a
# multiple of 5, 45 or 765) with finer ones added, down to -2 .. 2. So a
# partition of zeros with one peak costs little more than the peak.
#
# The codebooks' code lengths come from how often each entry is used in
# encoding sample material (Peta::Vorbis::Encode::Weights, made by
# devbin/vorbis-train); without them, from assumed distributions.
#
# The bitrate varies with quality (0 to 10): how far below the masking the
# noise is put. Two channels are coupled with Vorbis' square polar mapping,
# on the integer residues and so without loss; where they are alike, the
# second is mostly zeros.
#
# Blocks are long, or short around attacks, so that an attack's noise does
# not spread to before it (pre-echo). Each block's centre follows the last
# one's by a quarter of each one's size; the next block is short when an
# attack lies within what a long one would cover, so no long block holds an
# attack. A long block beside a short one has that side's slope short.
# Floor, residue and mapping are each there twice, for the two sizes.

use v5.36;
use List::Util qw(any max min);
use Peta::Hearing;
use Peta::Vorbis::Encode::Book;
use Peta::Vorbis::Encode::MDCT;
use Peta::Vorbis::Encode::Ogg;
use Peta::Vorbis::Encode::Psy;

our $VERSION = '0.2610180';

use constant {
    BLOCK      => 2048,
    HALF       => 1024,
    SHORT      => 256,
    SEGMENT    => 64,      # samples the attack detector looks at, at a time
    ATTACK     => 10,      # a segment this many times louder than the eight before it
    AUDIBLE    => 1e-6,    # and at least this loud (energy per sample)
    MULTIPLIER => 2,       # floor 1: Y values 0 .. 127, steps of 2 in the table
    RANGE      => 128,
    POSTS      => 32,      # points of a long block's floor (a short one's: 8)
    PARTITION  => 16,      # residue partition size
    LARGEST    => 4972,    # the largest residue value the cascade codes
    VENDOR     => 'Peta::Vorbis::Encode',
};

# floor1_inverse_dB_table, as the specification gives it: Y * multiplier
# into a linear amplitude, -140 dB to 0 dB.
my @DB = (
    1.0649863e-07, 1.1341951e-07, 1.2079015e-07, 1.2863978e-07, 1.3699951e-07, 1.4590251e-07, 1.5538408e-07, 1.6548181e-07,
    1.7623575e-07, 1.8768855e-07, 1.9988561e-07, 2.1287530e-07, 2.2670913e-07, 2.4144197e-07, 2.5713223e-07, 2.7384213e-07,
    2.9163793e-07, 3.1059021e-07, 3.3077411e-07, 3.5226968e-07, 3.7516214e-07, 3.9954229e-07, 4.2550680e-07, 4.5315863e-07,
    4.8260743e-07, 5.1396998e-07, 5.4737065e-07, 5.8294187e-07, 6.2082472e-07, 6.6116941e-07, 7.0413592e-07, 7.4989464e-07,
    7.9862701e-07, 8.5052630e-07, 9.0579828e-07, 9.6466216e-07, 1.0273513e-06, 1.0941144e-06, 1.1652161e-06, 1.2409384e-06,
    1.3215816e-06, 1.4074654e-06, 1.4989305e-06, 1.5963394e-06, 1.7000785e-06, 1.8105592e-06, 1.9282195e-06, 2.0535261e-06,
    2.1869758e-06, 2.3290978e-06, 2.4804557e-06, 2.6416497e-06, 2.8133190e-06, 2.9961443e-06, 3.1908506e-06, 3.3982101e-06,
    3.6190449e-06, 3.8542308e-06, 4.1047004e-06, 4.3714470e-06, 4.6555282e-06, 4.9580707e-06, 5.2802740e-06, 5.6234160e-06,
    5.9888572e-06, 6.3780469e-06, 6.7925283e-06, 7.2339451e-06, 7.7040476e-06, 8.2047000e-06, 8.7378876e-06, 9.3057248e-06,
    9.9104632e-06, 1.0554501e-05, 1.1240392e-05, 1.1970856e-05, 1.2748789e-05, 1.3577278e-05, 1.4459606e-05, 1.5399272e-05,
    1.6400004e-05, 1.7465768e-05, 1.8600792e-05, 1.9809576e-05, 2.1096914e-05, 2.2467911e-05, 2.3928002e-05, 2.5482978e-05,
    2.7139006e-05, 2.8902651e-05, 3.0780908e-05, 3.2781225e-05, 3.4911534e-05, 3.7180282e-05, 3.9596466e-05, 4.2169667e-05,
    4.4910090e-05, 4.7828601e-05, 5.0936773e-05, 5.4246931e-05, 5.7772202e-05, 6.1526565e-05, 6.5524908e-05, 6.9783085e-05,
    7.4317983e-05, 7.9147585e-05, 8.4291040e-05, 8.9768747e-05, 9.5602426e-05, 0.00010181521, 0.00010843174, 0.00011547824,
    0.00012298267, 0.00013097477, 0.00013948625, 0.00014855085, 0.00015820453, 0.00016848555, 0.00017943469, 0.00019109536,
    0.00020351382, 0.00021673929, 0.00023082423, 0.00024582449, 0.00026179955, 0.00027881276, 0.00029693158, 0.00031622787,
    0.00033677814, 0.00035866388, 0.00038197188, 0.00040679456, 0.00043323036, 0.00046138411, 0.00049136745, 0.00052329927,
    0.00055730621, 0.00059352311, 0.00063209358, 0.00067317058, 0.00071691700, 0.00076350630, 0.00081312324, 0.00086596457,
    0.00092223983, 0.00098217216, 0.0010459992, 0.0011139742, 0.0011863665, 0.0012634633, 0.0013455702, 0.0014330129,
    0.0015261382, 0.0016253153, 0.0017309374, 0.0018434235, 0.0019632195, 0.0020908006, 0.0022266726, 0.0023713743,
    0.0025254795, 0.0026895994, 0.0028643847, 0.0030505286, 0.0032487691, 0.0034598925, 0.0036847358, 0.0039241906,
    0.0041792066, 0.0044507950, 0.0047400328, 0.0050480668, 0.0053761186, 0.0057254891, 0.0060975636, 0.0064938176,
    0.0069158225, 0.0073652516, 0.0078438871, 0.0083536271, 0.0088964928, 0.009474637, 0.010090352, 0.010746080,
    0.011444421, 0.012188144, 0.012980198, 0.013823725, 0.014722068, 0.015678791, 0.016697687, 0.017782797,
    0.018938423, 0.020169149, 0.021479854, 0.022875735, 0.024362330, 0.025945531, 0.027631618, 0.029427276,
    0.031339626, 0.033376252, 0.035545228, 0.037855157, 0.040315199, 0.042935108, 0.045725273, 0.048696758,
    0.051861348, 0.055231591, 0.058820850, 0.062643361, 0.066714279, 0.071049749, 0.075666962, 0.080584227,
    0.085821044, 0.091398179, 0.097337747, 0.10366330, 0.11039993, 0.11757434, 0.12521498, 0.13335215,
    0.14201813, 0.15124727, 0.16107617, 0.17154380, 0.18269168, 0.19456402, 0.20720788, 0.22067342,
    0.23501402, 0.25028656, 0.26655159, 0.28387361, 0.30232132, 0.32196786, 0.34289114, 0.36517414,
    0.38890521, 0.41417847, 0.44109412, 0.46975890, 0.50028648, 0.53279791, 0.56742212, 0.60429640,
    0.64356699, 0.68538959, 0.72993007, 0.77736504, 0.82788260, 0.88168307, 0.9389798, 1.0,
);
my $DB_STEP = log(1 / $DB[0]) / 255;    # natural log per table step

# The residue's classes: [ the largest value, the books of its passes ].
# The books are those of %LATTICE below.
my @CLASSES = (
    [ 0,       [] ],
    [ 1,       ['r1'] ],
    [ 2,       ['r2'] ],
    [ 4,       ['r4'] ],
    [ 12,      [ 'by5', 'r2' ] ],
    [ 22,      [ 'by5wide', 'r2' ] ],
    [ 382,     [ 'by45', 'by5wide', 'r2' ] ],
    [ LARGEST, [ 'by765', 'by45', 'by5wide', 'r2' ] ],
);

# The cascades of the classes that have them: per pass the step its book's
# values are multiples of, and the most steps it holds. The last pass
# carries what is left, -2 .. 2.
my %CASCADE = (
    4 => [ [ 5, 2 ] ],
    5 => [ [ 5, 4 ] ],
    6 => [ [ 45, 8 ], [ 5, 4 ] ],
    7 => [ [ 765, 6 ], [ 45, 8 ], [ 5, 4 ] ],
);

# The residue books' values: [ dimensions, number of values, minimum, step ].
my %LATTICE = (
    r1      => [ 4, 3,  -1,    1 ],
    r2      => [ 2, 5,  -2,    1 ],
    r4      => [ 2, 9,  -4,    1 ],
    by5     => [ 2, 5,  -10,   5 ],
    by5wide => [ 2, 9,  -20,   5 ],
    by45    => [ 1, 17, -360,  45 ],
    by765   => [ 1, 13, -4590, 765 ],
);

# How fast the assumed weights of a residue book fall off from the middle
# value, where no counted weights are at hand.
my %SPREAD = (r1 => 0.9, r2 => 0.8, r4 => 0.4, by5 => 1.0, by5wide => 0.8, by45 => 0.8, by765 => 0.8);

# All the books, in the order of the setup header.
my @BOOKS = (
    'floor',
    'classes',
    sort { $LATTICE{$a}[3] <=> $LATTICE{$b}[3] || $LATTICE{$a}[1] <=> $LATTICE{$b}[1] } keys %LATTICE,
);

sub new ($class, %arg) {
    my $rate     = $arg{rate}     // 44100;
    my $channels = $arg{channels} // 2;
    my $quality  = $arg{quality}  // 5;

    die "channels: 1 or 2\n" if $channels != 1 && $channels != 2;
    die "quality: 0 to 10\n" if $quality < 0 || $quality > 10;

    my $self = bless {
        rate     => $rate,
        channels => $channels,
        quality  => $quality,
        ogg      => Peta::Vorbis::Encode::Ogg->new($arg{serial} // int(rand 0x7FFFFFFF)),

        pcm      => [ map { [ (0.0) x HALF ] } 1 .. $channels ],    # from half a block before the first sample
        base     => -HALF,    # the sample pcm starts at
        center   => 0,        # the next block's centre
        size     => BLOCK,    # and size
        before   => BLOCK,    # the last block's size
        attacks  => [],       # where attacks are, in samples
        seen     => 0,        # the samples looked at for attacks
        energies => [ (0.0) x 8 ],
        tail     => [ (0.0) x $channels ],

        packets  => 0,
        samples  => 0,
        bytes    => 0,
        shorts   => 0,        # short blocks
    }, $class;

    my $mdct = _mdct($arg{mdct} // 'auto');
    $self->{config}{$_} = $self->_configure($_, $mdct) for SHORT, BLOCK;

    # The windows: short; long, with either side's slope long or short.
    $self->{windows}{short} = Peta::Vorbis::Encode::MDCT::window(SHORT);
    for my $left (SHORT, BLOCK) {
        for my $right (SHORT, BLOCK) {
            $self->{windows}{"$left/$right"} = Peta::Vorbis::Encode::MDCT::window(BLOCK, $left, $right);
        }
    }

    $self->_books;
    if ($arg{count}) { $_->count for values %{ $self->{books} } }

    return $self;
}

# The MDCT's class: 'pdl', 'perl', or 'auto' (PDL where it loads).
sub _mdct ($name) {
    my $mdct = 'Peta::Vorbis::Encode::MDCT';

    return $mdct          if $name eq 'perl';
    return "${mdct}::PDL" if eval { require Peta::Vorbis::Encode::MDCT::PDL; 1 };
    return $mdct          if $name ne 'pdl';

    die "the PDL MDCT needs PDL: $@";
}

# What a block size needs: its MDCT, the model, where the coded residue
# ends, and its floor's points.
sub _configure ($self, $n, $mdct_class) {
    my $half = $n / 2;
    my $mdct = $mdct_class->new($n, 4 / $n);

    # The level of a full-scale 1 kHz sine in the transform's bins.
    my @sine = map { sin(2 * 3.141592653589793 * 1000 * $_ / $self->{rate}) } 0 .. $n - 1;
    my $full = 0;
    $full += $_ * $_ for @{ $mdct->transform(\@sine, Peta::Vorbis::Encode::MDCT::window($n)) };

    # The residue is coded up to where hearing ends, by quality, in whole
    # partitions; a short block's to the same frequency.
    my $top = 15000 + 600 * $self->{quality};
    my $end = min(int($top / ($self->{rate} / 2) * HALF / PARTITION) * PARTITION, HALF);

    return {
        n    => $n,
        half => $half,
        mdct => $mdct,
        end  => int($end * $half / HALF / PARTITION) * PARTITION,
        psy  => Peta::Vorbis::Encode::Psy->new($self->{rate}, $half, $self->{quality}, $full),
        $self->_floor_posts($half, $n == BLOCK ? POSTS : 8),
    };
}

sub mdct ($self) { return ref($self->{config}{+BLOCK}{mdct}) =~ /PDL\z/ ? 'pdl' : 'perl' }

sub quality ($self) { return $self->{quality} }
sub packets ($self) { return $self->{packets} }
sub bytes   ($self) { return $self->{bytes} }
sub shorts  ($self) { return $self->{shorts} }

# With count => 1: how often each book's entries were written, by book.
sub counts ($self) {
    my $books = $self->{books};
    return { map { $_ => [ @{ $books->{$_}->count } ] } keys %$books };
}

# A floor's points for $half bins: X positions 0 and $half, then $posts
# points evenly spaced in Bark, in an order that halves the intervals (each
# point is predicted from its neighbours already coded); and for each point
# from the third, its neighbours among those before it.
sub _floor_posts ($self, $half, $posts) {
    my $width = $self->{rate} / 2 / $half;
    my $bark  = sub ($bin) { return Peta::Hearing::bark($bin * $width) };

    my ($z0, $z1) = ($bark->(1), $bark->($half - 1));
    my @x;
    my $bin = 1;
    for my $j (0 .. $posts - 1) {
        my $z = $z0 + ($z1 - $z0) * $j / ($posts - 1);
        $bin++ while $bin < $half - 1 && $bark->($bin) < $z;
        push @x, @x && $bin <= $x[-1] ? $x[-1] + 1 : $bin;
    }

    # Coarse to fine: the middle of each interval before its halves.
    my @order;
    my @todo = ([ 0, $#x ]);
    while (@todo) {
        my @next;
        for my $span (@todo) {
            my ($from, $to) = @$span;
            next if $from > $to;

            my $mid = int(($from + $to) / 2);
            push @order, $x[$mid];
            push @next, [ $from, $mid - 1 ], [ $mid + 1, $to ];
        }
        @todo = @next;
    }
    my @list = (0, $half, @order);

    my (@low, @high);
    for my $i (2 .. $#list) {
        my ($lo, $hi) = (0, 1);
        for my $j (0 .. $i - 1) {
            $lo = $j if $list[$j] < $list[$i] && $list[$j] > $list[$lo];
            $hi = $j if $list[$j] > $list[$i] && $list[$j] < $list[$hi];
        }
        $low[$i]  = $lo;
        $high[$i] = $hi;
    }

    my $bits = 0;
    $bits++ while (1 << $bits) < $half;

    return (
        floor_x      => \@list,
        floor_low    => \@low,
        floor_high   => \@high,
        floor_sorted => [ sort { $list[$a] <=> $list[$b] } 0 .. $#list ],
        rangebits    => $bits,
    );
}

# The codebooks, with their numbers in the setup header. Their weights (how
# often each entry is expected) are counted ones where there are counts.
sub _books ($self) {
    my %counted = eval { no warnings 'once'; require Peta::Vorbis::Encode::Weights; %Peta::Vorbis::Encode::Weights::WEIGHTS };
    my $classes = @CLASSES;
    my (%book, %number);

    for my $i (0 .. $#BOOKS) {
        my $name = $BOOKS[$i];
        $number{$name} = $i;

        if ($name eq 'floor') {
            my $weights = _counted($counted{$name}, RANGE) // [ map { exp(-$_ / 5) } 0 .. RANGE - 1 ];
            $book{$name} = Peta::Vorbis::Encode::Book->new(entries => RANGE, weights => $weights);
        }
        elsif ($name eq 'classes') {
            # Scalar, but its dimension says how many classes a word holds.
            my $assumed = [ map { 0.6**int($_ / $classes) * 0.6**($_ % $classes) } 0 .. $classes**2 - 1 ];
            my $weights = _counted($counted{$name}, $classes**2) // $assumed;
            $book{$name} = Peta::Vorbis::Encode::Book->new(entries => $classes**2, dimensions => 2, weights => $weights);
        }
        else {
            my ($dim, $m, $min, $step) = @{ $LATTICE{$name} };
            my $weights = _counted($counted{$name}, $m**$dim) // _laplace($m, $dim, $SPREAD{$name});
            $book{$name} = Peta::Vorbis::Encode::Book->new(
                dimensions => $dim,
                values     => $m,
                minimum    => $min,
                delta      => $step,
                weights    => $weights,
            );
        }
    }

    $self->{books}       = \%book;
    $self->{book_number} = \%number;
    return;
}

# Counted weights, if there are counts for all the entries; each count
# raised by a half, so that no entry goes without a codeword.
sub _counted ($counts, $entries) {
    return undef if !$counts || @$counts != $entries;
    return [ map { $_ + 0.5 } @$counts ];
}

# Assumed weights for a lattice of $dim dimensions over $m values: a
# Laplace distribution about the middle value, for each component.
sub _laplace ($m, $dim, $lambda) {
    my $mid = ($m - 1) / 2;
    my @p   = map { exp(-abs($_ - $mid) * $lambda) } 0 .. $m - 1;
    my @w;
    for my $e (0 .. $m**$dim - 1) {
        my ($w, $v) = (1, $e);
        for (1 .. $dim) {
            $w *= $p[ $v % $m ];
            $v = int($v / $m);
        }
        push @w, $w;
    }
    return \@w;
}

# The three header packets: identification, comment and setup.
sub _headers ($self) {
    return ($self->_id_header, $self->_comment_header, $self->_setup_header);
}

sub _id_header ($self) {
    my $id = Peta::Vorbis::Encode::Bits->new;
    $id->put(1, 8);
    $id->put(ord, 8) for split //, 'vorbis';
    $id->put(0, 32);                  # version
    $id->put($self->{channels}, 8);
    $id->put($self->{rate}, 32);
    $id->put(0, 32) for 1 .. 3;       # bitrates: not said
    $id->put(8, 4);                   # short blocks of 2^8
    $id->put(11, 4);                  # long blocks of 2^11
    $id->put(1, 1);                   # framing
    return $id->bytes;
}

sub _comment_header ($self) {
    my $comment = Peta::Vorbis::Encode::Bits->new;
    $comment->put(3, 8);
    $comment->put(ord, 8) for split //, 'vorbis';
    $comment->put(length VENDOR, 32);
    $comment->put(ord, 8) for split //, VENDOR;
    $comment->put(0, 32);             # no comments
    $comment->put(1, 1);              # framing
    return $comment->bytes;
}

sub _setup_header ($self) {
    my $s = Peta::Vorbis::Encode::Bits->new;
    $s->put(5, 8);
    $s->put(ord, 8) for split //, 'vorbis';

    my @books = map { $self->{books}{$_} } @BOOKS;
    $s->put(@books - 1, 8);
    $_->header($s) for @books;

    $s->put(0, 6);                    # time: one placeholder
    $s->put(0, 16);

    my @configs = map { $self->{config}{$_} } SHORT, BLOCK;
    $self->_setup_floors($s, @configs);
    $self->_setup_residues($s, @configs);
    $self->_setup_mappings($s, @configs);

    # Modes: 0 short blocks, 1 long.
    $s->put(@configs - 1, 6);
    for my $m (0 .. $#configs) {
        $s->put($m, 1);               # block flag
        $s->put(0, 16);               # window type
        $s->put(0, 16);               # transform type
        $s->put($m, 8);               # mapping
    }

    $s->put(1, 1);                    # framing
    return $s->bytes;
}

# Floors 0 (short blocks) and 1 (long): the points in partitions of four,
# one class, one book.
sub _setup_floors ($self, $s, @configs) {
    $s->put(@configs - 1, 6);
    for my $c (@configs) {
        my @x     = @{ $c->{floor_x} };
        my $parts = (@x - 2) / 4;

        $s->put(1, 16);               # type 1
        $s->put($parts, 5);
        $s->put(0, 4) for 1 .. $parts;
        $s->put(4 - 1, 3);            # class 0: four values
        $s->put(0, 2);                # no subclasses
        $s->put($self->{book_number}{floor} + 1, 8);
        $s->put(MULTIPLIER - 1, 2);
        $s->put($c->{rangebits}, 4);
        $s->put($x[$_], $c->{rangebits}) for 2 .. $#x;
    }
    return;
}

# Residues 0 and 1, of format 1: the partitions, the classes and their books.
sub _setup_residues ($self, $s, @configs) {
    $s->put(@configs - 1, 6);
    for my $c (@configs) {
        $s->put(1, 16);               # format 1
        $s->put(0, 24);               # begin
        $s->put($c->{end}, 24);
        $s->put(PARTITION - 1, 24);
        $s->put(@CLASSES - 1, 6);
        $s->put($self->{book_number}{classes}, 8);

        for my $class (@CLASSES) {
            my $cascade = (1 << @{ $class->[1] }) - 1;    # which passes have a book
            $s->put($cascade & 7, 3);
            $s->put($cascade > 7 ? 1 : 0, 1);
            $s->put($cascade >> 3, 5) if $cascade > 7;
        }
        for my $class (@CLASSES) {
            $s->put($self->{book_number}{$_}, 8) for @{ $class->[1] };
        }
    }
    return;
}

# Mappings 0 and 1: one submap each, its floor and residue those of its
# size; two channels coupled.
sub _setup_mappings ($self, $s, @configs) {
    $s->put(@configs - 1, 6);
    for my $m (0 .. $#configs) {
        $s->put(0, 16);               # type 0
        $s->put(0, 1);                # one submap
        if ($self->{channels} == 2) {
            $s->put(1, 1);            # coupling: one step,
            $s->put(0, 8);
            $s->put(0, 1);            # channel 0 the magnitude,
            $s->put(1, 1);            # channel 1 the angle
        }
        else {
            $s->put(0, 1);            # no coupling
        }
        $s->put(0, 2);                # reserved
        $s->put(0, 8);                # time
        $s->put($m, 8);               # floor
        $s->put($m, 8);               # residue
    }
    return;
}

# Takes samples (-1 .. 1), one array reference per channel. Returns the
# pages they complete, the headers' with the first call.
sub encode ($self, @channels) {
    die "expected $self->{channels} channel(s)\n" if @channels != $self->{channels};

    my $out = '';
    if (!$self->{started}) {
        my ($id, $comment, $setup) = $self->_headers;
        my $ogg = $self->{ogg};
        $out .= $ogg->packet($id, 0) . $ogg->flush;
        $out .= $ogg->packet($comment, 0) . $ogg->packet($setup, 0) . $ogg->flush;
        $self->{started} = 1;
    }

    push @{ $self->{pcm}[$_] }, @{ $channels[$_] } for 0 .. $#channels;
    $self->{samples} += @{ $channels[0] };
    $out .= $self->_blocks;

    $self->{bytes} += length $out;
    return $out;
}

# Returns the rest: blocks until one's centre reaches the last sample (the
# decoder has every sample then), its page the last, saying how many
# samples there are.
sub finish ($self) {
    my $out = $self->{started} ? '' : $self->encode(map { [] } 1 .. $self->{channels});
    push @$_, (0.0) x (2 * BLOCK) for @{ $self->{pcm} };
    $self->{final} = 1;
    $out .= $self->_blocks;

    $self->{bytes} += length $out;
    return $out;
}

# Codes the blocks there are samples for: each needs its own samples and,
# to choose the next one's size, those a long block after it would cover.
sub _blocks ($self) {
    my $pcm = $self->{pcm};
    my $out = '';

    while (!$self->{done}) {
        my ($c, $n)   = @$self{qw(center size)};
        my $long_next = $c + $n / 4 + BLOCK / 4;
        my $have      = $self->{base} + @{ $pcm->[0] };
        last if !$self->{final} && $have < $long_next + HALF + SEGMENT;

        # The next block is short if an attack lies where a long one would reach.
        $self->_attacks;
        my $next = (any { $_ >= $c && $_ < $long_next + HALF } @{ $self->{attacks} }) ? SHORT : BLOCK;

        my $from   = $c - $n / 2 - $self->{base};
        my @block  = map { [ @$_[ $from .. $from + $n - 1 ] ] } @$pcm;
        my $packet = $self->_packet(\@block, $n, $self->{before}, $next);
        $self->{shorts}++ if $n == SHORT;
        $self->{packets}++;

        my $granule = min($c, $self->{samples});
        my $last    = $self->{final} && $c >= $self->{samples};
        $out .= $self->{ogg}->packet($packet, $granule, $last);

        # The first audio packet goes on a page of its own: its granule
        # position, 0, then says nothing is to be cut at the start, and the
        # last page's can only mean the end (FFmpeg reads a short first page
        # as a cut start).
        $out .= $self->{ogg}->flush if $self->{packets} == 1 && !$last;
        if ($last) {
            $self->{done} = 1;
            last;
        }

        # On to the next block; no block reaches further back than half a
        # long block before its centre.
        $self->{before} = $n;
        $self->{size}   = $next;
        $self->{center} = $c + $n / 4 + $next / 4;

        my $drop = $self->{center} - HALF - $self->{base};
        if ($drop > 0) {
            splice @$_, 0, $drop for @$pcm;
            $self->{base} += $drop;
        }
        my $old = $self->{center} - BLOCK;
        @{ $self->{attacks} } = grep { $_ >= $old } @{ $self->{attacks} };
    }
    return $out;
}

# Finds the attacks in the samples not yet looked at: in segments of 64
# samples, the energy of the changes from sample to sample (what is high in
# pitch, where pre-echo is heard), against the loudest of the eight
# segments before.
sub _attacks ($self) {
    my $pcm  = $self->{pcm};
    my $have = $self->{base} + @{ $pcm->[0] };
    my @seen = @{ $self->{energies} };

    while ($self->{seen} + SEGMENT <= $have) {
        my $at     = $self->{seen} - $self->{base};
        my $energy = 0.0;
        for my $ch (0 .. $#$pcm) {
            my $x        = $pcm->[$ch];
            my $previous = $self->{tail}[$ch];
            for my $i ($at .. $at + SEGMENT - 1) {
                my $d = $x->[$i] - $previous;
                $energy  += $d * $d;
                $previous = $x->[$i];
            }
            $self->{tail}[$ch] = $previous;
        }

        if ($energy > ATTACK * max(@seen) && $energy > AUDIBLE * SEGMENT) {
            push @{ $self->{attacks} }, $self->{seen};
        }
        shift @seen;
        push @seen, $energy;
        $self->{seen} += SEGMENT;
    }
    $self->{energies} = \@seen;
    return;
}

# A block's packet: $n samples of each channel, and the sizes of the blocks
# before and after it (for a long one's slopes).
sub _packet ($self, $blocks, $n, $before, $after) {
    my $config = $self->{config}{$n};
    my $out    = Peta::Vorbis::Encode::Bits->new;
    $out->put(0, 1);                  # audio

    my $window;
    if ($n == SHORT) {
        $out->put(0, 1);              # mode 0: short
        $window = $self->{windows}{short};
    }
    else {
        $out->put(1, 1);              # mode 1: long
        $out->put($before == BLOCK ? 1 : 0, 1);
        $out->put($after  == BLOCK ? 1 : 0, 1);
        $window = $self->{windows}{"$before/$after"};
    }

    my (@residue, @used);
    for my $x ($config->{mdct}->transform_all($blocks, $window)) {
        my ($r, $used) = $self->_floor($config, $out, $x);
        push @residue, $r;
        push @used, $used;
    }

    if ($self->{channels} == 2) {
        _couple(@residue, $config->{end});
        $used[0] = $used[1] = 1 if $used[0] || $used[1];    # the decoder decodes both, or neither
    }

    $self->_residue($out, \@residue, \@used, $config->{end});
    return $out->bytes;
}

# Square polar coupling, the decoder's four cases inverted: the channel with
# the larger value is the magnitude, the angle what takes it to the other.
# (A silent channel's residue is zeros: the decoder ignores what it makes
# of it, as that channel's floor is unused.)
sub _couple ($l, $r, $end) {
    for my $i (0 .. $end - 1) {
        my ($a, $b) = ($l->[$i], $r->[$i]);
        my $magnitude = abs $a >= abs $b ? $a : $b;
        $l->[$i] = $magnitude;
        $r->[$i] = $magnitude > 0 ? $a - $b : $b - $a;
    }
    return;
}

# A channel's floor: fitted below the steps the model allows, coded, and
# drawn as the decoder draws it. Returns the residue it leaves (the
# spectrum divided by it, rounded), and whether the channel is used at all.
sub _floor ($self, $config, $out, $x) {
    my $want = $self->_floor_wanted($config, $x);
    my ($final, $values, $flag) = _floor_values($config, $want);
    my $curve = _floor_curve($config, $final, $flag);

    my $end = $config->{end};
    my @r   = (0) x $config->{half};
    my $any = 0;
    for my $b (0 .. $end - 1) {
        my $v = _round($x->[$b] / $DB[ $curve->[$b] ], LARGEST);
        $r[$b] = $v;
        $any ||= $v;
    }

    if (!$any) {
        $out->put(0, 1);              # not used
        return (\@r, 0);
    }

    # Used: the first two points as they are; the rest with the floor book.
    $out->put(1, 1);
    $out->put($final->[0], 7);
    $out->put($final->[1], 7);
    my $book = $self->{books}{floor};
    $book->put($out, $values->[$_]) for 2 .. $#$values;

    return (\@r, 1);
}

# The Y each floor point wants: the finest step of the bins around it.
sub _floor_wanted ($self, $config, $x) {
    my $half   = $config->{half};
    my $step   = $config->{psy}->steps($x);
    my @list   = @{ $config->{floor_x} };
    my @sorted = @{ $config->{floor_sorted} };
    my @want   = (0) x @list;

    for my $k (0 .. $#sorted) {
        my $i    = $sorted[$k];
        my $from = $k > 0        ? int(($list[ $sorted[$k - 1] ] + $list[$i]) / 2) : 0;
        my $to   = $k < $#sorted ? int(($list[$i] + $list[ $sorted[$k + 1] ]) / 2) : $half - 1;
        $to   = $half - 1 if $to > $half - 1;
        $from = $to if $from > $to;

        my $least = min(@$step[ $from .. $to ]);
        my $index = 255 + log($least > 1e-30 ? $least : 1e-30) / $DB_STEP;
        $want[$i] = _clamp_to(int($index / MULTIPLIER), 0, RANGE - 1);
    }
    return \@want;
}

# The values to code: each point against its prediction from its
# neighbours, as the decoder unwraps them. Returns the points' final Y, the
# values, and which points the decoder draws the curve through.
sub _floor_values ($config, $want) {
    my @list  = @{ $config->{floor_x} };
    my @final = @$want[ 0, 1 ];
    my @value = (0, 0);
    my @flag  = (1, 1);

    for my $i (2 .. $#list) {
        my ($lo, $hi) = ($config->{floor_low}[$i], $config->{floor_high}[$i]);
        my $predicted = _render_point($list[$lo], $final[$lo], $list[$hi], $final[$hi], $list[$i]);
        my $v = _wrap($predicted, $want->[$i]);
        push @value, $v;
        $final[$i] = $want->[$i];

        if ($v) { $flag[$lo] = $flag[$hi] = $flag[$i] = 1 }
        else    { $flag[$i] //= 0 }
    }
    return (\@final, \@value, \@flag);
}

# The floor's curve, as the decoder draws it: indices into @DB, per bin.
sub _floor_curve ($config, $final, $flag) {
    my $half   = $config->{half};
    my @list   = @{ $config->{floor_x} };
    my @sorted = @{ $config->{floor_sorted} };
    my @curve  = (0) x $half;

    my ($lx, $ly) = (0, $final->[ $sorted[0] ] * MULTIPLIER);
    my ($hx, $hy) = (0, $ly);
    for my $k (1 .. $#sorted) {
        my $i = $sorted[$k];
        next if !$flag->[$i];

        ($hx, $hy) = ($list[$i], $final->[$i] * MULTIPLIER);
        _render_line($lx, $ly, $hx, $hy, \@curve);
        ($lx, $ly) = ($hx, $hy);
    }
    _render_line($hx, $hy, $half, $hy, \@curve) if $hx < $half;

    return \@curve;
}

# The value a floor point is coded with: what the decoder turns back into
# $y from its prediction (the specification's unwrapping, inverted).
sub _wrap ($predicted, $y) {
    my $highroom = RANGE - $predicted;
    my $lowroom  = $predicted;
    my $room     = 2 * min($highroom, $lowroom);
    my $d        = $y - $predicted;

    return 0 if $d == 0;

    if ($d > 0) {
        return 2 * $d         if 2 * $d < $room;
        return $d + $lowroom  if $highroom > $lowroom;
    }
    else {
        return -2 * $d - 1    if -2 * $d - 1 < $room;
        return $highroom - 1 - $d if $highroom <= $lowroom;
    }

    # Out of what the wrapping reaches from this prediction (cannot happen
    # for y within the range): code the prediction itself.
    return 0;
}

# Vorbis' integer line: its Y at $x.
sub _render_point ($x0, $y0, $x1, $y1, $x) {
    my $dy  = $y1 - $y0;
    my $adx = $x1 - $x0;
    my $off = int(abs($dy) * ($x - $x0) / $adx);
    return $dy < 0 ? $y0 - $off : $y0 + $off;
}

# Vorbis' integer line, drawn into @$v from x0 up to (not including) x1.
sub _render_line ($x0, $y0, $x1, $y1, $v) {
    my $dy  = $y1 - $y0;
    my $adx = $x1 - $x0;
    return if $adx <= 0;

    my $ady  = abs $dy;
    my $base = $dy < 0 ? -int(-$dy / $adx) : int($dy / $adx);
    my $sy   = $dy < 0 ? $base - 1 : $base + 1;
    $ady -= abs($base) * $adx;

    my $n = @$v;
    my ($y, $err) = ($y0, 0);
    $v->[$x0] = $y if $x0 < $n;
    for my $x ($x0 + 1 .. $x1 - 1) {
        $err += $ady;
        if ($err >= $adx) { $err -= $adx; $y += $sy }
        else              { $y += $base }
        $v->[$x] = $y if $x < $n;
    }
    return;
}

# Codes the residue of the used channels (format 1: each channel's vector
# on its own): a class word for every two partitions, then pass by pass
# the partitions' values with their classes' books.
sub _residue ($self, $out, $residue, $used, $end) {
    my @channels = grep { $used->[$_] } 0 .. $#$residue;
    return if !@channels;

    my $parts = $end / PARTITION;
    my %class = map { $_ => _classes($residue->[$_], $parts) } @channels;

    my $words    = $self->{books}{classes};
    my $per      = $words->dimensions;
    my $nclasses = @CLASSES;

    for my $pass (0 .. 3) {
        my $p = 0;
        while ($p < $parts) {
            if ($pass == 0) {
                for my $ch (@channels) {
                    my $word = 0;
                    $word = $word * $nclasses + ($class{$ch}[$p + $_] // 0) for 0 .. $per - 1;
                    $words->put($out, $word);
                }
            }
            for my $i (0 .. $per - 1) {
                last if $p >= $parts;

                for my $ch (@channels) {
                    my $c    = $class{$ch}[$p];
                    my $name = $CLASSES[$c][1][$pass] // next;
                    $self->_partition($out, $self->{books}{$name}, $c, $pass, $residue->[$ch], $p * PARTITION);
                }
                $p++;
            }
        }
    }
    return;
}

# Each partition's class: the first whose largest value holds the
# partition's largest.
sub _classes ($r, $parts) {
    my @classes;
    for my $p (0 .. $parts - 1) {
        my $top = max(map { abs } @$r[ $p * PARTITION .. ($p + 1) * PARTITION - 1 ]);
        my $c   = 0;
        $c++ while $CLASSES[$c][0] < $top;
        push @classes, $c;
    }
    return \@classes;
}

# Codes a partition's values in one pass: what is left of each value for
# this pass's book, entry by entry of the book's dimension.
sub _partition ($self, $out, $book, $class, $pass, $r, $at) {
    my $dim  = $book->dimensions;
    my @part = map { _share($class, $pass, $r->[$_]) } $at .. $at + PARTITION - 1;
    for (my $i = 0; $i < PARTITION; $i += $dim) {
        $book->put($out, $book->entry(@part[ $i .. $i + $dim - 1 ]));
    }
    return;
}

# What of a value the given pass of a class carries: the cascades split it
# into coarse values (each a multiple of its step, as far as its book goes)
# and what is left for the last pass.
sub _share ($class, $pass, $v) {
    my $steps = $CASCADE{$class} // return $v;
    for my $p (0 .. $#$steps) {
        my ($step, $most) = @{ $steps->[$p] };
        my $part = $step * _round($v / $step, $most);
        return $part if $p == $pass;
        $v -= $part;
    }
    return _clamp_to($v, -2, 2);
}

# $x rounded half away from zero, within +-$limit.
sub _round ($x, $limit) {
    my $r = $x < 0 ? -int(-$x + 0.5) : int($x + 0.5);
    return _clamp_to($r, -$limit, $limit);
}

sub _clamp_to ($x, $low, $high) {
    return $low  if $x < $low;
    return $high if $x > $high;
    return $x;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Vorbis::Encode - Ogg Vorbis encoder

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Vorbis::Encode;

    my $ogg = Peta::Vorbis::Encode->new(rate => 48000, channels => 2, quality => 5);
    print $fh $ogg->encode(\@left, \@right);    # samples -1 .. 1, as many as you like
    print $fh $ogg->finish;

=head1 DESCRIPTION

Encodes samples into an Ogg Vorbis stream: a variable bitrate by quality
(0 to 10), floor 1, residue 1 with this encoder's own codebooks, long
blocks, and short ones around attacks.

=head1 METHODS

=head2 new

    Peta::Vorbis::Encode->new(
        rate     => 44100,
        channels => 2,
        quality  => 5,        # 0 .. 10
        mdct     => 'auto',   # perl, pdl, auto
        serial   => undef,    # the Ogg stream's serial number; random by default
        count    => 0,
    );

C<mdct> C<auto> uses PDL where it is installed: the same coefficients,
faster. With C<< count => 1 >> the encoder counts how often each codebook
entry is written (see C<counts>), which is how F<devbin/vorbis-train>
makes the weights.

=head2 encode

    my $bytes = $ogg->encode(\@left, \@right);

Returns the pages these samples complete; the headers come with the first
call.

=head2 finish

Returns the rest, the last page marking the end of the stream and the
number of samples.

=head2 quality, packets, bytes, shorts

The quality; the audio packets, bytes and short blocks so far.

=head2 counts

With C<< count => 1 >>: how often each codebook's entries were written, by
book.

=head2 mdct

Which MDCT the encoder uses: C<perl> or C<pdl>.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
