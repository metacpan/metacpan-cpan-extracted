#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde

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
use Test::More tests => 39;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use lib 'devel/lib';
require Perl::Critic::Policy::Modules::UseExporter;


#-----------------------------------------------------------------------------
my $want_version = 94;
is ($Perl::Critic::Policy::Modules::UseExporter::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Modules::UseExporter->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Modules::UseExporter->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Modules::UseExporter->VERSION($check_version); 1 }, "VERSION class check $check_version");
}



#-----------------------------------------------------------------------------
# _document_has_use_Exporter()

require PPI::Document;
foreach my $data
  (
   [ 1, "use base qw(Exporter), qw(Blah)" ],
   [ 1, "use base qw(Exporter)" ],
   [ 1, "use base qw(Blah), qw(Exporter)" ],
   [ 1, "use base qw(Exporter Blah)" ],
   [ 1, "use base qw(Blah Blah Exporter)" ],
   [ 1, "use base 'Exporter'" ],
   [ 1, "use parent 'Exporter'" ],
   # [ 0, "use parent '-norequire', 'Exporter'" ],  # maybe
   [ 1, "use base \"Exporter\"" ],
   [ 0, "use base" ],
   [ 0, "use base 'exporter'" ],
   [ 0, "use base qw(Export)" ],

   [ 1, "require Exporter" ],
   [ 1, "use Exporter" ],
   [ 0, "require Export" ],

  ) {
  my ($want, $base_str) = @$data;

  foreach my $str ($base_str,
                   $base_str . ';') {
    my $document = PPI::Document->new(\$str);

    ## no critic (ProtectPrivateSubs)
    my $got = Perl::Critic::Policy::Modules::UseExporter::_document_has_use_Exporter($document)
      ? 1 : 0;
    is ($got, $want, "str: $str");
  }
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Modules::UseExporter$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy UseExporter');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data
  ([ 0, "use Exporter; \@EXPORT = ('foo')" ],
   [ 0, "use Exporter; \@EXPORT_OK = ('foo')" ],
   [ 0, "use Exporter; \@EXPORT_TAGS = (':foo' => [])" ],

  ) {
  my ($want_count, $str) = @$data;

  foreach my $str ($str, $str . ';') {
    my @violations = $critic->critique (\$str);

    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: $str");

    if ($got_count != $want_count) {
      foreach (@violations) {
        diag ($_->description);
      }
    }
  }
}

exit 0;
