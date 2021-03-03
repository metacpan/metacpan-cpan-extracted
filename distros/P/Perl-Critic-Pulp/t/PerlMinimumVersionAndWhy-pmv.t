#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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


# Tests with Perl::MinimumVersion available.


use 5.006;
use strict;
use warnings;
use Test::More;
use Perl::Critic;

my $critic;
eval {
  $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => '^Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy$');
  1;
}
  or plan skip_all => "cannot create Critic object -- $@";

my @policies = $critic->policies;
if (@policies == 0) {
  plan skip_all => "due to policy not initializing";
}

plan tests => 180;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

is (scalar @policies, 1, 'single policy PerlMinimumVersionAndWhy');
my $policy = $policies[0];
diag "Perl::MinimumVersion ", Perl::MinimumVersion->VERSION;

{
  my $want_version = 99;
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

my $have_pulp_bareword_double_colon
  = exists $Perl::MinimumVersion::CHECKS{_Pulp__bareword_double_colon};
diag "pulp bareword double colon: ",($have_pulp_bareword_double_colon||0);

my $have_pulp_5010_magic_fix
  = exists $Perl::MinimumVersion::CHECKS{_Pulp__5010_magic__fix};
diag "pulp magic fix: ",($have_pulp_5010_magic_fix||0);

foreach my $data (
                  ## no critic (RequireInterpolationOfMetachars)

                  # Modern::Perl equivalent to 5.010
                  [ 0, 'use Modern::Perl;        exists &foo' ],
                  [ 0, 'use Modern::Perl "2014"; exists &foo' ],

                  # _Pulp__5010_stacked_filetest
                  [ 0, 'use 5.008; if (-e "/tmp/foo.txt") { }' ],
                  [ 1, 'use 5.008; if (-e -x "/tmp/foo.txt") { }' ],
                  [ 1, 'use 5.008; if (-e -x -f "/tmp/foo.txt") { }' ],
                  [ 0, 'use 5.010; if (-e -x "/tmp/foo.txt") { }' ],
                  [ 0, 'use 5.010; if (-e -x -f "/tmp/foo.txt") { }' ],

                  # _Pulp__eval_line_directive_first_thing
                  [ 1, 'use 5.006; eval "#line 123"' ],
                  [ 0, 'use 5.008; eval "#line 123"' ],
                  #
                  [ 1, 'use 5.006; eval "# line 123"' ],
                  [ 1, "use 5.006; eval '#\tline 123'" ],
                  [ 1, "use 5.006; eval q{#line 123}" ],
                  [ 0, "use 5.006; eval q{\n#line 123}" ],
                  [ 1, 'use 5.006; eval <<HERE
#line 123
HERE
' ],
                  [ 1, 'use 5.006; eval <<"HERE"
#line 123
HERE
' ],


                  # _Pulp__keys_of_array
                  [ 1, 'use 5.010; keys @foo' ],
                  [ 0, 'use 5.012; keys @foo' ],
                  [ 1, 'use 5.010; keys @$foo' ],
                  [ 0, 'use 5.012; keys @$foo' ],
                  [ 1, 'use 5.010; keys @{$foo}' ],
                  [ 0, 'use 5.012; keys @{$foo}' ],
                  [ 1, 'use 5.010; keys(((@{$foo})))' ],
                  [ 0, 'use 5.012; keys(((@{$foo})))' ],
                  # _Pulp__values_of_array
                  [ 1, 'use 5.010; values @foo' ],
                  [ 0, 'use 5.012; values @foo' ],
                  # _Pulp__each_of_array
                  [ 1, 'use 5.010; each @foo' ],
                  [ 0, 'use 5.012; each @foo' ],

                  # _Pulp__var_method_without_parens
                  [ 1, 'use 5.005; $obj->$method' ],
                  [ 0, 'use 5.006; $obj->$method' ],
                  [ 1, 'use 5.005; Foo->$method == 123' ],
                  [ 0, 'use 5.006; Foo->$method == 123' ],
                  # parens always ok
                  [ 0, 'use 5.005; Foo->$method()' ],
                  [ 0, 'use 5.005; $obj->$method()' ],
                  [ 0, 'use 5.005; $obj->$method(123)' ],

                  # _Pulp__UNIVERSAL_methods_5004
                  [ 1, 'require 5; Foo->VERSION' ],
                  [ 0, 'use 5.004; Foo->VERSION' ],
                  [ 1, 'require 5; Foo->isa("Bar")' ],
                  [ 0, 'use 5.004; Foo->isa("Bar")' ],
                  [ 1, 'require 5; Foo->can("new")' ],
                  [ 0, 'use 5.004; Foo->can("new")' ],

                  # _Pulp__UNIVERSAL_methods_5004
                  [ 1, 'require 5; Foo->DOES' ],
                  [ 1, 'use 5.008; Foo->DOES' ],
                  [ 0, 'use 5.010; Foo->DOES' ],

                  # _Pulp__delete_array_elem
                  [ 1, 'use 5.005; delete $x[0]' ],
                  [ 0, 'use 5.006; delete $x[0]' ],
                  [ 1, 'use 5.005; delete($x[1])' ],
                  [ 0, 'use 5.005; delete $x[0]',
                    { _skip_checks => '_Pulp__delete_array_elem'} ],
                  #
                  [ 1, 'delete $x[0][1]' ],
                  [ 1, 'delete($x[0][1])' ],
                  [ 1, 'delete((((($x[0][1])))))' ],
                  [ 1, 'delete(($x[0][1]))' ],
                  [ 0, 'delete $x[0]{key}' ],
                  [ 0, 'delete($x[0]{key})' ],
                  [ 0, 'delete $x[0]->{key}' ],
                  [ 1, 'delete $x[0]->{key}->[123]' ],
                  [ 1, 'delete $x[0]->{key}[123]' ],
                  [ 1, 'delete $x[0]{key}->[123]' ],
                  [ 1, 'delete $x[0]{key}[123]' ],
                  [ 1, 'delete($x[0]{key}[123])' ],

                  # _Pulp__my_list_with_undef
                  [ 1, 'my (undef, $y)' ],
                  [ 1, 'my (undef, $y) = @_' ],
                  [ 0, 'my ($x)' ],
                  [ 0, 'my ($x, $y)' ],
                  [ 1, 'my ($x, ($y, undef), $z) = @_' ],
                  [ 1, 'my ($x, ($y, (undef, $w)), $z) = @_' ],
                  [ 1, 'my ((((((undef))))))' ],
                  [ 1, 'my (undef' ],
                  [ 1, 'my ((((((undef' ],
                  [ 0, 'use 5.005; my (undef, $y)' ],

                  # _Pulp__fat_comma_across_newline
                  [ 0, "return (foo =>\n123)" ],
                  [ 1, "return (foo\n=>\n123)" ],
                  [ 1, "return (foo\t\n\t=>\n123)" ],
                  [ 1, "return (foo # foo\n=>\n123)" ],
                  [ 1, "return (foo # foo\n\n=>\n123)" ],
                  [ 1, "return (foo # 'comment'\n \n # 'comment'\n=>\n123)" ],
                  # method calls
                  [ 0, "return (Foo->bar => 123" ],
                  [ 0, "return (Foo->bar \n => 123" ],
                  [ 0, "return (Foo -> bar \n => 123" ],

                  # _Pulp__arrow_coderef_call
                  [ 1, '$coderef->()' ],
                  [ 1, '$coderef->(1,2,3)' ],
                  [ 1, '$hashref->{code}->()' ],
                  [ 1, '$hashref->{code}->(1,2,3)' ],
                  [ 0, 'use 5.004; $coderef->()' ],

                  # _Pulp__for_loop_variable_using_my
                  [ 1, 'foreach my $i (1,2,3) { }' ],
                  [ 0, 'use 5.004; foreach my $i (1,2,3) { }' ],
                  [ 0, 'foreach $i (1,2,3) { }' ],
                  [ 0, 'foreach (1,2,3) { }' ],
                  [ 1, 'for my $i (1,2,3) { }' ],
                  [ 0, 'use 5.004; for my $i (1,2,3) { }' ],
                  [ 0, 'for $i (1,2,3) { }' ],
                  [ 0, 'for (1,2,3) { }' ],

                  # _Pulp__use_version_number
                  [ 1, 'use 5' ],
                  [ 1, 'use 5.003' ],
                  [ 0, 'use 5.004' ],
                  #
                  # these are ok if Foo is using Exporter.pm ...
                  # [ 1, 'require 5.003; use Foo 1.0' ],
                  # [ 0, 'require 5.004; use Foo 1.0' ],
                  # [ 0, 'use Foo 1.0, 2.0' ],  # args not ver num

                  # _Pulp__special_literal__PACKAGE__
                  [ 1, 'require 5.003; my $str = __PACKAGE__;' ],
                  [ 0, 'use 5.004; my $str = __PACKAGE__;' ],
                  [ 0, 'require 5.003; my %hash = (__PACKAGE__ => 1);' ],
                  [ 1, 'require 5.003; my %hash = (__PACKAGE__,   1);' ],
                  [ 0, 'require 5.003; my $elem = $hash{__PACKAGE__};' ],

                  # _Pulp__exists_array_elem
                  [ 1, 'use 5.005; exists $x[0]' ],
                  [ 0, 'use 5.006; exists $x[0]' ],
                  [ 0, 'use 5.005; exists($x[1])',
                    { _skip_checks => '_Pulp__delete_array_elem _Pulp__exists_array_elem'} ],

                  # _Pulp__exists_sub
                  [ 1, 'use 5.005; exists &foo' ],
                  [ 0, 'use 5.006; exists &foo' ],
                  [ 1, 'use 5.005; exists(&foo)' ],

                  # _Pulp__0b_number
                  [ 1, 'use 5.005; 0b01101101' ],
                  [ 0, 'use 5.006; 0b01101101' ],

                  # _Pulp__syswrite_length_optional
                  [ 1, 'use 5.005; syswrite($fh,$str)' ],
                  [ 0, 'use 5.006; syswrite($fh,$str)' ],
                  [ 0, 'use 5.005; syswrite($fh,$str,$length)' ],
                  [ 0, 'use 5.006; syswrite($fh,$str,$length)' ],
                  [ 0, 'use 5.005; syswrite($fh,$str,$length,$offset)' ],
                  [ 0, 'use 5.006; syswrite($fh,$str,$length,$offset)' ],
                  [ 0, 'use 5.005; syswrite()' ],  # bogus, but unreported
                  [ 0, 'use 5.006; syswrite()' ],
                  [ 0, 'use 5.005; syswrite($fh)' ], # bogus, but unreported
                  [ 0, 'use 5.006; syswrite($fh)' ],

                  # _Pulp__open_my_filehandle
                  [ 1, 'use 5.005; open my $fh, "foo.txt"' ],
                  [ 0, 'use 5.006; open my $fh, "foo.txt"' ],
                  [ 0, 'use 5.006; open FH, "foo.txt"' ],

                  [ 1, 'use 5.005; open(my $fh, "foo.txt")' ],
                  [ 0, 'use 5.006; open(my $fh, "foo.txt")' ],
                  [ 0, 'use 5.006; open(FH, "foo.txt")' ],

                  [ 1, 'use 5.005; pipe my $read, my $write' ],
                  [ 1, 'use 5.005; pipe IN, my $write' ],
                  [ 1, 'use 5.005; pipe my $read, OUT' ],
                  [ 0, 'use 5.006; pipe my $read, my $write' ],
                  [ 0, 'use 5.006; pipe IN, my $write' ],
                  [ 0, 'use 5.006; pipe my $read, OUT' ],
                  [ 0, 'use 5.005; pipe IN, OUT' ],

                  [ 1, 'socketpair my $one, my $two' ],
                  [ 1, 'socketpair ONE, my $two' ],
                  [ 1, 'socketpair my $one, TWO' ],
                  [ 0, 'socketpair ONE, TWO' ],
                  [ 1, 'socketpair func(), my $two' ],

                  [ 0, 'open my $fh = gensym(), "foo.txt"' ],
                  [ 0, 'open(my $fh = gensym(), "foo.txt")' ],
                  [ 1, 'pipe my $one, my $two = gensym()' ],
                  [ 1, 'pipe my $one = gensym(), my $two' ],
                  [ 0, 'pipe my $one = gensym(), my $two = gensym()' ],


                  # _Pulp__bareword_double_colon
                  [ ($have_pulp_bareword_double_colon ? 1 : 0),
                    'use 5.004; foo(Foo::Bar::)' ],
                  [ 0, 'use 5.005; foo(Foo::Bar::)' ],

                  #
                  # pack(), unpack()
                  #

                  # _Pulp__5004_pack_format
                  [ 1, 'require 5.002; pack "w", 123' ],
                  [ 0, 'use 5.004; pack "w", 123' ],
                  [ 0, 'require 5.002; pack "$w", 123' ],
                  [ 1, "require 5.002; pack 'i'.<<HERE, 123
w
HERE
" ],
                  [ 1, "require 5.002; pack w => 123" ],
                  [ 1, 'require 5.002; unpack "i".w => $bytes' ],
                  [ 0, "require 5.002; pack MYFORMAT(), 123" ],
                  [ 0, "require 5.002; pack MYFORMAT, 123" ],

                  # _Pulp__5006_pack_format
                  [ 1, 'use 5.005; pack ("Z", "hello")' ],
                  [ 0, 'use 5.006; pack ("Z", "hello")' ],
                  [ 1, 'use 5.005; pack ("Z#comment", "hello")' ],
                  [ 0, 'use 5.006; pack ("Z#comment", "hello")' ],

                  # _Pulp__5008_pack_format
                  [ 1, 'use 5.006; pack ("F", 1.5)' ],
                  [ 0, 'use 5.008; pack ("F", 1.5)' ],
                  [ 1, 'use 5.006; pack ("L[20]", 1.5)' ],
                  [ 0, 'use 5.008; pack ("L[20]", 1.5)' ],

                  # _Pulp__5010_pack_format
                  [ 1, 'use 5.008; unpack ("i<", $bytes)' ],
                  [ 0, 'use 5.010; unpack ("i<", $bytes)' ],
                  [ 1, 'unpack ("i<", $bytes)',
                    { _above_version => version->new('5.8.0') } ],
                  [ 0, 'unpack ("i<", $bytes)',
                    { _above_version => version->new('5.10.0') } ],


                  # _Pulp__5010_qr_m_working_properly
                  #
                  [ 1, 'use 5.008; qr/^x$/m' ],
                  [ 0, 'use 5.010; qr/^x$/m' ],
                  [ 1, 'use 5.006; my $re = qr/pattern/m;' ],
                  [ 0, 'use 5.010; my $re = qr/pattern/m;' ],
                  #
                  # plain patterns ok, only qr// bad
                  [ 0, '$str =~ /^foo$/m' ],
                  [ 0, '$str =~ m{^foo$}m' ],
                  #
                  # with other modifiers
                  [ 1, 'use 5.008; qr/^x$/im' ],
                  [ 1, 'use 5.008; qr/^x$/ms' ],
                  #
                  # other modifiers
                  [ 0, 'use 5.006; my $re = qr/pattern/s;' ],
                  [ 0, 'use 5.006; my $re = qr/pattern/i;' ],
                  [ 0, 'use 5.006; my $re = qr/pattern/x;' ],
                  [ 0, 'use 5.006; my $re = qr/pattern/o;' ],


                  # _Pulp__5010_magic__fix
                  # _Pulp__5010_operators__fix
                  #
                  [ ($have_pulp_5010_magic_fix ? 1 : 0), "1 // 2" ],
                  [ ($have_pulp_5010_magic_fix ? 1 : 0), "use 5.008; 1 // 2" ],
                  [ 0, "use 5.010; 1 // 2" ],

                 ) {
  my ($want_count, $str, $options) = @$data;
  $policy->{'_skip_checks'} = '';      # default
  $policy->{'_above_version'} = undef; # default

  my $name = "str: '$str'";
  foreach my $key (keys %$options) {
    $name .= " $key=$options->{$key}";
    $policy->{$key} = $options->{$key};
  }

  my @violations = $critic->critique (\$str);

  # only the Pulp ones, not any Perl::MinimumVersion itself might gain
  @violations = grep {$_->description =~ /^_Pulp_/} @violations;

  my $got_count = scalar @violations;
  is ($got_count, $want_count, $name);

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
