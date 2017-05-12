# Copyright (c) Philippe Verdret, 1999

require 5.005;
use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

package Parse::LexEvent;
$Parse::LexEvent::VERSION = '2.21';

use Parse::ALex;
@Parse::LexEvent::ISA = qw(Parse::ALex);

my $lexer = __PACKAGE__->clone;
sub prototype { $lexer or __PACKAGE__->SUPER::prototype }

####################################################################

my %TEMPLATE = ();
$TEMPLATE{'HEADER_STRING_PART'} =  q@
  {		
   pos($LEX_BUFFER) = $LEX_POS;
   my $textLength = 0;
   my $content = '';
   #
 PARSE:{
   %% $SKIP ne '' ? WITH_SKIP_PART() : '' %%
   if ($LEX_POS == $LEX_LENGTH) { 
     $self->[%%$EOI%%] = 1;
     $LEX_TOKEN = $Parse::Token::EOI;
     return $Parse::Token::EOI;
   }
   # 
@;
$TEMPLATE{'HEADER_STREAM_PART'} =  q@
  {
   pos($LEX_BUFFER) = $LEX_POS;
   my $LEX_FH = $$LEX_FHR;
   my $textLength = 0;
   my $content = '';
   #
 PARSE:{
   %% $SKIP ne '' ? WITH_SKIP_PART() : '' %%
   if ($LEX_POS == $LEX_LENGTH) { 
     if ($self->[%%$EOI%%]) # if EOI
       { 
         $LEX_TOKEN = $Parse::Token::EOI;
         return $Parse::Token::EOI;
       } 
     else 
       {
	READ:{
	    do {
	      $LEX_BUFFER = <$LEX_FH>; 
	      if (defined($LEX_BUFFER)) {
		pos($LEX_BUFFER) = $LEX_POS = 0;
		$LEX_LENGTH = CORE::length($LEX_BUFFER);
		$LEX_RECORD++;
		%%$SKIP ne '' ? WITH_SKIP_LAST_READ_PART() : '' %%
	      } else {
		$self->[%%$EOI%%] = 1;
		$LEX_TOKEN = $Parse::Token::EOI;
		return $Parse::Token::EOI;
	      }
	    } while ($LEX_POS == $LEX_LENGTH);
	  }# READ
      }
   }
@;
$TEMPLATE{'FOOTER_PART'} = q!
  }# PARSE
  $self				# return the lexer instance
}
!;
$TEMPLATE{'WITH_SKIP_PART'} =  q@
   if ($LEX_POS < $LEX_LENGTH and $LEX_BUFFER =~ /\G(?:%%$SKIP%%)/cg) {
     $textLength = pos($LEX_BUFFER) - $LEX_POS; # length $&
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
   }
@;
$TEMPLATE{'WITH_SKIP_LAST_READ_PART'} =  q@
		if ($LEX_BUFFER =~ /\G(?:%%$SKIP%%)/cg) { # skip this pattern
		  $textLength = pos($LEX_BUFFER) - $LEX_POS; # length $&
		  $LEX_OFFSET += $textLength;
		  $LEX_POS += $textLength;
		} else {
		  last READ;
		}
@;
$lexer->template(Parse::Template->new(%TEMPLATE)); # code template

my $LEXER_SUB = $lexer->_map('LEXER_SUB');
sub parse { &{$_[0]->[$LEXER_SUB]} }

1;
__END__

=head1 NAME

C<Parse::LexEvent> - Generator of event-oriented lexical analyzers (1.00 ALPHA)

=head1 SYNOPSIS

  use Parse::LexEvent;

  sub string {
    print $_[0]->name, ": $_[1]\n";
  }
  sub comment {
    print $_[0]->name, ": $_[1]\n";
  }
  sub remainder {
    print $_[0]->name, ": $_[1]\n";
  }

  $lexer = Parse::LexEvent->new()->configure(
       From => \*DATA,
       Tokens =>
         [
          Type => 'Simple', Name => 'ccomment', Handler => 'comment',
               Regex => '//.*\n',
          Type => 'Delimited', Name => 'comment', Handler => 'comment',
               Start => '/[*]', End => '[*]/',
          Type => 'Quoted', Name => 'squotes', Handler => 'string', Quote => qq!\'!,
          Type => 'Quoted', Name => 'dquotes', Handler => 'string', Quote => qq!\"!,
          Type => 'Simple', Name => 'remainder',
               Regex => '(?s:[^/\'\"]+)', ReadMore => 1,
         ]
      )->parse();
  __END__
  /*
    C comment
  */
  // C++ comment
  var d = "string in double quotes";
  var s = 'string in single quotes';
  var i = 10;
  var y = 100;

=head1 DESCRIPTION

C<Parse::LexEvent> generates lexical analyzers in the fashion of
C<Parse::Lex>, but the generated analyzers emit an event at the
finish of recognition of each token.  This event corresponds to
the call of a procedure whose name is that of the token.  It is
possible to give a different name to this procedure by making use
of the C<Handler> parameter when defining a token.

An application using C<Parse::LexEvent> must define the required
procedures.  These procedures take the token object as first
argument and the recognized character string as the second.

C<Parse::LexEvent> inherits from C<Parse::ALex> and possesses all
the methods described in the documentation of the C<Parse::Lex>
class, except for the methods C<analyze()>, C<every()> C<next()>, and
C<nextis()>.

=head2 Methods

=over 4

=item parse()

This method runs the analysis of data specified by C<from()>.

=back

=head1 EXAMPLES

cparser.pl - This analyzer recognizes three types of structures:
C ou C++ comments, strings within quotation marks, and the rest.
It emits an event specific to each.  You can use it, for example,
to analyze C, C++ or Javascript programs.

=head1 SEE ALSO

C<Parse::Lex>, C<Parse::Token>.

=head1 AUTHOR

Philippe Verdret.

=head1 COPYRIGHT

Copyright (c) 1999 Philippe Verdret. All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
