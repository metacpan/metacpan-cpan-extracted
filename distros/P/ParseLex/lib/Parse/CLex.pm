require 5.004;
use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

package Parse::CLex;
use Parse::ALex;
$Parse::CLex::VERSION = '2.21';
@Parse::CLex::ISA = qw(Parse::Tokenizer);

my $lexer = __PACKAGE__->clone;
sub prototype { $lexer or __PACKAGE__->SUPER::prototype }

####################################################################
#Structure of the next routine:
#  HEADER_STRING | HEADER_STREAM
#  TOKEN+
#  FOOTER

# %%...%% are processed by the Parse::Template class
# RegExp must be delimited by // or m!!

my %TEMPLATE = ();
$TEMPLATE{'WITH_SKIP_PART'} = q@
   if ($LEX_BUFFER ne '' and $LEX_BUFFER =~ s/^(?:%%$SKIP%%)//) {
     $textLength = CORE::length($&);
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
     %%$IS_HOLD ? HOLD_SKIP_PART() : ''%%
   }
@;
$TEMPLATE{'WITH_SKIP_LAST_READ_PART'} = q@
	      if ($LEX_BUFFER =~ s/^(?:%%$SKIP%%)//) {
		$textLength = CORE::length($&);
		$LEX_OFFSET+= $textLength;
		$LEX_POS = $textLength;
                %%$IS_HOLD ? HOLD_SKIP_PART() : ''%%
	      } else {
		$LEX_POS = 0; 
		last READ;
	      }
@;
$TEMPLATE{'HOLD_SKIP_PART'} = q@$self->[%%$HOLD_TEXT%%] .= $&;@;
$TEMPLATE{'HEADER_STRING_PART'} = q!
  {		
   my $textLength = 0;
   %%$SKIP ne '' ? WITH_SKIP_PART() : '' %%
   if ($LEX_BUFFER eq '') {
     $self->[%%$EOI%%] = 1;
     $LEX_TOKEN = $Parse::Token::EOI;
     return $Parse::Token::EOI;
   }
   my $content = '';
   $LEX_TOKEN = undef;
 CASE:{
!;
$TEMPLATE{'HEADER_STREAM_PART'} = q!
  {
   my $textLength = 0;
   %%$SKIP ne '' ? WITH_SKIP_PART() : '' %%
   my $LEX_FH = $$LEX_FHR;
   if ($LEX_BUFFER eq '') {
     if ($self->[%%$EOI%%]) # if EOI
       { 
         $self->[%%$PENDING_TOKEN%%] = $Parse::Token::EOI;
         return $Parse::Token::EOI;
       } 
     else 
       {
      READ: {
	  do {
	    $LEX_BUFFER = <$LEX_FH>; 
	    if (defined($LEX_BUFFER)) {
	      $LEX_RECORD++;
	      %%$SKIP ne '' ? WITH_SKIP_LAST_READ_PART() : '' %%
	    } else {
	      $self->[%%$EOI%%] = 1;
	      $LEX_TOKEN = $Parse::Token::EOI;
	      return $Parse::Token::EOI;
	    }
	  } while ($LEX_BUFFER eq '');
	}
      }
   }
   my $content = '';
   $LEX_TOKEN = undef;
 CASE:{
!;

$TEMPLATE{'HOLD_TOKEN_PART'} = q@$self->[%%$HOLD_TEXT%%] .= $content;@;
$TEMPLATE{'FOOTER_PART'} = q!
  }#CASE
  %%$IS_HOLD ? HOLD_TOKEN_PART() : ''%%
  $self->[%%$PENDING_TOKEN%%] = $LEX_TOKEN;
  $LEX_TOKEN;
}
!;

$lexer->template(new Parse::Template (%TEMPLATE));
####################################################################

my $POS = $lexer->_map('POS');
sub pos {			
  my $self = shift;
  if (defined $_[0]) {    
    require Carp;
    Carp::carp "can't change buffer offset";
  } else {
    ${$self->[$POS]};
  }
}

1;
__END__

=head1 NAME

C<Parse::CLex> - Generator of lexical analyzers - consuming recoginzed data

=head1 SYNOPSIS

See the C<Parse::Lex> documentation.

=head1 DESCRIPTION

See the C<Parse::Lex> documentation.

=head1 AUTHOR

Philippe Verdret.

=head1 COPYRIGHT

Copyright (c) 1999 Philippe Verdret. All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
