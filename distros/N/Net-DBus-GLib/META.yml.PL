# Copyright (C) 2008 Daniel Berrange <dan@berrange.com>

use strict;
use warnings;

die unless (scalar @ARGV == 1);

open SRC, "lib/Net/DBus/GLib.pm"
    or die "lib/Net/DBus/GLib.pm: $!";

our $VERSION;
while (<SRC>) {
    if (/\$VERSION\s*=\s*'(.*)'/) {
	$VERSION=$1;
    }
}
close SRC;

local $/ = undef;
$_ = <DATA>;
s/\@VERSION\@/$VERSION/g;

open SPEC, ">$ARGV[0]" or die "$!";
print SPEC $_;
close SPEC;
__DATA__
--- #YAML:1.0
name:         Net-DBus-GLib
abstract:     Extension for the DBus GLib bindings
version:      @VERSION@
author:
  - Daniel P. Berrange <dan@berrange.com>
license: gpl
generated_by: ExtUtils::MakeMaker version 6.30
requires:
   GLib:                          0
   Net::DBus:                     0.33.0
build_requires:
   Test::More:                    0
   Test::Pod:                     0
   Test::Pod::Coverage:           0

resources:
  license: http://www.gnu.org/licenses/gpl.html
  homepage: http://www.freedesktop.org/wiki/Software/dbus
  repository: http://hg.berrange.com/libraries/net-dbus-glib--devel
  MailingList: http://lists.freedesktop.org/mailman/listinfo/dbus/

distribution_type: module

meta-spec:
   version: 1.3
   url: http://module-build.sourceforge.net/META-spec-v1.3.html
