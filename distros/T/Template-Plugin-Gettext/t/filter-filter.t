#! /usr/bin/env perl

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

use strict;

use Test::More tests => 18;

use Template;

my $tt = Template->new or die Template->error;

my ($template, $output);

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[% FILTER gettext -%]
Hello, world!
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'Hello, world!';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[% FILTER ngettext('many files', 1) -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'one file';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[% FILTER ngettext('many files', 42) -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'many files';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER pgettext('Hello, world!') -%]
Context
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'Hello, world!';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER gettextp('Context') -%]
Hello, world!
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'Hello, world!';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER npgettext('one file', 'many files', 1) -%]
Context
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'one file';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER npgettext('one file', 'many files', 42) -%]
Context
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'many files';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[% FILTER ngettextp('many files', 1, 'Context') -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'one file';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER ngettextp('many files', 42, 'Context') -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'many files';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[% FILTER xgettext(who => 'world') -%]
Hello, {who}!
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'Hello, world!';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER nxgettext('{count} files', 1, count => 1) -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'one file';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER nxgettext('{count} files', 42, count => 42) -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, '42 files';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER pxgettext('Hello, {who}!', who => 'world') -%]
Context
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'Hello, world!';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER xgettextp('Context', who => 'world') -%]
Hello, {who}!
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'Hello, world!';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER npxgettext('one file', '{count} files', 1, count => 1) -%]
Context
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'one file';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER npxgettext('one file', '{count} files', 42, count => 42) -%]
Context
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, '42 files';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER nxgettextp('{count} files', 1, 'Context', count => 1) -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, 'one file';

$output = '';
$template = <<'EOF';
[%- USE Gettext -%]
[%- FILTER nxgettextp('{count} files', 42, 'Context', count => 42) -%]
one file
[%- END -%]
EOF
$tt->process(\$template, {}, \$output) or die $tt->error;
is $output, '42 files';
