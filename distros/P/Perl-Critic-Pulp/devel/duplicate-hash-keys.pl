#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use lib 'devel/lib';
use Perl::Critic;

use FindBin;
my $progname = $FindBin::Script;

my %zzz;
my $zzz = {};
my %dup = (
           qw(a 1 a 2),
           x => 1,
           ,
           %zzz,
           %$zzz,
           x => 2);

my $rr = \\{};
%$$$rr = (a => 1, 'a' => 2);
%zzz = (a => 1, 'a' => 2);

my %_Expiration_Units = ( map(($_, 1), qw(a b c)),
                          map(($_, 1), qw(d e f)),
                        );


my @filenames = (
                 "$FindBin::Bin/$FindBin::Script",

                 "/usr/share/perl5/AppConfig/State.pm",
                 "/usr/share/perl5/AnyEvent/HTTP.pm",
                 "/usr/share/perl5/Cache/BaseCache.pm",
                 "/usr/share/perl5/Dpkg/Deps.pm",
                 "/usr/share/perl5/Encode/X11.pm",
                 "/usr/share/perl5/Image/TIFF.pm",
                 "/usr/share/perl5/Regexp/Assemble.pm",
                 "/usr/share/perl5/Regexp/Grammars.pm",
                 "/usr/share/perl5/String/RewritePrefix.pm",
                 "/usr/share/perl5/Text/Autoformat.pm",
                 "/usr/share/perl5/XML/XPathEngine.pm",
                 "/usr/share/perl5/Email/Simple/Header.pm",
                 "/usr/share/perl5/HTML/Lint/HTML4.pm",
                 "/usr/share/perl5/PPIx/Regexp/Lexer.pm",
                 "/usr/share/perl5/Perl/Critic/Command.pm",
                 "/usr/share/perl5/Regexp/Parser/Objects.pm",
                 
                 # tricked by @_
                 "/usr/share/perl5/Acme/Tie/Eleet.pm",
                 "/usr/share/perl5/Pod/Simple/RTF.pm",
                 
                 # conditional
                 "/usr/share/perl5/App/Nopaste/Service.pm",
                 "/usr/share/perl5/CPAN/Meta/Converter.pm",
                 
                 # expression
                 "/usr/share/perl5/XUL/Gui.pm",
                 "/usr/share/perl5/Class/Meta/Attribute.pm",
                 "/usr/share/perl5/Curses/UI/Buttonbox.pm",
                 "/usr/share/perl5/Curses/UI/Calendar.pm",
                 "/usr/share/perl5/Curses/UI/Checkbox.pm",
                 "/usr/share/perl5/Curses/UI/Listbox.pm",
                 "/usr/share/perl5/Date/Calendar/Profiles.pm",
                 "/usr/share/perl5/Dpkg/Control/Fields.pm",
                 "/usr/share/perl5/Image/Caa/DriverANSI.pm",
                 
                 # tricked by reverse
                 "/usr/share/perl5/XML/FeedPP.pm",
                 
                 # genuine dups ...
                 "/usr/share/perl5/Parse/DebControl.pm",
                 "/usr/share/perl5/XML/Twig.pm",
                 "/usr/share/perl5/CPAN/Meta/Validator.pm",
                 "/usr/share/perl5/Date/Manip/Zones.pm",
                 "/usr/share/perl5/Image/ExifTool/APP12.pm",
                 "/usr/share/perl5/Image/ExifTool/DICOM.pm",
                 "/usr/share/perl5/Image/ExifTool/Exif.pm",
                 "/usr/share/perl5/Image/ExifTool/Flash.pm", # and diff value
                 "/usr/share/perl5/Image/ExifTool/FlashPix.pm",# and diff value
                 "/usr/share/perl5/Image/ExifTool/GPS.pm",
                 "/usr/share/perl5/Image/ExifTool/GeoTiff.pm",
                 "/usr/share/perl5/Image/ExifTool/HTML.pm",
                 "/usr/share/perl5/Image/ExifTool/Leaf.pm",
                 "/usr/share/perl5/Image/ExifTool/PNG.pm", # same
                 "/usr/share/perl5/Image/ExifTool/Pentax.pm",
                 "/usr/share/perl5/Image/ExifTool/QuickTime.pm",
                 "/usr/share/perl5/Lingua/EN/Inflect.pm",

                );

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ProhibitDuplicateHashKeys');
print "Policies:\n";
foreach my $p ($critic->policies) {
  print "  ",$p->get_short_name,"\n";
}

# "%f:%l:%c:" is good for emacs compilation-mode
Perl::Critic::Violation::set_format ("%f:%l:%c:\n %P\n %m\n %r\n");

foreach my $filename (@filenames) {
  print "$filename\n";
  my @violations;
  if (! eval { @violations = $critic->critique ($filename); 1 }) {
    print "Died in \"$filename\": $@\n";
    next;
  }
  print @violations;
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Caught exception in \"$filename\": $exception\n";
  }
}

exit 0;
