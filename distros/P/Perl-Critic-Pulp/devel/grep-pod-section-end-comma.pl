#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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


# Usage: perl grep-pod-section-end-comma.pl
#
# Search for POD paragraphs ending with a comma.


use strict;
use warnings;
use FindBin;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
# use Smart::Comments;


my $verbose = 0;

my $l = MyLocatePerl->new (include_pod => 1,
                           under_directory => '/usr/share/perl5');
my $filename;
# {
#   $filename = "$FindBin::Bin/$FindBin::Script";
#   if ($verbose) { print "look at $filename\n"; }
#   my $str = Perl6::Slurp::slurp ($filename);
#   my $p = MyParser->new;
#   $p->parse_from_string ($str);
# }
my $count = 0;
while (($filename, my $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }
  my $p = MyParser->new;
  $p->parse_from_string ($str);
  $p->check_last();
  $count++;
}
print "total $count\n";

exit 0;

package MyParser;
use base 'Perl::Critic::Pulp::PodParser';
sub new {
  my $class = shift;
  ### new() ...
  return $class->SUPER::new (last_text => '',
                             last_command => '',
                             @_);
}
sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command(): $command

  if ($command eq 'for' || $command eq 'pod') {
    ### ignore ...
    return;
  }

  # my $this_level = $command_level{$command} || 0;
  # my $prev_level = $command_level{$self->{'last_command'}} || 0;

  if ($command eq 'item' && $self->{'last_command'} eq 'item') {

  } elsif ($command eq 'over'
           || $command eq 'back') {

  } else {
    $self->check_last;
  }
  $self->{'last_text'} = '';
  $self->{'last_command'} = $command;
}
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock(): $text
  $self->check_last;
  if (! defined $text) {
    $text = '';
  }
  $self->{'last_linenum'} = $linenum;
  $self->{'last_text'} = $text;
}
sub verbatim {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### verbatim() ...
  $self->{'last_text'} = '';
}
sub check_last {
  my ($self) = @_;
  ### check_last(): $self->{'last_text'}
  if ($self->{'last_text'} =~ /,\s*$/s) {
    print "$filename:$self->{'last_linenum'}:1: end comma\n";
    $self->{'last_text'} = '';
  }
}

=pod

=head1 ONE

Using pages like,

=for Finance_Quote_Grab symbols MNG

=over 4

blah

=back

=head1 TWO

This one bad,

This one ok.

=head2

This one ok,

=cut

=pod

    verbatim para

Blah.












=cut

# Old stuff for comma following L<> link.

# sub new {
#   my $class = shift;
#   my $self = $class->SUPER::new (last => '',
#                                  @_);
#   $self->parseopts(-process_cut_cmd => 1);
#   return $self;
# }
# 
# sub parse_from_filehandle {
#   my $self = shift;
#   $self->SUPER::parse_from_filehandle(@_);
#   $self->comma_violation_maybe;
# }
# 
# sub comma_violation_maybe {
#   my ($self) = @_;
#   if ($self->{'last'} eq 'L-comma') {
#     $self->violation_at_linenum_and_textpos
#       ("Comma after L<> at end of section, should it be a full stop, or removed?",
#        $self->{'saw_comma_linenum'},
#        $self->{'saw_comma_text'},
#        $self->{'saw_comma_textpos'});
#   }
# }
# 
# my %command_non_text = (for   => 1,
#                         begin => 1,
#                         end   => 1,
#                         cut   => 1);
# 
# sub command {
#   my ($self, $command, $text, $linenum, $paraobj) = @_;
#   ### $command
#   ### last: $self->{'last'}
#   # ### $text
# 
#   if ($command_non_text{$command}) {
#     # skip directives
#     return '';
#   }
# 
#   if (# before =over is ok
#       $command eq 'over'
# 
#       # in between successive =item is ok
#       || ($command eq 'item' && $self->{'last'} eq '=item')) {
# 
#   } else {
#     # before =head or =cut is bad
#     $self->comma_violation_maybe;
#   }
# 
#   $self->{'last'} = '';
#   return '';
# }
# 
# sub verbatim {
#   my ($self) = @_;
#   ### verbatim
#   $self->{'last'} = '';
#   return '';
# }
# 
# sub textblock {
#   my ($self, $text, $linenum, $pod_para) = @_;
#   ### textblock
#   ### $text
#   $self->{'saw_comma_linenum'} = $linenum;
#   $self->{'saw_comma_text'} = $text;
#   $self->parse_text({-expand_seq => 'textblock_seq',
#                      -expand_text => 'textblock_text' },
#                     $text, $linenum);
#   ### last now: $self->{'last'}
#   return '';
# }
# sub textblock_seq {
#   my ($self, $seq) = @_;
#   ### seqsubr: $seq
#   my $cmd = $seq->cmd_name;
#   if ($cmd eq 'L') {
#     if ($self->{'last'} eq 'L') {
#       $self->violation_at_linenum_and_textpos
#         ("Missing comma between L<> sequences",
#          $self->{'saw_comma_linenum'},
#          '', 0);
#     }
#     $self->{'last'} = 'L';
# 
#   } elsif ($cmd eq 'X') {
#     # ignore X<>
# 
#   } else {
#     # other like C<> as text
#     ### raw_text: $seq->raw_text
#     $self->textblock_text ($seq->raw_text, $seq);
#   }
#   return;
# }
# sub textblock_text {
#   my ($self, $text, $textnode) = @_;
#   ### textsubr: $text
#   ### $textnode
#   if ($text =~ /^(\s.*),\s*$/) {
#     if ($self->{'last'} eq 'L') {
#       $self->{'last'} = 'L-comma';
#       $self->{'saw_comma_textpos'} = length($text) - length($1);
#       return;
#     }
#   }
#   if ($text !~ /^\s.*$/) {
#     $self->{'last'} = '';
#   }
#   ### last now: $self->{'last'}
#   return;
# }
