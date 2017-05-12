# Copyright (C) 2001-2007 Daniel Berrange <dan@berrange.com>

use strict;
use warnings;

die unless (scalar @ARGV == 1);

unless (do "lib/Test/AutoBuild.pm")
  {
    if ($@) { die $@ }
    die "lib/Test/AutoBuild.pm: $!"
  }

local $/ = undef;
$_ = <DATA>;
s/\@VERSION\@/$Test::AutoBuild::VERSION/g;

open YML, ">$ARGV[0]" or die "$!";
print YML $_;
close YML;
__DATA__
--- #YAML:1.0
name:         Test-AutoBuild
abstract:     Framework for performing continuous, unattended, automated software builds
version:      @VERSION@
author:
  - Daniel P. Berrange <dan@berrange.com>
license: gpl
generated_by: ExtUtils::MakeMaker version 6.30
requires:
   BSD::Resource:                 1.10
   Carp:                          0
   Class::MethodMaker:            0
   Config:                        0
   Config::Record:                1.1.0
   Cwd:                           0
   Data::Dumper:                  0
   Date::Manip:                   0
   Digest::MD5:                   0
   Fcntl:                         0
   File::Copy:                    0
   File::Find:                    0
   File::Glob:                    0
   File::Path:                    0
   File::Spec:                    0
   File::stat:                    0
   File::Temp:                    0
   IO::File:                      0
   IO::Scalar:                    0
   List::Util:                    0
   Log::Log4perl:                 0
   Net::SMTP:                     2.15
   POSIX:                         0
   Storable:                      0
   Symbol:                        0
   Sys::Hostname:                 0
   Template:                      0
   XML::Simple:                   0
build_requires:
   Test::More:                    0

resources:
  license: http://www.gnu.org/licenses/gpl.html
  homepage: http://autobuild.org/
  bugtracker: https://gna.org/bugs/?group=testautobuild
  repository: https://gna.org/cvs/?group=testautobuild
  MailingList: https://gna.org/mail/?group=testautobuild

distribution_type: module

meta-spec:
   version: 1.3
   url: http://module-build.sourceforge.net/META-spec-v1.3.html
