
#include "tokenizer.h"
#include "forward_scan.h"
#include "unknown.h"

using namespace PPITokenizer;

static bool is_an_attribute(Tokenizer *t) {
	Token *prev1 = t->_last_significant_token(1);
	if ( prev1 == NULL )
		return false;
	if ( prev1->type->isa( Token_Attribute ) || prev1->type->isa( Token_Prototype ) )
		return true;
	if ( ! prev1->type->isa( Token_Word ) )
		return false;
	if ( ! strcmp( prev1->text, "sub" ) )
		return true;
	
	Token *prev2 = t->_last_significant_token(2);
	Token *prev3 = t->_last_significant_token(3);
	return ( ( prev2 != NULL ) && prev2->type->isa( Token_Word ) && ( !strcmp(prev2->text, "sub") ) &&
		( ( prev3 == NULL ) || ( prev3->type->isa( Token_Structure ) ) ) );
}

CharTokenizeResults UnknownToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	if ( token->length != 1 ) {
		sprintf(t->ErrorMsg, "Programmer ERROR: reached UnknownToken::tokenize with token lenght %d", token->length);
		return error_fail;
	}

	// is it control-character symbol (e.g. @{^_Foo})?
	// qr{^\^[[:upper:]_]\w+\}};
	PredicateAnd<
		PredicateIsChar< '^' >,
		PredicateFunc< is_upper_or_underscore >,
		PredicateOneOrMore< PredicateFunc< is_word > >,
		PredicateIsChar< '}' > > CurlyMagic;

	if ( token->text[0] == '*' ) {
		if ( is_letter(c_char) || ( c_char == '_' ) || ( c_char == ':' ) ) {
			Token *prev = t->_last_significant_token(1);
			if ( ( prev != NULL ) && ( ! prev->type->isa( Token_Number ) ) ) {
				t->changeTokenType( Token_Symbol );
				return my_char;
			}
		}

		if ( c_char == '{' ) {
			t->changeTokenType( Token_Cast );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}

		if ( c_char == '$' ) {
			TokenTypeNames type;
			Token *prev = t->_last_significant_token(1);
			if ( prev == NULL ) {
				type = Token_Cast;
			} else {
				AbstractTokenType *prev_type = prev->type;
				if ( prev_type->isa( Token_Symbol ) || prev_type->isa( Token_Number ) ) {
					type = Token_Operator;
				} else if ( prev_type->isa( Token_Structure ) && ( ( prev->text[0] == ')' ) || ( prev->text[0] == ']' ) ) ) {
					type = Token_Operator;
				} else {
					type = Token_Cast;
				}
			}
			t->changeTokenType( type );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}

		if ( ( c_char == '*' ) || ( c_char == '=' ) ) {
			t->changeTokenType( Token_Operator );
			return my_char;
		}

		t->changeTokenType( Token_Operator );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	if ( token->text[0] == '$' ) {
		if ( is_word( c_char ) ) {
			t->changeTokenType( Token_Symbol );
			return my_char;
		}

		token->text[ token->length ] = c_char;
		token->text[ token->length + 1 ] = 0;
		if ( t->is_magic( token->text ) ) {
			t->changeTokenType( Token_Magic );
			return my_char;
		}

		if ( c_char == '{' ) {
			unsigned long pos = t->line_pos + 1;
			if ( CurlyMagic.test( t->c_line, &pos, t->line_length ) ) {
				for ( unsigned long ix = t->line_pos; ix < pos; ix++ ) {
					token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
				}
				t->changeTokenType( Token_Magic );
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
		}

		t->changeTokenType( Token_Cast );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	if ( token->text[0] == '@' ) {
		if ( is_word( c_char ) || ( c_char == ':') ) {
			t->changeTokenType( Token_Symbol );
			return my_char;
		}
		if ( ( c_char == '-' ) || ( c_char == '+' ) || ( c_char == '*' ) ) {
			t->changeTokenType( Token_Magic );
			return my_char;
		}

		if ( c_char == '{' ) {
			unsigned long pos = t->line_pos + 1;
			if ( CurlyMagic.test( t->c_line, &pos, t->line_length ) ) {
				for ( unsigned long ix = t->line_pos; ix < pos; ix++ ) {
					token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
				}
				t->changeTokenType( Token_Magic );
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
		}

		t->changeTokenType( Token_Cast );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	if ( token->text[0] == '%' ) {
		if ( is_digit( c_char ) ) {
			t->changeTokenType( Token_Operator );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		token->text[ token->length ] = c_char;
		token->text[ token->length + 1 ] = 0;
		if ( ( c_char == '^' ) || t->is_magic( token->text ) ) {
			t->changeTokenType( Token_Magic );
			return my_char;
		}
		if ( is_word( c_char ) || ( c_char == ':') ) {
			t->changeTokenType( Token_Symbol );
			return my_char;
		}
		if ( c_char == '{' ) {
			unsigned long pos = t->line_pos + 1;
			if ( CurlyMagic.test( t->c_line, &pos, t->line_length ) ) {
				for ( unsigned long ix = t->line_pos; ix < pos; ix++ ) {
					token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
				}
				t->changeTokenType( Token_Magic );
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
		}
		if ( is_sigil( c_char ) || ( c_char == '{') ) {
			t->changeTokenType( Token_Cast );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		t->changeTokenType( Token_Operator );
		return done_it_myself;
	}

	if ( token->text[0] == '&' ) {
		if ( is_digit( c_char ) ) {
			t->changeTokenType( Token_Operator );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		if ( is_word( c_char ) || ( c_char == ':') ) {
			t->changeTokenType( Token_Symbol );
			return my_char;
		}
		if ( is_sigil( c_char ) || ( c_char == '{') ) {
			t->changeTokenType( Token_Cast );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		t->changeTokenType( Token_Operator );
		return done_it_myself;
	}

	if ( token->text[0] == '-' ) {
		if ( is_digit( c_char ) ) {
			t->changeTokenType( Token_Number );
			return my_char;
		}
		if ( c_char == '.' ) {
			t->changeTokenType( Token_Number_Float );
			return my_char;
		}
		if ( is_letter( c_char ) ) {
			t->changeTokenType( Token_DashedWord );
			return my_char;
		}
		t->changeTokenType( Token_Operator );
		return done_it_myself;
	}

	if ( token->text[0] == ':' ) {
		if ( c_char == ':' ) {
			t->changeTokenType( Token_Word );
			return my_char;
		}
		if ( is_an_attribute( t ) ) {
			t->changeTokenType( Token_Operator_Attribute );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		t->changeTokenType( Token_Operator );
		return done_it_myself;
	}
	sprintf(t->ErrorMsg, "ERROR: Failed to recognize token starting in %c%c in pos %d", token->text[0], c_char);
	return error_fail;
}

