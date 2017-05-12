
require 5;
package Pod::PseudoPod::Text;
use strict;
use Carp ();
use vars qw( $VERSION $FREAKYMODE );
$VERSION = '0.11';
use base qw( Pod::PseudoPod );

use Text::Wrap 98.112902 ();
$Text::Wrap::wrap = 'overflow';
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->accept_target_as_text(qw( text plaintext plain ));
  $new->accept_targets_as_text( qw(author blockquote comment caution
      editor epigraph example figure important listing note production
      programlisting screen sidebar table tip warning) );

  $new->nix_X_codes(1);
  $new->nix_Z_codes(1);
  $new->nbsp_for_S(1);
  $new->codes_in_verbatim(1);
  $new->{'scratch'} = '';
  $new->{'Indent'} = 0;
  $new->{'Indentstring'} = '   ';
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_text {  $_[0]{'scratch'} .= $_[1] }

sub start_Para     {  $_[0]{'scratch'} = '' }
sub end_Para       { $_[0]->emit(0) }
sub start_Verbatim { $_[0]{'scratch'} = ''   }

sub start_head0 { $_[0]{'scratch'} = '' }
sub end_head0   { $_[0]->emit(-4) }
sub start_head1 { $_[0]{'scratch'} = '' }
sub end_head1   { $_[0]->emit(-3) }
sub start_head2 { $_[0]{'scratch'} = '' }
sub end_head2   { $_[0]->emit(-2) }
sub start_head3 { $_[0]{'scratch'} = '' }
sub end_head3   { $_[0]->emit(-1) }
sub start_head4 { $_[0]{'scratch'} = '' }
sub end_head4   { $_[0]->emit(0) }

sub start_item_bullet { $_[0]{'scratch'} = $FREAKYMODE ? '' : '* ' }
sub end_item_bullet   { $_[0]->emit( 0) }
sub start_item_number { $_[0]{'scratch'} = $FREAKYMODE ? '' : "$_[1]{'number'}. "  }
sub end_item_number   { $_[0]->emit( 0) }
sub start_item_text   { $_[0]{'scratch'} = ''   }
sub end_item_text     { $_[0]->emit(-2) }

sub start_over_bullet  { ++$_[0]{'Indent'} }
sub end_over_bullet    { --$_[0]{'Indent'} }
sub start_over_number  { ++$_[0]{'Indent'} }
sub end_over_number    { --$_[0]{'Indent'} }
sub start_over_text    { ++$_[0]{'Indent'} }
sub end_over_text      { --$_[0]{'Indent'} }
sub start_over_block   { ++$_[0]{'Indent'} }
sub end_over_block     { --$_[0]{'Indent'} }

sub start_for { ++$_[0]{'Indent'} }
sub end_for   { $_[0]->emit(); --$_[0]{'Indent'} }

sub start_sidebar { 
  my ($self, $flags) = @_;
  $self->{'scratch'} = '';
  if ($flags->{'title'}) {
    $self->{'scratch'} .= "Sidebar: " . $flags->{'title'} . "\n";
  }
  ++$self->{'Indent'};
  $self->emit();
}
sub end_sidebar   { $_[0]->emit(); --$_[0]{'Indent'} }

sub start_table { 
  my ($self, $flags) = @_;
  $self->{'scratch'} = '';
  if ($flags->{'title'}) {
    $self->{'scratch'} .= "Table: " . $flags->{'title'} . "\n";
  }
  ++$self->{'Indent'};
}
sub end_table { --$_[0]{'Indent'} }

sub end_cell { $_[0]{'scratch'} .= " | "; }
sub end_row  { $_[0]->emit() }

sub start_N { $_[0]{'scratch'} .= ' [footnote: '; }
sub end_N   { $_[0]{'scratch'} .= ']'; }

sub emit {
  my($self, $tweak_indent) = splice(@_,0,2);
  my $indent = ' ' x ( 2 * $self->{'Indent'} + 4 + ($tweak_indent||0) );
   # Yes, 'STRING' x NEGATIVE gives '', same as 'STRING' x 0

  $self->{'scratch'} =~ tr{\xAD}{}d if Pod::Simple::ASCII;
  my $out = $self->{'scratch'} . "\n";
  $out = Text::Wrap::wrap($indent, $indent, $out);
  $out =~ tr{\xA0}{ } if Pod::Simple::ASCII;
  print {$self->{'output_fh'}} $out, "\n";
  $self->{'scratch'} = '';
  
  return;
}

# . . . . . . . . . . And then off by its lonesome:

sub end_Verbatim  {
  my $self = shift;
  if(Pod::Simple::ASCII) {
    $self->{'scratch'} =~ tr{\xA0}{ };
    $self->{'scratch'} =~ tr{\xAD}{}d;
  }

  my $i = ' ' x ( 2 * $self->{'Indent'} + 4);
  #my $i = ' ' x (4 + $self->{'Indent'});
  
  $self->{'scratch'} =~ s/^/$i/mg;
  
  print { $self->{'output_fh'} }   '', 
    $self->{'scratch'},
    "\n\n"
  ;
  $self->{'scratch'} = '';
  return;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
1;


__END__

=head1 NAME

Pod::PseudoPod::Text -- format PseudoPod as plaintext

=head1 SYNOPSIS

  perl -MPod::PseudoPod::Text -e \
   "exit Pod::PseudoPod::Text->filter(shift)->any_errata_seen" \
   thingy.pod

=head1 DESCRIPTION

This class is a formatter that takes PseudoPod and renders it as
wrapped plaintext.

Its wrapping is done by L<Text::Wrap>, so you can change
C<$Text::Wrap::columns> as you like.

This is a subclass of L<Pod::PseudoPod> and inherits all its methods.

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::Simple::TextContent>, L<Pod::Text>

=head1 COPYRIGHT

Copyright (c) 2002-2004 Sean M. Burke and Allison Randal.  All rights
reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org> &
Allison Randal <allison@perl.org>

=cut

