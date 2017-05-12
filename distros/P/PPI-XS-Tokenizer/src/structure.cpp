#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"
#include "forward_scan.h"
#include "structure.h"

using namespace PPITokenizer;

CharTokenizeResults StructureToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// Structures are one character long, always.
	// Finalize and process again.
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults StructureToken::commit(Tokenizer *t) {
	t->_new_token(Token_Structure);
	return my_char;
}

CharTokenizeResults CastToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults PrototypeToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// scanning untill a ')' or end of line. Prototype can not be multi-line.
	while ( t->line_length > t->line_pos ) {
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
		if ( t->c_line[ t->line_pos - 1 ] == ')' )
			break;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

extern const char l_utf32_be[] = "\x00\x00\xfe\xff"; // => 'UTF-32',
extern const char l_utf32_le[] = "\xff\xfe\x00\x00"; // => 'UTF-32',
extern const char l_utf16_be[] = "\xfe\xff"; //         => 'UTF-16',
extern const char l_utf16_le[] = "\xff\xfe"; //         => 'UTF-16',
extern const char l_utf8[] = "\xef\xbb\xbf"; //     => 'UTF-8',

CharTokenizeResults BOMToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	PredicateOr< 
		PredicateBinaryLiteral< 4, l_utf32_be >,
		PredicateBinaryLiteral< 4, l_utf32_le >,
		PredicateBinaryLiteral< 2, l_utf16_be >,
		PredicateBinaryLiteral< 2, l_utf16_le >
	> regex1;
	unsigned long pos = 0;
	if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
		sprintf(t->ErrorMsg, "BOM error: we do not support anything but ascii and utf8 (%02X,%02X)", t->c_line[0], t->c_line[1]);
		return error_fail; 
	}
	PredicateBinaryLiteral< 3, l_utf8 > regex2;
	if ( regex2.test( t->c_line, &pos, t->line_length ) ) {
		// well, if it's a utf8 maybe we will manage
		for (unsigned long ix = 0; ix < pos; ix++ ) {
			token->text[ ix ] = t->c_line[ ix ];
		}
		// move the beginning of the line to after the BOM
		t->c_line += pos;
		t->line_length -= pos;
		token->length = 3;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}
