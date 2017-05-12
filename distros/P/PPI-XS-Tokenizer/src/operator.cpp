#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"
#include "forward_scan.h"
#include "operator.h"

using namespace PPITokenizer;

AttributeOperatorToken::AttributeOperatorToken() : OperatorToken() {
	type = Token_Operator_Attribute;
}

bool inline is_quote(char c) {
	return ( ( c == '\'' ) || ( c == '"' ) || ( c == '`' ) );
}

CharTokenizeResults OperatorToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	token->text[token->length] = c_char;
	token->text[token->length+1] = '\0';

	if ( t->is_operator( token->text ) )
		return my_char;

	token->text[token->length] = '\0';

	if ( ( !strcmp( token->text, ".") ) && ( is_digit(c_char) ) ) {
		t->changeTokenType(Token_Number_Float);
		return done_it_myself;
	}

	if ( !strcmp( token->text, "<<") ) {
		// parsing:  $line =~ /^(?: (?!\d)\w | \s*['"`] | \\\w ) /x 
		static PredicateOr<
			PredicateAnd<
				PredicateNot< PredicateFunc< is_digit > >,
				PredicateFunc< is_word > >,
			PredicateAnd<
				PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
				PredicateFunc< is_quote > >,
			PredicateAnd<
				PredicateIsChar<'\\'>,
				PredicateFunc< is_word > >
		> regex;
		unsigned long pos = t->line_pos;
		if ( regex.test(t->c_line, &pos, t->line_length) ) {
			t->changeTokenType(Token_HereDoc);
			return done_it_myself;
		}
	}

	if ( !strcmp( token->text, "<>") ) {
		t->changeTokenType(Token_QuoteLike_Readline);
	}
 
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

// in a heredoc token:
//   'state' is 0 means that the heredoc is broken, while 1 means it OK.
//   'modifiers.close_char' is the type of the heredoc, where:
//		0 - interpolate ( <<HERE or <<"HERE" )
//		1 - literal ( <<'HERE' or <<\HERE )
//		2 - command ( <<`HERE` )
bool detect_heredoc(Tokenizer *t, unsigned long &start_key, unsigned long &stop_key, unsigned long &pos, int &heredoc_type);
CharTokenizeResults HereDocToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// we are one the first char after the "<<"
	// /^( \s* (?: "[^"]*" | '[^']*' | `[^`]*` | \\?\w+ ) )/x 
	unsigned long pos = t->line_pos;
	unsigned long start_key = pos, stop_key = pos;
	int heredoc_type;
	bool found = detect_heredoc(t, start_key, stop_key, pos, heredoc_type);
	if ( !found ) {
		// fall back to operator
		t->changeTokenType( Token_Operator );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}
	// is a here-doc. suck it.
	while ( t->line_pos < pos ) {
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}

	ExtendedToken *exToken = (ExtendedToken *)token;
	exToken->current_section = 1;
	exToken->sections[0].position = 0;
	exToken->sections[0].size = exToken->length;
	exToken->modifiers.position = start_key - (t->line_pos - exToken->length);
	exToken->modifiers.size = stop_key - start_key;
	exToken->modifiers.close_char = heredoc_type;
	exToken->sections[1].position = exToken->length;
	exToken->sections[1].size = 0;
	TokenTypeNames zone = t->_pospond_token();
	t->_new_token( zone );
	return done_it_myself;
}

bool detect_heredoc(Tokenizer *t, unsigned long &start_key, unsigned long &stop_key, unsigned long &pos, int &heredoc_type) {
	PredicateOneOrMore< PredicateFunc< is_word > > regex1;
	if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
		stop_key = pos;
		heredoc_type = 0;
		return true;
	}

	PredicateZeroOrMore< PredicateFunc< is_whitespace > > regex2;
	regex2.test( t->c_line, &pos, t->line_length );
	start_key = pos;

	PredicateAnd< 
		PredicateIsChar< '"' >,
		PredicateZeroOrMore< PredicateIsNotChar< '"' > >,
		PredicateIsChar< '"' > > regex5;
	if ( regex5.test( t->c_line, &pos, t->line_length ) ) {
		start_key += 1;
		stop_key = pos - 1;
		heredoc_type = 0;
		return true;
	} 

	PredicateAnd< 
		PredicateIsChar< '\'' >,
		PredicateZeroOrMore< PredicateIsNotChar< '\'' > >,
		PredicateIsChar< '\'' > > regex6;
	if ( regex6.test( t->c_line, &pos, t->line_length ) ) {
		start_key += 1;
		stop_key = pos - 1;
		heredoc_type = 1;
		return true;
	}

	PredicateAnd< 
		PredicateIsChar< '`' >,
		PredicateZeroOrMore< PredicateIsNotChar< '`' > >,
		PredicateIsChar< '`' > > regex7;
	if ( regex7.test( t->c_line, &pos, t->line_length ) ) {
		start_key += 1;
		stop_key = pos - 1;
		heredoc_type = 2;
		return true;
	}

	PredicateAnd< 
		PredicateIsChar< '\\' >,
		PredicateOneOrMore< PredicateFunc< is_word > > > regex4;
	if ( regex4.test( t->c_line, &pos, t->line_length ) ) {
		start_key += 1;
		stop_key = pos;
		heredoc_type = 1;
		return true;
	}

	return false;
}

bool inline is_newline( char c ) {
	return ( (  c == 10 ) || (  c == 13 ) );
}

HeredocBodyStates HereDocToken::Unpospone( Tokenizer *t, ExtendedToken *self, const char *line, unsigned long length) {
	// will reach here only in the beginning of a line
	ExtendedToken::section &key = self->modifiers;
	ExtendedToken::section &value = self->sections[ 1 ];
	PredicateFunc< is_newline > regex1;
	unsigned long pos = key.size;
	self->current_section = 2;

	// copy this line anyway
	unsigned long ix = 0;
	while ( length > ix ) {
		self->text[self->length++] = line[ ix++ ];
	}
	value.size += length;

	if ( ( length > key.size ) && 
		 ( !strncmp( line, &self->text[ key.position ], key.size  ) ) &&
		 regex1.test( line, &pos, length ) ) {
		// found end line
		self->state = 1;
		self->text[self->length] = '\0';
		return heredocbody_ended;
	}
	return heredocbody_still_in_effect;
}
