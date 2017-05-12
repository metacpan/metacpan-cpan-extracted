#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tokenizer.h"
#include "forward_scan.h"
#include "whitespace.h"

using namespace PPITokenizer;

TokenTypeNames commit_map[128] = {
	Token_NoType, /* 0 */ Token_NoType, /* 1 */ Token_NoType, /* 2 */ Token_NoType, /* 3 */ 
	Token_NoType, /* 4 */ Token_NoType, /* 5 */ Token_NoType, /* 6 */ Token_NoType, /* 7 */ 
	Token_NoType, /* 8 */ Token_Whitespace, /* '9' */ Token_Whitespace, /* '10' */ Token_NoType, /* 11 */ 
	Token_NoType, /* 12 */ Token_Whitespace, /* '13' */ Token_NoType, /* 14 */ Token_NoType, /* 15 */ 
	Token_NoType, /* 16 */ Token_NoType, /* 17 */ Token_NoType, /* 18 */ Token_NoType, /* 19 */ 
	Token_NoType, /* 20 */ Token_NoType, /* 21 */ Token_NoType, /* 22 */ Token_NoType, /* 23 */ 
	Token_NoType, /* 24 */ Token_NoType, /* 25 */ Token_NoType, /* 26 */ Token_NoType, /* 27 */ 
	Token_NoType, /* 28 */ Token_NoType, /* 29 */ Token_NoType, /* 30 */ Token_NoType, /* 31 */ 
	Token_Whitespace, /* '32' */ Token_Operator, /* '!' */ Token_Quote_Double, /* '"' */ Token_Comment, /* '#' */ 
	Token_Unknown, /* '$' */ Token_Unknown, /* '%' */ Token_Unknown, /* '&' */ Token_Quote_Single, /* ''' */ 
	Token_NoType, /* 40 */ Token_Structure, /* ')' */ Token_Unknown, /* '*' */ Token_Operator, /* '+' */ 
	Token_Operator, /* ',' */ Token_NoType, /* 45 */ Token_Operator, /* '.' */ Token_NoType, /* 47 */ 
	Token_Number, /* '0' */ Token_Number, /* '1' */ Token_Number, /* '2' */ Token_Number, /* '3' */ 
	Token_Number, /* '4' */ Token_Number, /* '5' */ Token_Number, /* '6' */ Token_Number, /* '7' */ 
	Token_Number, /* '8' */ Token_Number, /* '9' */ Token_Unknown, /* ':' */ Token_Structure, /* ';' */ 
	Token_NoType, /* 60 */ Token_Operator, /* '=' */ Token_Operator, /* '>' */ Token_Operator, /* '?' */ 
	Token_Unknown, /* '@' */ Token_Word, /* 'A' */ Token_Word, /* 'B' */ Token_Word, /* 'C' */ 
	Token_Word, /* 'D' */ Token_Word, /* 'E' */ Token_Word, /* 'F' */ Token_Word, /* 'G' */ 
	Token_Word, /* 'H' */ Token_Word, /* 'I' */ Token_Word, /* 'J' */ Token_Word, /* 'K' */ 
	Token_Word, /* 'L' */ Token_Word, /* 'M' */ Token_Word, /* 'N' */ Token_Word, /* 'O' */ 
	Token_Word, /* 'P' */ Token_Word, /* 'Q' */ Token_Word, /* 'R' */ Token_Word, /* 'S' */ 
	Token_Word, /* 'T' */ Token_Word, /* 'U' */ Token_Word, /* 'V' */ Token_Word, /* 'W' */ 
	Token_Word, /* 'X' */ Token_Word, /* 'Y' */ Token_Word, /* 'Z' */ Token_Structure, /* '[' */ 
	Token_Cast, /* '\' */ Token_Structure, /* ']' */ Token_Operator, /* '^' */ Token_Word, /* '_' */ 
	Token_QuoteLike_Backtick, /* '`' */ Token_Word, /* 'a' */ Token_Word, /* 'b' */ Token_Word, /* 'c' */ 
	Token_Word, /* 'd' */ Token_Word, /* 'e' */ Token_Word, /* 'f' */ Token_Word, /* 'g' */ 
	Token_Word, /* 'h' */ Token_Word, /* 'i' */ Token_Word, /* 'j' */ Token_Word, /* 'k' */ 
	Token_Word, /* 'l' */ Token_Word, /* 'm' */ Token_Word, /* 'n' */ Token_Word, /* 'o' */ 
	Token_Word, /* 'p' */ Token_Word, /* 'q' */ Token_Word, /* 'r' */ Token_Word, /* 's' */ 
	Token_Word, /* 't' */ Token_Word, /* 'u' */ Token_Number_Version, /* 'v' */ Token_Word, /* 'w' */ 
	Token_NoType, /* 120 */ Token_Word, /* 'y' */ Token_Word, /* 'z' */ Token_Structure, /* '{' */ 
	Token_Operator, /* '|' */ Token_Structure, /* '}' */ Token_Operator, /* '~' */ Token_NoType, /* 127 */
};

