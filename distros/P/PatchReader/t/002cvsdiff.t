#!/usr/bin/env perl -w
use strict;
use lib qw(lib t);

use Test::PatchReader;

# Sample patch
my $patch_cvsdiff = <<EOF;
Index: dir2/file.cpp
===================================================================
RCS file: /cvsroot/dir1/dir2/file.cpp,v
retrieving revision 1.2.1.1
diff -u -p -r1.2.1.1 file.cpp
--- dir2/file.cpp 20 Jan 2011 18:10:20 -0000  1.2.1.1
+++ dir2/file.cpp 21 Jan 2011 19:20:30 -0000
@@ -10,7 +10,8 @@
     }
 
     File::PerformA();
-  } else if (strcmp(var, PERFORM_B) {
+  } else if (strcmp(var, PERFORM_B) ||
+             strcmp(var, "STRING_C")) {
     File::PerformB();
   }
 
EOF

# Expected output from reading the sample patch
my $patch_expected = <<EOF;
Index: dir2/file.cpp
===================================================================
RCS file: /cvsroot/dir1/dir2/file.cpp,v
--- dir2/file.cpp		1.2.1.1
+++ dir2/file.cpp	
@@ -10,7 +10,8 @@ 
     }
 
     File::PerformA();
-  } else if (strcmp(var, PERFORM_B) {
+  } else if (strcmp(var, PERFORM_B) ||
+             strcmp(var, "STRING_C")) {
     File::PerformB();
   }
 
EOF

# Run the test
convert_patch($patch_cvsdiff, $patch_expected, 1, 2, 1, undef,
  "dir2/file.cpp", "1.2.1.1", undef, "/cvsroot/dir1/dir2/file.cpp,v");
