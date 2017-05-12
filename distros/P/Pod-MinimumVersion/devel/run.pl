#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.
#
# Pod-MinimumVersion is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use FindBin;
use File::Spec;
use Pod::MinimumVersion;
use Data::Dumper;

# uncomment this to run the ### lines
use Smart::Comments;

my $script_filename = File::Spec->catfile ($FindBin::Bin, $FindBin::Script);

{
  my $pmv = Pod::MinimumVersion->new
    (
     # string => "use 5.010; =encoding\n",
     # string => "=encoding",
     # string => "=pod\n\nC<< foo >>",
     filename => $script_filename,
     # filehandle => do { require IO::String; IO::String->new("=pod\n\nE<sol> E<verbar>") },
     #  string => "=pod\n\nL<foo|bar>",
     one_report_per_version => 1,
     above_version => '5.005',
    );

  ### $pmv
  ### min: $pmv->minimum_version
  ### $pmv

  my @reports = $pmv->reports;
  foreach my $report (@reports) {
    print $report->as_string,"\n";
    # my $loc = $report->PPI_location;
    # print Data::Dumper->new ([\$loc],['loc'])->Indent(0)->Dump,"\n";
  }
  exit 0;
}


use 5.002;

__END__

=head1 C<< NAME >>

=encoding utf-8

x

=head1 DESCRIPTION

=head1 Heading

J<< C<< x >> >>
C<< double >>
S<< double >>
L<C<Foo>|Footext>

=begin foo

text meant only for foo ...

=end foo

=cut