// seeking to see if: ( $line =~ /^<(?!\d)\w+>/ )
// asumations: the current inspected char is '<'
static bool scan_ahead_for_lineread(const Tokenizer *t) {
	unsigned long pos = t->line_pos + 1;

	PredicateAnd<
		PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
		PredicateNot< PredicateFunc< is_digit > >,
		PredicateOneOrMore< PredicateFunc < is_word > >,
		PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
		PredicateIsChar<'>'>
	> regex;
	return regex.test(t->c_line, &pos, t->line_length);
}

CharTokenizeResults WhiteSpaceToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	if ( t->line_pos == 0 ) {
		// start of the line testings
		PredicateAnd<
			PredicateIsChar< '=' >,
			PredicateFunc< is_word >
		> regex1;
		unsigned long pos = 0;
		if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
			t->_finalize_token();
			t->_new_token( Token_Pod );
			return done_it_myself;
		}
		// FIXME: I'm not going to handle "use v6-alpha;" - Perl6 blocks
	}

	while ( t->line_pos < t->line_length ) {
		c_char = t->c_line[t->line_pos];
		if ( ( c_char >= 128 ) || ( commit_map[c_char] != Token_Whitespace ) )
			break;
		token->text[token->length++] = c_char;
		t->line_pos++;
	}
	if ( t->line_pos == t->line_length ) {
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

    if ( ( c_char < 128 ) && ( commit_map[c_char] != Token_NoType ) ) {
        // this is the first char of some token
		return t->TokenTypeNames_pool[commit_map[c_char]]->commit( t );
    }
	
	if (c_char == 40) { // '('
		Token *t0 = t->_last_significant_token(1);
		Token *t1 = t->_last_significant_token(2);
		Token *t2 = t->_last_significant_token(3);
		if ( ( t0 != NULL ) && ( t0->type->isa( Token_Word ) ) && 
			 ( t1 != NULL ) && ( t1->type->isa( Token_Word ) ) &&
			 ( !strcmp(t1->text, "sub") ) &&
			 ( ( t2 == NULL ) || ( t2->type->isa( Token_Structure ) ) ) ) {
			t->_new_token(Token_Prototype);
			return my_char;
		}

		if ( ( t0 != NULL ) && ( t0->type->isa( Token_Word ) ) && ( !strcmp(t0->text, "sub") ) ) {
			t->_new_token(Token_Prototype);
			return my_char;
		}
		t->_new_token(Token_Structure);
		return my_char;
	}
	
	if (c_char == 60) { // '<'
		Token *t0 = t->_last_significant_token(1);
		if ( t0 == NULL ) {
			t->_new_token(Token_Operator);
			return my_char;
		}
		TokenTypeNames t0_type = t0->type->type;
		if ( t0->type->isa( Token_Symbol ) || t0->type->isa( Token_Number ) ||
			 ( t0_type == Token_ArrayIndex ) ) {
			t->_new_token(Token_Operator);
			return my_char;
		}
		
		if ( t->c_line[ t->line_pos + 1 ] == '<' ) {
			// a HereDoc
			t->_new_token(Token_Operator);
			return my_char;
		}

		if ( ( ( t0_type == Token_Structure ) && ( !strcmp(t0->text, "(" ) ) ) ||
			 ( ( t0_type == Token_Word      ) && ( !strcmp(t0->text, "while" ) ) ) ||
			 ( ( t0_type == Token_Operator  ) && ( !strcmp(t0->text, "=" ) ) ) ||
			 ( ( t0_type == Token_Operator  ) && ( !strcmp(t0->text, "," ) ) ) ) {
			t->_new_token(Token_QuoteLike_Readline);
			return my_char;
		}

		if ( ( t0_type == Token_Structure ) && ( !strcmp(t0->text, "}" ) ) ) {
			if ( scan_ahead_for_lineread(t) ) {
				t->_new_token(Token_QuoteLike_Readline);
				return my_char;
			}
		}

		t->_new_token(Token_QuoteLike_Readline);
		return my_char;
	}

	if (c_char == 47) { // '/'
		Token *t0 = t->_last_significant_token(1);
		if (t0 == NULL) {
			t->_new_token(Token_Regexp_Match_Bare);
			return my_char;
		}
		if ( t0->type->isa( Token_Operator ) ) { 
			t->_new_token(Token_Regexp_Match_Bare);
			return my_char;
		}
		if ( t0->type->isa( Token_Symbol ) || t0->type->isa( Token_Number ) ||
			 ( t0->type->isa( Token_Structure ) && ( !strcmp(t0->text, "]" ) ) ) ) { 
			t->_new_token(Token_Operator);
			return my_char;
		}
		if ( t0->type->isa( Token_Structure ) && 
			( ( !strcmp(t0->text, "(") ) || ( !strcmp(t0->text, "{") ) || ( !strcmp(t0->text, ";") ) ) ) {
			t->_new_token(Token_Regexp_Match_Bare);
			return my_char;
		}
		if ( t0->type->isa( Token_Word ) && 
			 ( ( !strcmp(t0->text, "split") ) || 
			   ( !strcmp(t0->text, "if") ) || 
			   ( !strcmp(t0->text, "unless") ) || 
			   ( !strcmp(t0->text, "grep") ) ) ) {
			t->_new_token(Token_Regexp_Match_Bare);
			return my_char;
		}

		unsigned char n_char = t->c_line[ t->line_pos + 1 ];
		if ( ( n_char == '^' ) || ( n_char == '[' ) || ( n_char == '\\' ) ) {
			t->_new_token(Token_Regexp_Match);
			return my_char;
		}

		t->_new_token(Token_Operator);
		return my_char;
	}

	if ( c_char == 'x' ) {
		unsigned char n_char = t->c_line[ t->line_pos + 1 ];
		Token *t0 = t->_last_significant_token(1);
		if ( ( t0 != NULL ) && ( n_char >= '0' ) && ( n_char <= 9 ) ) {
			TokenTypeNames p_type = t0->type->type;
			if ( ( p_type == Token_Quote_Single ) || ( p_type == Token_Quote_Double ) ) { // FIXME
				t->_new_token(Token_Operator);
				return my_char;
			}
		}
		return t->TokenTypeNames_pool[Token_Word]->commit( t );
	}

	if ( c_char == '-' ) {
		if ( t->_opcontext() == ooc_Operator ) {
			t->_new_token(Token_Operator);
			return my_char;
		} else {
			t->_new_token(Token_Unknown);
			return my_char;
		}
	}

	// FIXME: Add the c_char > 127 part?

	sprintf(t->ErrorMsg, "Error: charecter rejected: %d at pos %d", c_char, t->line_pos);
    return error_fail;
}

