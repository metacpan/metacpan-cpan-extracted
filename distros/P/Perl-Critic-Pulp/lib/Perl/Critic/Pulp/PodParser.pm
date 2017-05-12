# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

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

package Perl::Critic::Pulp::PodParser;
use 5.006;
use strict;
use warnings;
use Perl::Critic::Pulp::Utils;
use base 'Pod::Parser';

our $VERSION = 93;

# uncomment this to run the ### lines
# use Smart::Comments;


# sub new {
#   my $class = shift;
#   ### Pulp-PodParser new()
#   my $self = $class->SUPER::new (@_);
#   return $self;
# }
sub initialize {
  my ($self) = @_;
  ### initialize() ...

  # empty violations for violations() to return before a parse
  $self->{'violations'} = [];
  $self->{'in_begin'} = '';
  $self->errorsub ('error_handler'); # method name

  # Note: The violations list is never cleared.  Might like to do so at the
  # start of a new a pod document, though this parser is only ever used on a
  # single document and then discarded.  begin_input() and begin_pod() are
  # no good as they're invoked for each chunk fed in by parse_from_elem().
}

sub error_handler {
  my ($self, $errmsg) = @_;
  ### error_handler() ...
  return 1;  # error handled

  # Don't think it's the place of this policy to report pod parse errors.
  # Maybe within sections a policy is operating on, on the basis that could
  # affect the goodness of its checks, but better leave it all to podchecker
  # or other perlcritic policies.
  #
  #   my $policy = $self->{'policy'};
  #   my $elem   = $self->{'elem'};
  #   push @{$self->{'violations'}},
  #     $policy->violation ("Pod::Parser $errmsg", '', $elem);
}

sub parse_from_elem {
  my ($self, $elem) = @_;
  ### Pulp-PodParser parse_from_elem(): ref($elem)

  my $elems = ($elem->can('find')
               ? $elem->find ('PPI::Token::Pod')
               : [ $elem ])
    || return;  # find() returns false if nothing found
  foreach my $pod (@$elems) {
    ### pod chunk at linenum: $pod->line_number
    $self->{'elem'} = $pod;
    $self->parse_from_string ($pod->content);
  }
}

# this is generic except for holding onto $str ready for violation override
sub parse_from_string {
  my ($self, $str) = @_;
  $self->{'str'} = $str;
  require IO::String;
  my $fh = IO::String->new ($str);
  $self->parse_from_filehandle ($fh);
}

sub command {
  my ($self, $command, $text, $linenum) = @_;
  if ($command eq 'begin') {
    push @{$self->{'in_begin_stack'}}, $self->{'in_begin'};
    if ($text =~ /^:/) {
      # "=begin :foo" is ordinary POD
      $self->{'in_begin'} = '';
    } elsif ($text =~ /(\w+)/) {
      $self->{'in_begin'} = $1;  # first word only
    } else {
      # "=begin" with no word chars ...
      $self->{'in_begin'} = '';
    }
    ### in_begin: $self->{'in_begin'}

  } elsif ($command eq 'end') {
    $self->{'in_begin'} = pop @{$self->{'in_begin_stack'}};
    if (! defined $self->{'in_begin'}) {
      $self->{'in_begin'} = '';
    }
    ### pop to in_begin: $self->{'in_begin'}
  }
}
use constant verbatim => '';
use constant textblock => '';

sub violation_at_linenum {
  my ($self, $message, $linenum) = @_;
  ### violation on elem: ref($self->{'elem'})

  my $policy = $self->{'policy'};
  ### policy: ref($policy)
  my $violation = $policy->violation ($message, '', $self->{'elem'});

  # fix dodgy Perl::Critic::Policy 1.108 violation() ending up with caller
  # package not given $policy
  if ($violation->policy eq __PACKAGE__
      && defined $violation->{'_policy'}
      && $violation->{'_policy'} eq __PACKAGE__) {
    $violation->{'_policy'} = ref($policy);
  }

  Perl::Critic::Pulp::Utils::_violation_override_linenum
      ($violation, $self->{'str'}, $linenum);
  ### $violation
  push @{$self->{'violations'}}, $violation;
}

sub violation_at_linenum_and_textpos {
  my ($self, $message, $linenum, $text, $pos) = @_;
  ### violation_at_linenum_and_textpos()
  ### $message
  ### $linenum
  ### $pos

  my $part = substr($text,0,$pos);
  $linenum += ($part =~ tr/\n//);
  $self->violation_at_linenum ($message, $linenum);
}

# return list of violation objects (possibly empty)
sub violations {
  my ($self) = @_;
  return @{$self->{'violations'}};
}

#------------------------------------------------------------------------------
# This not documented yet.  Might prefer to split it out for separate use too.
#
# Not sure about padding to make the column right.  Usually good, but
# perhaps not always.  Maybe should offset a column by examining
# $paraobj->cmd_prefix() and $paraobj->cmd_name().

{
  my %command_non_text = (for   => 1,
                          begin => 1,
                          end   => 1,
                          cut   => 1);

  # The parameters are as per the command() method of Pod::Parser.
  # If $command contains text style markup then call $self->textblock() on
  # its text.
  # All commands except =for, =begin, =end and =cut have marked-up text.
  # Eg. =head2 C<blah blah>
  #
  sub command_as_textblock {
    my ($self, $command, $text, $linenum, $paraobj) = @_;
    ### command: $command
    ### $text

    # $text can be undef if =foo with no newline at end-of-file
    if (defined $text && ! $command_non_text{$command}) {
      # padded to make the column number right, the leading spaces do no harm
      # for this policy
      $self->textblock ((' ' x (length($command)+1)) . $text,
                        $linenum,
                        $paraobj);
    }
    return '';
  }
}

1;
__END__

=for stopwords perlcritic Ryde

=head1 NAME

Perl::Critic::Pulp::PodParser - shared POD parsing code for the Pulp perlcritic add-on

=head1 SYNOPSIS

 use base 'Perl::Critic::Pulp::PodParser';

=head1 DESCRIPTION

This is only meant for internal use yet.

It's some shared parse-from-element, error suppression, no output, violation
accumulation and violation line number things for POD parsing in policies.

=head1 SEE ALSO

L<Perl::Critic::Pulp>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut
