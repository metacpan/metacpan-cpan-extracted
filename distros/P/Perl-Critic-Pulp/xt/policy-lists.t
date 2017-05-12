#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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


# Check that the supported fields described in each pod matches what the
# code says.

use 5.005;
use strict;
use FindBin;
use ExtUtils::Manifest;
use List::Util 'max';
use File::Spec;
use Test::More;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 1;

my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my @lib_policies
  = map {m{^lib/Perl/Critic/Policy/(.+)\.pm$} ? $1 : ()} keys %$manifest;
foreach (@lib_policies) { s{/}{::} }
@lib_policies = sort @lib_policies;
### @lib_policies
diag "module policies count ",scalar(@lib_policies);

#------------------------------------------------------------------------------

{
  open FH, 'lib/Perl/Critic/Pulp.pm' or die $!;
  my $content = do { local $/; <FH> }; # slurp
  close FH or die;
  # ### $content

  {
    $content =~ /=for my_pod policy_list begin(.*)=for my_pod policy_list end/s
      or die "pulp_list not matched, content:\n",$content;
    my $pulp_list = $1;

    my @pulp_list;
    while ($pulp_list =~ /^=item L<([^|]+)/mg) {
      push @pulp_list, $1;
    }
    @pulp_list = sort @pulp_list;
    ### @pulp_list
    diag "pulp list count ",scalar(@pulp_list);

    my $s = join(', ',@pulp_list);
    my $l = join(', ',@lib_policies);
    is ($s, $l, 'Pulp.pm policy list');

    my $j = "$s\n$l";
    $j =~ /^(.*)(.*)\n\1(.*)/ or die;
    my $sd = $2;
    my $ld = $3;
    if ($sd) {
      diag "pulp list: ",$sd;
      diag "modules:   ",$ld;
    }
  }
}

#------------------------------------------------------------------------------

exit 0;
