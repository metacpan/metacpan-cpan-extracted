# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the RDF::Core module
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 2001 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package RDF::Core::Query;

use strict;
require Exporter;


use Carp;

use Exporter;
use vars qw(@ISA @EXPORT_OK @EXP_SYNTAX %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXP_SYNTAX = qw(Q_QUERY Q_RESULTSET Q_SOURCE Q_SOURCEPATH Q_HASTARGET
		 Q_TARGET Q_CONDITION Q_NAMESPACE Q_MATCH Q_PATH
		 Q_CLASS Q_BINDING Q_ELEMENTS Q_ELEMENTPATH Q_ELEMENT
		 Q_FUNCTION Q_NODE Q_VARIABLE Q_URIDEF Q_NAME Q_EXPRESSION
		 Q_CONNECTION Q_RELATION Q_OPERATION Q_LITERAL Q_URI 
                 Q_SUBSTITUTION);
@EXPORT_OK = (@EXP_SYNTAX);
%EXPORT_TAGS = (syntax => \@EXP_SYNTAX);

# token types
use constant TOK_NONE     => 'TOK_NONE';
use constant TOK_END      => 'TOK_END';

use constant TOK_LITERAL  => 'TOK_LITERAL';
use constant TOK_VAR      => 'TOK_VAR';
use constant TOK_URI      => 'TOK_URI';
use constant TOK_NAME     => 'TOK_NAME';
use constant TOK_COMMENT  => 'TOK_COMMENT';
use constant TOK_SUBSTITUTION  => 'TOK_SUBSTITUTION';

use constant TOK_CLASS    => 'TOK_CLASS';
use constant TOK_MATCH    => 'TOK_MATCH';

use constant TOK_LPAREN   => 'TOK_LPAREN';
use constant TOK_RPAREN   => 'TOK_RPAREN';
use constant TOK_LCUR     => 'TOK_LCUR';
use constant TOK_RCUR     => 'TOK_RCUR';
use constant TOK_PERIOD   => 'TOK_PERIOD';
use constant TOK_COMMA    => 'TOK_COMMA';
use constant TOK_COLON    => 'TOK_COLON';
use constant TOK_PIPE     => 'TOK_PIPE';
use constant TOK_EQ       => 'TOK_EQ';
use constant TOK_NEQ      => 'TOK_NEQ';
use constant TOK_LE       => 'TOK_LE';
use constant TOK_LT       => 'TOK_LT';
use constant TOK_GE       => 'TOK_GE';
use constant TOK_GT       => 'TOK_GT';

use constant TOK_SELECT   => 'TOK_SELECT';
use constant TOK_WHERE    => 'TOK_WHERE';
use constant TOK_FROM     => 'TOK_FROM';
use constant TOK_USE      => 'TOK_USE';
use constant TOK_FOR      => 'TOK_FOR';
use constant TOK_AND      => 'TOK_AND';
use constant TOK_OR       => 'TOK_OR';

#query syntax elements

use constant Q_QUERY        => 'QUERY';
use constant Q_RESULTSET    => 'RESULTSET';
use constant Q_SOURCE       => 'SOURCE';
use constant Q_SOURCEPATH   => 'SOURCEPATH';
use constant Q_HASTARGET    => 'HASTARGET';
use constant Q_TARGET       => 'TARGET';
use constant Q_CONDITION    => 'CONDITION';
use constant Q_NAMESPACE    => 'NAMESPACE';
use constant Q_MATCH        => 'MATCH';
use constant Q_PATH         => 'PATH';
use constant Q_CLASS        => 'CLASS';
use constant Q_BINDING      => 'BINDING';
use constant Q_ELEMENTS     => 'ELEMENTS';
use constant Q_ELEMENTPATH  => 'ELEMENTPATH';
use constant Q_ELEMENT      => 'ELEMENT';
use constant Q_FUNCTION     => 'FUNCTION';
use constant Q_NODE         => 'NODE';
use constant Q_VARIABLE     => 'VARIABLE';
use constant Q_URIDEF       => 'URIDEF';
use constant Q_NAME         => 'NAME';
use constant Q_EXPRESSION   => 'EXPRESSION';
use constant Q_CONNECTION   => 'CONNECTION';
use constant Q_RELATION     => 'RELATION';
use constant Q_OPERATION    => 'OPERATION';
use constant Q_LITERAL      => 'LITERAL';
use constant Q_URI          => 'URI';
use constant Q_SUBSTITUTION => 'SUBSTITUTION';

sub new {
    my ($pkg,%options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_options} = \%options;
    bless $self, $pkg;
}

sub getOptions {
    my $self = shift;
    return $self->{_options};
}

sub query {
    my ($self, $queryString) = @_;
    my @tokens = $self->_tokenize($queryString);
    $self->_parse (\@tokens);
    $self->_syntaxTree($self->{+Q_QUERY}[0],50,'')
      if $self->getOptions->{Debug};
    return $self->getOptions->{Evaluator}->evaluate($self->{+Q_QUERY}[0]);
}
sub prepare {
    my ($self, $queryString) = @_;
    my @tokens = $self->_tokenize($queryString);
    $self->_parse (\@tokens);
    $self->_syntaxTree($self->{+Q_QUERY}[0],50,'')
      if $self->getOptions->{Debug};
    return $self->{+Q_QUERY}[0];
}
sub execute {
    my ($self, $substitutions, $query) = @_;
    $query ||= $self->{+Q_QUERY}[0];
    return $self->getOptions->{Evaluator}->evaluate($query, $substitutions);
}

sub _tokenize {
    #Translate query string into an array of tokens
    #token's properties: type, value

    my ($self, $queryString) = @_;
    print "Tokenizing $queryString"
      if $self->getOptions->{Debug};
    my @tokens;
    my $pos = 0;
    my $lastToken = -1;
    until ($lastToken eq TOK_END || $lastToken eq TOK_NONE) {
	my $token = $self->_nextToken(\$queryString,\$pos);
	unless ($token->{type} eq TOK_COMMENT) {
	    push @tokens, $token;
	    $lastToken = $token->{type};
	}
    }
    return @tokens;
}
sub _nextToken {
    my ($self, $str, $pos) = @_;
    my $retVal;
    $retVal->{type} = TOK_NONE;
    
    #skip blank spaces
    while (substr($$str, $$pos, 1) =~ /\s/) {
	$$pos++;
    }
    
    my $firstChar = substr($$str, $$pos, 1);
    my $secondChar = substr($$str, $$pos + 1, 1);
    
    print "\ngetting next token at pos $$pos, from ",substr ($$str, $$pos, 20)
      if $self->getOptions->{Debug};
    
    if ($firstChar eq '') {
	$retVal->{type} = TOK_END;
    } elsif ($firstChar eq '(') {
	$retVal->{type} = TOK_LPAREN;
	$retVal->{value} = $firstChar;
	$$pos++;
    } elsif ($firstChar eq ')') {
	$retVal->{type} = TOK_RPAREN;
	$retVal->{value} = $firstChar;
	$$pos++;
    } elsif ($firstChar eq '{') {
	$retVal->{type} = TOK_LCUR;
	$retVal->{value} = $firstChar;
	$$pos++;
    } elsif ($firstChar eq '}') {
	$retVal->{type} = TOK_RCUR;
	$retVal->{value} = $firstChar;
	$$pos++;
    } elsif ($firstChar eq ',') {
	$retVal->{type} = TOK_COMMA;
	$retVal->{value} = $firstChar;
	$$pos++;
    } elsif ($firstChar eq '|') {
	$retVal->{type} = TOK_PIPE;
	$retVal->{value} = $firstChar;
	$$pos++;
    } elsif ($firstChar eq '=') {
	if ($secondChar eq '>') {
	    $retVal->{type} = TOK_MATCH;
	    $retVal->{value} = $firstChar.$secondChar;
	    $$pos += 2;
	} else {
	    $retVal->{type} = TOK_EQ;
	    $retVal->{value} = $firstChar;
	    $$pos++;
	}
    } elsif ($firstChar eq '-') {
	if ($secondChar eq '>') {
	    $retVal->{type} = TOK_PERIOD;
	    $retVal->{value} = $firstChar.$secondChar;
	    $$pos += 2;
	} elsif ($secondChar eq '-') {
	    $retVal->{type} = TOK_COMMENT;
	    $retVal->{value} = $self->_str2Token($str, $pos, $retVal->{type})
	}
    } elsif ($firstChar eq '<') {
	if ($secondChar eq '=') {
	    $retVal->{type} = TOK_LE;
	    $retVal->{value} = $firstChar.$secondChar;
	    $$pos += 2;
	} else {
	    $retVal->{type} = TOK_LT;
	    $retVal->{value} = $firstChar;
	    $$pos++;
	}
    } elsif ($firstChar eq '>') {
	if ($secondChar eq '=') {
	    $retVal->{type} = TOK_GE;
	    $retVal->{value} = $firstChar.$secondChar;
	    $$pos += 2;
	} else {
	    $retVal->{type} = TOK_GT;
	    $retVal->{value} = $firstChar;
	    $$pos++;
	}
    } elsif ($firstChar eq ':') {
	if ($secondChar eq ':') {
	    $retVal->{type} = TOK_CLASS;
	    $retVal->{value} = $firstChar.$secondChar;
	    $$pos += 2;
	} else {
	    $retVal->{type} = TOK_COLON;
	    $retVal->{value} = $firstChar;
	    $$pos++;
	}
    } elsif (substr ($$str, $$pos, 7) =~ /select\W/i) {
	$retVal->{type} = TOK_SELECT;
	$retVal->{value} = substr ($$str, $$pos, 6);
	$$pos += 6;
    } elsif (substr ($$str, $$pos, 6) =~ /where\W/i) {
	$retVal->{type} = TOK_WHERE;
	$retVal->{value} = substr ($$str, $$pos, 5);
	$$pos += 5;
    } elsif (substr ($$str, $$pos, 5) =~ /from\W/i) {
	$retVal->{type} = TOK_FROM;
	$retVal->{value} = substr ($$str, $$pos, 4);
	$$pos += 4;
    } elsif (substr ($$str, $$pos, 4) =~ /use\W/i) {
	$retVal->{type} = TOK_USE;
	$retVal->{value} = substr ($$str, $$pos, 3);
	$$pos += 3;
    } elsif (substr ($$str, $$pos, 4) =~ /for\W/i) {
	$retVal->{type} = TOK_FOR;
	$retVal->{value} = substr ($$str, $$pos, 3);
	$$pos += 3;
    } elsif (substr ($$str, $$pos, 4) =~ /and\W/i) {
	$retVal->{type} = TOK_AND;
	$retVal->{value} = substr ($$str, $$pos, 3);
	$$pos += 3;
    } elsif (substr ($$str, $$pos, 3) =~ /or\W/i) {
	$retVal->{type} = TOK_OR;
	$retVal->{value} = substr ($$str, $$pos, 2);
	$$pos += 2;
    } elsif (substr ($$str, $$pos, 2) =~ /!=/i) {
	$retVal->{type} = TOK_NEQ;
	$retVal->{value} = substr ($$str, $$pos, 2);
	$$pos += 2;
    } elsif ($firstChar eq '"' || $firstChar eq '\'') {
	$retVal->{type} = TOK_LITERAL;
	$retVal->{value} = $self->_str2Token($str, $pos, $retVal->{type});
    } elsif ($firstChar eq '?' || $firstChar eq '$') {
	$retVal->{type} = TOK_VAR;
	$retVal->{value} = $self->_str2Token($str, $pos, $retVal->{type});
    } elsif ($firstChar eq '#') {
	$retVal->{type} = TOK_SUBSTITUTION;
	$retVal->{value} = $self->_str2Token($str, $pos, TOK_VAR);
    } elsif ($firstChar eq '[') {
	$retVal->{type} = TOK_URI;
	$retVal->{value} = $self->_str2Token($str, $pos, $retVal->{type});
    } elsif ($firstChar =~ /\w/) {
	$retVal->{type} = TOK_NAME;
	$retVal->{value} = $self->_str2Token($str, $pos, $retVal->{type});
    } elsif ($firstChar eq '/' && $secondChar eq '*') {
	$retVal->{type} = TOK_COMMENT;
	$retVal->{value} = $self->_str2Token($str, $pos, $retVal->{type})
    } else {
	$retVal->{type} = TOK_NONE;
	$retVal->{value} = $firstChar;
	$$pos++;
	
    } 
    
    return $retVal;
}
sub _str2Token {
    my ($self, $str, $pos, $tokenType) = @_;
    my $retVal;
    if ($tokenType eq TOK_LITERAL) {
	my $quote = substr ($$str, $$pos, 1);
	my $subpos = $$pos ;
	my $escaped = '';
	my $found = 0;
	while (defined(my $char = substr ($$str, ++$subpos, 1))) {
	    if ($char eq $quote && !$escaped) {
		$found = $subpos;
		last;
	    } else {
		if (!($char eq "\\") || $escaped) {
		    $retVal .= $char;
		}
	    }
	    if ($char eq "\\") {
		$escaped = !$escaped;
	    } else {
		$escaped = '';
	    }
	}
	unless ($found) {
	    croak "Syntax error: Infinite literal at position ".$$pos
	      ."\n".substr ($$str, $$pos,30);
	}
	$$pos = ++$subpos;
    } elsif ($tokenType eq TOK_URI) {
	my $delim = "]";
	my $subpos = $$pos ;
	my $found = 0;
	while (defined (my $char = substr ($$str, ++$subpos, 1))) {
	    if ($char eq $delim) {
		$found = $subpos;
		last;
	    } else {
		$retVal .= $char;
	    }
	}
	unless ($found) {
	    croak "Syntax error: Infinite URI at position ".$$pos
	      ."\n".substr ($$str, $$pos,30);
	}
	$$pos = ++$subpos;
    } elsif ($tokenType eq TOK_VAR) {
	$retVal = substr ($$str, $$pos++,1);
	$retVal .= $self->_str2Token($str, $pos, TOK_NAME);
    } elsif ($tokenType eq TOK_NAME) {
	my $subpos = $$pos ;
	if (substr ($$str, $subpos ,1) =~ /[a-zA-Z_]/ ) {
	    $retVal = substr ($$str, $subpos,1);
	} else {
	    croak "Syntax error: Invalid name at position ".$$pos
	      ."\n".substr ($$str, $$pos,30);
	}
	while (defined (my $char = substr ($$str, ++$subpos, 1))) {
	    if ($char =~ /[a-zA-Z0-9_]/) {
		$retVal .= $char;
	    } else {
		last;
	    }
	}
	$$pos = $subpos;
    } elsif ($tokenType eq TOK_COMMENT) {
	my $delim;
	my $delimLength;

	if (substr ($$str, $$pos, 2) eq '/*') {
	    $delim = "*/";
	    $delimLength = 2;
	} else {
	    $delim = "\n";
	    $delimLength = 1;
	}
	my $subpos = $$pos ;
	my $found = 0;
	while (defined (my $char = substr ($$str, ++$subpos, $delimLength))) {
	    if ($char eq $delim) {
		$found = $subpos;
		last;
	    } else {
		$retVal .= $char;
	    }
	}
	unless ($found || $delim eq "\n") {
	    croak "Syntax error: Infinite comment at position ".$$pos
	      ."\n".substr ($$str, $$pos,30);
	}
	$$pos = $subpos += $delimLength;
    }
    return $retVal;
}
sub _parse {
    my ($self, $tokens) = @_;
    
    #init query tree
    delete $self->{+Q_QUERY};
    my @context = ([Q_QUERY, 0]);
    my @rndParens;		#keep track of which parenthesis you are in
    $self->_treeNode(\@context);
    
    for (my $i = 0; $i < @$tokens; $i++) {
	my $token = $tokens->[$i];
	#debug############################################################
	if ($self->getOptions->{Debug}) {
	    use Data::Dumper;
	    print Dumper @context;
	    print "TOKEN: ",$token->{value}, "\n";
	}
	##################################################################
	if ($token->{type} eq TOK_NONE) {
	    _errSyntax ($tokens, $i, \@context, "Token not recognized");
	} elsif ($token->{type} eq TOK_END) {
	} elsif ($token->{type} eq TOK_LITERAL) {
	    until ( @context == 0 || 
		    @context[@context - 1]->[0] eq Q_TARGET ||
		    @context[@context - 1]->[0] eq Q_ELEMENTPATH ||
		    @context[@context - 1]->[0] eq Q_PATH ||
		    @context[@context - 1]->[0] eq Q_EXPRESSION) {
		pop @context;
	    }
	    if (@context > 0) {
		#we might have expected Q_ELEMENT, let's remove it now 
		my $node = $self->_treeNode(\@context);
		#TODO: $node should point to an empty structure, raise error 
		# if there is a token value in it
		# $node->{elements}[0]{element} = [] is ok
		# $node->{elements}[0]{element} = [{node}...] is not ok
		
		undef %$node;
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	    
	    if (@context[@context - 1]->[0] eq Q_TARGET || 
		@context[@context - 1]->[0] eq Q_PATH || 
		@context[@context - 1]->[0] eq Q_ELEMENTPATH) {
		
		my $node = $self->_treeNodeAppend(\@context, Q_EXPRESSION);
		$node = $self->_treeNodeAppend(\@context, Q_EXPRESSION);
		$node->{+Q_LITERAL}->[0] = $token->{value};
		pop @context;	#Q_EXPRESSION (inner)
	    } elsif (@context[@context - 1]->[0] eq Q_EXPRESSION) {
		#just add literal
		my $node = $self->_treeNode(\@context);
		$node->{+Q_LITERAL}->[0] = $token->{value};
		pop @context	#Q_EXPRESSION
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_VAR) {
	    if (@context[@context - 1]->[0] eq Q_BINDING) {
		#variable binding
		my $node = $self->_treeNodeAppend(\@context, Q_VARIABLE);
		$node->{+Q_NAME}->[0] = $token->{value};
		pop @context;   #Q_VARIABLE
	    } elsif (@context[@context - 1]->[0] eq Q_ELEMENT) {
		my $node = $self->_treeNodeAppend(\@context, Q_VARIABLE);
		$node->{+Q_NAME}->[0] = $token->{value};
		pop @context;	#Q_VARIABLE
		pop @context;	#Q_ELEMENT
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_URI) {
            
            if (@context[@context - 1]->[0] eq Q_ELEMENT) {
		my $node = $self->_treeNodeAppend(\@context, Q_NODE);
		$node->{+Q_URI}->[0] = $token->{value};
		pop @context;	#Q_NODE
                pop @context;	#Q_ELEMENT
	    } elsif (@context[@context - 1]->[0] eq Q_NAMESPACE) {
		my $node = $self->_treeNode(\@context);
		my $index = defined $node->{+Q_URI} ? @{$node->{+Q_URI}} : 0;
		$node->{+Q_URI}->[$index] = $token->{value};
            } else {
                _errSyntax ($tokens, $i, \@context, "Unexpected token");                
            }
	} elsif ($token->{type} eq TOK_SUBSTITUTION) {
	    
	    if (@context[@context - 1]->[0] eq Q_ELEMENT) {
		my $node = $self->_treeNodeAppend(\@context, Q_SUBSTITUTION);
		$node->{+Q_NAME}->[0] = $token->{value};
		pop @context;	#Q_SUBSTITUTION
		pop @context;	#Q_ELEMENT
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_NAME) {
	    if (@context[@context - 1]->[0] eq Q_ELEMENT) {
		if ($tokens->[$i+1]->{type} eq TOK_LPAREN) {
		    my $node = $self->_treeNodeAppend(\@context, Q_FUNCTION);
		    $node->{+Q_NAME}->[0] = $token->{value};
		} else {
		    my $node = $self->_treeNodeAppend(\@context, Q_NODE);
		    $node->{+Q_NAME}->[0] = $token->{value};
		    unless ($tokens->[$i+1]->{type} eq TOK_COLON) {
			pop @context; #Q_NODE
			pop @context; #Q_ELEMENT
		    }
		}
	    } elsif (@context[@context - 1]->[0] eq Q_NODE) {
		my $node = $self->_treeNode(\@context);
		my $index = @{$node->{+Q_NAME}};
		_errSyntax ($tokens, $i, \@context, "Invalid node")
		  if $index > 1;
		$node->{+Q_NAME}->[$index] = $token->{value};
		unless ($tokens->[$i+1]->{type} eq TOK_COLON) {
		    pop @context; #Q_NODE
		    pop @context; #Q_ELEMENT
		}
	    } elsif (@context[@context - 1]->[0] eq Q_NAMESPACE) {
		my $node = $self->_treeNode(\@context);
		my $index = defined $node->{+Q_NAME} ? @{$node->{+Q_NAME}} : 0;
		$node->{+Q_NAME}->[$index] = $token->{value};
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_CLASS) {
  	    until ( @context == 0 || 
  		    @context[@context - 1]->[0] eq Q_PATH ||
  		    @context[@context - 1]->[0] eq Q_SOURCEPATH) {
  		pop @context;
  	    }
  	    if (@context > 0) {
		#move node into Q_CLASS
		#move one level up in the tree and get parent node
		my $pathType = pop @context;  
		my $pathNode = $self->_treeNode(\@context);
		my $node = $pathNode->{$pathType->[0]}[$pathType->[1]];
		delete $pathNode->{$pathType->[0]}[$pathType->[1]];
		#move back one level down
		push @context, $pathType;
		my $class = $self->_treeNodeAppend(\@context, Q_CLASS);
		%$class = %$node;
		pop @context;	#Q_CLASS
  		$self->_treeNodeAppend(\@context, Q_ELEMENTS)
  		  if $pathType->[0] eq Q_PATH;
  		$self->_treeNodeAppend(\@context, Q_ELEMENT);
  	    } else {
  		_errSyntax ($tokens, $i, \@context, "Unexpected token");
  	    }
	} elsif ($token->{type} eq TOK_MATCH) {
	    until (@context == 0 || @context[@context - 1]->[0] eq Q_SOURCEPATH) {
		pop @context
	    }
	    if (@context > 0) {
		my $node = $self->_treeNode(\@context);
		$node->{+Q_HASTARGET}->[0] = 1;
		$self->_treeNodeAppend(\@context, Q_TARGET);
		$self->_treeNodeAppend(\@context, Q_ELEMENT);
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_LPAREN) {
	    if (@context[@context - 1]->[0] eq Q_CONDITION) {
		# look ahead to specify context
		my $pos = $i;
		my $depth = 1;
		my %significant;
		while (1) {
		    $pos++;
		    my $tok = $tokens->[$pos];
		    if ($tok->{type} eq TOK_END) {
			_errSyntax ($tokens, $i, \@context, "Unclosed parenthesis");
			last;
		    }
		    if ($depth == 1 &&
			$tok->{type} eq TOK_COMMA ||
			$tok->{type} eq TOK_AND ||
			$tok->{type} eq TOK_OR ||
			$tok->{type} eq TOK_LITERAL ||
			$tok->{type} eq TOK_PIPE ||
			$tok->{type} eq TOK_PERIOD
		       ) {
			$significant{$tok->{type}} = 1;
		    }
		    $depth++ if $tok->{type} eq TOK_LPAREN;
		    $depth-- if $tok->{type} eq TOK_RPAREN;
		    last unless $depth;
		}
		#look one more token ahead
		if ($tokens->[$pos+1]{type} eq TOK_CLASS) {
		    $significant{+TOK_CLASS} = 1;
		} 
		if (exists $significant{+TOK_COMMA} ||
		    exists $significant{+TOK_CLASS}) {
		    #elements
		    push @rndParens, Q_ELEMENTS;
		    $self->_treeNodeAppend(\@context,Q_MATCH);
		    $self->_treeNodeAppend(\@context,Q_PATH);
		    $self->_treeNodeAppend(\@context,Q_ELEMENTS);
		    $self->_treeNodeAppend(\@context,Q_ELEMENT);
		} elsif (exists $significant{+TOK_AND} ||
			 exists $significant{+TOK_OR}) {
		    #condition 
		    push @rndParens, Q_CONDITION;
		    $self->_treeNodeAppend(\@context, Q_CONDITION);
		    unless ($tokens->[$i+1]->{type} eq TOK_LPAREN) {
			$self->_treeNodeAppend(\@context,Q_MATCH);
			$self->_treeNodeAppend(\@context,Q_PATH);
			$self->_treeNodeAppend(\@context,Q_ELEMENTS);
			$self->_treeNodeAppend(\@context,Q_ELEMENT);
		    }
		} elsif (	#exists $significant{+TOK_LITERAL} ||
			 exists $significant{+TOK_PIPE}) {
		    #expression
		    push @rndParens, Q_EXPRESSION;
		    $self->_treeNodeAppend(\@context, Q_EXPRESSION);
		} else {
		    #condition again
		    push @rndParens, Q_CONDITION;
		    $self->_treeNodeAppend(\@context, Q_CONDITION);
		    unless ($tokens->[$i+1]->{type} eq TOK_LPAREN) {
			$self->_treeNodeAppend(\@context,Q_MATCH);
			$self->_treeNodeAppend(\@context,Q_PATH);
			$self->_treeNodeAppend(\@context,Q_ELEMENTS);
			$self->_treeNodeAppend(\@context,Q_ELEMENT);
		    }
		}
		
		
		############################################################
		
	    } elsif (@context[@context - 1]->[0] eq Q_EXPRESSION) {
		push @rndParens, Q_EXPRESSION;
		$self->_treeNodeAppend(\@context, Q_EXPRESSION);
	    } elsif (@context[@context - 1]->[0] eq Q_FUNCTION) {
		push @rndParens, Q_FUNCTION;
		$self->_treeNodeAppend(\@context, Q_ELEMENTPATH);
		$self->_treeNodeAppend(\@context,Q_ELEMENT);
	    } elsif (@context[@context - 1]->[0] eq Q_ELEMENT) {
		if (@context[@context - 2]->[0] eq Q_ELEMENTS) {
		    push @rndParens, Q_ELEMENTS;		
		} else {
		    # we expected element but found expression
		    until ( @context == 0 || 
			    @context[@context - 1]->[0] eq Q_TARGET ||
			    @context[@context - 1]->[0] eq Q_ELEMENTPATH ||
			    @context[@context - 1]->[0] eq Q_PATH ||
			    @context[@context - 1]->[0] eq Q_EXPRESSION) {
			pop @context;
		    }
		    if (@context > 0) {
			my $node = $self->_treeNode(\@context);
			undef %$node;
		    } else {
			_errSyntax ($tokens, $i, \@context, 
				    "Unexpected token");
		    }
		    $self->_treeNodeAppend(\@context, Q_EXPRESSION);
		    $self->_treeNodeAppend(\@context, Q_EXPRESSION);
		    push @rndParens, Q_EXPRESSION;
		}
	    }
	} elsif ($token->{type} eq TOK_RPAREN) {
	    #Q_CONDITION, Q_ELEMENTS, Q_FUNCTION, Q_EXPRESSION
	    my $lastIn = pop @rndParens;
	    my $item = pop @context;
	    until ( @context == 0 || 
		    $item->[0] eq $lastIn) {
		$item = pop @context;
	    }
	    if (@context > 0) {
		pop @context	#element
		  if $item->[0] eq Q_FUNCTION;
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	    
	} elsif ($token->{type} eq TOK_LCUR) {
	    if (@context[@context - 1]->[0] eq Q_SOURCEPATH) {
		#variable binding
		my $node = $self->_treeNode(\@context);
		my $index = @{$node->{+Q_ELEMENT}} -1;
		push @context, [Q_BINDING, $index];
		#	    } elsif (@context[@context - 2]->[0] eq Q_SOURCEPATH &&
		#		     @context[@context - 1]->[0] eq Q_CLASS) {
		#		#variable binding in Class expression
		#		my $node = $self->_treeNodeAppend(\@context, Q_BINDING);
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	    
	} elsif ($token->{type} eq TOK_RCUR) {
	    until (@context == 0 ||
		   @context[@context - 1]->[0] eq Q_BINDING
		  ) {
		pop @context;
	    }
	    ;
	    pop @context;	#Q_BINDING
	    
	} elsif ($token->{type} eq TOK_PERIOD) {
	    if (@context[@context - 1]->[0] eq Q_ELEMENTPATH ||
		@context[@context - 1]->[0] eq Q_SOURCEPATH) {
		$self->_treeNodeAppend(\@context, Q_ELEMENT);
	    } elsif (@context[@context - 1]->[0] eq Q_ELEMENTS ||
		     @context[@context - 1]->[0] eq Q_PATH) {
		#Q_ELEMENTS is to be removed (or anything up to Q_PATH)
		until (@context == 0 || @context[@context-1]->[0] eq Q_PATH) {
		    pop @context;
		}
		
		$self->_treeNodeAppend(\@context, Q_ELEMENTS);
		$self->_treeNodeAppend(\@context, Q_ELEMENT);
		#	    } elsif (@context[@context - 1]->[0] eq Q_CLASS) {
		#		#Q_CLASS is to be removed and then decide whether Q_ELEMENTS
		#		#should be added
		#		pop @context;  #Q_CLASS
		#		$self->_treeNodeAppend(\@context, Q_ELEMENTS)
		#		  if @context[@context - 1]->[0] eq Q_PATH;
		#		$self->_treeNodeAppend(\@context, Q_ELEMENT);
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");
	    }
	} elsif ($token->{type} eq TOK_COMMA) {
	    if (@context[@context - 1]->[0] eq Q_EXPRESSION) {
		pop @context;	#Q_EXPRESSION
	    }
	    if (@context[@context - 1]->[0] eq Q_TARGET) {
		pop @context;	#Q_TARGET
	    }
	    #	    if (@context[@context - 1]->[0] eq Q_CLASS) {
	    #		#finish Q_CLASS and continue with some PATH
	    #		pop @context;  #Q_CLASS
	    #	    }
	    if (@context[@context - 1]->[0] eq Q_ELEMENTPATH ||
		@context[@context - 1]->[0] eq Q_SOURCEPATH) {
		my $type = @context[@context - 1]->[0];
		pop @context;	#$type
		$self->_treeNodeAppend(\@context, $type);
		$self->_treeNodeAppend(\@context,Q_ELEMENT);
	    } elsif (@context[@context - 1]->[0] eq Q_ELEMENTS) {
		$self->_treeNodeAppend(\@context, Q_ELEMENT);
	    } elsif (@context[@context - 1]->[0] eq Q_NAMESPACE) {
	    } elsif (@context[@context - 1]->[0] eq Q_BINDING) {
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");
	    }
	} elsif ($token->{type} eq TOK_PIPE) {
	    if (@context[@context - 1]->[0] eq Q_EXPRESSION) {
		my $node = $self->_treeNode(\@context);
		$node->{+Q_OPERATION} = [] unless exists $node->{+Q_OPERATION};
		my $index = @{$node->{+Q_OPERATION}};
		$node->{+Q_OPERATION}->[$index] = $token->{value};
		$self->_treeNodeAppend(\@context, Q_EXPRESSION);
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_COLON) {
	    unless (@context[@context - 1]->[0] eq Q_NODE) {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_EQ ||
		 $token->{type} eq TOK_NEQ||
		 $token->{type} eq TOK_LE ||
		 $token->{type} eq TOK_LT ||
		 $token->{type} eq TOK_GE ||
		 $token->{type} eq TOK_GT) {
	    until (@context == 0 || @context[@context - 1]->[0] eq Q_MATCH) {
		pop @context
	    }
	    if (@context > 0) {
		my $node = $self->_treeNode(\@context);
		$node->{+Q_RELATION}->[0] = $token->{value};
		$self->_treeNodeAppend(\@context, Q_PATH);
		$self->_treeNodeAppend(\@context, Q_ELEMENTS);
		$self->_treeNodeAppend(\@context, Q_ELEMENT);
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	    
	} elsif ($token->{type} eq TOK_SELECT) {
	    if (@context[@context - 1]->[0] eq Q_QUERY) {
		$self->_treeNodeAppend(\@context, Q_RESULTSET);
		$self->_treeNodeAppend(\@context, Q_ELEMENTPATH);
		$self->_treeNodeAppend(\@context, Q_ELEMENT); 
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_FROM) {
	    until (@context == 0 || @context[@context - 1]->[0] eq Q_QUERY) {
		pop @context
	    }
	    if (@context > 0) {
		$self->_treeNodeAppend(\@context, Q_SOURCE);
		$self->_treeNodeAppend(\@context, Q_SOURCEPATH);
		$self->_treeNodeAppend(\@context, Q_ELEMENT);
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_WHERE) {
	    until (@context == 0 || @context[@context - 1]->[0] eq Q_QUERY) {
		pop @context
	    }
	    if (@context > 0) {
		$self->_treeNodeAppend(\@context,Q_CONDITION);
		$self->_treeNodeAppend(\@context,Q_CONDITION);
		unless ($tokens->[$i+1]->{type} eq TOK_LPAREN) {
		    $self->_treeNodeAppend(\@context,Q_MATCH);
		    $self->_treeNodeAppend(\@context,Q_PATH);
		    $self->_treeNodeAppend(\@context, Q_ELEMENTS);
		    $self->_treeNodeAppend(\@context, Q_ELEMENT);
		}
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_USE) {
	    until (@context == 0 || @context[@context - 1]->[0] eq Q_QUERY) {
		pop @context
	    }
	    if (@context > 0) {
		$self->_treeNodeAppend(\@context, Q_NAMESPACE);
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	} elsif ($token->{type} eq TOK_FOR) {
	} elsif ($token->{type} eq TOK_AND ||
		 $token->{type} eq TOK_OR) {
	    
	    until (@context == 0 ||
		   @context[@context - 1]->[0] eq Q_CONDITION 
		   #|| @context[@context - 1]->[0] eq Q_MATCH
		  ) {
		pop @context;
	    }
	    if (@context > 0) {
		pop @context;	#Q_CONDITION 
		my $node = $self->_treeNode(\@context);
		$node->{+Q_CONNECTION} = [] unless exists $node->{+Q_CONNECTION};
		my $index = @{$node->{+Q_CONNECTION}};
		$node->{+Q_CONNECTION}->[$index] = $token->{value};
		$self->_treeNodeAppend(\@context, Q_CONDITION);
		unless ($tokens->[$i+1]->{type} eq TOK_LPAREN) {
		    $self->_treeNodeAppend(\@context,Q_MATCH);
		    $self->_treeNodeAppend(\@context,Q_PATH);
		    $self->_treeNodeAppend(\@context, Q_ELEMENTS);
		    $self->_treeNodeAppend(\@context, Q_ELEMENT);
		}
	    } else {
		_errSyntax ($tokens, $i, \@context, "Unexpected token");		
	    }
	}
    }
}

sub _treeNode {
    my ($self, $context) = @_;
    #@$context example: ([Q_QUERY, 0],
    #    		 [Q_RESULTSET, 0],
    #			 [Q_ELEMENTPATH, 2])

    my $node = $self;
    foreach (@$context) {
	if (exists $node->{$_->[0]}->[$_->[1]]) {
	    $node = $node->{$_->[0]}->[$_->[1]];
	} else {
	    $node = $node->{$_->[0]}->[$_->[1]] = {};
	}
	
    }
    return $node;
}

sub _treeNodeAppend {
    my ($self, $context, $name) = @_;

    my $node = $self->_treeNode($context);
    $node->{$name} = [] unless defined $node->{$name};
    my $lastIndex = @{$node->{$name}} - 1;
    push @$context, [$name, ++$lastIndex];
    return $self->_treeNode($context);
}
sub _syntaxTree {
    #dump parsed query 
    my ($self, $node, $depth, $indent) = @_;
    if ($depth > 0) {
	if (ref $node) {
	    foreach (keys %$node) {
		print "\n",$indent,$_;
		for (my $i = 0; $i < @{$node->{$_}};$i++) {
		    #		print $i;
		    print "\n--$i--" if $i;
		    $self->_syntaxTree($node->{$_}->[$i], $depth-1, $indent.'    ');
		}
	    }
	} else {
	    print "\n",$indent,$node;
	}
    } else {
	if (ref $node) {
	    foreach (keys %$node) {
		for (my $i = 0; $i < @{$node->{$_}};$i++) {
		    $self->_syntaxTree($node->{$_}->[$i], $depth-1, $indent.'    ');
		}
	    }
	} else {
	    print " $node";
	}
    }
}
############################################################
# Utils

sub _errSyntax {
    my ($tokens, $i, $context, @message) = @_;
    croak 'Syntax error near ',join (' ', $tokens->[$i-2]->{value},
				    $tokens->[$i-1]->{value},
				    "<$tokens->[$i]->{value}>",
				    $tokens->[$i+1]->{value},
				    $tokens->[$i+2]->{value}), "\n", @message;
}


1;
__END__

=head1 NAME

RDF::Core::Query - Implementation of query language

=head1 SYNOPSIS

  my %namespaces = (Default => 'http://myApp.gingerall.org/ns#',
                    ns     => 'http://myApp.gingerall.org/ns#',
		   );
  sub printRow {
    my (@row) = @_;
	    
    foreach (@row) {
	my $label = defined($_) ? $_->getLabel : 'NULL';
	print $label, ' ';
    }
    print "\n";
  }

  my $functions = new RDF::Core::Function(Data => $model,
	  				  Schema => $schema,
					  Factory => $factory,
					 );

  my $evaluator = new RDF::Core::Evaluator
    (Model => $model,            #an instance of RDF::Core::Model
     Factory => $factory,        #an instance of RDF::Core::NodeFactory
     Functions => $functions,
     Namespaces => \%namespaces,
     Row => \&printRow
    );

  my $query = new RDF::Core::Query(Evaluator=> $evaluator);

  $query->query("Select ?x->title 
                 From store->book{?x}->author{?y} 
                 Where ?y = 'Lewis'");

=head1 DESCRIPTION

Query module together with RDF::Core::Evaluator and RDF::Core::Function implements a query language. A result of a query is a set of handler calls, each call corresponding to one row of data returned.

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * Evaluator

RDF::Core::Evaluator object.

=back

=item * query($queryString)

Evaluates $queryString. Returns an array reference, each item containing one resulting row. There is an option Row in RDF::Core::Evaluator, which contains a function to handle a row returned from query. If the handler is set, it is called for each row of the result and no result array is returned. Parameters of the handler are RDF::Core::Resource or RDF::Core::Literal or undef values.

=item * prepare($queryString)

Prepares parsed query from $queryString. The string can contain external variables - names with hash prepended (#name), which are bound to values in execute().

=item * execute(\%bindings,$parsedQuery)

Executes prepared query. If $parsedQuery is not supplied, the last prepared/executed/queried query is executed. Binding hash must contain value for each external variable used. The value is RDF::Core::Resource or RDF::Core::Literal object.

=back

=head2 Query language

Query language has three major parts, beginning with B<select>, B<from> and B<where> keywords. The B<select> part specifies which "columns" of data should be returned. The B<from> part defines the pattern or path in the graph I'm searching for and binds variables to specific points of the path. The B<where> part specifies conditions that each path found must conform.  

Let's start in midst, with B<from> part:

  Select ?x from ?x->ns:author

This will find all resources that have property ns:author. We can chain properties:

  Select ?x from ?x->ns:author->ns:name

This means find all resources that have property ns:author and value of the property has property ns:name. We can bind values to variables to refer them back:

  Select ?x, ?authorName from ?x->ns:author{?authorID}->ns:name{?authorName}

This means find the same as in the recent example and bind ?authorID variable to author value and ?authorName to name value. The variable is bound to a value of property, not property itself. If there is a second variable bound, it's bound to property itself:

  Select ?x from ?x->ns:author{?authorID}->ns:name{?authorName,?prop}

The variable ?authorName will contain a name of an author, while ?prop variable will contain an uri of ns:name property. This kind of binding can be useful with function calls (see below).

If there is more then one path specified, the result must satisfy all of them. Common variables represent the same value, describing how the paths are joined together. If there are no common variables in two paths, cartesian product is produced.

  Select ?x 
  From ?x->ns:author{?author}->ns:name{?name}, 
       ?author->ns:birth{?birth}

B<Target element.> The value of the last property in the path can be specified:

  Select ?x from ?x->ns:author->ns:name=>'Lewis'


B<Class expression.> Class of the starting element in the path can be specified:

  Select ?x from ns:Book::?x->ns:author

which is equivalent to 

  Select ?x from ?x->ns:author, ?x->rdf:type=>ns:Book

supposing we have defined namespace rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'. (See B<Names and URIs> paragraph later in the text.)

B<Condition.> Now we described data we talk about and let's put more conditions on them in B<where> section:

  Select ?x 
  From ?x->ns:author{?author}->ns:name{?name}, ?author->ns:birth{?birth}
  Where ?name = 'Lewis' And  ?birth->ns:year < '1900'

This means: get all paths in the graph described in B<from> section and exclude those that don't conform the condition. Only variables declared in B<from> section can be used, binding is not allowed in condition. 

In condition, each element (resource, predicate or value) can be replaced with a list of variants. So we may ask:

  Select ?x 
  From ?x->ns:author{?author}
  Where ?author->(ns:book,ns:booklet,ns:article)->ns:published < '1938'

and it means

  Select ?x 
  From ?x->ns:author{?author}, ?author->ns:birth{?birth}
  Where ?author->ns:book.published < '1938'
     Or ?author->ns:booklet.published < '1938'
     Or ?author->ns:article.published < '1938'

The list of variants can be combined with class expression:

  Select ?x 
  From ?x->ns:author{?author}
    Where (clss:Writer, clss:Teacher)::?author->ns:birth < '1900'

and it means

  ...
  Where (?author->rdf:type = clss:Writer 
         Or ?author->rdf:type = clss:Teacher) 
    And ?author->ns:birth < '1900' 

B<Resultset.>  The B<select> section describes how to output each path found. We can think of a path as a n-tuple of values bound to variables.

  Select ?x->ns:title, ?author->ns:name 
  From ?x->ns:author{?author}
    Where (clss:Writer, clss:Teacher)::?author->ns:birth < '1900'


For each n-tuple [?x, ?author] conforming the query ?x->ns:title and ?author->ns:name are evaluated and the pair of values is returned as one row of the result. If there is no value for ?x->ns:title, undef is returned instead of the value. If there are more values for one particular ?x->ns:title, all of them are returned in cartesian product with ?author->ns:name.

B<Names and URIs>

'ns:name' is a shortcut for URI. Each B<prefix:name> is evaluated to URI as B<prefix value> concatenated with B<name>. If prefix is not present, prefix B<Default> is taken. There are two ways to assign a namespace prefix to its value. You can specify prefix and its value in Evaluator's option Namespaces. This is a global setting, which applies to all queries evaluated by Query object. Locally you can set namespaces in each select, using B<USE> clause. This overrides global settings for the current select. URIs can be typed explicitly in square brackets. The following queries are equivalent:

  Select ?x from ?x->[http://myApp.gingerall.org/ns#name]

  Select ?x from ?x->ns:name
  Use ns For [http://myApp.gingerall.org/ns#]

B<Functions>

Functions can be used to obtain custom values for a resource. They accept recources or literals as parameters and return set of resources or literals. They can be used in place of URI or name. If they are at position of property, they get resource as a special parameter and what they return is considered to be a value of the expression rather then 'real' properties.

Let's have function foo() that always returns resource with URI http://myApp.gingerall.org/ns#foo. The expression

  ?x->foo()

evaluates to  

  [http://myApp.gingerall.org/ns#foo], 

not 

  ?x->[http://myApp.gingerall.org/ns#foo]

Now we can restate the condition with variants to a condition with a function call.

  Select ?x 
  From ?x->ns:author{?author}
  Where ?author->subproperty(ns:publication)->ns:published < '1938'

We consider we have apropriate schema where book, booklet, article etc. are (direct or indirect) rdfs:subPropertyOf publication.

The above function does this: search schema for subproperties of publication and return value of the subproperty. Sometimes we'd like to know not only value of that "hidden" property, but the property itself. Again, we can use a multiple binding. In following example we get uri of publication in ?publication and uri of property (book, booklet, article, ...) in ?property.

  Select ?publication, ?property
  From ?author->subproperty(ns:publication){?publication, ?property}
  Where ?publication->ns:published < '1938'

B<Comments.>

Comments are prepended with two dashes (to end of line or string), or enclosed in slash asterisk parenthesis /*...*/.

  Select ?publication, ?property --the rest of line is a comment
  From ?author->subproperty(publication){?publication, ?property}
  Where /*another
          comment*/ ?publication->published < '1938'


=head2 A BNF diagram for query language

  <query>	::= Select <resultset> From <source> [Where <condition>]
                    ["Use" <namespaces>]
  <resultset>	::= <elementpath>{","<elementpath>}
  <source>	::= <sourcepath>{","<sourcepath>}
  <sourcepath>	::= [<element>[ "{" <variable> "}" ]"::"]
                    <element>[ "{" <variable> "}" ]
                    {"->"<element>[ "{" <variable> [, <variable>]"}" ]} 
		    ["=>"<element> | <expression>]
  <condition>	::= <match> | <condition> <connection> <condition> 
                    {<connection> <condition>} 
		    | "(" <condition> ")"
  <namespaces>  ::= <name> ["For"] "["<uri>"]" { "," <name> [for] "["<uri>"]"}
  <match>	::= <path> [<relation> <path>]
  <path>	::= [<elements>"::"]<elements>{"->"<elements>} | <expression>
  <elements>	::= <element> | "(" <element>  {"," <element>} ")"
  <elementpath>	::= <element>{"->"<element>} | <expression>
  <element>	::= <variable> | <node> | <function> 
  <function>	::= <name> "(" <elementpath>["," <elementpath>] ")"
  <node>	::= "[" <uri> "]" | "[" "_:" <name> "]" | [<name>":"]<name>
  <variable>	::= "?"<name>
  <name>	::= [a-zA-Z_][a-zA-Z0-9_]
  <expression>	::= <literal> | <expression> <operation> <expression> 
                    {<operation> <expression>}
		    | "(" <expression> ")"
  <connection>	::= and | or
  <relation>	::= "=" | "<" | ">"
  <operation>	::= "|"
  <literal>	::= """{any_character}""" | "'"{any_character}"'" 
  <uri>		::= absolute uri resource, see uri specification


=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Evaluator, RDF::Core::Function

=cut