extern const char end_pod[] = "=cut";
CharTokenizeResults PodToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// will enter here only on the line's start, but not nessesery on byte 0.
	// there may be a BOM before it.
	PredicateLiteral< 4, end_pod > regex;
	unsigned long pos = t->line_pos;
	// suck the line anyway
	for ( unsigned long ix = pos; ix < t->line_length; ix++ ) {
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	if ( regex.test( t->c_line, &pos, t->line_length ) &&
		( ( pos >= t->line_length ) || is_whitespace( t->c_line[ pos ] ) ) ) {
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
	}
	return done_it_myself;
}

CharTokenizeResults EndToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// will always reach here in a new line
	PredicateAnd<
		PredicateIsChar< '=' >,
		PredicateFunc< is_word >
	> regex1;
	unsigned long pos = 0;
	if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
		t->_finalize_token();
		t->_new_token( Token_Pod );
		return done_it_myself;
	}
	// if not Pod - just copy the whole line to myself
	while ( t->line_length > t->line_pos ) {			
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	return done_it_myself;
}

CharTokenizeResults DataToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// copy everything anytime
	while ( t->line_length > t->line_pos ) {			
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	return done_it_myself;
}

CharTokenizeResults CommentToken::commit(Tokenizer *t) {
	if (( t->c_token != NULL ) && 
		( t->c_token->type->type == Token_Whitespace ) &&
		( t->c_token->length == t->line_pos ) ) {
		// This is a whole-line comment, that should own the whitespace before
		// and the newline after it.
		t->changeTokenType(Token_Comment);
		Token *c_token = t->c_token;
	    
		while ( ( t->line_pos < t->line_length ) ) {
			c_token->text[c_token->length++] = t->c_line[t->line_pos++];
		}
	} else {
		// This is an inline comment - not contains the newline
		t->_new_token(Token_Comment);
		Token *c_token = t->c_token;
	    
		while ( ( t->line_pos < t->line_length ) && ( t->c_line[t->line_pos] != t->local_newline ) ) {
			c_token->text[c_token->length++] = t->c_line[t->line_pos++];
		}
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults CommentToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	token->text[token->length++] = c_char;
	if (t->line_pos >= t->line_length) {
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
	}
	return done_it_myself;
}
