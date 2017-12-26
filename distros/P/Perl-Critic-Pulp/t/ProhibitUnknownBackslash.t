#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 299;

use lib 't';
use MyTestHelpers;
#BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash;


#-----------------------------------------------------------------------------
my $want_version = 96;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash->VERSION($check_version); 1 }, "VERSION class check $check_version");
}



#-----------------------------------------------------------------------------
# _pos_after_interpolate_variable()

foreach my $elem (## no critic (RequireInterpolationOfMetachars)
                  ["\$#x \200\200\0", 3],
                  ['$#x blah', 3],
                  ['$#{x} blah', 5],
                  ['$x blah', 2],
                  ['${\scalar @a} blah', 13],
                  ['${x} blah', 4],
                  ['$x{y} blah', 5],
                  ['$x{\'y\'} blah', 7],
                  ['$x{$y}|', 6],
                  ['$hash{1} {y} blah', 8],
                  ['$array[1][2] {y} blah', 12],
                  ['@{[foo()]} blah', 10],
                  ['@{[foo()]} blah', 10],
                  ['@{[foo()]}{123}', 10],
                  ['$foo}; 1', 4],
                  ['$foo[1]', 7],
                  ['$_[1]', 5],
                  ['$foo.bar', 4],
                 ) {
  my ($str, $want) = @$elem;

  ## no critic (ProtectPrivateSubs)
  my $got = Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash::_pos_after_interpolate_variable($str, 0);
  is ($got, $want, "_pos_after_interpolate_variable: $str");
  if ($got != $want) {
    require PPI::Dumper;
    my $doc = PPI::Document->new(\$str);
    my $dumper = PPI::Dumper->new($doc);
    diag $dumper->string;

    diag "child2: ", $doc->child(0)->child(0)->content;
  }
}

#-----------------------------------------------------------------------------
# _string(), but not _quote_delims() for now ...

require PPI::Document;
foreach my $want_string ("abc", "a\nb") {

  foreach my $want_q ('', 'q', 'qq', 'qx') {

    foreach my $quotes ("''", '""', '{}', '##', '%%', 'ZZ') {
      next if (!$want_q && $quotes ne "''" && $quotes ne '""');
      my $want_open = substr ($quotes, 0, 1);
      my $want_close = substr ($quotes, 1, 1);

      foreach my $comment ("", " #\n", " # blah\n\t# blah \t\n  ") {
        next if ($quotes eq '##' && $comment);
        next if ($quotes eq 'ZZ' && !$comment);

        my $str = $want_q.$comment.$want_open.$want_string.$want_close;

        my $doc = PPI::Document->new(\$str);
        my $elem = $doc->schild(0)->schild(0);
        ($elem->isa('PPI::Token::Quote')
         || $elem->isa('PPI::Token::QuoteLike'))
          or die "Oops, didn't get Quote or QuoteLike: $str";

        # unused ...
        #        ## no critic (ProtectPrivateSubs)
        #         my ($got_string) = Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash::_string($elem);
        #         is ($got_string, $want_string, "string of: $str");

        # unused ...
        # my ($got_q, $got_open, $got_close) = Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash::_quote_delims($elem);
        # is ($got_q,      $want_q,      "q of: $str");
        # is ($got_open,   $want_open,   "open of: $str");
        # is ($got_close,  $want_close,  "close of: $str");
      }
    }
  }
}

#-----------------------------------------------------------------------------
# policy

require PPI;
diag "PPI version ",PPI->VERSION;

