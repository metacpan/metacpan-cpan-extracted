#! /usr/bin/env perl # -*- perl -*-

# Copyright (C) 2016-2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;

BEGIN {
    my $test_dir = __FILE__;
    $test_dir =~ s/[-a-z0-9]+\.t$//i;
    unshift @INC, $test_dir;
}

use TestSite;
use Test::More;

use Qgoda::CLI;
use Qgoda::Util qw(read_file);

my $vmap_array = <<EOF;
[%- USE q = Qgoda -%]
[%- haystack = [
	{ junk => -1, needle => 2, ignore => -1 },
	{ junk => -1, needle => 3, ignore => -1 },
	{ junk => -1, needle => 0, ignore => -1 },
	{ junk => -1, needle => 4, ignore => -1 }
]
-%]
[%- FOR value IN haystack.vmap('needle') -%]
[%- value -%]
[%- END -%]
EOF

my $vmap_hash = <<EOF;
[%- USE q = Qgoda -%]
[%- haystack = {
	abc => { junk => -1, needle => 2, ignore => -1 },
	def => { junk => -1, needle => 3, ignore => -1 },
	ghi => { junk => -1, needle => 0, ignore => -1 },
	jkl => { junk => -1, needle => 4, ignore => -1 }
}
-%]
[%- FOR value IN haystack.vmap('needle') -%]
[%- value -%]
[%- END -%]
EOF

my $vmap_scalar = <<EOF;
[%- USE q = Qgoda -%]
[%- haystack = 'does not work' -%]
[%- FOR value IN haystack.vmap('needle') -%]
[%- value -%]
[%- END -%]
EOF

my $site = TestSite->new(
	name => 'tgp-vmethods',
	assets => {
		'vmap-array.md' => {content => $vmap_array},
		'vmap-hash.md' => {content => $vmap_hash},
		'vmap-scalar.md' => {content => $vmap_scalar},
    },
	files => {
		'_views/default.html' => "[% asset.content %]"
	}
);

ok (Qgoda::CLI->new(['build'])->dispatch);

ok -e '_site/vmap-array/index.html';
is ((read_file '_site/vmap-array/index.html'), '<p>2304</p>', 'vmap array');

ok -e '_site/vmap-hash/index.html';
is ((read_file '_site/vmap-hash/index.html'), '<p>2304</p>', 'vmap hash');

ok -e '_site/vmap-scalar/index.html';
is ((read_file '_site/vmap-scalar/index.html'), '', 'vmap scalar');

$site->tearDown;

done_testing;
