#include "tokenizer.h"
#include "forward_scan.h"
#include "quotes.h"

using namespace PPITokenizer;

enum ExtendedTokenState {
	inital = 0, // not even detected the type of quote
	consume_whitespaces,
	in_section_braced, 
	in_section_not_braced,
};

static unsigned char GetClosingSeperator( unsigned char opening ) {
	switch (opening) {
		case '<': return '>';
		case '{': return '}';
		case '(': return ')';
		case '[': return ']';
		default: return 0;
	}
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncConsumeModifiers(Tokenizer *t, ExtendedToken *token) {
	ExtendedToken::section &ms = token->modifiers;
	ms.size = 0;
	ms.position = token->length;
	if ( m_acceptModifiers ) {
		while ( ( t->line_length > t->line_pos ) && is_letter( t->c_line[ t->line_pos ] ) ) {
			token->text[token->length++] = t->c_line[ t->line_pos++ ];
			ms.size++;
		}
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncInSectionBraced(Tokenizer *t, ExtendedToken *token) {
	token->state = in_section_braced;
	unsigned char c_section_num = token->current_section - 1;
	ExtendedToken::section &cs = token->sections[ c_section_num ];
	bool slashed = false;
	while ( t->line_length > t->line_pos ) {
		unsigned char my_char = token->text[token->length++] = t->c_line[ t->line_pos++ ];
		if ( !slashed ) {
			if ( my_char == cs.close_char ) {
				if ( token->brace_counter == 0 ) {

					if ( token->current_section == m_numSections ) {
						return StateFuncConsumeModifiers( t, token );
					} else {
						// there is another section - read on
						//token->current_section++;
						return StateFuncExamineFirstChar( t, token );
					}
				} else {
					token->brace_counter--;
				}
			} else
			if ( my_char == cs.open_char ) {
				token->brace_counter++;
			}
		}
		slashed = ( my_char == '\\' ) ? !slashed : false;
		cs.size++;
	}
	// line ended before the section ended
	return done_it_myself;
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncInSectionUnBraced(Tokenizer *t, ExtendedToken *token) {
	token->state = in_section_not_braced;
	unsigned char c_section_num = token->current_section - 1;
	ExtendedToken::section &cs = token->sections[ c_section_num ];
	bool slashed = false;
	while ( t->line_length > t->line_pos ) {
		unsigned char my_char = token->text[token->length++] = t->c_line[ t->line_pos++ ];
		if ( ( !slashed ) && ( my_char == cs.close_char ) ) {

			if ( token->current_section == m_numSections ) {
				return StateFuncConsumeModifiers( t, token );
			} else {
				// there is another section - read on
				ExtendedToken::section &next = token->sections[ token->current_section ];
				token->current_section++;
				next.position = token->length;
				next.size = 0;
				next.open_char = cs.open_char;
				next.close_char = cs.close_char;
				return StateFuncInSectionUnBraced( t, token );
			}
		}
		slashed = ( my_char == '\\' ) ? !slashed : false;
		cs.size++;
	}
	// line ended before the section ended
	return done_it_myself;
}

// Assumation - the charecter we are on is the beginning seperator
CharTokenizeResults AbstractQuoteTokenType::StateFuncBootstrapSection(Tokenizer *t, ExtendedToken *token) {
	unsigned char my_char = t->c_line[ t->line_pos ];
	unsigned char c_section_num = token->current_section;
	token->text[token->length++] = t->c_line[ t->line_pos++ ];
	ExtendedToken::section &cs = token->sections[ c_section_num ];
	cs.position = token->length;
	token->current_section++;
	cs.size = 0;
	cs.open_char = my_char;
	unsigned char close_char = GetClosingSeperator( my_char );
	if ( close_char == 0 ) {
		cs.close_char = my_char;
		return StateFuncInSectionUnBraced( t, token );
	} else {
		// FIXME
		cs.close_char = close_char;
		token->brace_counter = 0;
		return StateFuncInSectionBraced( t, token );
	}
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncConsumeWhitespaces(Tokenizer *t, ExtendedToken *token) {
	token->state = consume_whitespaces;
	while ( t->line_length > t->line_pos ) {
		unsigned char my_char = t->c_line[ t->line_pos ];
		if ( is_whitespace( my_char ) ) {
			token->text[token->length++] = t->c_line[ t->line_pos++ ];
			continue;
		}
		if ( my_char == '#' ) {
			// this is a comment - eat until the end of the line
			while ( t->line_length > t->line_pos ) {
				token->text[token->length++] = t->c_line[ t->line_pos++ ];
			}
			return done_it_myself;
		}
		// the char is the beginning of the section - keep it
		return StateFuncBootstrapSection(t, token);
	}
	return done_it_myself;
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token) {
	if ( ! ( t->line_length > t->line_pos ) ) {
		// the end of the line
		return StateFuncConsumeWhitespaces( t, token );
	}
	unsigned char my_char = t->c_line[ t->line_pos ];
	if ( is_whitespace( my_char ) ) {
		return StateFuncConsumeWhitespaces( t, token );
	}
	return StateFuncBootstrapSection(t, token);
}

CharTokenizeResults AbstractQuoteTokenType::tokenize(Tokenizer *t, Token *token1, unsigned char c_char) {
	ExtendedToken *token = (ExtendedToken*)token1;
	switch ( token->state ) {
		case inital:
			return StateFuncExamineFirstChar( t, token );
		case consume_whitespaces:
			return StateFuncConsumeWhitespaces( t,  token );
		case in_section_braced:
			return StateFuncInSectionBraced( t, token );
		case in_section_not_braced:
			return StateFuncInSectionUnBraced( t, token );
	}
	sprintf(t->ErrorMsg, "Reached to AQTT::tokenize in undefined state. Token type %d, tokenizer position %d", token->type->type, t->line_pos);
	return error_fail;
}

CharTokenizeResults AbstractBareQuoteTokenType::StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token) {
	// in this case, we are already after the first char. 
	// rewind and let the boot strap section to handle it
	token->length--;
	t->line_pos--;
	return StateFuncBootstrapSection( t, token );
}

bool AbstractQuoteTokenType::isa( TokenTypeNames is_type ) const {
	return ( AbstractTokenType::isa(is_type) || 
		   ( is_type == isToken_QuoteOrQuotaLike) ||
		   ( is_type == isToken_Extended) );
}

bool AbstractExtendedTokenType::isa( TokenTypeNames is_type ) const {
	return ( AbstractTokenType::isa(is_type) || 
		   ( is_type == isToken_Extended) );
}

CharTokenizeResults AbstractSimpleQuote::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// the first char is always the beginning quote
	if ( token->length < 1 ) {
		token->text[token->length++] = t->c_line[ t->line_pos++ ];
	}

	bool is_slash = false;
	while ( t->line_length > t->line_pos ) {
		unsigned char my_char = token->text[token->length++] = t->c_line[ t->line_pos++ ];
		if ( ( !is_slash ) && ( my_char == seperator ) ) {
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		is_slash = ( my_char == '\\' ) ? !is_slash : false;
	}
	// will reach here only if the line ended while still in the string
	return done_it_myself; 
}

bool AbstractSimpleQuote::isa( TokenTypeNames is_type ) const {
	return ( AbstractTokenType::isa(is_type) || ( is_type == isToken_QuoteOrQuotaLike) );
}

bool ParameterizedAttributeToken::isa( TokenTypeNames is_type ) const {
	return ( ( is_type == type ) || ( is_type == Token_Attribute ) || ( is_type == isToken_Extended) );
}
