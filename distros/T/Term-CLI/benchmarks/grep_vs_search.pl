#!/usr/bin/perl
#
# Benchmark showing that finding prefix matches in a *sorted* list of
# strings is faster using a loop with shortcutting than a `grep` with
# `rindex`.
#
# There's also a version which first uses a binary search to locate the
# place where to start matching, but, depending on the type of item being
# compared, this only saves time when the list has more than 215 strings
# or 46 objects (with a "name" method); this is with a search string of
# 3 characters. For shorter search strings, the start point for binary
# search is higher and for longer strings it's lower.
#
# Mind you, the binary search starts to really pay off with very
# large lists (1000s of items).
#
# YMMVVM (your mileage may vary very much).

use 5.014;
use warnings;
use FindBin;
use Benchmark qw( cmpthese timethese );
use Time::HiRes qw( time );

use Getopt::Long qw( :config bundling );

my $DFL_ITERATIONS   = 10_000;
my $DFL_PREFIX_LEN   =      3;
my $DFL_LIST_SIZE    =    200;
my @DFL_ALGORITHMS   = qw( search:rindex search:bin );
my @DFL_MATCH_POINTS = ( 0, 0.5, 1 );

my $USAGE = <<EO_USAGE;
usage: $FindBin::Script [options]

Options:
  --words=f, -w f           - Read words from file f. Default is to autogenerate
                              the list of words (see --list-size).

  --prefix-len=n, -p n      - Match on prefix length n; 0 means match exact.
                              (default: $DFL_PREFIX_LEN)

  --iterations=n, -n n      - Run n iterations.
                              (default: $DFL_ITERATIONS)

  --list-size=n, -S n       - Create lists of n elements.
                              (default: $DFL_LIST_SIZE)

  --match-points=f1,f2,...
  -m f1,f2,...              - Match on prefixes from specific portions
                              of the list.
                              (default: @DFL_MATCH_POINTS)

  --algorithms=a1,a2,... 
  -a a1,a2,...              - Run tests for these algorithms.
                              (default: @DFL_ALGORITHMS)

  --indirect, -i            - Run the "indirect" versions of the algorithms
                              (i.e. where list items are hashes with a "name"
                              field).

  --list-algorithms, -l     - List the available algorithms.

EO_USAGE
 
my %ALGORITHM = (
    'grep:rindex'              => \&grep_rindex,
    'grep:substr'              => \&grep_substr,
    'search:rindex'            => \&search_rindex,
    'search:substr'            => \&search_substr,
    'search:bin'               => \&search_bin,
    'search:balanced'          => \&search_balanced,

    'grep:rindex:indirect'     => \&grep_rindex_indirect,
    'grep:substr:indirect'     => \&grep_substr_indirect,
    'search:rindex:indirect'   => \&search_rindex_indirect,
    'search:substr:indirect'   => \&search_substr_indirect,
    'search:bin:indirect'      => \&search_bin_indirect,
    'search:balanced:indirect' => \&search_balanced_indirect,
);

