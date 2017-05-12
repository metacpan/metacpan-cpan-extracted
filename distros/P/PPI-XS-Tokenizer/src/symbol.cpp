#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tokenizer.h"
#include "forward_scan.h"
#include "symbol.h"

using namespace PPITokenizer;

	//$content =~ /^(
	//	[\$@%&*]
	//	(?: : (?!:) | # Allow single-colon non-magic vars
	//		(?: \w+ | \' (?!\d) \w+ | \:: \w+ )
	//		(?:
	//			# Allow both :: and ' in namespace separators
	//			(?: \' (?!\d) \w+ | \:: \w+ )
	//		)*
	//		(?: :: )? # Technically a compiler-magic hash, but keep it here
	//	)
	//)/x or return undef;
// assumation - the first charecter is a sigil, and the length >= 1
static bool oversuck(char *text, unsigned long length, unsigned long *new_length) {
	static PredicateOr <
		PredicateAnd < 
			PredicateIsChar<':'>, PredicateNot< PredicateIsChar<':'> > >,
		PredicateAnd< 
			PredicateOr<
				PredicateOneOrMore< PredicateFunc< is_word > >,
				PredicateAnd< 
					PredicateIsChar<'\''>, 
					PredicateNot< PredicateFunc< is_digit > >,
					PredicateOneOrMore< PredicateFunc< is_word > > >,
				PredicateAnd< 
					PredicateIsChar<':'>, 
					PredicateIsChar<':'>, 
					PredicateOneOrMore< PredicateFunc< is_word > > > >,
			PredicateZeroOrMore<
				PredicateOr<
					PredicateAnd< 
						PredicateIsChar<'\''>, 
						PredicateNot< PredicateFunc< is_digit > >,
						PredicateOneOrMore< PredicateFunc< is_word > > >,
					PredicateAnd< 
						PredicateIsChar<':'>, 
						PredicateIsChar<':'>, 
						PredicateOneOrMore< PredicateFunc< is_word > > > > >,
			PredicateZeroOrOne< 
				PredicateAnd< 
					PredicateIsChar<':'>, 
					PredicateIsChar<':'> > >
		> > regex;
	return regex.test( text, new_length, length );
}

