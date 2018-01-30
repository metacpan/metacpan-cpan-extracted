#! /usr/bin/env perl

# Copyright (C) 2016-2018 Guido Flohr <guido.flohr@cantanea.com>,
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

use Test::More tests => 4;

use Locale::XGettext::TT2;

BEGIN {
    my $test_dir = __FILE__;
    $test_dir =~ s/[-a-z0-9]+\.t$//i;
    chdir $test_dir or die "cannot chdir to $test_dir: $!";
    unshift @INC, '.';
}

use TestLib qw(find_entries);

my @po = Locale::XGettext::TT2->new({},
                                    'templates/nested.tt')
                              ->run->po;
is((scalar find_entries \@po, msgid => qq{"%Y/%m/%d"}), 1);

@po = Locale::XGettext::TT2->new({},
                                 'templates/bugs-1.tt')
                           ->run->po;

# https://github.com/gflohr/Template-Plugin-Gettext/issues/3
is((scalar find_entries \@po, msgid => qq{"no parentheses around filter"}), 1,
   'filter without parens');
is((scalar find_entries \@po,
           msgid => qq{"no parentheses around filter and filter following"}), 1,
   'filter without parens and filter following');
is((scalar find_entries \@po,
           msgid => qq{"no parentheses around filter and dot following"}), 1,
   'filter without parens and dot following');
