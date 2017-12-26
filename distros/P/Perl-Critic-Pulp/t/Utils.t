#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


use 5.006;
use strict;
use warnings;
use Test::More tests => 97;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Pulp::Utils;

#-----------------------------------------------------------------------------
my $want_version = 96;
is ($Perl::Critic::Pulp::Utils::VERSION,$want_version, 'VERSION variable');
is (Perl::Critic::Pulp::Utils->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Pulp::Utils->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Pulp::Utils->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# _str_line_n()

foreach my $data ([ "one",   1, "one" ],
                  [ "one\n", 1, "one" ],
                  [ "one\ntwo\n", 1, "one" ],
                  [ "one\ntwo\n", 2, "two" ],
                  [ "one\ntwo\n\nfour\n", 3, "" ],
                  [ "one\ntwo\n\nfour\n", 4, "four" ],
                 ) {
  my ($str, $n, $want) = @$data;

  ## no critic (ProtectPrivateSubs)
  my $got = Perl::Critic::Pulp::Utils::_str_line_n
    ($str, $n);
  is ($got, $want, "n=$n str=$str");
}

#-----------------------------------------------------------------------------
# version_if_valid()

foreach my $elem ([ 1, '1' ],
                  [ 1, '1.5' ],
                 ) {
  my ($want, $str) = @$elem;
  my $version = Perl::Critic::Pulp::Utils::version_if_valid($str);
  my $got = (defined $version ? 1 : 0);
  is ($want, $got, "version_if_valid '$str'");
}

{
  # version.pm 0.77 relaxed what it accepts or rejects, so can't say whether
  # "somebogosity" will pass or fail, but at least run version_if_valid(0 to
  # see it doesn't error out
  my $str = 'somebogosity';
  Perl::Critic::Pulp::Utils::version_if_valid($str);
  ok(1, "version_if_valid '$str'");
}

#-----------------------------------------------------------------------------
# include_module_version()

foreach my $data ([ 'use foo 10 -3', 10 ],
                  [ 'use foo 10-3', undef ],
                  [ 'use foo', undef ],

                  [ 'use foo 1', 1 ],
                  [ 'use foo 1;', 1 ],
                  [ 'no foo 1', 1 ],
                  [ 'no foo 1;', 1 ],

                  [ 'use foo 1.5', 1.5 ],
                  [ 'use foo 1.5;', 1.5 ],
                  [ 'no foo 1.5', 1.5 ],
                  [ 'no foo 1.5;', 1.5 ],

                  [ 'use foo 1_000;', '1_000' ],
                  [ 'use foo 1.000_999;', '1.000_999' ],

                  [ 'use foo 1,2', undef ],
                  [ 'use foo 1, ;', undef ],
                  [ "use foo '1';", undef ],
                  [ 'use foo "1";', undef ],
                  [ 'use foo q{1};', undef ],
                  [ 'use foo 0x1;', undef ],
                  [ 'use foo 1e0;', undef ],

                  # trailing comma is ok at end of file, and it's not a
                  # version number
                  [ 'use foo 1,', undef ],

                  # these are syntax errors, because 5 is taken to be the
                  # version number and , or => is then the start of the
                  # args
                  [ 'use foo 5 , 6', 5 ],
                  [ 'use foo 5 => 6', 5 ],

                  # this is a syntax error, but the func still interprets it
                  # the same as "use" or "no"
                  [ 'require foo 5', 5 ],

                 ) {
  my ($str, $want) = @$data;

  foreach my $suffix ('', ';') {
    $str .= $suffix;

    require PPI::Document;
    my $document = PPI::Document->new (\$str)
      or die "oops, no parse: $str";
    my $incs = ($document->find ('PPI::Statement::Include')
                || $document->find ('PPI::Statement::Sub')
                || die "oops, no target statement in '$str'");
    my $inc = $incs->[0] or die "oops, no Include element";
    my $ver = Perl::Critic::Pulp::Utils::include_module_version ($inc);
    is (defined $ver ? $ver->content : undef,
        $want,
        "str: $str");
  }
}

#-----------------------------------------------------------------------------
# include_module_first_arg()

foreach my $data ([ 'use foo',   undef ],
                  [ 'use foo;',  undef ],
                  [ 'use foo 1', undef ],

                  [ 'use foo 0x123',       '0x123' ],
                  [ 'use foo 123,456',     '123' ],
                  [ 'use foo 123,',        '123' ],
                  [ 'use foo 123,{x=>1}',  '123' ],
                  [ 'use foo 1.03 {x=>1}', '{x=>1}' ],
                  [ 'use foo {x=>1}',      '{x=>1}' ],

                 ) {
  foreach my $suffix ('', ';', " \t", "\t\t;") {

    my ($str, $want) = @$data;
    $str .= $suffix;

    require PPI::Document;
    my $document = PPI::Document->new (\$str)
      or die "oops, no parse: $str";
    my $incs = ($document->find ('PPI::Statement::Include')
                || $document->find ('PPI::Statement::Sub')
                || die "oops, no target statement in '$str'");
    my $inc = $incs->[0] or die "oops, no Include element";
    my $elem = Perl::Critic::Pulp::Utils::include_module_first_arg ($inc);
    #### elem class: ref($elem)
    is ($elem ? "$elem" : undef, $want, "str: $str");
  }
}

exit 0;
