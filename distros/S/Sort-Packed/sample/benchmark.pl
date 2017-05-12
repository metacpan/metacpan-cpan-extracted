#!/usr/bin/perl

use strict;
use warnings;

my $size = $ARGV[0] || 10000;

use Sort::Packed qw(radixsort_packed mergesort_packed mergesort_packed_custom);

use Benchmark qw(cmpthese);

sub bm {
    my ($format, @data) = @_;
    my $packed = pack "$format*" => @data;

    print "format $format\n";
    cmpthese(-1,
             { native => sub { my @out = sort { $a <=> $b } @data },
               bad_native => sub { my @out = sort { -$b <=> -$a } @data },
               radix => sub { my $in = pack "$format*" => @data;
                              radixsort_packed $format => $in;
                              my @out = unpack "$format*" => $in
                          },
               radix2 => sub { my $cp = $packed;
                                radixsort_packed $format => $cp
                            },
               mergesort => sub { my $in = pack "$format*" => @data;
                                  radixsort_packed $format => $in;
                                  my @out = unpack "$format*" => $in
                              },
               mergesort2 => sub { my $cp = $packed;
                                   mergesort_packed $format => $cp
                               },
               mergesort_custom => sub { my $in = pack "$format*" => @data;
                                         mergesort_packed_custom { unpack($format,$a) <=> unpack($format,$b) } $format => $in;
                                         my @out = unpack "$format*" => $in
                                     },
               mergesort_custom2 => sub { my $cp = $packed;
                                          mergesort_packed_custom { unpack($format,$a) <=> unpack($format,$b) } $format => $cp
                                      },
               mergesort_custom3 => sub { my $cp = $packed;
                                          mergesort_packed_custom { $a cmp $b } $format => $cp
                                      },
             }
            );
}

my @data = map { 2**31 - 2**32 * rand } 1..$size;
bm(F => @data);



my @int = map { int $_ } @data;
bm(j => @data);

my @uint = map { int abs $_ } @data;
bm(J => @data);
bm(N => @data);
bm(V => @data);
