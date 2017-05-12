#!/usr/bin/env perl -w
use strict;
use lib qw(lib t);

use Test::PatchReader;

# Sample patch
my $patch_cvsdiff = <<EOF;
--- filename.c.orig	2009-05-03
+++ filename.c	2009-06-07
@@ -3,5 +3,5 @@
 aaa
 bbb
-ccc
+ddd
 eee
 fff
--- otherfile.h.orig	2009-05-03
+++ otherfile.h	2009-06-07
@@ -4,5 +4,5 @@
 111
 222
-333
+444
 555
 666
EOF

# Expected output from reading the sample patch
my $patch_expected = <<EOF;
--- filename.c.orig	2009-05-03
+++ filename.c.orig	2009-06-07
@@ -3,5 +3,5 @@ 
 aaa
 bbb
-ccc
+ddd
 eee
 fff
--- otherfile.h.orig	2009-05-03
+++ otherfile.h.orig	2009-06-07
@@ -4,5 +4,5 @@ 
 111
 222
-333
+444
 555
 666
EOF

# Run the test
convert_patch($patch_cvsdiff, $patch_expected, 2, 1, 1, undef,
  "filename.c.orig", undef, undef, undef);
