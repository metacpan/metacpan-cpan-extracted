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

use v5.10.0;
use strict;
use warnings;
use Perl::PrereqScanner;
use Test::More tests => 1;

my $scanner = Perl::PrereqScanner->new(
    scanners => [qw(DistZilla::PluginBundle)],
);

# Test the scanner on a Dist::Zilla plugin bundle.
my $prereqs = $scanner->scan_string(<<'EOF')->as_string_hash;
package Dist::Zilla::PluginBundle::Test;

use strict;
use warnings;
use namespace::autoclean;
use Moose;
use Dist::Zilla;

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
    my ($self) = @_;

    $self->add_bundle(
	'@Filter' => {
	    -bundle	=> '@Filtered1',
	    -version	=> 1.234,
	    -remove	=> [qw(UnWanted Plugins)],
	},
    );
    $self->add_bundle(
	'@Filter' => {
	    -bundle	=> '@Filtered2',
	    -remove	=> [qw(More Bad Plugins)],
	},
    );
    $self->add_bundle('@TestBundle');
    $self->add_plugins(
	qw(Some Cool::Plugins),
	[PluginWithOptions => {
	    option1	=> 'foo',
	    option2	=> 'bar',
	}],
	qw<More Cool Plugins>,
	['Quoted::WithOptions' => {
	    do		=> 'this',
	    do_not_do	=> 'that',
	}],
	'Finally', qw/One More::Plugin/,
    );
}

__PACKAGE__->meta->make_immutable;

1;
EOF

# What we expected.
my %expected = (
    Plugin => [qw(
	Some Cool::Plugins PluginWithOptions More Cool Plugins
	Quoted::WithOptions Finally One More::Plugin
    )],
    PluginBundle => [
	qw(Filter TestBundle), [Filtered1 => 1.234], 'Filtered2'
    ],
);

my %expected_prereqs;
while (my ($category, $items) = each %expected) {
    foreach my $spec (@$items) {
	my ($item, $version) = ref $spec eq 'ARRAY' ? @$spec : $spec;
	$expected_prereqs{"Dist::Zilla::$category\::$item"} =
	    $version // 0;
    }
}

# Check that we got the right prereqs.
is_deeply($prereqs, \%expected_prereqs);