sub Main {
    my @match_points;
    my @algorithms;
    GetOptions(
        'words|w=s'          => \(my $word_file),
        'prefix-len|p=i'     => \(my $prefix_len = $DFL_PREFIX_LEN),
        'iterations|n=i'     => \(my $iterations = $DFL_ITERATIONS),
        'list-size|S=i'      => \(my $list_size = $DFL_LIST_SIZE),
        'match-points|m=s@'  => \@match_points,
        'algorithms|a=s@'    => \@algorithms,
        'indirect|i'         => \(my $indirect = 0),
        'list-algorithms|l'  => sub {
            say join(' ', sort keys %ALGORITHM);
            exit 0;
        },
        'help|h|?'           => sub { print $USAGE; exit 0 },
    ) or die $USAGE;

    die $USAGE if @ARGV;

    @algorithms    = @DFL_ALGORITHMS   if !@algorithms;
    my $algorithms = join(' ', @algorithms);
    $algorithms    =~ s{ , }{ }gxms;
    @algorithms    = split(q{ }, $algorithms);

    my $match_points = join(' ', @match_points);
    $match_points =~ s{ , }{ }gxms;
    @match_points = split(q{ }, $match_points);
    @match_points = grep { $_ >= 0 && $_ <= 1 } @match_points;
    @match_points = @DFL_MATCH_POINTS if !@match_points;

    if ($indirect) {
        @algorithms = map { m{:indirect$} ? $_ : "$_:indirect" } @algorithms;
    }

    my ($list, $list_indirect) = mk_lists($list_size, $word_file);
    
    my %compare_func;

    my @search_patterns = map { $list->[int($#{$list}*$_)] } @match_points;
    if ($prefix_len > 0) {
        @search_patterns = map { substr $_, 0, $prefix_len } @search_patterns;
    }

    for my $algo (@algorithms) {

        my $func = $ALGORITHM{$algo}
            or die "$algo: unknown algorithm (see '$FindBin::Script -l').\n";

        my $list_r = $algo =~ /:indirect$/ ? $list_indirect : $list;

        $compare_func{$algo} = sub {
            for my $text (@search_patterns) {
                my @l = $func->($text, $list_r, $prefix_len == 0);
            }
        }
    }

    say "list size: ", int( @$list );
    say "matching: @search_patterns";
    cmpthese( $iterations, \%compare_func );
    #print "\n";
    #timethese( $iterations, \%compare_func );
}

sub mk_lists {
    my ($list_size, $word_file) = @_;
    my (@list, @list_indirect);

    my $list_iter = 0;

    if ($word_file) {
        open my $fh, '<', $word_file or die "$word_file: $!\n";
        chomp( @list = (<$fh>) );
    }
    else {
        while (@list < $list_size) {
            for my $c ('a' .. 'z') {
                my $letter = chr( ord('a') + $list_iter %26 );
                my $elt = sprintf("%s%s", $c x 8, $letter x $list_iter);
                push @list, $elt;
                last if @list >= $list_size;
            }
            $list_iter++;
        }
    }
    @list = sort @list;
    @list_indirect = map { Item->new( name => $_ ) } @list;
    return (\@list, \@list_indirect);
}

sub grep_rindex {
    my ($text, $list, $exact) = @_;

    my @found = grep { rindex( $_, $text, 0 ) == 0 } @{$list};
    return $found[0] if $exact && @found && $found[0] eq $text;
    return @found;
}

sub grep_rindex_indirect {
    my ($text, $list, $exact) = @_;

    my @found = grep { rindex( $_->name, $text, 0 ) == 0 } @{$list};
    return $found[0] if $exact && @found && $found[0]->name eq $text;
    return @found;
}


sub grep_substr {
    my ($text, $list, $exact) = @_;

    my @found = grep { substr( $_, 0, length $text ) eq $text } @{$list};
    return $found[0] if $exact && @found && $found[0] eq $text;
    return @found;
}

sub grep_substr_indirect {
    my ($text, $list, $exact) = @_;

    my @found = grep { substr( $_->name, 0, length $text ) eq $text } @{$list};
    return $found[0] if $exact && @found && $found[0]->name eq $text;
    return @found;
}

sub search_rindex {
    my ($text, $list, $exact) = @_;

    my @found;
    foreach (@{$list}) {
        next if $_ lt $text;
        if (rindex( $_, $text, 0 ) == 0) {
            push @found, $_;
            return @found if $exact && $_ eq $text;
            next;
        }
        last;
    }
    return @found;
}

sub search_rindex_indirect {
    my ($text, $list, $exact) = @_;

    my @found;
    foreach (@{$list}) {
        my $n = $_->name;
        next if $n lt $text;
        if (rindex( $n, $text, 0 ) == 0) {
            push @found, $_;
            return @found if $exact && $n eq $text;
            next;
        }
        last;
    }
    return @found;
}

sub search_substr {
    my ($text, $list) = @_;
    my @found;
    foreach (@{$list}) {
        next if $_ lt $text;
        my $prefix = substr($_, 0, length($text));
        last if $prefix gt $text;
        push @found, $_ if $prefix eq $text;
    }
    return @found;
}

sub search_substr_indirect {
    my ($text, $list) = @_;
    my @found;
    foreach (@{$list}) {
        my $n = $_->name;
        next if $n lt $text;
        my $prefix = substr($n, 0, length($text));
        last if $prefix gt $text;
        push @found, $_ if $prefix eq $text;
    }
    return @found;
}

sub search_bin {
    my ($text, $list, $exact) = @_;

    my ( $lo, $hi ) = ( 0, $#{$list} );

    while ($lo < $hi) {
        my $mid = int( ($lo + $hi) / 2 );
        my $cmp = $text cmp $list->[$mid];
        if ($cmp < 0) {
            $hi = $mid;
            next;
        }
        if ($cmp > 0) {
            if ($lo == $hi-1) {
                $lo++;
                last;
            }
            $lo = $mid;
            next;
        }
        return $list->[$mid] if $exact;
        $lo = $hi = $mid;
        last;
    }
    return if $exact;

    my @found;
    foreach (@{$list}[$lo..$#{$list}]) {
        if (rindex( $_, $text, 0 ) == 0) {
            push @found, $_;
            next;
        }
        last;
    }
    return @found;
}

sub search_bin_indirect {
    my ($text, $list, $exact) = @_;

    my ( $lo, $hi ) = ( 0, $#{$list} );

    while ($lo < $hi) {
        my $mid = int( ($lo + $hi) / 2 );
        my $cmp = $text cmp $list->[$mid]->name;
        if ($cmp < 0) {
            $hi = $mid;
            next;
        }
        if ($cmp > 0) {
            if ($lo == $hi-1) {
                $lo++;
                last;
            }
            $lo = $mid;
            next;
        }
        return $list->[$mid] if $exact;
        $lo = $hi = $mid;
        last;
    }
    return if $exact;

    my @found;
    foreach (@{$list}[$lo..$#{$list}]) {
        my $n = $_->name;
        if (rindex( $n, $text, 0 ) == 0) {
            push @found, $_;
            next;
        }
        last;
    }
    return @found;
}

sub search_balanced {
    my ($text, $list, $exact) = @_;

    if ( @$list <= 42 || ( !$exact && @$list <= 215 ) ) {
        my @found;
        foreach (@{$list}) {
            next if $_ lt $text;
            if (rindex( $_, $text, 0 ) == 0) {
                push @found, $_;
                return @found if $exact && $_ eq $text;
                next;
            }
            last;
        }
        return @found;
    }

    my ( $lo, $hi ) = ( 0, $#{$list} );

    while ($lo < $hi) {
        my $mid = int( ($lo + $hi) / 2 );
        my $cmp = $text cmp $list->[$mid];
        if ($cmp < 0) {
            $hi = $mid;
            next;
        }
        if ($cmp > 0) {
            if ($lo == $hi-1) {
                $lo++;
                last;
            }
            $lo = $mid;
            next;
        }
        return $list->[$mid] if $exact;
        $lo = $hi = $mid;
        last;
    }

    my @found;
    foreach (@{$list}[$lo..$#{$list}]) {
        if (rindex( $_, $text, 0 ) == 0) {
            push @found, $_;
            next;
        }
        last;
    }
    return @found;

}

sub search_balanced_indirect {
    my ($text, $list, $exact) = @_;

    if ( @$list <= 11 || ( !$exact && @$list <= 46 ) ) {
        my @found;
        foreach (@{$list}) {
            my $n = $_->name;
            next if $n lt $text;
            if (rindex( $n, $text, 0 ) == 0) {
                push @found, $_;
                return @found if $exact && $n eq $text;
                next;
            }
            last;
        }
        return @found;
    }

    my ( $lo, $hi ) = ( 0, $#{$list} );

    while ($lo < $hi) {
        my $mid = int( ($lo + $hi) / 2 );
        my $cmp = $text cmp $list->[$mid]->name;
        if ($cmp < 0) {
            $hi = $mid;
            next;
        }
        if ($cmp > 0) {
            if ($lo == $hi-1) {
                $lo++;
                last;
            }
            $lo = $mid;
            next;
        }
        return $list->[$mid] if $exact;
        $lo = $hi = $mid;
        last;
    }

    my @found;
    foreach (@{$list}[$lo..$#{$list}]) {
        my $n = $_->name;
        if (rindex( $n, $text, 0 ) == 0) {
            push @found, $_;
            next;
        }
        last;
    }
    return @found;
}

package Item {
    use 5.014;
    use warnings;
    use Moo;
    use namespace::clean;

    has name => ( is => 'rw', required => 1 );
}

Main();
