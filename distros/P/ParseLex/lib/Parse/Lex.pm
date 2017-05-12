require 5.004;
use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

package Parse::Lex;
use Parse::ALex;
$Parse::Lex::VERSION = '2.21';
@Parse::Lex::ISA = qw(Parse::Tokenizer);

my $lexer = __PACKAGE__->clone;
sub prototype { $lexer or __PACKAGE__->SUPER::prototype }

####################################################################
#Structure of the next routine:
#  HEADER_STRING | HEADER_STREAM
#  TOKEN+
#  FOOTER

# %%...%% are processed by the Parse::Template class
# In %%%% $template and $self are the same Parse::Template instance
# RegExp must be delimited by // or m!!

my %TEMPLATE = ();

$TEMPLATE{'WITH_SKIP_PART'} =  q@
   if ($LEX_POS < $LEX_LENGTH and $LEX_BUFFER =~ /\G(?:%%$SKIP%%)/cg) {
     $textLength = pos($LEX_BUFFER) - $LEX_POS; # length $&
     $LEX_OFFSET += $textLength;
     $LEX_POS += $textLength;
     %% $IS_HOLD ? HOLD_SKIP_PART(): ''%%
   }
@;
$TEMPLATE{'WITH_SKIP_LAST_READ_PART'} =  q@
		if ($LEX_BUFFER =~ /\G(?:%%$SKIP%%)/cg) { # skip this pattern
		  $textLength = pos($LEX_BUFFER) - $LEX_POS; # length $&
		  $LEX_OFFSET += $textLength;
		  $LEX_POS += $textLength;
                  %% $IS_HOLD ? HOLD_SKIP_PART(): ''%%
		} else {
		  last READ;
		}
