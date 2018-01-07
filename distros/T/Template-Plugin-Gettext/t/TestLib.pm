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

use vars qw(@ISA @EXPORT_OK);

use Locale::XGettext::TT2;
use Locale::XGettext::Util::Keyword;

@ISA = qw(Exporter);
@EXPORT_OK  = qw(find_entries use_keywords);

sub find_entries {
    my ($po, %args) = @_;

    my @hits;
    foreach my $entry (@$po) {
        next if exists $args{msgid} && $entry->msgid ne $args{msgid};
        next if exists $args{msgstr} && $entry->msgstr ne $args{msgstr};
        next if exists $args{msgctxt} && $entry->msgctxt ne $args{msgctxt};
        next if exists $args{comment} && $entry->comment ne $args{comment};
        next if exists $args{automatic} && $entry->automatic ne $args{automatic};
        push @hits, $entry;
    }

    return @hits;
}

sub use_keywords($) {
    my ($keywords) = @_;

    foreach my $method (keys %$keywords) {
        $keywords->{$method} =
            Locale::XGettext::Util::Keyword->new($method,
                                                 @{$keywords->{$method}});
    }

    Locale::XGettext::TT2->new({keywords => $keywords}, 'dummy');
}

