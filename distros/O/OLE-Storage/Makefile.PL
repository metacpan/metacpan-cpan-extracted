#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile (
   "NAME"      => "OLE::Storage",
   "VERSION"   => "0.386",
   "dist"      => {
      "COMPRESS" => "gzip", 
      "SUFFIX"   => "gz"
   },
   "EXE_FILES" => [
      "tools/herbert",
      "tools/lclean",
      "tools/ldat",
      "tools/lhalw",
      "tools/lls",
      "contrib/MkWinwordIndex",
   ],
);

