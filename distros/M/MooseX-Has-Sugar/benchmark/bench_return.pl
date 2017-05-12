#!/usr/bin/env perl
# FILENAME: bench_return.pl
# CREATED: 06/26/14 07:41:05 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Benchmark difference of return styles

use strict;
use warnings;
use utf8;

sub constant_return() {
  return ( 'is', 'ro' );
}

sub constant_bare() {
  ( 'is', 'ro' );
}

use Benchmark qw( :all :hireswallclock );

cmpthese(
  -2,
  {
    return => sub {
      my @x;
      @x = constant_return for 0 .. 100;
    },
    bare => sub {
      my @x;
      @x = constant_bare for 0 .. 100;
    },
    return2 => sub {
      my @x;
      @x = constant_return for 0 .. 100;
    },
    bare2 => sub {
      my @x;
      @x = constant_bare for 0 .. 100;
    },
  }
);

__END__
5.21.1
config_args='-de -Dusecbacktrace -Doptimize=-O3 -march=native -mtune=native -g -ggdb3 -Dusedevel -Accflags=-DUSE_C_BACKTRACE_ON_ERROR -Aldflags=-lbfd

           Rate    bare   bare2 return2  return
bare2   16364/s      --     -1%     -6%     -6%
bare    16527/s      1%      --     -5%     -5%
return2 17436/s      7%      6%      --     -0%
return  17436/s      7%      6%      0%      --

5.10.1
config_args='-de'

           Rate    bare   bare2 return2  return
bare    12155/s      --     -0%     -1%     -1%
bare2   12190/s      0%      --     -1%     -1%
return2 12272/s      1%      1%      --     -0%
return  12272/s      1%      1%      0%      --

5.18.0
config_args='-de'
             Rate    bare   bare2  return return2
bare2   12597/s      --     -1%     -4%     -4%
bare    12664/s      1%      --     -4%     -4%
return2 13149/s      4%      4%      --     -0%
return  13149/s      4%      4%      0%      --

5.12.5
config_args='-de'
             Rate    bare   bare2 return2  return
bare    10803/s      --     -3%     -7%     -7%
bare2   11112/s      3%      --     -4%     -4%
return  11555/s      7%      4%      --     -0%
return2 11600/s      7%      4%      0%      --
