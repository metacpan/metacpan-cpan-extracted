package Repl::Core::Parser;

use strict;

use Repl::Core::Buffer;
use Repl::Core::Token;
use Carp;
use Repl::Core::Pair;

# Parameters:
# - None.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $self = {};
    return bless($self, $class);
}

# Parameters:
# - A character buffer.
sub getNextToken
{
    my $self = shift;
    my $buffer = shift;
    
    if(exists $self->{PUSHBACK})
    {
        my $pushback = $self->{PUSHBACK};
        delete $self->{PUSHBACK};
        return $pushback;
    }
    
    if($buffer->eof())
    {
        return Repl::Core::Token->new(TYPE=>"eof" , VALUE=>"Unexpected end of expression encoutered.",
                          LINENO=>$buffer->getLineNo(), COLNO=>$buffer->getColNo());
    }
    
    # Keep track of the start of the token.
    my $line = $buffer->getLineNo;
    my $col = $buffer->getColNo;
    # We switch on the value of $char to see what we have to do next.
    my $char = $buffer->consumeChar;
    
    if("(" eq $char)
    {
        return Repl::Core::Token->new(TYPE=>"beginlist", VALUE=>"(", LINENO=>$line, COLNO=>$col);
    }
    elsif(")" eq $char)
    {
        return Repl::Core::Token->new(TYPE=>"endlist", VALUE=>")", LINENO=>$line, COLNO=>$col);
    }
    elsif("'" eq $char)
    {
        return Repl::Core::Token->new(TYPE=>"quote", VALUE=>"'", LINENO=>$line, COLNO=>$col);
    }
    elsif("=" eq $char)
    {
        return Repl::Core::Token->new(TYPE=>"pair", VALUE=>"=", LINENO=>$line, COLNO=>$col);
    }
    elsif($char =~ /\s/)
    {
        my @whitebuf = ($char);
        while(!$buffer->eof() && $buffer->peekChar() =~ /\s/)
        {
            push @whitebuf, $buffer->consumeChar();
        }
        return Repl::Core::Token->new(TYPE=>"whitespace", VALUE=>join("", @whitebuf), LINENO=>$line, COLNO=>$col);        
    }
    elsif(';' eq $char)
    {
        # Comments, skip until end of line.
        my $peek = $buffer->peekChar();
        while (!$buffer->eof() && "\n" ne $peek)
        {
            $buffer->consumeChar();
            $peek = $buffer->peekChar();
        }
        # Consume newline as well.
        $buffer->consumeChar() if("\n" eq $peek);
        return Repl::Core::Token->new(TYPE=>"whitespace", VALUE=>sprintf("<comment>"), LINENO=>$line, COLNO=>$col);        
    }
    elsif('"' eq $char)
    {
        # String literal encountered.
        # Support for '\\', '\"', '\n' and '\t'.
        # Note that the starting " is skipped, it is not added to the value.
        my @stringbuf = ();
        while(!$buffer->eof() && $buffer->peekChar() ne "\"")
        {
            if($buffer->peekChar() eq "\\")
            {
                # Consume the backslash.
                $buffer->consumeChar;
                if($buffer->peekChar() eq "n")
                {
                    # We found a newline.
                    push @stringbuf, "\n";
                    $buffer->consumeChar();
                    
                }
                elsif($buffer->peekChar() eq "\\")
                {
                    # We found a backslash.
                    push @stringbuf, "\\";
                    $buffer->consumeChar();                  
                }
                elsif($buffer->peekChar() eq "t")
                {
                    # We found a tab.
                    push @stringbuf, "\t";
                    $buffer->consumeChar();                    
                }
                elsif($buffer->peekChar() eq '"')
                {
                    # We found a double quote.
                    push @stringbuf, '"';
                    $buffer->consumeChar();
                }
                else
                {
                    # Strict version: it produces an error.
                    # return Repl::Core::Token->new(TYPE=>"error", VALUE=>sprintf("Unknown quoted character %s found in string constant.", $buffer->peekChar()), LINENO=>$line, COLNO=>$col);
                    
                    # Relaxed version: it copies the sequence
                    # if it cannot be transated into a code.
                    push @stringbuf, "\\";
                    push @stringbuf, $buffer->consumeChar();
                }                
            }
            else
            {
                push @stringbuf, $buffer->consumeChar();
            }            
        }
        
        # We examine the two finishing conditions of the preceding loop.
        # The string is complete OR  the buffer ended unexpectedly.
        if($buffer->eof())
        {
            # EOF encountered, open string ...
            return Repl::Core::Token->new(TYPE=>"eof", VALUE=>sprintf("Unclosed string encountered at line: %d, col: %d.",$line, $col), LINENO=>$line, COLNO=>$col);            
        }
        else
        {
            # The string ended the normal way.
            # Consume the closing ".
            $buffer->consumeChar();
            return Repl::Core::Token->new(TYPE=>"string", VALUE=>join("", @stringbuf), LINENO=>$line, COLNO=>$col);            
        }        
    }
    else
    {
        my @literalbuf = ($char);
        while(!$buffer->eof() && $buffer->peekChar() !~ m/[=\(\)\'\n\"\s;]/ )
        {
            push @literalbuf, $buffer->consumeChar();
        }
        return Repl::Core::Token->new(TYPE=>"string", VALUE=>join("", @literalbuf), LINENO=>$line, COLNO=>$col);        
    }
}

# Parameters
# - A token instance.
sub pushBackToken
{
    my $self = shift;
    my $token = shift;
    
    $self->{PUSHBACK} = $token;
}

# Parameters:
# - A character buffer.
sub getNextNonWhitespaceToken
{
    my $self = shift || confess "Expected a method call on a Parser object.";
    my $buffer = shift || confess "Expected 1 parameter, a Buffer object.";
    
    my $token = $self->getNextToken($buffer);
    $token = $self->getNextToken($buffer) while($token->isWhitespace());
    
    return $token;
}

# Parameters
# - A character buffer.
# Returns a token or an array of objects. A token result always indicates an error, parsing failed.
sub parseList
{
    my $self = shift;
    my $buffer = shift;
    
    my $token = $self->getNextNonWhitespaceToken($buffer);
    if($token->isErroneous())
    {
        return $token;
    }
    
    if($token->isBeginList())
    {
        my $line = $buffer->getLineNo();
        my $col = $buffer->getColNo();
        $token = $self->getNextNonWhitespaceToken($buffer);
        my @result = ();
        
        while(!$token->isErroneous() && !$token->isEndList())
        {
            $self->pushBackToken($token);
            my $expr = $self->parseExpression($buffer);
            if(UNIVERSAL::can($expr, 'isa') && $expr->isa("Repl::Core::Token"))
            {
                if($expr->isErroneous())
                {
                    return $expr;
                }
                else
                {
                    return Repl::Core::Token->new(TYPE=>"eof", VALUE=>"Syntax error in the list.", LINENO=>$line, COLNO=>$col);                    
                }                 
            } else
            {
                push @result, $expr;
            }
            
            $token = $self->getNextNonWhitespaceToken($buffer);
        }
        
        if($token->isErroneous())
        {
            return $token;
        }
        
        return \@result;
        
    } else
    {
        return Repl::Core::Token->new(TYPE=>"error", VALUE=>sprintf("Syntax error, expected '(' but encountered: %s.", $token->getValue()),
                          LINENO=>$buffer->getLineNo(), COLNO=>$buffer->getColNo());
    }
    
}

# Parameters
# - A character buffer.
sub parseExpression
{
    my $self = shift;
    my $buffer = shift;
    
    my $token = $self->getNextNonWhitespaceToken($buffer);
    
    if($token->isErroneous())
    {
       return $token; 
    }
    elsif($token->isBeginList() || $token->isString())
    {
        my $resultExpr;
        if($token->isBeginList())
        {
            # List found.
            $self->pushBackToken($token);
            $resultExpr = $self->parseList($buffer);
        }
        else
        {
            # String found.
            $resultExpr = $token->getValue();
        }
        
        # Return the error token on error.
        if(UNIVERSAL::can($resultExpr, 'isa') && $resultExpr->isa('Repl::Core::Token'))
        {
            return $resultExpr;
        }
        
        my $peek = $self->getNextNonWhitespaceToken($buffer);
        if($peek->isPair())
        {
            # Yes, pairing found.
            my $lvalueExpr = $self->parseExpression($buffer);
            return $lvalueExpr if(UNIVERSAL::can($lvalueExpr, 'isa') && $lvalueExpr->isa('Repl::Core::Token'));
            return Repl::Core::Pair->new(LEFT=>$resultExpr, RIGHT=>$lvalueExpr);                                              
        }
        else
        {
            # No pairing found.
            $self->pushBackToken($peek);
            return $resultExpr;
        }
    }
    elsif($token->isQuote())
    {
        my $peekToken = $self->getNextToken($buffer);
        $self->pushBackToken($peekToken);
        if(!$peekToken->isWhitespace())
        {
            my $expr = $self->parseExpression($buffer);
            if(UNIVERSAL::can($expr, 'isa' ) && $expr->isa("Repl::Core::Token"))
            {
                return $expr;
            } else
            {
                return ["quote", $expr];
            }            
        }
        else
        {
            return $peekToken->getValue();
        }
        
    } else 
    {
        return Repl::Core::Token->new(TYPE=>"error", VALUE=>sprintf("Syntax error, expected a string or a list but encountered %s.", $token->getValue()), LINENO=>$token->getLineNo(), COLNO=>$token=>getColNo());        
    }
}

# Parameters:
# - A string containing an expression.
sub parseString
{
    my $self = shift;
    my $sentence = shift;
    
    if(exists $self->{PUSHBACK})
    {
        my $pushback = $self->{PUSHBACK};
        delete $self->{PUSHBACK};
    }
    
    my $buffer = Repl::Core::Buffer->new(SENTENCE=>$sentence);
    return $self->parseExpression($buffer);
}

1;