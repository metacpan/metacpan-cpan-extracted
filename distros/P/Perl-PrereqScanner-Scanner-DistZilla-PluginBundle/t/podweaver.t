#!/usr/bin/env perl

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

use v5.6.0;
use strict;
use warnings;
use Perl::PrereqScanner;
use Test::More tests => 1;

my $scanner = Perl::PrereqScanner->new(
    scanners => [qw(PodWeaver::PluginBundle)],
);

# Test the scanner on a Pod::Weaver plugin bundle.
my $prereqs = $scanner->scan_string(<<'EOF')->as_string_hash;
package Pod::Weaver::PluginBundle::Test;

use strict;
use warnings;
use namespace::autoclean;
use Pod::Weaver::Config::Assembler;

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_) }
my sub expand { _exp @_ }

my @plugins = (
    [ PluginBundle1	=> '@Bundle1'	=> {}			],
    [ 'A::Section',	   Section1	=> { opt => 'value'}	],
    [ 'Another::Bundle'	=> '@Plugin::Bundle2', { foo => 'bar'}	],
    [ 'Literal::Plugin'	=> '=My::Literal::Plugin', {}		],
);
$_->[1] = _exp $_->[1] foreach @plugins;

push @plugins,
    [ 'Another::Section',	(_exp 'Section::2')	=> {}	],
    [ 'A::Plugin',		(expand '-My::Plugin')	=> {}	],
    [ 'Yet::Another::Bundle',	_exp('@Bundle3')	=> {}	],
    [ 'One::More::Bundle',	expand('@Bundle4')	=> {}	];

sub mvp_bundle_config { @plugins }

1;
EOF

# What we expected.
my %expected = (
    Section	=> [qw(Section1 Section::2)],
    Plugin	=> [qw(My::Plugin)],
    PluginBundle => [qw(Bundle1 Plugin::Bundle2 Bundle3 Bundle4)],
    ''		=> [qw(My::Literal::Plugin)],
);

my %expected_prereqs;
while (my ($category, $items) = each %expected) {
    my $prefix = $category eq '' ? '' : "Pod::Weaver::$category\::";
    $expected_prereqs{$prefix . $_} = 0 foreach @$items;
}

# Check that we got the right prereqs.
is_deeply($prereqs, \%expected_prereqs);