{
  require Perl::Critic;
  my $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash$');
  my @policies = $critic->policies;
  is (scalar @policies, 1, 'single policy ProhibitUnknownBackslash');

  my $policy = $policies[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");


  #---------------------
  # default

  foreach my $data
    (## no critic (RequireInterpolationOfMetachars)
     
     # with non-ASCII chars
     [ 0, '  "$x  \200\0 $y"  ' ],
     [ 1, '  "$x  \200\0 $y \z"  ' ],  # bad \z

     #-------------------
     # "$foo\::bar" etc

     # not sure this one parses right
     # [ 0, '  "$foo{\\"key\\"}\\[1]"  ' ],
     #
     [ 0, '  "$foo{\'key\'}\\[1]"  ' ],
     [ 0, '  "$foo{key}\\[1]"  ' ],
     [ 0, '  "$foo{key}\\{k2}"  ' ],
     [ 0, '  "$foo{key}{k2}\\{k3}"  ' ],
     [ 0, '  "$foo{key}{k2}\\[0]"  ' ],

     [ 0, '  "$foo\\->[0]"  ' ],
     [ 0, '  "$foo\\->{k}"  ' ],
     [ 1, '  "$foo\\->method"  ' ],
     [ 1, '  "$coderef\\->(123)"  ' ],
     [ 1, '  "$foo\\-> [0]"  ' ], # doesn't interpolate with space
     [ 0, '  "$foo->[0]"  ' ],

     [ 0, '  "$foo\\::bar"  ' ],
     [ 0, '  "$foo\\:\\:bar"  ' ],
     [ 0, '  "$foo\\:"  ' ],
     [ 0, '  "$foo\\:\\:"  ' ],
     [ 0, '  "$#foo\\:\\:bar"  ' ],
     [ 0, '  "@foo\\:\\:bar"  ' ],

     [ 0, '  "$foo[0]\\[1]"  ' ],
     [ 0, '  "$foo[0]\\{key}"  ' ],
     [ 0, '  "$foo[0][1]\\[2]"  ' ],
     [ 0, '  "$foo[0][1]\\{key}"  ' ],

     [ 1, '  "\\:"  ' ],
     [ 1, '  "\\::"  ' ],
     [ 1, '  "\\::bar"  ' ],
     [ 2, '  "\\:\\:bar"  ' ],
     [ 1, '  "foo\\::"  ' ],
     [ 1, '  "foo\\::bar"  ' ],

     [ 1, '  "\\["  ' ],
     [ 1, '  "foo\\["  ' ],
     [ 1, '  "\\{"  ' ],
     [ 1, '  "foo\\{"  ' ],

     #----------------
     # \cX including \c\

     [ 0, '  "\\cA"  ' ],
     [ 0, '  "\\cz"  ' ],
     [ 0, '  "\\cm\\cj"  ' ],
     [ 0, '  "\\c\\"  ' ],
     [ 0, '  "\\c\\v"  ' ],
     [ 0, '  "\\c\\z"  ' ],
     [ 0, '  "\\c\\\\n"  ' ],
     [ 1, '  "\\c\\\\v"  ' ],

     [ 1, '  "\\c*"  ' ],
     [ 2, '  "\\c1\\c2"  ' ],

     #----------------
     # \c at end-of-string

     [ 1, '  "\\c"  ' ],
     [ 1, '  qq X\\cX  ' ],


     #----------------
     # control-\ before interpolation

     [ 1, q{  qq$\\c\\${\\scalar 123} $  } ],
     [ 0, q{  qq@\\c\\${\\scalar 123} @  } ],


     #----------------

     [ 0, '  qq{}  ' ],
     [ 0, '  ""  ' ],
     [ 1, '  "\\z"  ' ],
     [ 1, '  qq{\\z}  ' ],
     [ 0, '  "\\\\z"  ' ],
     [ 0, '  qq{\\\\z}  ' ],
     [ 1, '  "\\\\\\z"  ' ],
     [ 1, '  qq{\\\\\\z}  ' ],
     [ 2, '  "\\\\\\z\z"  ' ],
     [ 2, '  qq{\\\\\\z\z}  ' ],

     [ 0, '  "$"    ' ],  # dodgy interpolation, but not an unknown backslash
     [ 0, '  "\\$"  ' ],

     [ 0, "qx'echo \\z'" ],
     [ 1, "qx{echo \\z}" ],

     [ 0, '"blah ${\scalar @array} blah"' ],

     [ 0, "print <<'HERE'
\\z
HERE
" ],
     [ 1, "print <<\"HERE\"
\\z
HERE
" ],
     [ 1, "print <<HERE
\\z
HERE
" ],

     # Not sure if wide chars and/or non-ascii are supposed to be allowed in
     # an input string, presumably yes, but some combination of perl 5.8.3
     # and PPI 1.206 threw an error on wide chars.  It runs ok with 5.10.1.
     #
     #      [ 1, ($] >= 5.008
     #            ? 'qq{\\'.chr(0x16A).'}' # 5.8 wide U-with-macron
     #            : '') ],                 # not 5.8, dummy passing
     #
     [ 1, "qq{\\\374}" ],  # latin-1/unicode u-dieresis

     [ 1, 'use 5.005; "\\400"' ],
     [ 0, 'use 5.006; "\\400"' ],
     [ 0, '"\\400"' ],

     [ 0, 'use 5.005; "\\000"' ],
     [ 0, 'use 5.005; "\\100"' ],
     [ 0, 'use 5.005; "\\200"' ],
     [ 0, 'use 5.005; "\\300"' ],
     [ 1, 'use 5.005; "\\400"' ],
     [ 1, 'use 5.005; "\\500"' ],
     [ 1, 'use 5.005; "\\600"' ],
     [ 1, 'use 5.005; "\\700"' ],
     [ 1, 'use 5.005; "\\800"' ],
     [ 1, 'use 5.005; "\\900"' ],
     [ 0, '"\\000"' ],
     [ 0, '"\\100"' ],
     [ 0, '"\\200"' ],
     [ 0, '"\\300"' ],
     [ 0, '"\\400"' ],
     [ 0, '"\\500"' ],
     [ 0, '"\\600"' ],
     [ 0, '"\\700"' ],
     [ 1, '"\\800"' ],
     [ 1, '"\\900"' ],

     #----------------
     # the various known escapes

     [ 0, '  "aa\\t\\n\\r\\f\\b\\a\\ebb"  ' ],
     [ 0, '  "aa\\033\177\200\377\\xFF\\cJ\\tbb"  ' ],
     [ 0, '  "aa\\Ua\\u\\LX\\l\\Q\\E"  ' ],

     #----------------
     # close of singles and doubles

     [ 0, "  'aa\\\\'bb'  " ],
     [ 0, '  q{aa\\}bb}  ' ],
     [ 0, '  q{aa\\}bb}  ' ],
     [ 0, '  qq{aa\\}bb}  ' ],
     [ 0, '  qq  {aa\\}bb}  ' ],

     [ 0, '  `aa\\nbb`  ' ],
     [ 0, '  qx{aa\\n\\}bb}  ' ],
     [ 0, q{  qx'aa\\nbb'  } ],

     #----------------
     # singles ok

     [ 0, q{  '\\xFF'  } ],
     [ 0, q{  '\\c*'  } ],
     [ 0, q{  my $pat = '[0-9eE\\.\\-]'  } ],

     [ 1, 'use 5.005;  "\\777"       ' ],
     [ 0, 'use 5.006;  "\\777"       ' ],

     #----------------
     # \N 

     [ 1, '  "\\N{COLON}"  ' ],
     [ 0, 'use charnames;          "\\N{COLON}"  ' ],
     [ 0, 'use charnames q{:full}; "\\N{COLON}"  ' ],
     [ 1, '{ use charnames; }  "\\N{COLON}"  ' ],  # not in lexical scope
     [ 0, 'use 5.016;  "\\N{COLON}"  ' ],  # autoloaded charnames in 5.16
     [ 0, '"\\N{COLON}"; use 5.016' ],     # version can appear anywhere


     #----------------
     # runs of backslashes

     [ 0, q{  "\\\\s"  } ],
     [ 1, q{  "\\\\\\s"  } ],
     [ 0, q{  "\\\\\\\\s"  } ],
     [ 1, q{  "\\\\\\\\\\s"  } ],
     [ 0, q{  "\\\\\\\\\\\\s"  } ],
     [ 1, q{  "\\\\\\\\\\\\\\s"  } ],

    ) {
    my ($want_count, $str) = @$data;

    foreach my $str ($str, $str . ';') {
      my @violations = $critic->critique (\$str);

      # foreach my $violation (@violations) {
      #   diag $violation->description;
      # }

      my $got_count = scalar @violations;
      require Data::Dumper;
      my $testname = 'default: '
        . Data::Dumper->new([$str],['str'])->Useqq(1)->Dump;
      is ($got_count, $want_count, $testname);
    }
  }

  #-------------------
  # double=quotemeta

  $policy->{_double} = 'quotemeta';

  foreach my $data
    (# no critic (RequireInterpolationOfMetachars)

     # non-ascii allowed under default 'quotemeta'
     [ 0, "qq{\\\374}" ],  # latin-1/unicode u-dieresis

     # Not sure if literal wide chars are supposed to be allowed in an input
     # string, presumably yes, but some combination of perl 5.8.6 and PPI
     # 1.212 threw an error on it.  It runs ok with 5.10.1.
     #
     #      [ 1, ($] >= 5.008
     #            ? 'qq{\\'.chr(0x16A).'}' # 5.8 wide U-with-macron
     #            : '') ],                 # not 5.8, dummy passing


    ) {
    my ($want_count, $str) = @$data;

    foreach my $str ($str, $str . ';') {
      # my $printable = Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash::_printable($str);
      # ### str printable: $printable

      my @violations = $critic->critique (\$str);

      # foreach my $violation (@violations) {
      #   diag $violation->description;
      # }

      my $got_count = scalar @violations;
      require Data::Dumper;
      my $testname = 'quotemeta: '
        . Data::Dumper->new([$str],['str'])->Useqq(1)->Dump;
      is ($got_count, $want_count, $testname);
    }
  }

  #-----------------------
  # single=all

  # FIXME: what's the progammatic way to set parameters?
  $policy->{_single} = 'all';

  foreach my $data
    (## no critic (RequireInterpolationOfMetachars)
     [ 0, 'q{}' ],
     [ 0, 'q{\\\\}' ],
     [ 1, 'q{\\z}' ],
     [ 0, 'q{\\\\z}' ],
     [ 1, 'q{\\\\\\z}' ],

     [ 0, '\'\\\'\'' ],
     [ 1, 'q{\\\'}' ],
     [ 0, 'q{\\}}' ],
     [ 1, 'q{\\{}' ],

     [ 1, "qx'echo \\z'" ],
     [ 1, q{  qx'aa\\nbb'  } ],

     [ 1, q{  '\\xFF'  } ],
     [ 2, q{  my $pat = '[0-9eE\\.\\-]'  } ],

     [ 1, "q{\\\374}" ],  # latin-1/unicode u-dieresis

     # Not sure if wide chars and/or non-ascii are supposed to be allowed in
     # an input string, presumably yes, but some combination of perl 5.8.3
     # and PPI 1.206 threw an error on wide chars.  It runs ok with 5.10.1.
     #
     #      [ 1, ($] >= 5.008
     #            ? 'q{\\'.chr(0x16A).'}' # 5.8 unicode U-with-macron
     #            : 'q{\\z}') ],          # not 5.8, dummy failing
     #      [ 1, ($] >= 5.008
     #            ? 'q{\\'.chr(0x2022).'}' # 5.8 unicode BULLET
     #            : 'q{\\z}') ],           # not 5.8, dummy failing

     # backslash then some whitespaces
     [ 1, "  '\\\n'  " ],
     [ 1, "  '\\\t'  " ],
     [ 1, "  '\\\f'  " ],
     [ 1, "  '\\ '  " ],

     # two violations, not a control-\
     [ 2, "  '\\c\\z '  " ],

    ) {
    my ($want_count, $str) = @$data;

    foreach my $str ($str, $str . ';') {
      my @violations = $critic->critique (\$str);

      # foreach my $violation (@violations) {
      #   diag $violation->description;
      # }

      my $got_count = scalar @violations;
      require Data::Dumper;
      my $testname = 'single: '
        . Data::Dumper->new([$str],['str'])->Useqq(1)->Dump;
      is ($got_count, $want_count, $testname);
    }
  }
}



#-----------------------------------------------------------------------------
# _quote_open()

# require PPI::Document;
# foreach my $data ([ "'", "'x'" ],
#                   [ '"', '"x"' ],
#                   [ '`', '`echo hi`' ],
#
#                   [ 'q{', 'q{x}' ],
#                   [ 'qq{', 'qq{x}' ],
#                   [ 'qx{', 'qx{x}' ],
#
#                   [ 'q#', 'q#x#' ],
#                   [ 'q{', "q #foo#\n{bar}" ],
#                   [ 'q{', "q #foo\n#foo\n{bar}" ],
#                   [ 'q{', "q #foo\n #foo\n{bar}" ],
#                   [ 'q{', "q #foo\n #foo\n \t{bar}" ],
#
#                  ) {
#   my ($want, $str) = @$data;
#
#   my $document = PPI::Document->new (\$str)
#     or die $@->message;
#   my $elem = $document->schild(0)->schild(0);
#
#   diag "elem: $elem";
#   my $got = Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash::_quote_open($elem);
#   is ($got, $want, "_quote_open: $str");
# }


exit 0;