CharTokenizeResults SymbolToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// Suck in till the end of the symbol
	while ( is_word(c_char) || ( c_char == ':' ) || ( c_char == '\'' ) ) {
			 token->text[token->length++] = t->c_line[t->line_pos++];
			 c_char = t->c_line[t->line_pos];
	}
	token->text[token->length] = '\0';
	// token ended: let's see what we have got

	// Handle magic things
	if ( ( token->length == 2 ) && ( !strcmp(token->text, "@_") || !strcmp(token->text, "$_"))) {
		token->type = t->TokenTypeNames_pool[Token_Magic];
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}
	
	// Shortcut for most of the X:: symbols
	if ( ( token->length == 3 ) && ( !strcmp(token->text, "$::") )) {
		// May well be an alternate form of a Magic
		if ( t->c_line[t->line_pos] == '|' ) {
			token->text[token->length++] = c_char = t->c_line[t->line_pos++];
			token->type = t->TokenTypeNames_pool[Token_Magic];
		}
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	// examine the first charecther
	int first_is_sigil = 0;
	if ( token->length >= 1 ) {
		char first = token->text[0];
		if ( first == '$' ) {
			first_is_sigil = 3;
		} else if ( first == '@' ) {
			first_is_sigil = 2;
		}
		else if ( ( first == '%' ) || ( first == '*' ) ||  ( first == '&' ) ) {
			first_is_sigil = 1;
		}
	}

	// checking: $content =~ /^[\$%*@&]::(?:[^\w]|$)/
	if ( token->length >= 3 ) {
		if ( ( first_is_sigil != 0 ) && ( token->text[1] == ':' ) && ( token->text[2] == ':' ) ) {
			if ( ( token->length == 3 ) || ( ! is_word(token->text[3]) ) ) {
				t->line_pos = t->line_pos - token->length + 3;
				token->length = 3;
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
		}
	}

	// checking $content =~ /^(?:\$|\@)\d+/
	if ( ( token->length >= 2 ) && ( first_is_sigil > 1 ) ) {
		char second = token->text[1];
		if ( ( second >= '0' ) && ( second <= '9' ) ) {
			token->type = t->TokenTypeNames_pool[Token_Magic];
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
	}

	if ( first_is_sigil != 0 ) {
		unsigned long new_length = 1;
		bool ret = oversuck(token->text, token->length, &new_length);
		if ( false == ret ) {
			sprintf(t->ErrorMsg, "ERROR: Symbol oversuck protection does not identify the token as symbol. pos=%d", t->line_pos);
			return error_fail;
		}
		if ( new_length != token->length ) {
			t->line_pos -= token->length - new_length;
			token->length = new_length;
		}
	}

	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

bool inline is_word_colon_tag( char c ) {
	return ( is_word(c) || ( c == ':' ) || ( c == '\'' ) );
}

CharTokenizeResults ArrayIndexToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	PredicateOneOrMore< PredicateFunc< is_word_colon_tag > > regex;
	unsigned long pos = t->line_pos;
	if ( regex.test( t->c_line, &pos, t->line_length ) ) {
		for ( unsigned long ix = t->line_pos; ix < pos; ix++ ) {
			token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
		}
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults MagicToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	token->text[ token->length ] = c_char;
	if ( token->text[0] == '$' ) {
		unsigned long pos = 1;
		unsigned long nlen = token->length + 1;
		// /^\$\'[\w]/ 
		PredicateAnd<
			PredicateIsChar< '\'' >,
			PredicateFunc< is_word > > regex1;
		if (regex1.test( token->text, &pos, nlen)) {
			if (is_digit(c_char)) {
				// we have $'\d, and the magic part is only $'
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
			t->changeTokenType( Token_Symbol );
			return done_it_myself;
		}
		// /^(\$(?:\_[\w:]|::))/ 
		PredicateOr< 
			PredicateAnd<
				PredicateIsChar< '_' >,
				PredicateOr<
					PredicateFunc< is_word >,
					PredicateIsChar< ':' > > >,
			PredicateAnd<
				PredicateIsChar< ':' >,
				PredicateIsChar< ':' > > > regex2;
		if (regex2.test( token->text, &pos, nlen)) {
			t->changeTokenType( Token_Symbol );
			return done_it_myself;
		}

		// /^\$\$\w/
		PredicateAnd<
			PredicateIsChar< '$' >,
			PredicateFunc< is_word > > regex3;
		if (regex3.test( token->text, &pos, nlen )) {
			// dereferencing
			t->changeTokenType( Token_Cast );
			token->length = 1;
			t->_finalize_token();
			t->_new_token( Token_Symbol );
			t->c_token->text[0] = '$';
			t->c_token->length = 1;
			return done_it_myself;
		}

		if ( ( nlen == 3 ) && ( strncmp(token->text, "$${", 3) == 0 ) ) {
			// check for $${^MATCH}
			// qr{^\^[[:upper:]_]\w+\}};
			PredicateAnd<
				PredicateIsChar< '^' >,
				PredicateFunc< is_upper_or_underscore >,
				PredicateOneOrMore< PredicateFunc< is_word > >,
				PredicateIsChar< '}' > > regex1;
			unsigned long pos = t->line_pos + 1;
			if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
				// cast token containing '$'
				t->changeTokenType( Token_Cast );
				t->c_token->length = 1;
				t->_finalize_token();
				// magic token containing the $${^MATCH}
				t->_new_token( Token_Magic );
				token = t->c_token;
				t->line_pos--;
				for ( unsigned long ix = t->line_pos; ix < pos; ix++ ) {
					token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
				}
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
		}

		if ( ( token->length == 2 ) && ( token->text[1] == '#' ) ) {
			if ( ( c_char == '$' ) || ( c_char == '{' ) ) {
				t->changeTokenType( Token_Cast );
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
			if ( is_word( c_char ) ) {
				t->changeTokenType( Token_ArrayIndex );
				return done_it_myself;
			}
		}

		if ( ( token->length == 2 ) && ( token->text[1] == '^' ) && is_word( c_char ) ) {
			// $^M or $^WIDE_SYSTEM_CALLS 
			while ( ( t->line_length > t->line_pos ) && is_word( t->c_line[ t->line_pos ] ) )
				token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
			token->text[ token->length ] = 0; 
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
	}
	if ( ( token->text[0] == '%' ) && ( token->length >= 1 ) && ( token->text[1] == '^' ) ) {
		// is this a magic token or a % operator?
		token->text[ token->length + 1 ] = '\0';
		if ( t->is_magic( token->text ) ) {
			token->length++;
			t->line_pos++;
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		// trat % as operator
		t->line_pos -= token->length - 1;
		token->length = 1;
		t->changeTokenType( Token_Operator );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	token->text[ token->length + 1 ] = 0;
	if ( t->is_magic( token->text ) ) {
		// $#+ and $#-
		t->line_pos++;
		token->length++;
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

bool MagicToken::isa( TokenTypeNames is_type ) const {
	return (( is_type == Token_Magic ) || ( is_type == Token_Symbol ));
}
