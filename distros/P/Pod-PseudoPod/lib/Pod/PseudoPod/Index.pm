package Pod::PseudoPod::Index;
use strict;
use Carp ();
use base qw( Pod::PseudoPod );

use vars qw( $VERSION );
$VERSION = '0.11';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $self = shift;
  my $index = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->accept_targets_as_text( qw(author blockquote comment caution
      editor epigraph example figure important note production
      programlisting screen sidebar table tip warning) );

  $new->nix_Z_codes(1);
  $new->{'index'} = $index || {};
  $new->{'scratch'} = '';
  $new->{'Indent'} = 0;
  $new->{'Indentstring'} = '   ';
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub start_X { $_[0]{'X'} = 1; }
sub end_X {
  my $self = shift;
  my $text = $self->{'scratch'};
  $self->{'scratch'} = '';

  my $cross_ref = $self->{'index_file'} || $self->set_filename;
  &_build_index($self->{'index'},$cross_ref,split(';', $text));
  $self->{'X'} = 0;
}

sub _build_index {
  my ($node,$cross_ref,@elems) = @_;
  foreach my $entry (@elems,undef) {
    if (defined $entry) {
      $node->{$entry} = {} unless (defined $node->{$entry});
      $node = $node->{$entry};
    } else {
      $node->{'page'} = [] unless (defined $node->{'page'});
      push @{$node->{'page'}}, $cross_ref;
    }
  }
}

sub handle_text { $_[0]{'scratch'} .= $_[1] if $_[0]{'X'}; }

sub get_index { return $_[0]{'index'} }

sub output_text {
  my $self = shift;
  $self->_print_index($self->{'index'},'');
  print {$self->{'output_fh'}} $self->{'scratch'};
}

# recursively print out index tree structure
sub _print_index {
  my ($self,$node,$indent) = @_;
  foreach my $key (sort {lc($a) cmp lc($b)} keys %{$node}) {
    if ($key eq 'page') {
       $self->{'scratch'} .= ', '. join(", ", @{$node->{'page'}});
    } else {
       $self->{'scratch'} .= "\n". $indent. $key;
       $self->_print_index($node->{$key}, $indent.'    ');
    }
  }
}

sub set_filename {
  my $self = shift;
  my $file = $self->{'source_filename'} || '';
  $file =~ /(\w+)\.pod$/;
  $self->{'index_file'} =  $1 || "0";
  return $self->{'index_file'};
}

1;


__END__

=head1 NAME

Pod::PseudoPod::Index -- format PseudoPod index entries

=head1 SYNOPSIS

  use Pod::PseudoPod::Index;

  my $parser = Pod::PseudoPod::Index->new();

  $parser->parse_file('path/to/file1.pod');
  $parser->parse_file('path/to/file2.pod');

  $parser->output_text;

=head1 DESCRIPTION

This class is a formatter that extracts index items from PseudoPod files
and renders them as plain text or html.

This is a subclass of L<Pod::PseudoPod> and inherits all its methods.

=head1 SEE ALSO

L<Pod::PseudoPod>

=head1 COPYRIGHT

Copyright (c) 2004 Allison Randal.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Allison Randal <allison@perl.org>

=cut

