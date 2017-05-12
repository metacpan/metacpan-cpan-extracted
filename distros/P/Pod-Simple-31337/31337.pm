require 5;
package Pod::Simple::31337;
use strict;
use Carp ();
require Exporter;
use Pod::Simple::Methody ();
use Pod::Simple ();
use vars qw(@ISA $VERSION $FREAKYMODE @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.02';
@ISA = ('Pod::Simple::Methody', 'Exporter');
%EXPORT_TAGS = ( all => qw(pod231337) );
@EXPORT_OK = $EXPORT_TAGS{all};
BEGIN { *DEBUG = defined(&Pod::Simple::DEBUG)
          ? \&Pod::Simple::DEBUG
          : sub() {0}
      }

use Text::Wrap 98.112902 ();
$Text::Wrap::wrap = 'overflow';

use Lingua::31337 qw[text231337];
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->accept_target_as_text(qw( text plaintext plain ));
  $new->nix_X_codes(1);
  $new->nbsp_for_S(1);
  $new->{'Thispara'} = '';
  $new->{'Indent'} = 0;
  $new->{'Indentstring'} = '   ';
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_text {  $_[0]{'Thispara'} .= $_[1] }

sub start_Para  {  $_[0]{'Thispara'} = '' }
sub start_head1 {  $_[0]{'Thispara'} = '' }
sub start_head2 {  $_[0]{'Thispara'} = '' }
sub start_head3 {  $_[0]{'Thispara'} = '' }
sub start_head4 {  $_[0]{'Thispara'} = '' }

sub start_Verbatim    { $_[0]{'Thispara'} = ''   }
sub start_item_bullet { $_[0]{'Thispara'} = $FREAKYMODE ? '' : '* ' }
sub start_item_number { $_[0]{'Thispara'} = $FREAKYMODE ? '' : "$_[1]{'number'}. "  }
sub start_item_text   { $_[0]{'Thispara'} = ''   }

sub start_over_bullet  { ++$_[0]{'Indent'} }
sub start_over_number  { ++$_[0]{'Indent'} }
sub start_over_text    { ++$_[0]{'Indent'} }
sub start_over_block   { ++$_[0]{'Indent'} }

sub   end_over_bullet  { --$_[0]{'Indent'} }
sub   end_over_number  { --$_[0]{'Indent'} }
sub   end_over_text    { --$_[0]{'Indent'} }
sub   end_over_block   { --$_[0]{'Indent'} }

# . . . . . Now the actual formatters:

sub end_head1       { $_[0]->emit_par(-4) }
sub end_head2       { $_[0]->emit_par(-3) }
sub end_head3       { $_[0]->emit_par(-2) }
sub end_head4       { $_[0]->emit_par(-1) }
sub end_Para        { $_[0]->emit_par( 0) }
sub end_item_bullet { $_[0]->emit_par( 0) }
sub end_item_number { $_[0]->emit_par( 0) }
sub end_item_text   { $_[0]->emit_par(-2) }

sub emit_par {
  my($self, $tweak_indent) = splice(@_,0,2);
  my $indent = ' ' x ( 2 * $self->{'Indent'} + 4 + ($tweak_indent||0) );
   # Yes, 'STRING' x NEGATIVE gives '', same as 'STRING' x 0

  $self->{'Thispara'} =~ tr{\xAD}{}d if Pod::Simple::ASCII;
  my $out = Text::Wrap::wrap($indent, $indent, $self->{'Thispara'} .= "\n");
  $out =~ tr{\xA0}{ } if Pod::Simple::ASCII;
  print {$self->{'output_fh'}} text231337( $out, "\n" );
  $self->{'Thispara'} = '';
  
  return;
}

# . . . . . . . . . . And then off by its lonesome:

sub end_Verbatim  {
  my $self = shift;
  if(Pod::Simple::ASCII) {
    $self->{'Thispara'} =~ tr{\xA0}{ };
    $self->{'Thispara'} =~ tr{\xAD}{}d;
  }

  my $i = ' ' x ( 2 * $self->{'Indent'} + 4);
  #my $i = ' ' x (4 + $self->{'Indent'});
  
  $self->{'Thispara'} =~ s/^/$i/mg;
  
  print { $self->{'output_fh'} }  text231337( '', 
    $self->{'Thispara'},
    "\n\n"
  );
  $self->{'Thispara'} = '';
  return;
}

sub pod231337 {
  my $pod = undef;
  
  if ( @ARGV ) {
    require Pod::Find;
    $pod = Pod::Find::pod_where( {-inc=>1,-script=>1,-perl=>1}, shift @ARGV );
  }
  
  if ( ! $pod ) {
    $pod = \ do { local $/; <> };
  }

  print "Filtering $pod\n";
  Pod::Simple::31337->filter( $pod );
}

1;

__END__

=head1 NAME

Pod::Simple::31337 - Convert POD to Cool Talk

=head1 SYNOPSIS

  perl -MPod::Simple::31337=all -epod231337 foo.pod
  # or
  pod2text perlpod | \
  perl -MPod::Simple::31337 -0 -ne'Pod::Simple::31337->filter(\$_)'
  # or
  pod231337 perlpodspec

=head1 DESCRIPTION

This module translates POD into Cool Talk.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 COPYRIGHT

Copyright (c) 2002 Casey R. West <casey@geeknest.com>.
All rights reserved.  This program is free software; you
can redistribute it and/or modify it under the same terms
as Perl itself.


=head1 SEE ALSO

perl(1), Pod::Simple, Lingua::31337.

=cut
