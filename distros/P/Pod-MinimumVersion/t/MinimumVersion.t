#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.
#
# Pod-MinimumVersion is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.


use 5.004;
use strict;
use Test;
BEGIN { plan tests => 100; }

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Pod::MinimumVersion;

#------------------------------------------------------------------------------
{
  my $want_version = 50;
  ok ($Pod::MinimumVersion::VERSION, $want_version, 'VERSION variable');
  ok (Pod::MinimumVersion->VERSION,  $want_version, 'VERSION class method');
  {
    ok (eval { Pod::MinimumVersion->VERSION($want_version); 1 },
        1,
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Pod::MinimumVersion->VERSION($check_version); 1 },
        1,
        "VERSION class check $check_version");
  }
  { my $pmv = Pod::MinimumVersion->new;
    ok ($pmv->VERSION, $want_version, 'VERSION object method');
    ok (eval { $pmv->VERSION($want_version); 1 },
        1,
        "VERSION object check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { $pmv->VERSION($check_version); 1 },
        1,
        "VERSION object check $check_version");
  }
}

#------------------------------------------------------------------------------
foreach my $data (
                  # command with no final newline
                  # provokes warnings from Pod::Parser itself though ...
                  # [ 0, undef, "=head1" ],

                  # combination double-angles and =for
                  [ 2, '5.006', "=pod\n\nC<< foo >>\n\n=for something\n" ],

                  [ 0, undef, "=pod\n\nS<C<foo>C<bar>>" ],
                  # unterminated C<
                  [ 0, undef, "=pod\n\nC<" ],

                  # doubles
                  [ 1, '5.006', "=pod\n\nC<< foo >>" ],
                  [ 0, undef, "=pod\n\nC<foo>" ],
                  [ 1, '5.006', "=pod\n\nL< C<< foo >> >" ],
                  [ 1, '5.006', "=item C<< foo >>\n" ],

                  # Pod::MultiLang
                  [ 0, undef, "=pod\n\nJ<< ... >>" ],

                  # links
                  [ 0, undef, "=pod\n\nL<foo>" ],
                  [ 0, undef, "=pod\n\nL<Foo::Bar>" ],

                  # links - alt text
                  [ 1, '5.005', "=pod\n\nL<foo|bar>" ],
                  [ 0, undef, "=pod\n\nL<foo|bar>",
                    above_version => '5.005' ],
                  [ 2, '5.006', "=pod\n\nL<C<< foo >>|S<< bar >>>" ],
                  [ 3, '5.006', "=pod\n\nL<C<< foo >>|S<< bar >>>",
                    want_reports => 'all' ],

                  # links - url
                  [ 1, '5.008', "=pod\n\nL<http://www.foo.com/index.html>" ],
                  [ 1, '5.008', "=pod\n\nL<http://www.foo.com/index.html>",
                    above_version => '5.006' ],
                  [ 0, undef, "=pod\n\nL<http://www.foo.com/index.html>",
                    above_version => '5.008' ],

                  # links - url and text
                  # 5.005 for text, 5.012 for url+text
                  [ 2, '5.012',
                    "=pod\n\nL<some text|http://www.foo.com/index.html>" ],
                  [ 1, '5.012',
                    "=pod\n\nL<some text|http://www.foo.com/index.html>",
                    above_version => '5.010' ],
                  [ 0, undef,
                    "=pod\n\nL<some text|http://www.foo.com/index.html>",
                    above_version => '5.012' ],

                  [ 0, undef, "=pos\n\nE<lt>\n" ],
                  [ 0, undef, "=pos\n\nE<gt>\n" ],
                  [ 0, undef, "=pos\n\nE<quot>\n" ],
                  # E<apos>
                  [ 1, '5.008', "=pos\n\nE<apos>\n" ],
                  [ 0, undef, "=pos\n\nE<apos>\n", above_version => '5.008' ],
                  # E<sol>
                  [ 1, '5.008', "=pos\n\nE<sol>\n" ],
                  [ 0, undef, "=pos\n\nE<sol>\n", above_version => '5.008' ],
                  # E<verbar>
                  [ 1, '5.008', "=pos\n\nE<verbar>\n" ],
                  [ 0, undef, "=pos\n\nE<verbar>\n", above_version => '5.008' ],

                  # =head3
                  [ 1, '5.008', "=head3\n" ],
                  [ 0, undef, "=head3\n", above_version => '5.008' ],
                  # =head4
                  [ 1, '5.008', "=head4\n" ],
                  [ 0, undef, "=head4\n", above_version => '5.008' ],

                  # =encoding
                  [ 1, '5.010', "=encoding\n" ],
                  [ 1, '5.010', "=encoding\n", above_version => '5.008' ],
                  [ 0, undef, "=encoding\n", above_version => '5.010' ],

                  # =for
                  [ 1, '5.004', "=for foo\n" ],
                  [ 1, '5.004', "=for foo\n", above_version => '5.003' ],
                  [ 0, undef, "=for foo\n", above_version => '5.004' ],
                  # =begin
                  [ 1, '5.004', "=begin foo\n" ],
                  [ 1, '5.004', "=begin foo\n", above_version => '5.003' ],
                  [ 0, undef, "=begin foo\n", above_version => '5.004' ],
                  # =end
                  [ 1, '5.004', "=end foo\n" ],
                  [ 1, '5.004', "=end foo\n", above_version => '5.003' ],
                  [ 0, undef, "=end foo\n", above_version => '5.004' ],

                 ) {
  my ($want_count, $want_minimum_version, $str, @options) = @$data;
  # MyTestHelpers::diag "POD: $str";

  my $pmv = Pod::MinimumVersion->new (string => $str,
                                      @options);
  my @reports = $pmv->reports;

  # MyTestHelpers::diag explain $pmv;
  foreach my $report (@reports) {
    MyTestHelpers::diag ("-- ", $report->as_string);
  }
  # MyTestHelpers::diag explain \@reports;

  my $got_count = scalar @reports;
  require Data::Dumper;
  ok ($got_count, $want_count,
      Data::Dumper->new([$str],['str'])->Indent(0)->Useqq(1)->Dump
      . Data::Dumper->new([\@options],['options'])->Indent(0)->Dump);

  ok ($pmv->minimum_version, $want_minimum_version, "minimum_version()");
}

#------------------------------------------------------------------------------
# for_version parse out

foreach my $data (
                  [ undef,   "" ],
                  [ '5.005', "=for Pod::MinimumVersion use 5.005" ],
                  [ '5.005', "=for\t\tPod::MinimumVersion\t\tuse\t\t5.005" ],
                 ) {
  my ($want_version, $str, @options) = @$data;
  # MyTestHelpers::diag ("POD: ",$str);
  my $pmv = Pod::MinimumVersion->new (string => $str,
                                      @options);
  my @reports = $pmv->analyze;
  my $got_version = $pmv->{'for_version'};
  ok ($got_version, $want_version,
      '=for Pod::MinimumVersion use 5.005');
}

exit 0;
