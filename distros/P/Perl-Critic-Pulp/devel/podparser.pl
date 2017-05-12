#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


use 5.005;
use strict;
use warnings;
use FindBin;

# uncomment this to run the ### lines
use Smart::Comments;

my $parser = MyParser->new;
$parser->parse_from_file ("$FindBin::Bin/$FindBin::Script");
exit 0;

package MyParser;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command() ...
  ### $text
  return '';
}
sub verbatim {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### verbatim() ...
  ### $text
  return '';
}
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock() ...
  ### $text
  return '';
}

exit 0;

__END__

=pod

=begin comment

This is a comment.

=end comment

This is pod text

=cut
