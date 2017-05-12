#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use PerlIO::via::EscStatus qw(print_status);
use Term::Sk;
use Time::HiRes 'usleep';

binmode (STDOUT, ':via(EscStatus)')
  or die "Cannot push EscStatus layer: $!";

# $str is a Term::Sk get_line() string, return without its backspacing
sub undo_sk_backspaces {
  my ($str) = @_;
  $str =~ s/([\b]+) +\1//;
  return $str;
}

my $target = 500;
my $sk = Term::Sk->new ('%d %3c records, %5t elapsed, [%10b] %3p',
                        {base   => 0,
                         target => $target,
                         quiet   => 1})
  or die "Term::Sk error ${Term::Sk::errcode}: $Term::Sk::errmsg";

# initial status
print_status undo_sk_backspaces($sk->get_line);


my $step = 50;

$sk->up ($step);
if (my $status = $sk->get_line) { print_status undo_sk_backspaces($status); }
sleep 1;

$sk->whisper("whisper\n");
sleep 1;

print_status '';
print "blanked\n";

$sk->whisper("whisper over blank\n");
sleep 1;

$sk->up ($step);
if (my $status = $sk->get_line) { print_status undo_sk_backspaces($status); }
sleep 1;

print "plain print\n";
sleep 1;

$sk->up ($step);
if (my $status = $sk->get_line) { print_status undo_sk_backspaces($status); }

print_status '';
exit 0;
