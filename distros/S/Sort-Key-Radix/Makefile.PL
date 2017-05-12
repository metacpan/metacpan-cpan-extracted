
use ExtUtils::MakeMaker;

use strict;
use warnings;

use Config;

open my $ch, ">", "rconfig.h"
    or die "unable to create config.h";

my %nv_format = ('5839b4c876bebf3f' => 'LE8',
                 '3fbfbe76c8b43958' => 'BE8',
                 '83c0caa145b6f3fdfb3f0000' => 'LE12_x86',
		 '3ffbfbe76c8b4395810624dd2f1a9fbe' => 'BE16',
		 'be9f1a2fdd24068195438b6ce7fbfb3f' => 'LE16',
                 '83c0caa145b6f3fdfb3f000000000000' => 'LE16_x86');

my $pnv = eval { unpack 'H*' => pack (($] < 5.008 ? 'd' : 'F') => 0.124) };
my $nv_format = $nv_format{$pnv};

my %sf_format = ('b6f3fd3d' => 'LE4',
                 '3dfdf3b6' => 'BE4',
                 '5839b4c876bebf3f' => 'LE8',
                 '3fbfbe76c8b43958' => 'BE8');

my $psf = eval {unpack 'H*' => pack f => 0.124 };
my $sf_format = $sf_format{$psf};

my %uv_format = ('01020304' => 'BE4',
                 '04030201' => 'LE4',
                 '0000000001020304' => 'BE8',
                 '0403020100000000' => 'LE4');

my $puv = eval { unpack 'H*' => pack (($] < 5.008 ? 'L!' : 'J') => 0x01020304) };
my $uv_format = $uv_format{$puv};

print $ch <<EOD;
#define NV_0124 "$pnv"
#define SF_0124 "$psf"
#define UV_01020304 "$puv"
EOD

if (defined $nv_format) {
    print $ch "#define NV_FORMAT $nv_format\n";
}

if (defined $sf_format) {
    print $ch "#define SF_FORMAT $sf_format\n";
}

if (defined $uv_format) {
    print $ch "#define UV_FORMAT $uv_format\n";
}

my $uvsize = $Config::Config{uvsize};

my $uvsuffix = $Config::Config{uvtype} eq "unsigned long long" ? 'ull' : 'ul';

print $ch "static UV uv_byte_mask[] = {\n";

for my $i (1..$uvsize) {
    print $ch "    0x", ('ff' x ($uvsize - $i)), ('00' x $i), "$uvsuffix, /* next byte: $i */\n";
}

print $ch "};\n";

close $ch;

unless ($nv_format and $sf_format) {
warn <<EOM;
The float point format of your computer is not supported by
Sort::Key::Radix yet!

Please, send an email to the author at sfandino\@yahoo.com with
information about your hardware, OS and the output from running "perl
-V".

Thank you!
EOM
}

WriteMakefile( NAME              => 'Sort::Key::Radix',
               VERSION_FROM      => 'lib/Sort/Key/Radix.pm',
               PREREQ_PM         => {},
               ABSTRACT_FROM  => 'lib/Sort/Key/Radix.pm',
               AUTHOR         => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS              => [''],
               INC               => '-I.',
               # OPTIMIZE => '-O0 -g'
               # OPTIMIZE => '-pg'
               # OPTIMIZE => '-O3'
               # OPTIMIZE => '-O2 -g'
             );
