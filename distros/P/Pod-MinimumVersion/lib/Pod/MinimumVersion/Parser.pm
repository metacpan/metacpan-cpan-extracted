# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.

# Pod-MinimumVersion is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.


package Pod::MinimumVersion::Parser;
use 5.004;
use strict;
use vars '$VERSION', '@ISA';

use Pod::Parser;
@ISA = ('Pod::Parser');

$VERSION = 50;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->errorsub ('error_handler'); # method name
  return $self;
}
sub error_handler {
  my ($self, $errmsg) = @_;
  ### PMV error_handler()
  return 1;  # error handled
}

# sub begin_input {
#   print "begin_input\n";
# }
# sub end_input {
#   print "end_input\n";
# }

sub parse_from_string {
  my ($self, $str) = @_;
  ### PMV parse_from_string()

  require IO::String;
  my $fh = IO::String->new ($str);
  $self->{_INFILE} = "(string)";
  return $self->parse_from_filehandle ($fh);
}

my %command_does_not_interpolate = (for   => 1,   # free form text
                                    begin => 1,   # formatname not text
                                    end   => 1,
                                    pod   => 1,   # text ignored
                                    cut   => 1,   # text ignored
                                    encoding => 1, # encoding name not text
                                   );
sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### PMV command()
  ### $command
  ### $text
  ### $linenum

  # If =foo command at EOF with no more chars, including no trailing
  # newline, then $text is undef (circa Pod::Parser 1.37 at least).
  #
  if (defined $text) {
    if ($command eq 'for'
        && $text =~ /^Pod::MinimumVersion\s+use\s+(v?[0-9._]+)/) {
      $self->{'pmv'}->{'for_version'} = version->new($1);
    }

    foreach my $func (@{$self->{'checks'}->{'command'}}) {
      $func->($self->{'pmv'}, $command, $text, $paraobj);
    }

    unless ($command_does_not_interpolate{$command}) {
      $self->interpolate ($text, $linenum);
    }
  }
  return '';
}

sub verbatim {
  ### PMV verbatim()
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### PMV textblock()
  ### $text
  return $self->interpolate ($text, $linenum);
}

sub interior_sequence {
  my ($self, $command, $arg, $seq_obj) = @_;
  ### interior
  ### $command
  ### $arg
  ### $seq_obj
  ### raw_text: $seq_obj->raw_text
  ### left: $seq_obj->left_delimiter
  ### nested: do { my $outer = $seq_obj->nested; $outer && $outer->cmd_name }

  # J<> from Pod::MultiLang -- doubled C<<>> or L<|display> are allowed
  # ENHANCE-ME: might prefer to make parse_tree() not descend into J<> at
  # all, but it doesn't seem setup for that
  my $outer;
  if ($command eq 'J'
      || (($outer = $seq_obj->nested) && $outer->cmd_name eq 'J')) {
    return '';
  }

  foreach my $func (@{$self->{'checks'}->{'interior_sequence'}}) {
    $func->($self->{'pmv'}, $command, $arg, $seq_obj);
  }
  return '';
}

1;
__END__

=for stopwords Ryde Pod-MinimumVersion

=head1 NAME

Pod::MinimumVersion::Parser - parser used by Pod::MinimumVersion

=head1 DESCRIPTION

This is an internal part of C<Pod::MinimumVersion>, not meant for other use.

=head1 SEE ALSO

L<Pod::MinimumVersion>

=head1 HOME PAGE

http://user42.tuxfamily.org/pod-minimumversion/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011 Kevin Ryde

Pod-MinimumVersion is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Pod-MinimumVersion is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.

=cut
