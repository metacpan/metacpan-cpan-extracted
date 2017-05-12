#!/usr/bin/perl
use Test;
use strict;
use PerlIO::via::dynamic;
BEGIN { plan tests => 1 };

# $Filename$

my $fname = $0;

my $p = PerlIO::via::dynamic->new
  (untranslate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/"\$Filename: $fname\$"/e},
   translate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename\$/});

open my $fh, '<'.$p->via, $fname;

local $/;

my $text = <$fh>;

ok (1) if $text =~ m/^# \$Filename: $0\$/m;

exit;