@;
$TEMPLATE{'HOLD_SKIP_PART'} =  q@$self->[%%$HOLD_TEXT%%] .= $1;@;
$TEMPLATE{'HEADER_STRING_PART'} =  q@
  {		
   pos($LEX_BUFFER) = $LEX_POS;
   my $textLength = 0;
   #
   %% $SKIP ne '' ? WITH_SKIP_PART() : '' %%
   if ($LEX_POS == $LEX_LENGTH) { 
     $self->[%%$EOI%%] = 1;
     $LEX_TOKEN = $Parse::Token::EOI;
     return $Parse::Token::EOI;
   }
   $LEX_TOKEN = undef;
   my $content = '';
   # 
 CASE:{
@;
$TEMPLATE{'HEADER_STREAM_PART'} =  q@
  {
   pos($LEX_BUFFER) = $LEX_POS;
   my $textLength = 0;
   my $LEX_FH = $$LEX_FHR;
   #
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
   my $content = '';
   $LEX_TOKEN = undef;
   # 
 CASE:{
@;
$TEMPLATE{'HOLD_TOKEN_PART'} = q@$self->[%%$HOLD_TEXT%%] .= $content;@;
$TEMPLATE{'FOOTER_PART'} = q!
  }#CASE
  %%$IS_HOLD ? HOLD_TOKEN_PART() : ''%%
  $self->[%%$PENDING_TOKEN%%] = $LEX_TOKEN;
  $LEX_TOKEN;
}
!;
$lexer->template(Parse::Template->new(%TEMPLATE)); # code template

1;
__END__


=head1 NAME

C<Parse::Lex> - Generator of lexical analyzers - moving pointer inside text

=head1 SYNOPSIS

        require 5.005;

        use Parse::Lex;
        @token = (
          qw(
             ADDOP    [-+]
             LEFTP    [\(]
             RIGHTP   [\)]
             INTEGER  [1-9][0-9]*
             NEWLINE  \n
             
            ),
          qw(STRING),   [qw(" (?:[^"]+|"")* ")],
          qw(ERROR  .*), sub {
            die qq!can\'t analyze: "$_[1]"!;
          }
         );

        Parse::Lex->trace;  # Class method
        $lexer = Parse::Lex->new(@token);
        $lexer->from(\*DATA);
        print "Tokenization of DATA:\n";

        TOKEN:while (1) {
          $token = $lexer->next;
          if (not $lexer->eoi) {
            print "Line $.\t";
            print "Type: ", $token->name, "\t";
            print "Content:->", $token->text, "<-\n";
          } else {
            last TOKEN;
          }
        }

        __END__
        1+2-5
        "a multiline
        string with an embedded "" in it"
        an invalid string with a "" in it"

=head1 DESCRIPTION

The classes C<Parse::Lex> and C<Parse::CLex> create lexical analyzers.
They use different analysis techniques:

1.  C<Parse::Lex> steps through the analysis by moving a pointer within
the character strings to be analyzed (use of C<pos()> together with C<\G>),

2.  C<Parse::CLex> steps through the analysis by consuming the data
recognized (use of C<s///>).

Analyzers of the C<Parse::CLex> class do not allow the use of
anchoring in regular expressions.  In addition, the subclasses
of C<Parse::Token> are not implemented for this type of analyzer.

A lexical analyzer is specified by means of a list of tokens passed as
arguments to the C<new()> method. Tokens are instances of the
C<Parse::Token> class, which comes with C<Parse::Lex>. The definition
of a token usually comprises two arguments: a symbolic name (like
C<INTEGER>), followed by a regular expression. If a sub ref (anonymous
subroutine) is given as third argument, it is called when the token is
recognized.  Its arguments are the C<Parse::Token> instance and the
string recognized by the regular expression.  The anonymous
subroutine's return value is used as the new string contents of the
C<Parse::Token> instance.

The order in which the lexical analyzer examines the regular
expressions is determined by the order in which these expressions are
passed as arguments to the C<new()> method. The token returned by the
lexical analyzer corresponds to the first regular expression which
matches (this strategy is different from that used by Lex, which
returns the longest match possible out of all that can be recognized).

The lexical analyzer can recognize tokens which span
multiple records.  If the definition of the token comprises
more than one regular expression (placed within a reference to an anonymous
array), the analyzer reads as many records as required to recognize
the token (see the documentation for the C<Parse::Token> class).
When the start pattern is found, the analyzer looks for the end,
and if necessary, reads more records.  No backtracking is done
in case of failure.

The analyzer can be used to analyze an isolated character string or
a stream of data coming from a file handle. At the end of the input
data the analyzer returns a C<Parse::Token> instance named
C<EOI> (End Of Input).

=head2 Start Conditions

You can associate start conditions with the token-recognition rules
that comprise your lexical analyzer (this is similar to what
Flex provides).  When start conditions are used, the rule which succeeds
is no longer necessarily the first rule that matches.

A token symbol may be preceded by a start condition specifier for
the associated recognition rule. For example:

        qw(C1:TERMINAL_1  REGEXP), sub { # associated action },
        qw(TERMINAL_2  REGEXP), sub { # associated action },

Symbol C<TERMINAL_1> will be recognized only if start condition C<C1>
is active.  Start conditions are activated/deactivated using the
C<start(CONDITION_NAME)> and C<end(CONDITION_NAME)> methods.

C<start('INITIAL')> resets the analysis automaton.

Start conditions can be combined using AND/OR operators as follows:

        C1:SYMBOL      condition C1

        C1:C2:SYMBOL   condition C1 AND condition C2

        C1,C2:SYMBOL   condition C1 OR  condition C2

There are two types of start conditions: I<inclusive> and I<exclusive>,
which are declared by class methods C<inclusive()> and C<exclusive()>
respectively.  With an inclusive start condition, all rules are active
regardless of whether or not they are qualified with the start condition.
With an exclusive start condition, only the rules qualified with
the start condition are active; all other rules are deactivated.

Example (borrowed from the documentation of Flex):

 use Parse::Lex;
 @token = (
          'EXPECT', 'expect-floats', sub {
            $lexer->start('expect'); 
            $_[1] 
          },
          'expect:FLOAT', '\d+\.\d+', sub { 
            print "found a float: $_[1]\n";
            $_[1] 
          },
          'expect:NEWLINE', '\n', sub { 
            $lexer->end('expect') ;
            $_[1] 
          },
          'NEWLINE2', '\n',
          'INT', '\d+', sub {
            print "found an integer: $_[1] \n";
            $_[1] 
          },
          'DOT', '\.', sub {
            print "found a dot\n";
            $_[1] 
          },
         );

 Parse::Lex->exclusive('expect');
 $lexer = Parse::Lex->new(@token);

The special start condition C<ALL> is always verified.

=head2 Methods

=over 4

=item analyze EXPR

Analyzes C<EXPR> and returns a list of pairs consisting of a token name
followed by recognized text. C<EXPR> can be a character string or a
reference to a filehandle.

Examples:

 @tokens = Parse::Lex->new(qw(PLUS [+] NUMBER \d+))->analyze("3+3+3");
 @tokens = Parse::Lex->new(qw(PLUS [+] NUMBER \d+))->analyze(\*STREAM);

=item buffer EXPR

=item buffer

Returns the contents of the internal buffer of the lexical analyzer.
With an expression as argument, places the result of the expression in
the buffer.

It is not advisable to directly change the contents of the buffer
without changing the position of the analysis pointer (C<pos()>) and the
value length of the buffer (C<length()>).

=item configure(HASH)

Instance method which permits specifying a lexical analyzer.  This
method accepts the list of the following attribute values:

=over 10

=item From => EXPR

This attribute plays the same role as the C<from(EXPR)> method.
C<EXPR> can be a filehandle or a character string.

=item Tokens => ARRAY_REF

C<ARRAY_REF> must contain the list of attribute values specifying
the tokens to be recognized (see the documentation for C<Parse::Token>).

=item Skip => REGEX

This attribute plays the same role as the C<skip(REGEX)> method. C<REGEX>
describes the patterns to skip over during the analysis.

=back

=item end EXPR

Deactivates condition C<EXPR>.

=item eoi

Returns TRUE when there is no more data to analyze.

=item every SUB

Avoids having to write a reading loop in order to analyze a stream of
data. C<SUB> is an anonymous subroutine executed after the recognition
of each token. For example, to lex the string "1+2" you can write:

        use Parse::Lex;

        $lexer = Parse::Lex->new(
          qw(
             ADDOP [-+]
             INTEGER \d+
            ));

        $lexer->from("1+2");
        $lexer->every (sub { 
          print $_[0]->name, "\t";
          print $_[0]->text, "\n"; 
        });

The first argument of the anonymous subroutine is the C<Parse::Token>
instance recognized.

=item exclusive LIST

Class method declaring the conditions present in LIST to be I<exclusive>.

=item flush

If saving of the consumed strings is activated, C<flush()> returns and
clears the buffer containing the character strings recognized up to
now.  This is only useful if C<hold()> has been called to activate
saving of consumed strings.

=item from EXPR

=item from

C<from(EXPR)> allows specifying the source of the data to be analyzed. The
argument of this method can be a string (or list of strings), or a
reference to a filehandle.  If no argument is given, C<from()> returns the
filehandle if defined, or C<undef> if input is a string.
When an argument C<EXPR> is used, the return value is the calling lexer
object itself.

By default it is assumed that data are read from C<STDIN>.

Examples:

        $handle = new IO::File;
        $handle->open("< filename");
        $lexer->from($handle);

        $lexer->from(\*DATA);
        $lexer->from('the data to be analyzed');

=item getSub

C<getSub> returns the anonymous subroutine that performs the lexical
analysis.

Example:

        my $token = '';
        my $sub = $lexer->getSub;
        while (($token = &$sub()) ne $Token::EOI) {
          print $token->name, "\t";
          print $token->text, "\n";
        }
    
   # or 
        
        my $token = '';
        local *tokenizer = $lexer->getSub;
        while (($token = tokenizer()) ne $Token::EOI) {
          print $token->name, "\t";
          print $token->text, "\n";
        }

=item getToken

Same as C<token()> method.

=item hold EXPR

=item hold

Activates/deactivates saving of the consumed strings.  The return value
is the current setting (TRUE or FALSE).  Can be used as a class method.

You can obtain the contents of the buffer using the C<flush> method,
which also empties the buffer.

=item inclusive LIST

Class method declaring the conditions present in LIST to be I<inclusive>.

=item length EXPR

=item length

Returns the length of the current record.
C<length EXPR> sets the length of the current record.

=item line EXPR

=item line

Returns the line number of the current record.  C<line EXPR>
sets the value of the line number.  Always returns 1 if a character
string is being analyzed.  The C<readline()> method increments the
line number.

=item name EXPR

=item name

C<name EXPR> lets you give a name to the lexical analyzer.
C<name()> return the value of this name.

=item next

Causes searching for the next token. Return the recognized C<Parse::Token>
instance. Returns the C<Token::EOI> instance at the end of the data.

Examples:

        $lexer = Parse::Lex->new(@token);
        print $lexer->next->name;   # print the token type
        print $lexer->next->text;   # print the token content

=item nextis SCALAR_REF

Variant of the C<next()> method. Tokens are placed in
C<SCALAR_REF>. The method returns 1 as long as the token is not C<EOI>.

Example:

        while($lexer->nextis(\$token)) {
           print $token->text();
        }

=item new LIST

Creates and returns a new lexical analyzer. The argument of the method
is a list of C<Parse::Token> instances, or a list of triplets permitting
their creation.  The triplets consist of: the symbolic name of the token,
the regular expression necessary for its recognition, and possibly an
anonymous subroutine that is called when the token is recognized. For
each triplet, an instance of type C<Parse::Token> is created in the
calling package.

=item offset

Returns the number of characters already consumed since the beginning
of the analyzed data stream.

=item pos EXPR

=item pos

C<pos EXPR> sets the position of the beginning of the next token to
be recognized in the current line (this doesn't work with analyzers
of the C<Parse::CLex> class).  C<pos()> returns the number of
characters already consumed in the current line.

=item readline

Reads data from the input specified by the C<from()> method. Returns the
result of the reading.

Example:

        use Parse::Lex;

        $lexer = Parse::Lex->new();
        while (not $lexer->eoi) {
          print $lexer->readline() # read and print one line
        }

=item reset

Clears the internal buffer of the lexical analyzer and erases all tokens
already recognized.

=item restart

Reinitializes the analysis automaton. The only active condition becomes
the condition C<INITIAL>.

=item setToken TOKEN

Sets the token to C<TOKEN>. Useful to requalify a token inside the
anonymous subroutine associated with this token.

=item skip EXPR

=item skip

C<EXPR> is a regular expression defining the token separator pattern
(by default C<[ \t]+>). C<skip('')> sets this to no pattern.  With
no argument, C<skip()> returns the value of the pattern.
C<skip()> can be used as a class method.

Changing the skip pattern causes recompilation of the lexical analyzer.

Example:

  Parse::Lex->skip('\s*#(?s:.*)|\s+');
  @tokens = Parse::Lex->new('INTEGER' => '\d+')->analyze(\*DATA);
  print "@tokens\n"; # print INTEGER 1 INTEGER 2 INTEGER 3 INTEGER 4 EOI 
  __END__
  1 # first string to skip
  2
  3# second string to skip
  4


=item start EXPR

Activates condition EXPR.

=item state EXPR

Returns the state of the condition represented by EXPR.

=item token

Returns the instance corresponding to the last recognized token. In case
no token was recognized, return the special token named C<DEFAULT>.

=item tokenClass EXPR

=item tokenClass 

Indicates which is the class of the tokens to be created from the
list passed as argument to the C<new()> method.  If no argument is
given, returns the name of the class.  By default the class is
C<Parse::Token>.

=item trace OUTPUT

=item trace 

Class method which activates trace mode. The activation of trace mode
must take place before the creation of the lexical analyzer. The mode
can then be deactivated by another call of this method.

C<OUTPUT> can be a file name or a reference to a filehandle where the
trace will be redirected.

=back

=head1 ERROR HANDLING

To handle the cases of token non-recognition, you can define a
specific token at the end of the list of tokens that comprise our
lexical analyzer.  If searching for this token succeeds, it is
then possible to call an error handling function:

     qw(ERROR  (?s:.*)), sub {
       print STDERR "ERROR: buffer content->", $_[0]->lexer->buffer, "<-\n";
       die qq!can\'t analyze: "$_[1]"!;
     }

=head1 EXAMPLES

ctokenizer.pl - Scan a stream of data using the C<Parse::CLex> class.

tokenizer.pl - Scan a stream of data using the C<Parse::Lex> class.

every.pl - Use of the C<every> method.

sexp.pl - Interpreter for prefix arithmetic expressions.

sexpcond.pl - Interpeter for prefix arithmetic expressions, using conditions.

=head1 BUGS

Analyzers of the C<Parse::CLex> class do not allow the use of regular
expressions with anchoring.

=head1 SEE ALSO

C<Parse::Token>, C<Parse::LexEvent>, C<Parse::YYLex>.

=head1 AUTHOR

Philippe Verdret. Documentation translated to English by Vladimir
Alexiev and Ocrat.

=head1 ACKNOWLEDGMENTS

Version 2.0 owes much to suggestions made by Vladimir Alexiev.
Ocrat has significantly contributed to improving this documentation.
Thanks also to the numerous people who have sent me bug reports and
occasionally fixes.

=head1 REFERENCES

Friedl, J.E.F. Mastering Regular Expressions. O'Reilly & Associates
1996.

Mason, T. & Brown, D. - Lex & Yacc. O'Reilly & Associates, Inc. 1990.

FLEX - A Scanner generator (available at ftp://ftp.ee.lbl.gov/ and elsewhere)

=head1 COPYRIGHT

Copyright (c) 1995-1999 Philippe Verdret. All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

