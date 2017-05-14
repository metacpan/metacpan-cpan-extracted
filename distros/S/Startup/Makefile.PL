#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile (
   "NAME"      => "Startup",
   "VERSION"   => "0.103",
   "dist"      => {
      "COMPRESS" => "gzip", 
      "SUFFIX"   => "gz"
   },
   "EXE_FILES" => [
      "tools/replace",
   ],
);

